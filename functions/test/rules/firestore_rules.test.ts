/**
 * Security-rules contract tests. Run via the emulator:
 *   firebase emulators:exec --only firestore "npm --prefix functions run test:rules"
 * (or `npm run test:rules` with an emulator already running).
 */

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

let env: RulesTestEnvironment;

const EMPLOYEE = { uid: 'emp1', token: { role: 'employee' } };
const MANAGER = { uid: 'mgr1', token: { role: 'manager' } };
const DISPATCHER = { uid: 'dsp1', token: { role: 'dispatcher' } };

function dbFor(user: { uid: string; token: Record<string, unknown> } | null) {
  return user
    ? env.authenticatedContext(user.uid, user.token).firestore()
    : env.unauthenticatedContext().firestore();
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'krizot-rules-test',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../../firestore.rules'), 'utf8'),
    },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('users/emp1').set({
      displayName: 'Dana',
      role: 'employee',
      certifications: ['certC'],
      status: 'available',
      fcmTokens: {},
    });
    await db.doc('shifts/shift1').set({
      stationId: 'station1',
      userId: 'emp1',
      start: new Date('2026-09-01T08:00:00Z'),
      end: new Date('2026-09-01T10:00:00Z'),
      dayKey: '2026-09-01',
      status: 'assigned',
      acknowledged: false,
      ackAt: null,
    });
    await db.doc('shifts/shift2').set({
      stationId: 'station1',
      userId: 'other',
      start: new Date('2026-09-01T10:00:00Z'),
      end: new Date('2026-09-01T12:00:00Z'),
      dayKey: '2026-09-01',
      status: 'assigned',
      acknowledged: false,
      ackAt: null,
    });
    await db.doc('emergencyEvents/event1').set({
      eventTypeId: 'typeC',
      eventTypeName: 'Event Type C',
      status: 'active',
      triggeredBy: 'dsp1',
      alertedUserIds: ['emp1'],
      alertedUsers: [{ uid: 'emp1', displayName: 'Dana' }],
      stationIds: [],
    });
  });
});

describe('shifts', () => {
  it('employee can acknowledge own shift (ack-only field mask)', async () => {
    await assertSucceeds(
      dbFor(EMPLOYEE).doc('shifts/shift1').update({
        acknowledged: true,
        ackAt: new Date(),
      }),
    );
  });

  it('employee cannot change other fields alongside the ack', async () => {
    await assertFails(
      dbFor(EMPLOYEE).doc('shifts/shift1').update({
        acknowledged: true,
        ackAt: new Date(),
        start: new Date('2026-09-01T09:00:00Z'),
      }),
    );
    await assertFails(
      dbFor(EMPLOYEE).doc('shifts/shift1').update({ userId: null }),
    );
  });

  it('employee cannot un-acknowledge', async () => {
    await assertFails(
      dbFor(EMPLOYEE).doc('shifts/shift1').update({
        acknowledged: false,
        ackAt: null,
      }),
    );
  });

  it("employee cannot read or ack someone else's shift", async () => {
    await assertFails(dbFor(EMPLOYEE).doc('shifts/shift2').get());
    await assertFails(
      dbFor(EMPLOYEE).doc('shifts/shift2').update({
        acknowledged: true,
        ackAt: new Date(),
      }),
    );
  });

  it('manager has full shift write access; employee cannot create/delete',
    async () => {
      await assertSucceeds(
        dbFor(MANAGER).doc('shifts/shift1').update({ userId: 'other' }),
      );
      await assertFails(
        dbFor(EMPLOYEE).collection('shifts').add({ stationId: 'x' }),
      );
      await assertFails(dbFor(EMPLOYEE).doc('shifts/shift1').delete());
    });
});

describe('users', () => {
  it('employee can update own status/fcmTokens but not role/certifications',
    async () => {
      await assertSucceeds(
        dbFor(EMPLOYEE).doc('users/emp1').update({ status: 'sick' }),
      );
      await assertFails(
        dbFor(EMPLOYEE).doc('users/emp1').update({ role: 'admin' }),
      );
      await assertFails(
        dbFor(EMPLOYEE)
          .doc('users/emp1')
          .update({ certifications: ['everything'] }),
      );
    });

  it("employee cannot read another user's profile; manager can", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/other').set({ role: 'employee' });
    });
    await assertFails(dbFor(EMPLOYEE).doc('users/other').get());
    await assertSucceeds(dbFor(MANAGER).doc('users/other').get());
  });
});

describe('emergencyEvents', () => {
  it('nobody can create events client-side (callable only)', async () => {
    await assertFails(
      dbFor(DISPATCHER).collection('emergencyEvents').add({ status: 'active' }),
    );
  });

  it('alerted responder can read the event and write only own ack', async () => {
    await assertSucceeds(dbFor(EMPLOYEE).doc('emergencyEvents/event1').get());
    await assertSucceeds(
      dbFor(EMPLOYEE)
        .doc('emergencyEvents/event1/acks/emp1')
        .set({ ackAt: new Date() }),
    );
    await assertFails(
      dbFor(EMPLOYEE)
        .doc('emergencyEvents/event1/acks/other')
        .set({ ackAt: new Date() }),
    );
  });

  it('non-alerted employee cannot read the event', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/lurker').set({ role: 'employee' });
    });
    await assertFails(
      dbFor({ uid: 'lurker', token: { role: 'employee' } })
        .doc('emergencyEvents/event1')
        .get(),
    );
  });

  it('dispatcher can resolve but only via the status field mask', async () => {
    await assertSucceeds(
      dbFor(DISPATCHER).doc('emergencyEvents/event1').update({
        status: 'resolved',
        resolvedBy: 'dsp1',
        resolvedAt: new Date(),
      }),
    );
  });
});
