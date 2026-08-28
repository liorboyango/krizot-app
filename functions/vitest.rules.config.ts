import { defineConfig } from 'vitest/config';

// Security-rules suite — requires the Firestore emulator:
//   firebase emulators:exec --only firestore "npm --prefix functions run test:rules"
export default defineConfig({
  test: {
    include: ['test/rules/**/*.test.ts'],
    testTimeout: 20000,
    hookTimeout: 30000,
  },
});
