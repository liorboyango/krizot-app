import { describe, expect, it } from 'vitest';

import {
  generateMissingShifts,
  splitIntoBlocks,
  zonedDayStartMs,
} from '../src/domain/shift_generator';
import { ShiftRecord, StationRecord } from '../src/domain/types';

const HOUR = 3_600_000;
const DAY_KEY = '2026-09-01';
/** 2026-09-01 is IDT (UTC+3): local midnight = 2026-08-31T21:00Z. */
const DAY_START = Date.parse('2026-08-31T21:00:00Z');
const OPTIONS = { defaultMinutes: 120, maxMinutes: 180 };

function station(overrides: Partial<StationRecord> = {}): StationRecord {
  return {
    id: 'stationA',
    name: 'Station A',
    status: 'active',
    requiredCertifications: [],
    manningType: 'onDemand',
    activeWindows: [],
    capacity: 1,
    ...overrides,
  };
}

function shift(startHour: number, endHour: number): ShiftRecord {
  return {
    id: `s${startHour}-${endHour}`,
    stationId: 'stationA',
    userId: null,
    startMs: DAY_START + startHour * HOUR,
    endMs: DAY_START + endHour * HOUR,
    dayKey: DAY_KEY,
  };
}

function generate(
  stations: StationRecord[],
  existing: ShiftRecord[] = [],
) {
  return generateMissingShifts(
    stations,
    existing,
    DAY_KEY,
    DAY_START,
    DAY_START + 24 * HOUR,
    OPTIONS,
  );
}

const hours = (spec: { startMs: number; endMs: number }) => [
  (spec.startMs - DAY_START) / HOUR,
  (spec.endMs - DAY_START) / HOUR,
];

describe('splitIntoBlocks', () => {
  const split = (durationHours: number) =>
    splitIntoBlocks(0, durationHours * HOUR, OPTIONS).map((block) => [
      block.startMs / HOUR,
      block.endMs / HOUR,
    ]);

  it('cuts default 2h blocks', () => {
    expect(split(4)).toEqual([
      [0, 2],
      [2, 4],
    ]);
  });

  it('merges a short remainder into one block up to the 3h cap', () => {
    expect(split(3)).toEqual([[0, 3]]);
    expect(split(5)).toEqual([
      [0, 2],
      [2, 5],
    ]);
  });

  it('keeps a remainder above the cap as separate blocks', () => {
    expect(split(3.5)).toEqual([
      [0, 2],
      [2, 3.5],
    ]);
  });

  it('handles a window shorter than the default', () => {
    expect(split(1)).toEqual([[0, 1]]);
  });
});

describe('generateMissingShifts', () => {
  it('covers a 24/7 station with twelve 2h blocks', () => {
    const specs = generate([station({ manningType: '24x7' })]);
    expect(specs).toHaveLength(12);
    expect(hours(specs[0])).toEqual([0, 2]);
    expect(hours(specs[11])).toEqual([22, 24]);
    expect(specs.every((spec) => spec.dayKey === DAY_KEY)).toBe(true);
  });

  it('covers only the active windows of an on-demand station', () => {
    const specs = generate([
      station({
        activeWindows: [{ startMinutes: 8 * 60, endMinutes: 13 * 60 }],
      }),
    ]);
    expect(specs.map(hours)).toEqual([
      [8, 10],
      [10, 13],
    ]);
  });

  it('generates nothing for an on-demand station without windows', () => {
    expect(generate([station()])).toEqual([]);
  });

  it('skips closed stations', () => {
    expect(
      generate([station({ manningType: '24x7', status: 'closed' })]),
    ).toEqual([]);
  });

  it('only fills the gaps around existing shifts', () => {
    const specs = generate(
      [
        station({
          activeWindows: [{ startMinutes: 8 * 60, endMinutes: 16 * 60 }],
        }),
      ],
      [shift(10, 12)],
    );
    expect(specs.map(hours)).toEqual([
      [8, 10],
      [12, 14],
      [14, 16],
    ]);
  });

  it('ignores an existing shift that already spans the whole window', () => {
    const specs = generate(
      [
        station({
          activeWindows: [{ startMinutes: 8 * 60, endMinutes: 12 * 60 }],
        }),
      ],
      [shift(7, 13)],
    );
    expect(specs).toEqual([]);
  });

  it('creates parallel blocks up to the station capacity', () => {
    const specs = generate(
      [
        station({
          capacity: 2,
          activeWindows: [{ startMinutes: 8 * 60, endMinutes: 10 * 60 }],
        }),
      ],
      [shift(8, 9)],
    );
    // Layer 1 runs wherever anyone is missing (8–10); layer 2 only where
    // two are missing (9–10). Every hour ends up staffed by exactly two.
    expect(specs.map(hours)).toEqual([
      [8, 10],
      [9, 10],
    ]);
  });

  it('extends a midnight-crossing window into the next day', () => {
    const specs = generate([
      station({
        activeWindows: [{ startMinutes: 22 * 60, endMinutes: 2 * 60 }],
      }),
    ]);
    expect(specs.map(hours)).toEqual([
      [22, 24],
      [24, 26],
    ]);
    expect(specs.every((spec) => spec.dayKey === DAY_KEY)).toBe(true);
  });
});

describe('zonedDayStartMs', () => {
  it('resolves Israel summer midnight (UTC+3)', () => {
    expect(zonedDayStartMs('2026-09-01', 'Asia/Jerusalem')).toBe(
      Date.parse('2026-08-31T21:00:00Z'),
    );
  });

  it('resolves Israel winter midnight (UTC+2)', () => {
    expect(zonedDayStartMs('2026-01-15', 'Asia/Jerusalem')).toBe(
      Date.parse('2026-01-14T22:00:00Z'),
    );
  });

  it('resolves UTC unchanged', () => {
    expect(zonedDayStartMs('2026-09-01', 'UTC')).toBe(
      Date.parse('2026-09-01T00:00:00Z'),
    );
  });
});
