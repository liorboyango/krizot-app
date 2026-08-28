/**
 * One-off admin promotion for an existing user (run BEFORE relying on the
 * admin role in rules):
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=service-account.json \
 *     npx tsx scripts/seed-admin.ts someone@example.com
 *
 * Prefer the ADMIN_EMAILS functions param for first-time sign-ups; this
 * script covers after-the-fact promotion.
 */

import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

import { COLLECTION_USERS, DATABASE_ID } from '../src/constants';

async function main() {
  const email = process.argv[2];
  if (!email) {
    console.error('Usage: npx tsx scripts/seed-admin.ts <email>');
    process.exit(1);
  }
  initializeApp();
  const user = await getAuth().getUserByEmail(email);
  await getAuth().setCustomUserClaims(user.uid, { role: 'admin' });
  await getFirestore(DATABASE_ID)
    .collection(COLLECTION_USERS)
    .doc(user.uid)
    .set(
      { role: 'admin', updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  console.log(`${email} (${user.uid}) is now admin.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
