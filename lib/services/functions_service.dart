import 'package:cloud_functions/cloud_functions.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';

/// Wrappers around the privileged callable Cloud Functions. Results come
/// back as plain maps; callers interpret the payloads.
class FunctionsService {
  final _log = Logger('FunctionsService');
  final _functions = locator<FirebaseFunctions>();

  Future<Map<String, dynamic>?> _call(
      String name, Map<String, dynamic> data) async {
    _log.info('$name - START');
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<Object?, Object?>>(data);
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      _log.severe('$name - Error: $e');
      return null;
    }
  }

  /// Auto-fill open shifts for a day. [dayKey] is 'YYYY-MM-DD'.
  /// [instructions] is optional free-text manager guidance for the LLM.
  /// Returns `{filled: int, unfilled: [shiftId], notes: string}` or null.
  Future<Map<String, dynamic>?> autoFillSchedule(String dayKey,
          {String? instructions}) =>
      _call(Constants.FN_AUTO_FILL_SCHEDULE, {
        'date': dayKey,
        'instructions': ?instructions,
      });

  /// Ranked replacement candidates for a shift whose assignee dropped out.
  /// Returns `{candidates: [{userId, displayName, rank, reason}]}` or null.
  Future<Map<String, dynamic>?> suggestReplacement(String shiftId) =>
      _call(Constants.FN_SUGGEST_REPLACEMENT, {'shiftId': shiftId});

  /// Trigger an emergency call-out. Returns `{eventId, alertedCount}` or null.
  Future<Map<String, dynamic>?> triggerEmergency(String eventTypeId) =>
      _call(Constants.FN_TRIGGER_EMERGENCY, {'eventTypeId': eventTypeId});

  /// Admin only: change a user's role (custom claim + Firestore mirror).
  Future<bool> setUserRole(String uid, String role) async {
    final result =
        await _call(Constants.FN_SET_USER_ROLE, {'uid': uid, 'role': role});
    return result != null;
  }
}
