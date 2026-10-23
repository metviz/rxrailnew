import 'dart:convert';
import 'dart:developer' as log;
import 'package:shared_preferences/shared_preferences.dart';

/// Rows per FRA page. Socrata drops the connection mid-row beyond ~1024,
/// surfacing as FormatException on jsonDecode, so callers page at 1000.
const int kFraPageSize = 1000;

/// Pages fetched at most per refresh — 5000 grouped rows covers the
/// densest US metros in a 25 km box.
const int kFraMaxPages = 5;

/// At-grade FRA crossings within ±0.225° (~25 km) of [lat],[lng]: page
/// [page] of the result, grouped by crossing + location.
///
/// Raw rows repeat each crossing ~10× (one per inventory revision), so an
/// ungrouped 1000-row page held only ~270 of the 324 crossings around
/// Morrisville — a different random subset per fetch. Grouping on the
/// server returns each location once; $order keeps paging stable.
///
/// latitude/longitude are text columns, so '>' needs a ::number cast, and
/// malformed rows with stray characters (29.303213°, 42.922107O,
/// 44.974607') fail the cast for the whole query (HTTP 400, depending on
/// the plan) unless filtered first. URL encoding: '%' → %25, '°' → %C2%B0.
/// Uri.parse keeps '$' unencoded, which Uri.https would not.
Uri fraCrossingsUri(double lat, double lng, {int page = 0}) {
  const delta = 0.225;
  const bad = ['%C2%B0', 'O', 'o', "''"];
  final filters = [
    for (final col in ['latitude', 'longitude'])
      for (final c in bad) " AND $col NOT LIKE '%25$c%25'",
  ].join();
  return Uri.parse(
    'https://data.transportation.gov/resource/vhwz-raag.json'
    '?\$select=crossingid,latitude,longitude,'
    'max(street) AS street,max(revisiondate) AS revisiondate'
    "&\$where=crossingposition='At Grade'"
    '$filters'
    ' AND latitude::number>${(lat - delta).toStringAsFixed(6)}'
    ' AND latitude::number<${(lat + delta).toStringAsFixed(6)}'
    ' AND longitude::number>${(lng - delta).toStringAsFixed(6)}'
    ' AND longitude::number<${(lng + delta).toStringAsFixed(6)}'
    '&\$group=crossingid,latitude,longitude'
    '&\$order=crossingid,latitude,longitude'
    '&\$limit=$kFraPageSize&\$offset=${page * kFraPageSize}',
  );
}

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
