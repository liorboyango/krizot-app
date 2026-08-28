/**
 * The acknowledgement loop's backend half: whenever a manager-side change
 * touches an assignee, reset `acknowledged` and push a notification.
 *
 * LOOP GUARD: the trigger's own ack-reset (and the employee's ack) change
 * only {acknowledged, ackAt} — such writes are ignored, or the reset would
 * re-trigger itself forever.
 */

import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';

import {
  COLLECTION_SHIFTS,
  COLLECTION_USERS,
  DATABASE_ID,
  REGION,
} from '../constants';
import { getDb } from '../domain/firestore';
import { sendPushToUsers } from '../fcm';

/** Fields whose change is relevant to the assignee. */
const RELEVANT_FIELDS = ['userId', 'start', 'end', 'stationId'] as const;
const ACK_FIELDS = new Set(['acknowledged', 'ackAt', 'lastModifiedBy', 'lastModifiedAt']);

function changedKeys(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): Set<string> {
  const keys = new Set<string>();
  const all = new Set([
    ...Object.keys(before ?? {}),
    ...Object.keys(after ?? {}),
  ]);
  for (const key of all) {
    const beforeValue = JSON.stringify(before?.[key] ?? null);
    const afterValue = JSON.stringify(after?.[key] ?? null);
    if (beforeValue !== afterValue) keys.add(key);
  }
  return keys;
}

async function notify(uid: string, title: string, body: string, shiftId: string) {
  const snapshot = await getDb().collection(COLLECTION_USERS).doc(uid).get();
  if (!snapshot.exists) return;
  await sendPushToUsers(
    [{ id: uid, fcmTokens: snapshot.data()?.fcmTokens ?? {} }],
    { title, body, data: { type: 'shiftChange', shiftId } },
  );
}

export const onShiftWrite = onDocumentWritten(
  {
    region: REGION,
    database: DATABASE_ID,
    document: `${COLLECTION_SHIFTS}/{shiftId}`,
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const shiftId = event.params.shiftId;

    // Deletion of an assigned shift → tell the assignee.
    if (before && !after) {
      if (before.userId) {
        await notify(
          before.userId as string,
          'Shift cancelled',
          'One of your shifts was removed from the schedule.',
          shiftId,
        );
      }
      return;
    }
    if (!after) return;

    const changed = changedKeys(before, after);
    // Loop guard: ack-only writes (employee ack or our own reset) are ignored.
    if (before && [...changed].every((key) => ACK_FIELDS.has(key))) {
      return;
    }
    const relevantChange = !before ||
      RELEVANT_FIELDS.some((field) => changed.has(field));
    if (!relevantChange) return;

    const newAssignee = (after.userId as string | null) ?? null;
    const oldAssignee = (before?.userId as string | null) ?? null;

    // Reset the acknowledgement whenever the assignee-relevant content
    // changed and someone is (still) assigned.
    if (newAssignee && after.acknowledged === true) {
      await event.data!.after.ref.update({ acknowledged: false, ackAt: null });
    }

    if (newAssignee && newAssignee !== oldAssignee) {
      await notify(
        newAssignee,
        'New shift assigned',
        'You have a new assignment. Please review and acknowledge it.',
        shiftId,
      );
    } else if (newAssignee) {
      await notify(
        newAssignee,
        'Shift updated',
        'One of your shifts changed. Please review and acknowledge it.',
        shiftId,
      );
    }
    if (oldAssignee && oldAssignee !== newAssignee) {
      await notify(
        oldAssignee,
        'Shift unassigned',
        'You were unassigned from a shift.',
        shiftId,
      );
    }
    logger.info(`Processed shift write ${shiftId}`, {
      changed: [...changed],
    });
  },
);
