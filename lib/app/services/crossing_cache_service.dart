import 'dart:convert';
import 'dart:developer' as log;
import 'package:shared_preferences/shared_preferences.dart';

/// Serializes nearby crossings to SharedPreferences so the background
/// task isolate can read them without GetX or HTTP.
class CrossingCacheService {
  static const String _crossingsKey = 'cached_crossings';
  static const String _warningEnabledKey = 'isWarningsEnabled';
  static const String _warningDistanceKey = 'warningDistance';

  /// Save a list of crossings as JSON. Call this whenever nearbyLocations changes.
  static Future<void> saveCrossings(
    List<Map<String, dynamic>> crossings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_crossingsKey, jsonEncode(crossings));
      log.log('✅ CrossingCacheService: saved ${crossings.length} crossings');
    } catch (e) {
      log.log('❌ CrossingCacheService.saveCrossings error: $e');
    }
  }

  /// Read the cached crossings. Returns empty list on error.
  static Future<List<Map<String, dynamic>>> loadCrossings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_crossingsKey);
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      log.log('❌ CrossingCacheService.loadCrossings error: $e');
      return [];
    }
  }

  /// Read warning settings. Returns defaults if not set.
  static Future<({bool enabled, double distanceMeters})>
      loadWarningSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        enabled: prefs.getBool(_warningEnabledKey) ?? true,
        distanceMeters: prefs.getDouble(_warningDistanceKey) ?? 200.0,
      );
    } catch (e) {
      log.log('❌ CrossingCacheService.loadWarningSettings error: $e');
      return (enabled: true, distanceMeters: 200.0);
    }
  }
}
