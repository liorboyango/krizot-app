import { defineConfig } from 'vitest/config';

// Rules tests need a running Firestore emulator — run them via `npm run
// test:rules` (or emulators:exec); the default `npm test` stays pure.
export default defineConfig({
  test: {
    exclude: ['test/rules/**', 'node_modules/**', 'lib/**'],
  },
});
