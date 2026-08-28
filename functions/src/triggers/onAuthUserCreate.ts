/**
 * First sign-in bootstrap (v1 API — v2 has no auth onCreate trigger; kept in
 * us-central1, a gen-1-safe region, since it is latency-insensitive):
 * default role claim + users/{uid} profile doc. Emails listed in the
 * ADMIN_EMAILS param (comma-separated) are promoted to admin on creation.
 */

import { FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import * as functionsV1 from 'firebase-functions/v1';
import * as logger from 'firebase-functions/logger';
import { defineString } from 'firebase-functions/params';

import { COLLECTION_USERS } from '../constants';
import { getDb } from '../domain/firestore';

const adminEmails = defineString('ADMIN_EMAILS', { default: '' });

export const onAuthUserCreate = functionsV1
  .region('us-central1')
  .auth.user()
  .onCreate(async (user) => {
    const admins = adminEmails
      .value()
      .split(',')
      .map((email) => email.trim().toLowerCase())
      .filter((email) => email.length > 0);
    const role =
      user.email && admins.includes(user.email.toLowerCase())
        ? 'admin'
        : 'employee';

    await getAuth().setCustomUserClaims(user.uid, { role });
    await getDb().collection(COLLECTION_USERS).doc(user.uid).set({
      displayName: user.displayName ?? user.email ?? 'New user',
      email: user.email ?? '',
      photoUrl: user.photoURL ?? null,
      role,
      certifications: [],
      status: 'available',
      fcmTokens: {},
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    logger.info(`Created profile for ${user.uid} with role ${role}`);
  });
