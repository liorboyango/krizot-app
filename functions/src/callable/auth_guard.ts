import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

export type Role = 'admin' | 'manager' | 'dispatcher' | 'employee';

/** Asserts the caller is signed in and holds one of [roles]; returns uid. */
export function requireRole(
  request: CallableRequest,
  roles: Role[],
): string {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const role = (auth.token.role as Role | undefined) ?? 'employee';
  if (!roles.includes(role)) {
    throw new HttpsError(
      'permission-denied',
      `Requires role: ${roles.join(' or ')}.`,
    );
  }
  return auth.uid;
}
