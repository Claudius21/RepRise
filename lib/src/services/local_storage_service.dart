import 'package:shared_preferences/shared_preferences.dart';

/// Simple key-value storage using SharedPreferences.
/// Persists small user preferences locally (active plan, settings, etc.)
abstract final class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Active Plan ────────────────────────────────────────────────────────────
  static const _activePlanKey = 'active_plan_id';

  static Future<void> setActivePlan(String planId) async {
    await _prefs?.setString(_activePlanKey, planId);
  }

  static String? getActivePlanId() {
    return _prefs?.getString(_activePlanKey);
  }

  static Future<void> clearActivePlan() async {
    await _prefs?.remove(_activePlanKey);
  }

  // ─── Generic Helpers ───────────────────────────────────────────────────────
  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
