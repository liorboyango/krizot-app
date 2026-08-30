/**
 * Demo-data seeder: a full Hebrew-named roster — 20 Hagana, 40 Bakara and
 * 20 Officer per unit×department (2 units × 2 departments → 320 users) on
 * the certification ladder, plus a fully assigned two-week schedule over
 * the existing stations.
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=service-account.json \
 *     npx tsx scripts/seed-demo.ts
 *
 * Against the emulator suite:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 GCLOUD_PROJECT=krizot-66232 \
 *     npx tsx scripts/seed-demo.ts
 *
 * Behavior:
 * - Certifications are matched by name against the existing catalog (ladder
 *   order: Maar → Pnim → Miz → Heli → Inter → Btk → Manager); missing ones
 *   are created. Held rungs are cumulative and role-based: Hagana 1–3,
 *   Bakara 2–5, Officer 4–7.
 * - Users are written as `demo-user-NN` docs (Firestore only, no Auth) and
 *   are wiped and re-created on every run.
 * - Existing real users (non `demo-user-*`) are backfilled, never wiped:
 *   held certifications missing an earned-at date get staggered ones, a
 *   missing courseNumber is derived from how many certifications they hold,
 *   and anyone without an upcoming presence window gets one covering the
 *   seeded fortnight.
 * - Shifts are generated for the next 14 days from every active station's
 *   windows and assigned greedily (certs ∧ no overlap ∧ ≤12h/day, least
 *   loaded first). Thu–Sun only the most-certified third of the roster is
 *   treated as available. Previous `createdBy == 'seed-demo'` shifts are
 *   wiped first.
 */

