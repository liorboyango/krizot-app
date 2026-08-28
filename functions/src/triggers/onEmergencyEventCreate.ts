/**
 * Emergency fan-out: when triggerEmergency creates an event doc, push a
 * high-priority notification to every alerted responder.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';

import {
  COLLECTION_EMERGENCY_EVENTS,
  COLLECTION_USERS,
  DATABASE_ID,
  REGION,
} from '../constants';
import { getDb } from '../domain/firestore';
import { sendPushToUsers } from '../fcm';

const FIRESTORE_IN_LIMIT = 30;

export const onEmergencyEventCreate = onDocumentCreated(
  {
    region: REGION,
    database: DATABASE_ID,
    document: `${COLLECTION_EMERGENCY_EVENTS}/{eventId}`,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const alertedUserIds = (data.alertedUserIds as string[]) ?? [];
    if (alertedUserIds.length === 0) return;

    const db = getDb();
    const users: { id: string; fcmTokens: Record<string, unknown> }[] = [];
    for (
      let offset = 0;
      offset < alertedUserIds.length;
      offset += FIRESTORE_IN_LIMIT
    ) {
      const chunk = alertedUserIds.slice(offset, offset + FIRESTORE_IN_LIMIT);
      const snapshot = await db
        .collection(COLLECTION_USERS)
        .where('__name__', 'in', chunk)
        .get();
      for (const doc of snapshot.docs) {
        users.push({
          id: doc.id,
          fcmTokens: (doc.data().fcmTokens as Record<string, unknown>) ?? {},
        });
      }
    }

    const sent = await sendPushToUsers(users, {
      title: `🚨 EMERGENCY: ${data.eventTypeName as string}`,
      body: 'You are needed. Open Krizot and acknowledge.',
      data: { type: 'emergency', eventId: event.params.eventId },
      highPriority: true,
    });
    logger.info(
      `Emergency ${event.params.eventId}: alerted ${sent} device(s) of ` +
        `${alertedUserIds.length} responder(s)`,
    );
  },
);
