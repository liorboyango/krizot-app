/**
 * Pure shift generation: given the stations' manning definitions and the
 * shifts that already exist on a day, produce the missing shift blocks so
 * auto-fill always has a complete skeleton to assign into.
 *
 * Durations are not a station property: blocks default to 2 hours and never
 * exceed 3 hours; managers can afterwards edit any single occurrence.
 *
 * A day "owns" the manning windows that START on it — a 22:00–06:00 window
 * generates its whole span (including the after-midnight blocks) under the
 * planning day's dayKey, and the next day's run does not regenerate them.
 */

import { ShiftRecord, StationRecord, StationWindow } from './types';

export interface ShiftSpec {
  stationId: string;
  startMs: number;
  endMs: number;
  dayKey: string;
}

export interface BlockOptions {
  defaultMinutes: number;
  maxMinutes: number;
}

interface MsWindow {
  startMs: number;
  endMs: number;
}

/**
 * Split [startMs, endMs) into default-length blocks, merging the final
 * remainder into one block when it fits under the cap — so a 3h window
 * yields a single 3h shift rather than 2h + 1h.
 */
export function splitIntoBlocks(
  startMs: number,
  endMs: number,
  options: BlockOptions,
): MsWindow[] {
  const defaultMs = options.defaultMinutes * 60_000;
  const maxMs = options.maxMinutes * 60_000;
  const blocks: MsWindow[] = [];
  let cursor = startMs;
  while (cursor < endMs) {
    const remaining = endMs - cursor;
    const blockMs = remaining <= maxMs ? remaining : defaultMs;
    blocks.push({ startMs: cursor, endMs: cursor + blockMs });
    cursor += blockMs;
  }
  return blocks;
}

/** A station's required manning windows on the day, in epoch ms. */
function requiredWindows(
  station: StationRecord,
  dayStartMs: number,
  dayEndMs: number,
): MsWindow[] {
  if (station.manningType === '24x7') {
    return [{ startMs: dayStartMs, endMs: dayEndMs }];
  }
  return (station.activeWindows ?? []).map((window: StationWindow) => ({
    startMs: dayStartMs + window.startMinutes * 60_000,
    endMs:
      dayStartMs +
      (window.endMinutes <= window.startMinutes
        ? window.endMinutes + 24 * 60
        : window.endMinutes) *
        60_000,
  }));
}

/**
 * The shifts that must be created so every active station is manned (at its
 * capacity) throughout its required windows, given what already exists.
 */
export function generateMissingShifts(
  stations: StationRecord[],
  existingShifts: ShiftRecord[],
  dayKey: string,
  dayStartMs: number,
  dayEndMs: number,
  options: BlockOptions,
): ShiftSpec[] {
  const specs: ShiftSpec[] = [];
  for (const station of stations) {
    if (station.status !== 'active') continue;
    const stationShifts = existingShifts.filter(
      (shift) => shift.stationId === station.id,
    );
    for (const window of requiredWindows(station, dayStartMs, dayEndMs)) {
      specs.push(
        ...coverWindow(station, stationShifts, window, dayKey, options),
      );
    }
  }
  return specs;
}

/** Blocks filling every sub-range of [window] where fewer than `capacity`
 * existing shifts run — layered, so a double-staffed station short one
 * person still gets exactly one parallel shift. */
function coverWindow(
  station: StationRecord,
  stationShifts: ShiftRecord[],
  window: MsWindow,
  dayKey: string,
  options: BlockOptions,
): ShiftSpec[] {
  const capacity = station.capacity ?? 1;

  // Elementary segments between every shift boundary inside the window.
  const boundaries = new Set([window.startMs, window.endMs]);
  for (const shift of stationShifts) {
    if (shift.startMs > window.startMs && shift.startMs < window.endMs) {
      boundaries.add(shift.startMs);
    }
    if (shift.endMs > window.startMs && shift.endMs < window.endMs) {
      boundaries.add(shift.endMs);
    }
  }
  const sorted = [...boundaries].sort((a, b) => a - b);
  const segments = sorted.slice(0, -1).map((segStart, i) => {
    const segEnd = sorted[i + 1];
    const covered = stationShifts.filter(
      (shift) => shift.startMs <= segStart && shift.endMs >= segEnd,
    ).length;
    return { startMs: segStart, endMs: segEnd, deficit: capacity - covered };
  });

  const specs: ShiftSpec[] = [];
  for (let layer = 1; layer <= capacity; layer++) {
    let runStart: number | null = null;
    const flush = (runEnd: number) => {
      if (runStart === null) return;
      for (const block of splitIntoBlocks(runStart, runEnd, options)) {
        specs.push({ stationId: station.id, dayKey, ...block });
      }
      runStart = null;
    };
    for (const segment of segments) {
      if (segment.deficit >= layer) {
        runStart ??= segment.startMs;
      } else {
        flush(segment.startMs);
      }
    }
    flush(window.endMs);
  }
  return specs;
}

/**
 * Epoch ms of local midnight of [dayKey] in [timeZone]. Two-pass offset
 * correction keeps DST transition days honest.
 */
export function zonedDayStartMs(dayKey: string, timeZone: string): number {
  const utcMidnight = Date.parse(`${dayKey}T00:00:00Z`);
  const firstGuess = utcMidnight - zoneOffsetMs(utcMidnight, timeZone);
  return utcMidnight - zoneOffsetMs(firstGuess, timeZone);
}

/** Offset (local − UTC) of [timeZone] at the instant [atMs]. */
function zoneOffsetMs(atMs: number, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(new Date(atMs));
  const get = (type: string) =>
    Number(parts.find((part) => part.type === type)?.value);
  const asUtc = Date.UTC(
    get('year'),
    get('month') - 1,
    get('day'),
    get('hour') % 24,
    get('minute'),
    get('second'),
  );
  return asUtc - atMs;
}