import { initializeApp } from 'firebase-admin/app';
import {
  FieldPath,
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';

import {
  COLLECTION_AVAILABILITY,
  COLLECTION_CERTIFICATIONS,
  COLLECTION_DAY_REQUIREMENTS,
  COLLECTION_SHIFTS,
  COLLECTION_STATIONS,
  COLLECTION_TRAINING_SESSIONS,
  COLLECTION_USERS,
  DATABASE_ID,
  DEFAULT_SHIFT_MINUTES,
  MAX_SHIFT_MINUTES,
} from '../src/constants';
import { splitIntoBlocks } from '../src/domain/shift_generator';

const SEED_MARKER = 'seed-demo';
const USER_ID_PREFIX = 'demo-user-';
const SCHEDULE_DAYS = 14;
const MAX_DAILY_HOURS = 12;
const TRAINING_DAYS = 7;
/** Course numbers ascend with recency; more certified → lower number. */
const FIRST_COURSE_NUMBER = 10;

// Organizational layers (see AppUser.site/department/jobRole).
const SITES = ['506', '509'];
const DEPARTMENTS = ['mesima', 'taavura'];
/** Roster per (unit, department): 20 Hagana, 40 Bakara, 20 Officer. */
const ROLE_QUOTAS: Record<string, number> = {
  hagana: 20,
  bakara: 40,
  officer: 20,
};
const USERS_PER_GROUP = Object.values(ROLE_QUOTAS).reduce((a, b) => a + b, 0);

/** Ladder order in which certifications are gained (first = everyone). */
const CERT_LADDER = ['Maar', 'Pnim', 'Miz', 'Heli', 'Inter', 'Btk', 'Manager'];
const CERT_COLORS = [
  '#0D7CFF',
  '#00A86B',
  '#F59E0B',
  '#8B5CF6',
  '#EC4899',
  '#EF4444',
  '#111827',
];

// 40 first × 10 last names → 400 unique combinations for the 320 users.
const FIRST_NAMES = [
  'אבי', 'יעל', 'משה', 'נועה', 'דוד', 'שרה', 'יוסי', 'רות', 'איתן', 'מיכל',
  'עומר', 'תמר', 'אלון', 'הילה', 'נדב', 'ליאור', 'גיא', 'דנה', 'רועי', 'שירה',
  'אורי', 'ענת', 'יונתן', 'מאיה', 'עידו', 'ליטל', 'ברק', 'קרן', 'אסף', 'גלית',
  'נמרוד', 'אורית', 'שי', 'רונית', 'אריאל', 'טליה', 'יובל', 'מירב', 'אלעד', 'נטע',
];
const LAST_NAMES = [
  'כהן', 'לוי', 'פרץ', 'ביטון', 'מזרחי',
  'אזולאי', 'אוחיון', 'דהן', 'חדד', 'עמר',
];

function hebrewName(index: number): string {
  const first = FIRST_NAMES[index % FIRST_NAMES.length];
  const last =
    LAST_NAMES[Math.floor(index / FIRST_NAMES.length) % LAST_NAMES.length];
  return `${first} ${last}`;
}

/** Thu–Sun; only the weekend pool may be assigned on these days. */
const WEEKEND_JS_DAYS = new Set([4, 5, 6, 0]);

interface SeedUser {
  id: string;
  displayName: string;
  certIds: string[];
  site: string;
  department: string;
  jobRole: string;
}

interface PlannedTraining {
  certificationId: string;
  type: 'simulation' | 'spectation' | 'tutoring';
  traineeId: string;
  trainerIds: string[];
  start: Date;
  end: Date;
  dayKey: string;
  priority: number;
}

interface StationDoc {
  id: string;
  name: string;
  requiredCertifications: string[];
  capacity: number;
  windows: { startMinutes: number; endMinutes: number }[];
  /** Org scope; an unset layer accepts anyone. */
  site?: string;
  department?: string;
  jobRole?: string;
}

interface PlannedShift {
  stationId: string;
  start: Date;
  end: Date;
  dayKey: string;
  userId: string | null;
}

function dayKeyOf(date: Date): string {
  const y = date.getFullYear();
  const m = `${date.getMonth() + 1}`.padStart(2, '0');
  const d = `${date.getDate()}`.padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function parseHhmm(value: string | undefined, fallback: number): number {
  if (!value) return fallback;
  const [h, m] = value.split(':').map((part) => parseInt(part, 10));
  if (Number.isNaN(h)) return fallback;
  return h * 60 + (Number.isNaN(m) ? 0 : m);
}

/** Commit writes in chunks below the 500-op batch limit. */
class BatchWriter {
  private ops = 0;
  private batch;

  constructor(private readonly db: Firestore) {
    this.batch = db.batch();
  }

  async set(ref: FirebaseFirestore.DocumentReference, data: object) {
    this.batch.set(ref, data);
    await this.tick();
  }

  async delete(ref: FirebaseFirestore.DocumentReference) {
    this.batch.delete(ref);
    await this.tick();
  }

  private async tick() {
    if (++this.ops >= 450) {
      await this.batch.commit();
      this.batch = this.db.batch();
      this.ops = 0;
    }
  }

  async flush() {
    if (this.ops > 0) await this.batch.commit();
    this.ops = 0;
  }
}

async function resolveCertLadder(db: Firestore): Promise<string[]> {
  const snapshot = await db.collection(COLLECTION_CERTIFICATIONS).get();
  const existing = snapshot.docs.map((doc) => ({
    id: doc.id,
    name: (doc.data().name as string) ?? '',
  }));
  const ids: string[] = [];
  for (const [index, ladderName] of CERT_LADDER.entries()) {
    const needle = ladderName.toLowerCase();
    const match = existing.find((cert) => {
      const name = cert.name.toLowerCase();
      return name === needle || name.includes(needle) || needle.includes(name);
    });
    if (match) {
      console.log(`  cert '${ladderName}' → existing '${match.name}' (${match.id})`);
      ids.push(match.id);
      continue;
    }
    const ref = await db.collection(COLLECTION_CERTIFICATIONS).add({
      name: ladderName,
      color: CERT_COLORS[index],
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log(`  cert '${ladderName}' → created (${ref.id})`);
    ids.push(ref.id);
  }

  // Training metadata: the ladder index doubles as the level (higher rung =
  // higher default training priority); rungs from the third up need a
  // holder of themselves plus one of the rung below to run a simulation.
  for (const [index, id] of ids.entries()) {
    await db.collection(COLLECTION_CERTIFICATIONS).doc(id).set(
      {
        level: index + 1,
        simulationStaff:
          index >= 2
            ? [
                { certificationId: id, count: 1 },
                { certificationId: ids[index - 1], count: 1 },
              ]
            : [],
      },
      { merge: true },
    );
  }
  return ids;
}

async function wipePreviousSeed(db: Firestore) {
  const writer = new BatchWriter(db);
  const users = await db
    .collection(COLLECTION_USERS)
    .where(FieldPath.documentId(), '>=', USER_ID_PREFIX)
    .where(FieldPath.documentId(), '<', `${USER_ID_PREFIX}\uf8ff`)
    .get();
  for (const doc of users.docs) await writer.delete(doc.ref);

  const shifts = await db
    .collection(COLLECTION_SHIFTS)
    .where('createdBy', '==', SEED_MARKER)
    .get();
  for (const doc of shifts.docs) await writer.delete(doc.ref);

  const windows = await db
    .collection(COLLECTION_AVAILABILITY)
    .where('notes', '==', SEED_MARKER)
    .get();
  for (const doc of windows.docs) await writer.delete(doc.ref);

  const sessions = await db
    .collection(COLLECTION_TRAINING_SESSIONS)
    .where('createdBy', '==', SEED_MARKER)
    .get();
  for (const doc of sessions.docs) await writer.delete(doc.ref);

  const requirements = await db
    .collection(COLLECTION_DAY_REQUIREMENTS)
    .where('lastModifiedBy', '==', SEED_MARKER)
    .get();
  for (const doc of requirements.docs) await writer.delete(doc.ref);

  await writer.flush();
  console.log(
    `Wiped ${users.size} previous demo user(s), ${shifts.size} demo ` +
      `shift(s), ${windows.size} window(s), ${sessions.size} training ` +
      `session(s), ${requirements.size} day requirement(s).`,
  );
}

/** Cumulative ladder rungs held, by role: guards junior, officers senior. */
function rungsFor(jobRole: string, indexInRole: number): number {
  switch (jobRole) {
    case 'officer':
      return 4 + (indexInRole % 4); // 4–7
    case 'bakara':
      return 2 + (indexInRole % 4); // 2–5
    default:
      return 1 + (indexInRole % 3); // hagana 1–3
  }
}

async function seedUsers(db: Firestore, certIds: string[]): Promise<SeedUser[]> {
  const writer = new BatchWriter(db);
  const users: SeedUser[] = [];
  const now = Date.now();
  const QUARTER_MS = 90 * 24 * 3_600_000;
  let index = 0;
  for (const site of SITES) {
    for (const department of DEPARTMENTS) {
      for (const [jobRole, quota] of Object.entries(ROLE_QUOTAS)) {
        for (let inRole = 0; inRole < quota; inRole++) {
          const rungs = rungsFor(jobRole, inRole);
          const id = `${USER_ID_PREFIX}${`${index + 1}`.padStart(3, '0')}`;
          const user: SeedUser = {
            id,
            displayName: hebrewName(index),
            certIds: certIds.slice(0, rungs),
            site,
            department,
            jobRole,
          };
          users.push(user);
          // One rung earned per quarter, the highest most recently.
          const certificationTimes = Object.fromEntries(
            user.certIds.map((certId, rung) => [
              certId,
              Timestamp.fromMillis(now - (rungs - rung) * QUARTER_MS),
            ]),
          );
          await writer.set(db.collection(COLLECTION_USERS).doc(id), {
            displayName: user.displayName,
            email: `demo${`${index + 1}`.padStart(3, '0')}@krizot.demo`,
            role: 'employee',
            certifications: user.certIds,
            certificationTimes,
            // The most-certified users belong to the earliest course cohort.
            courseNumber: FIRST_COURSE_NUMBER + (CERT_LADDER.length - rungs),
            site,
            department,
            jobRole,
            status: 'available',
            fcmTokens: {},
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          index++;
        }
      }
    }
  }
  await writer.flush();
  console.log(`Created ${users.length} demo users ` +
      `(${USERS_PER_GROUP} per unit×department).`);
  return users;
}

/**
 * Enrich real (non-demo) users in place so the app looks complete for them
 * too. Only ever fills gaps — nothing a manager already set is touched:
 * - an earned-at date for every held certification missing one (staggered
 *   one quarter apart, most recent last, like the demo users);
 * - a course number derived from certification count (more certifications →
 *   earlier cohort), clamped to the demo cohort range;
 * - a presence window covering the seeded fortnight when the user has no
 *   window ending after [start] (marked SEED_MARKER, so re-runs refresh it).
 */
async function backfillExistingUsers(db: Firestore, start: Date) {
  const snapshot = await db.collection(COLLECTION_USERS).get();
  const realUsers = snapshot.docs.filter(
    (doc) => !doc.id.startsWith(USER_ID_PREFIX),
  );
  const now = Date.now();
  const QUARTER_MS = 90 * 24 * 3_600_000;
  let patched = 0;
  let windowCount = 0;

  for (const doc of realUsers) {
    const data = doc.data();
    const certIds = (data.certifications as string[]) ?? [];
    const certTimes =
      (data.certificationTimes as Record<string, Timestamp>) ?? {};
    const update: Record<string, unknown> = {};

    // Dotted field paths patch individual map entries without clobbering
    // the dates managers already set.
    const missing = certIds.filter((certId) => certTimes[certId] == null);
    for (const [index, certId] of missing.entries()) {
      update[`certificationTimes.${certId}`] = Timestamp.fromMillis(
        now - (missing.length - index) * QUARTER_MS,
      );
    }

    if (data.courseNumber == null) {
      // Same seniority mapping as the demo roster: more certifications →
      // earlier (lower) course cohort.
      update.courseNumber =
        FIRST_COURSE_NUMBER + Math.max(0, CERT_LADDER.length - certIds.length);
    }

    if (Object.keys(update).length > 0) {
      update.updatedAt = FieldValue.serverTimestamp();
      await doc.ref.update(update);
      patched++;
    }

    const upcoming = await db
      .collection(COLLECTION_AVAILABILITY)
      .where('userId', '==', doc.id)
      .where('end', '>', Timestamp.fromDate(start))
      .limit(1)
      .get();
    if (upcoming.empty) {
      await db.collection(COLLECTION_AVAILABILITY).add({
        userId: doc.id,
        start: Timestamp.fromDate(start),
        end: Timestamp.fromDate(
          new Date(
            start.getFullYear(),
            start.getMonth(),
            start.getDate() + SCHEDULE_DAYS,
          ),
        ),
        notes: SEED_MARKER,
        createdAt: FieldValue.serverTimestamp(),
      });
      windowCount++;
    }
  }
  console.log(
    `Backfilled ${patched} of ${realUsers.length} existing user(s), ` +
      `added ${windowCount} presence window(s).`,
  );
}

async function loadOrCreateStations(
  db: Firestore,
  certIds: string[],
): Promise<StationDoc[]> {
  const snapshot = await db
    .collection(COLLECTION_STATIONS)
    .where('status', '==', 'active')
    .get();
  if (!snapshot.empty) {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const windows = ((data.activeWindows as { start?: string; end?: string }[]) ?? [])
        .map((w) => ({
          startMinutes: parseHhmm(w.start, 0),
          endMinutes: parseHhmm(w.end, 0),
        }));
      const is247 = data.manningType === '24x7';
      return {
        id: doc.id,
        name: (data.name as string) ?? doc.id,
        requiredCertifications: (data.requiredCertifications as string[]) ?? [],
        capacity: (data.capacity as number) ?? 1,
        windows: is247 || windows.length === 0
          ? [{ startMinutes: 0, endMinutes: 24 * 60 }]
          : windows,
        site: data.site as string | undefined,
        department: data.department as string | undefined,
        jobRole: data.jobRole as string | undefined,
      };
    });
  }

  // Empty catalog (fresh project / emulator) — create a demo set so the
  // two-week schedule has something to fill.
  console.log('No active stations found — creating 4 demo stations.');
  const demoStations = [
    {
      name: 'שער ראשי',
      manningType: '24x7',
      activeWindows: [],
      requiredCertifications: [certIds[0]],
    },
    {
      name: 'סיור פנים',
      manningType: 'onDemand',
      activeWindows: [{ start: '06:00', end: '22:00' }],
      requiredCertifications: [certIds[0], certIds[1]],
    },
    {
      name: 'מגדל מזרחי',
      manningType: 'onDemand',
      activeWindows: [{ start: '08:00', end: '20:00' }],
      requiredCertifications: [certIds[0], certIds[2]],
    },
    {
      name: 'מנחת מסוקים',
      manningType: 'onDemand',
      activeWindows: [{ start: '10:00', end: '18:00' }],
      requiredCertifications: [certIds[0], certIds[3]],
    },
  ];
  const created: StationDoc[] = [];
  for (const station of demoStations) {
    const ref = await db.collection(COLLECTION_STATIONS).add({
      ...station,
      status: 'active',
      capacity: 1,
      notes: SEED_MARKER,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    created.push({
      id: ref.id,
      name: station.name,
      requiredCertifications: station.requiredCertifications,
      capacity: 1,
      windows: station.manningType === '24x7'
        ? [{ startMinutes: 0, endMinutes: 24 * 60 }]
        : station.activeWindows.map((w) => ({
            startMinutes: parseHhmm(w.start, 0),
            endMinutes: parseHhmm(w.end, 0),
          })),
    });
  }
  return created;
}

function planShifts(stations: StationDoc[], start: Date): PlannedShift[] {
  const shifts: PlannedShift[] = [];
  for (let dayOffset = 0; dayOffset < SCHEDULE_DAYS; dayOffset++) {
    const day = new Date(start.getFullYear(), start.getMonth(), start.getDate() + dayOffset);
    for (const station of stations) {
      for (const window of station.windows) {
        // Windows ending at/before their start cross midnight.
        const endMinutes = window.endMinutes <= window.startMinutes
          ? window.endMinutes + 24 * 60
          : window.endMinutes;
        // Same block policy as the auto-fill generator: 2h default, 3h max.
        const blocks = splitIntoBlocks(
          day.getTime() + window.startMinutes * 60_000,
          day.getTime() + endMinutes * 60_000,
          { defaultMinutes: DEFAULT_SHIFT_MINUTES, maxMinutes: MAX_SHIFT_MINUTES },
        );
        for (const block of blocks) {
          for (let seat = 0; seat < station.capacity; seat++) {
            shifts.push({
              stationId: station.id,
              start: new Date(block.startMs),
              end: new Date(block.endMs),
              dayKey: dayKeyOf(day),
              userId: null,
            });
          }
        }
      }
    }
  }
  return shifts;
}

/**
 * Presence windows per user: the weekend pool lives on-site for the whole
 * fortnight; everyone else is present Mon–Fri of each seeded week
 * (arriving at midnight, leaving at midnight — full-day coverage so night
 * shifts stay assignable).
 */
function planAvailability(
  users: SeedUser[],
  weekendPool: Set<string>,
  start: Date,
): Map<string, { start: Date; end: Date }[]> {
  const dayAt = (offset: number) =>
    new Date(start.getFullYear(), start.getMonth(), start.getDate() + offset);
  const windows = new Map<string, { start: Date; end: Date }[]>();
  for (const user of users) {
    if (weekendPool.has(user.id)) {
      windows.set(user.id, [
        { start: dayAt(0), end: dayAt(SCHEDULE_DAYS) },
      ]);
      continue;
    }
    // Two on-site stretches of five days, one per seeded week.
    windows.set(user.id, [
      { start: dayAt(0), end: dayAt(5) },
      { start: dayAt(7), end: dayAt(12) },
    ]);
  }
  return windows;
}

/**
 * Training sessions over the first week: two blocks per day rotating over
 * the upper ladder rungs, matching each certification's staffing rules.
 * The trainee is always the most-certified user NOT yet holding the rung.
 */
function planTraining(
  users: SeedUser[],
  certIds: string[],
  start: Date,
): PlannedTraining[] {
  const TYPES: PlannedTraining['type'][] = [
    'simulation',
    'spectation',
    'tutoring',
  ];
  const SLOTS = [
    { startHour: 10, endHour: 12 },
    { startHour: 14, endHour: 16 },
  ];
  const sessions: PlannedTraining[] = [];
  for (let dayOffset = 0; dayOffset < TRAINING_DAYS; dayOffset++) {
    const day = new Date(
      start.getFullYear(),
      start.getMonth(),
      start.getDate() + dayOffset,
    );
    for (const [slotIndex, slot] of SLOTS.entries()) {
      // Rotate over the rungs that actually have non-holders to train.
      const rung = 2 + ((dayOffset + slotIndex) % (certIds.length - 2));
      const certId = certIds[rung];
      const holders = users.filter((u) => u.certIds.includes(certId));
      const nonHolders = users.filter((u) => !u.certIds.includes(certId));
      if (holders.length < 2 || nonHolders.length === 0) continue;
      const type = TYPES[(dayOffset + slotIndex) % TYPES.length];
      // Simulation staffing (see resolveCertLadder): one holder of the rung
      // plus one holder of the rung below — holders are cumulative, so two
      // rung-holders satisfy both.
      const trainerIds =
        type === 'simulation'
          ? [holders[0].id, holders[1].id]
          : [holders[(dayOffset + slotIndex) % holders.length].id];
      const startAt = new Date(day.getTime() + slot.startHour * 3_600_000);
      sessions.push({
        certificationId: certId,
        type,
        traineeId: nonHolders[0].id,
        trainerIds,
        start: startAt,
        end: new Date(day.getTime() + slot.endHour * 3_600_000),
        dayKey: dayKeyOf(startAt),
        priority: rung + 1,
      });
    }
  }
  return sessions;
}

function assignShifts(
  shifts: PlannedShift[],
  stations: StationDoc[],
  users: SeedUser[],
  weekendPool: Set<string>,
  availability: Map<string, { start: Date; end: Date }[]>,
  training: PlannedTraining[],
) {
  const stationById = new Map(stations.map((s) => [s.id, s]));
  const totalMs = new Map<string, number>(users.map((u) => [u.id, 0]));
  const dailyMs = new Map<string, number>();
  const assignedByUser = new Map<string, PlannedShift[]>(
    users.map((u) => [u.id, []]),
  );
  const trainingByUser = new Map<string, PlannedTraining[]>();
  for (const session of training) {
    for (const uid of [session.traineeId, ...session.trainerIds]) {
      trainingByUser.set(uid, [...(trainingByUser.get(uid) ?? []), session]);
    }
  }

  const ordered = [...shifts].sort(
    (a, b) => a.start.getTime() - b.start.getTime(),
  );
  for (const shift of ordered) {
    const station = stationById.get(shift.stationId);
    if (!station) continue;
    const isWeekend = WEEKEND_JS_DAYS.has(shift.start.getDay());
    const durationMs = shift.end.getTime() - shift.start.getTime();
    const candidates = users.filter((user) => {
      if (isWeekend && !weekendPool.has(user.id)) return false;
      // Org scope: every layer the station pins must match.
      if (station.site && user.site !== station.site) return false;
      if (station.department && user.department !== station.department) {
        return false;
      }
      if (station.jobRole && user.jobRole !== station.jobRole) return false;
      if (
        !station.requiredCertifications.every((cert) =>
          user.certIds.includes(cert),
        )
      ) {
        return false;
      }
      // On-site per the presence calendar for the whole shift.
      const windows = availability.get(user.id) ?? [];
      if (
        windows.length > 0 &&
        !windows.some((w) => w.start <= shift.start && w.end >= shift.end)
      ) {
        return false;
      }
      // Not tied up in a training session.
      if (
        (trainingByUser.get(user.id) ?? []).some(
          (s) => s.start < shift.end && shift.start < s.end,
        )
      ) {
        return false;
      }
      const dayLoad = dailyMs.get(`${user.id}|${shift.dayKey}`) ?? 0;
      if (dayLoad + durationMs > MAX_DAILY_HOURS * 3_600_000) return false;
      return !assignedByUser
        .get(user.id)!
        .some((other) => other.start < shift.end && shift.start < other.end);
    });
    if (candidates.length === 0) continue;
    candidates.sort((a, b) => totalMs.get(a.id)! - totalMs.get(b.id)!);
    const chosen = candidates[0];
    shift.userId = chosen.id;
    totalMs.set(chosen.id, totalMs.get(chosen.id)! + durationMs);
    const dayLoadKey = `${chosen.id}|${shift.dayKey}`;
    dailyMs.set(dayLoadKey, (dailyMs.get(dayLoadKey) ?? 0) + durationMs);
    assignedByUser.get(chosen.id)!.push(shift);
  }
}

async function writeShifts(db: Firestore, shifts: PlannedShift[]) {
  const writer = new BatchWriter(db);
  let assigned = 0;
  for (const [index, shift] of shifts.entries()) {
    const isAssigned = shift.userId !== null;
    if (isAssigned) assigned++;
    // Mix of acknowledged/pending assignments so the scheduler shows both.
    const acknowledged = isAssigned && index % 5 < 3;
    await writer.set(db.collection(COLLECTION_SHIFTS).doc(), {
      stationId: shift.stationId,
      userId: shift.userId,
      start: Timestamp.fromDate(shift.start),
      end: Timestamp.fromDate(shift.end),
      dayKey: shift.dayKey,
      status: isAssigned ? 'assigned' : 'open',
      acknowledged,
      ackAt: acknowledged ? Timestamp.fromDate(shift.start) : null,
      source: 'manual',
      createdBy: SEED_MARKER,
      lastModifiedBy: SEED_MARKER,
      lastModifiedAt: FieldValue.serverTimestamp(),
    });
  }
  await writer.flush();
  console.log(
    `Wrote ${shifts.length} shifts over ${SCHEDULE_DAYS} days ` +
      `(${assigned} assigned, ${shifts.length - assigned} open).`,
  );
}

async function writeAvailability(
  db: Firestore,
  availability: Map<string, { start: Date; end: Date }[]>,
) {
  const writer = new BatchWriter(db);
  let count = 0;
  for (const [userId, windows] of availability) {
    for (const window of windows) {
      count++;
      await writer.set(db.collection(COLLECTION_AVAILABILITY).doc(), {
        userId,
        start: Timestamp.fromDate(window.start),
        end: Timestamp.fromDate(window.end),
        notes: SEED_MARKER,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  }
  await writer.flush();
  console.log(`Wrote ${count} availability window(s).`);
}

async function writeTraining(db: Firestore, sessions: PlannedTraining[]) {
  const writer = new BatchWriter(db);
  for (const session of sessions) {
    await writer.set(db.collection(COLLECTION_TRAINING_SESSIONS).doc(), {
      certificationId: session.certificationId,
      type: session.type,
      traineeId: session.traineeId,
      trainerIds: session.trainerIds,
      start: Timestamp.fromDate(session.start),
      end: Timestamp.fromDate(session.end),
      dayKey: session.dayKey,
      priority: session.priority,
      createdBy: SEED_MARKER,
      lastModifiedBy: SEED_MARKER,
      lastModifiedAt: FieldValue.serverTimestamp(),
    });
  }
  await writer.flush();
  console.log(`Wrote ${sessions.length} training session(s).`);
}

/** Every seeded day requires 4× rung-1, 2× rung-2 and 1× rung-4 holders. */
async function writeDayRequirements(
  db: Firestore,
  certIds: string[],
  start: Date,
) {
  const writer = new BatchWriter(db);
  for (let dayOffset = 0; dayOffset < SCHEDULE_DAYS; dayOffset++) {
    const day = new Date(
      start.getFullYear(),
      start.getMonth(),
      start.getDate() + dayOffset,
    );
    const dayKey = dayKeyOf(day);
    await writer.set(
      db.collection(COLLECTION_DAY_REQUIREMENTS).doc(dayKey),
      {
        dayKey,
        requirements: [
          { certificationId: certIds[0], count: 4 },
          { certificationId: certIds[1], count: 2 },
          { certificationId: certIds[3], count: 1 },
        ],
        lastModifiedBy: SEED_MARKER,
        lastModifiedAt: FieldValue.serverTimestamp(),
      },
    );
  }
  await writer.flush();
  console.log(`Wrote ${SCHEDULE_DAYS} day requirement doc(s).`);
}

async function main() {
  initializeApp();
  const db = getFirestore(DATABASE_ID);

  console.log('Resolving certification ladder…');
  const certIds = await resolveCertLadder(db);

  await wipePreviousSeed(db);
  const users = await seedUsers(db, certIds);

  const today = new Date();
  const startOfToday = new Date(
    today.getFullYear(),
    today.getMonth(),
    today.getDate(),
  );

  // Real users keep whatever managers set; only their gaps are filled.
  await backfillExistingUsers(db, startOfToday);

  // The most-certified third is the only pool available Thu–Sun; because
  // the ladder is cumulative they cover every certification the roster can
  // offer.
  const byCertCount = [...users].sort(
    (a, b) => b.certIds.length - a.certIds.length,
  );
  const weekendPool = new Set(
    byCertCount.slice(0, Math.floor(users.length / 3)).map((u) => u.id),
  );
  console.log(
    `Weekend (Thu–Sun) pool: ${weekendPool.size} most-certified users.`,
  );

  const stations = await loadOrCreateStations(db, certIds);
  console.log(`Scheduling over ${stations.length} active station(s).`);

  const availability = planAvailability(users, weekendPool, startOfToday);
  await writeAvailability(db, availability);

  const training = planTraining(users, certIds, startOfToday);
  await writeTraining(db, training);

  await writeDayRequirements(db, certIds, startOfToday);

  const shifts = planShifts(stations, startOfToday);
  assignShifts(shifts, stations, users, weekendPool, availability, training);
  await writeShifts(db, shifts);

  console.log('Done.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
