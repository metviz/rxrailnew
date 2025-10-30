// static const String isLogin = 'isLogin';
// static const int deviceUserId = 0;
// static const String token = 'token';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class PreferencesManager {
  static PreferencesManager? _storageUtil;
  static SharedPreferences? _preferences;

  static Future<PreferencesManager?> getInstance() async {
    _preferences = await SharedPreferences.getInstance();
    if (_storageUtil == null) {
      var secureStorage = PreferencesManager._();
      await secureStorage._init();
      _storageUtil = secureStorage;
    }
    return _storageUtil;
  }

  PreferencesManager._();

  Future _init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// put integer
  static Future<bool>? setInt(String key, int value) {
    if (_preferences == null) return null;
    return _preferences!.setInt(key, value);
  }

  /// get integer
  static int getInt(String key, {int defValue = 0}) {
    if (_preferences == null) return defValue;
    return _preferences!.getInt(key) ?? defValue;
  }

  /// put String
  static Future<bool>? setString(String key, String value) {
    if (_preferences == null) return null;
    return _preferences!.setString(key, value);
  }

  /// Get String
  static String getString(String key, {String defValue = ""}) {
    if (_preferences == null) return defValue;
    return _preferences!.getString(key) ?? defValue;
  }

  static Future<bool> remove(String key) async {
    return _preferences!.remove(key);
  }

  static bool getBool(String key, bool defValue) {
    if (_preferences == null) return defValue;
    return _preferences!.getBool(key) ?? defValue;
  }

  static setBool(String key, bool value) async {
    _preferences!.setBool(key, value);
  }

  static clear() async {
    _preferences!.clear();
  }
  static clearAt(String key) async {
    _preferences!.remove(key);
  }
  // static Future storeLoginData(String key, Loginmodel loginData) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(key, jsonEncode(loginData));
  // }

  static Future<Map<String, dynamic>?> getLoginData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loginDataJson = prefs.getString(key);
    if (loginDataJson == null) {
      return null;
    } else {
      return jsonDecode(loginDataJson);
    }
  }
}












