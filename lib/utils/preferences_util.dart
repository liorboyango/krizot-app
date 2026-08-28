import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('PreferencesUtil');

const KEY_LAST_SELECTED_DATE = 'krizot_last_selected_date';
const KEY_LAST_INTERFACE = 'krizot_last_interface';

Future<void> saveData(String key, String? value) async {
  const METHOD = 'saveData';
  if (kDebugMode) {
    _log.info('$METHOD - key: $key value: $value');
  }
  if (key.isEmpty || value == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<String?> restoreData(String key) async {
  const METHOD = 'restoreData';
  if (kDebugMode) {
    _log.info('$METHOD - key: $key');
  }
  if (key.isEmpty) return null;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<String> restoreDataWithDefault(String key,
    {required String defaultValue}) async {
  final data = await restoreData(key);
  return data ?? defaultValue;
}

Future<void> deleteData(String key) async {
  const METHOD = 'deleteData';
  if (kDebugMode) {
    _log.info('$METHOD - key: $key');
  }
  if (key.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
