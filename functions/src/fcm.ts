/**
 * FCM fan-out with stale-token pruning. Token maps live on
 * users/{uid}.fcmTokens = { [token]: {platform, updatedAt} }.
 */

import { FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import * as logger from 'firebase-functions/logger';

import { COLLECTION_USERS } from './constants';
import { getDb } from './domain/firestore';

const FCM_CHUNK = 500;

export interface PushPayload {
  title: string;
  body: string;
  data: Record<string, string>;
  highPriority?: boolean;
}

interface UserTokens {
  uid: string;
  tokens: string[];
}

export async function sendPushToUsers(
  users: { id: string; fcmTokens: Record<string, unknown> }[],
  payload: PushPayload,
): Promise<number> {
  const userTokens: UserTokens[] = users
    .map((user) => ({ uid: user.id, tokens: Object.keys(user.fcmTokens) }))
    .filter((entry) => entry.tokens.length > 0);
  const flat = userTokens.flatMap((entry) =>
    entry.tokens.map((token) => ({ uid: entry.uid, token })),
  );
  if (flat.length === 0) return 0;

  const messaging = getMessaging();
  let successes = 0;
  const stale: { uid: string; token: string }[] = [];

  for (let offset = 0; offset < flat.length; offset += FCM_CHUNK) {
    const chunk = flat.slice(offset, offset + FCM_CHUNK);
    const response = await messaging.sendEachForMulticast({
      tokens: chunk.map((entry) => entry.token),
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
      android: {
        priority: payload.highPriority ? 'high' : 'normal',
        notification: payload.highPriority
          ? { sound: 'default', channelId: 'krizot_alerts' }
          : { channelId: 'krizot_schedule' },
      },
      apns: {
        payload: {
          aps: {
            sound: payload.highPriority ? 'default' : undefined,
            'interruption-level': payload.highPriority
              ? 'time-sensitive'
              : undefined,
          },
        },
      },
    });
    response.responses.forEach((result, index) => {
      if (result.success) {
        successes++;
        return;
      }
      const code = result.error?.code ?? '';
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/invalid-argument'
      ) {
        stale.push(chunk[index]);
      } else {
        logger.warn('FCM send failed', { code, uid: chunk[index].uid });
      }
    });
  }

  if (stale.length > 0) {
    const db = getDb();
    const batch = db.batch();
    for (const entry of stale) {
      batch.update(db.collection(COLLECTION_USERS).doc(entry.uid), {
        [`fcmTokens.${entry.token}`]: FieldValue.delete(),
      });
    }
    await batch.commit();
    logger.info(`Pruned ${stale.length} stale FCM token(s)`);
  }

  return successes;
}
