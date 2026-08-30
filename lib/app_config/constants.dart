/// App-wide constants: Firestore collection names, Cloud Functions region and
/// callable names, and scheduling defaults shared across services/managers.
library;

class Constants {
  Constants._();

  /// Named Firestore database (region me-west1) — the project does not use
  /// the `(default)` database. Must match functions/src/constants.ts and
  /// the `firestore.database` entry in firebase.json.
  static const FIRESTORE_DATABASE_ID = 'israel-1';

  /// Cloud Functions region, colocated with the Firestore database.
  /// Must match `REGION` in functions/src/constants.ts.
  static const FUNCTIONS_REGION = 'me-west1';

  // Firestore collections.
  static const COLLECTION_USERS = 'users';
  static const COLLECTION_CERTIFICATIONS = 'certifications';
  static const COLLECTION_STATIONS = 'stations';
  static const COLLECTION_SHIFTS = 'shifts';
  static const COLLECTION_EVENT_TYPES = 'eventTypes';
  static const COLLECTION_EMERGENCY_EVENTS = 'emergencyEvents';
  static const COLLECTION_ACKS = 'acks';
  static const COLLECTION_CONFIG = 'config';
  static const COLLECTION_AVAILABILITY = 'availability';
  static const COLLECTION_DAY_REQUIREMENTS = 'dayRequirements';
  static const COLLECTION_TRAINING_SESSIONS = 'trainingSessions';

  // Callable Cloud Functions.
  static const FN_AUTO_FILL_SCHEDULE = 'autoFillSchedule';
  static const FN_SUGGEST_REPLACEMENT = 'suggestReplacement';
  static const FN_TRIGGER_EMERGENCY = 'triggerEmergency';
  static const FN_SET_USER_ROLE = 'setUserRole';

  /// Default shift length when a station doesn't override it.
  static const DEFAULT_SHIFT_MINUTES = 120;

  // Local emulator ports — must match firebase.json.
  static const EMULATOR_AUTH_PORT = 9099;
  static const EMULATOR_FIRESTORE_PORT = 8080;
  static const EMULATOR_FUNCTIONS_PORT = 5001;
}
