/**
 * setUserRole({uid, role}) — admin only. Sets the custom claim (authoritative
 * for security rules) and mirrors it onto users/{uid}.role so the client's
 * UserManager notices and refreshes its token.
 */

import { FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

import { COLLECTION_USERS, REGION } from '../constants';
import { getDb } from '../domain/firestore';
import { requireRole, Role } from './auth_guard';

const VALID_ROLES: Role[] = ['admin', 'manager', 'dispatcher', 'employee'];

export const setUserRole = onCall(
  { region: REGION, enforceAppCheck: true },
  async (request) => {
    const callerUid = requireRole(request, ['admin']);
    const uid = request.data?.uid as string | undefined;
    const role = request.data?.role as Role | undefined;
    if (!uid || !role || !VALID_ROLES.includes(role)) {
      throw new HttpsError(
        'invalid-argument',
        `uid and role (${VALID_ROLES.join('|')}) are required.`,
      );
    }
    if (uid === callerUid && role !== 'admin') {
      throw new HttpsError(
        'failed-precondition',
        'Admins cannot demote themselves.',
      );
    }

    await getAuth().setCustomUserClaims(uid, { role });
    await getDb().collection(COLLECTION_USERS).doc(uid).update({
      role,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { uid, role };
  },
);
