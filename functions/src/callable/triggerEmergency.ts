/**
 * triggerEmergency({eventTypeId})
 *
 * Resolves responders server-side (holders of ANY responder certification,
 * excluding status 'unavailable') and creates the emergencyEvents doc; the
 * onEmergencyEventCreate trigger handles the FCM fan-out.
 */

import { FieldValue } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

import {
  COLLECTION_EMERGENCY_EVENTS,
  COLLECTION_EVENT_TYPES,
  REGION,
} from '../constants';
import { getDb, loadUsers } from '../domain/firestore';
import { requireRole } from './auth_guard';

export const triggerEmergency = onCall(
  { region: REGION, enforceAppCheck: true },
  async (request) => {
    const uid = requireRole(request, ['admin', 'dispatcher', 'manager']);
    const eventTypeId = request.data?.eventTypeId as string | undefined;
    if (!eventTypeId) {
      throw new HttpsError('invalid-argument', 'eventTypeId is required.');
    }

    const db = getDb();
    const eventTypeSnapshot = await db
      .collection(COLLECTION_EVENT_TYPES)
      .doc(eventTypeId)
      .get();
    if (!eventTypeSnapshot.exists) {
      throw new HttpsError('not-found', 'Unknown event type.');
    }
    const eventType = eventTypeSnapshot.data()!;
    if (eventType.active === false) {
      throw new HttpsError('failed-precondition', 'Event type is inactive.');
    }

    const responderCerts = (eventType.responderCertifications as string[]) ?? [];
    const users = await loadUsers();
    const responders = users.filter(
      (user) =>
        user.status !== 'unavailable' &&
        responderCerts.some((cert) => user.certifications.includes(cert)),
    );
    if (responders.length === 0) {
      throw new HttpsError(
        'failed-precondition',
        'No responders hold the required certifications.',
      );
    }

    const eventRef = await db.collection(COLLECTION_EMERGENCY_EVENTS).add({
      eventTypeId,
      eventTypeName: (eventType.name as string) ?? eventTypeId,
      priority: (eventType.priority as string) ?? 'high',
      triggeredBy: uid,
      triggeredAt: FieldValue.serverTimestamp(),
      status: 'active',
      alertedUserIds: responders.map((user) => user.id),
      alertedUsers: responders.map((user) => ({
        uid: user.id,
        displayName: user.displayName,
      })),
      stationIds: (eventType.stationIds as string[]) ?? [],
    });

    return { eventId: eventRef.id, alertedCount: responders.length };
  },
);
