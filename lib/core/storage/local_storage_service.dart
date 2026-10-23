import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  final Map<String, dynamic> _memoryCache = {};
  SharedPreferences? _prefs;

  LocalStorageService._();

  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // In-memory fallback if platform channel unavailable (e.g. CLI tests)
      _prefs = null;
    }
  }

  // Set shared preferences directly (useful for tests)
  void setPreferencesForTest(SharedPreferences prefs) {
    _prefs = prefs;
  }

  Future<void> setString(String key, String value) async {
    _memoryCache[key] = value;
    if (_prefs != null) {
      await _prefs!.setString(key, value);
    }
  }

  String? getString(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key] as String?;
    }
    final val = _prefs?.getString(key);
    if (val != null) {
      _memoryCache[key] = val;
    }
    return val;
  }

  Future<void> setJson(String key, dynamic value) async {
    final str = jsonEncode(value);
    await setString(key, str);
  }

  dynamic getJson(String key) {
    final str = getString(key);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
    if (_prefs != null) {
      await _prefs!.clear();
    }
  }
}
