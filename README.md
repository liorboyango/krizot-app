# Krizot

Shift scheduling & emergency dispatch on Flutter + Firebase, per [DESIGN.md](DESIGN.md):

1. **Admin Scheduler** (web) — stations (24/7 or on-demand windows), certification-gated assignment, drag & drop, AI Auto-Fill and Smart-Healing replacement suggestions.
2. **Employee app** (mobile) — Focus View of current/upcoming assignment, push notifications, Acknowledge loop (manager sees a green check).
3. **Emergency Dispatch** (web) — pre-defined event types alerting all matching responders, live acknowledgement tally.

Web serves interfaces 1 & 3 (role-gated switcher); mobile builds serve interface 2 only.

## Stack

- **Flutter** + **RxDart/GetIt** Service–Manager architecture (services = thin never-throw Firestore I/O with cold snapshot streams; managers = `BehaviorSubject` state; plain `StreamBuilder` widgets).
- **Firebase**: Auth (Google sign-in only, roles via custom claims), **Firestore** (named DB `israel-1`, region `me-west1` — there is *no* `(default)` database), Cloud Functions (`me-west1`, TypeScript), FCM, App Check.
- **LLM scheduling** (`functions/src/llm/`): provider-agnostic via the AI SDK — switch between Anthropic / Gemini / Grok at runtime through the `config/llm` Firestore doc. Every LLM plan is re-validated by a pure constraint engine (`plan_validator.ts`) with a greedy deterministic fallback.

## Development

```bash
flutter pub get
npm --prefix functions install

# Local loop against emulators (Auth + Firestore + Functions):
firebase emulators:start
flutter run -d chrome \
  --dart-define=USE_FIREBASE_EMULATOR=true \
  --dart-define=KRIZOT_RECAPTCHA_SITE_KEY=<site-key>
```

### Tests

```bash
flutter analyze && flutter test              # entities + managers (fake_cloud_firestore)
npm --prefix functions run build             # tsc
npm --prefix functions test                  # plan_validator + greedy_filler (pure)
firebase emulators:exec --only firestore \
  "npm --prefix functions run test:rules"    # security-rules contract
```

## Deployment

```bash
flutter build web
firebase deploy --only firestore,functions,hosting
```

One-time setup (Firebase console / CLI):

- Blaze plan (required for Cloud Functions).
- Authentication → enable **Google** provider (email/password is removed).
- Set `ADMIN_EMAILS` functions param, or promote after the fact: `npx tsx functions/scripts/seed-admin.ts <email>`.
- LLM key for auto-fill: `firebase functions:secrets:set ANTHROPIC_API_KEY` (or `GOOGLE_GENERATIVE_AI_API_KEY` / `XAI_API_KEY`, matching `config/llm.provider`).
- Android: add SHA-1/SHA-256 fingerprints for Google sign-in.
- iOS: upload APNs auth key; enable Push Notifications + Background Modes (remote notifications) in Xcode.

## Roles

`admin` > `manager` (scheduler, stations, staff) / `dispatcher` (dispatch board) / `employee` (own schedule + acks). The custom claim is authoritative; `users/{uid}.role` mirrors it for UI/queries.
