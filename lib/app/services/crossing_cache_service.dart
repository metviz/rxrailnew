import 'dart:convert';
import 'dart:developer' as log;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rows per FRA page. Socrata drops the connection mid-row beyond ~1024,
/// surfacing as FormatException on jsonDecode, so callers page at 1000.
const int kFraPageSize = 1000;

/// Pages fetched at most per refresh — 5000 grouped rows covers the
/// densest US metros in a 25 km box.
const int kFraMaxPages = 5;

/// At-grade FRA crossings within ±0.225° (~25 km) of [lat],[lng]: page
/// [page] of the result. See [fraCrossingsInBox].
Uri fraCrossingsUri(double lat, double lng, {int page = 0}) {
  const delta = 0.225;
  return fraCrossingsInBox(
      lat - delta, lat + delta, lng - delta, lng + delta, page: page);
}

/// At-grade FRA crossings inside the box: page [page] of the result,
/// grouped by crossing + location.
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
Uri fraCrossingsInBox(
    double minLat, double maxLat, double minLng, double maxLng,
    {int page = 0}) {
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
    ' AND latitude::number>${minLat.toStringAsFixed(6)}'
    ' AND latitude::number<${maxLat.toStringAsFixed(6)}'
    ' AND longitude::number>${minLng.toStringAsFixed(6)}'
    ' AND longitude::number<${maxLng.toStringAsFixed(6)}'
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

/// Whole-state crossing lists saved beside the offline map, so alerts keep
/// working where there is no signal to fetch the 25 km list. One JSON file
/// per state (NC: ~32k rows, 1.5 MB) in app support storage,
/// readable from the background isolate.
class OfflineCrossings {
  static Future<File> _file(String state) async =>
      File('${(await getApplicationSupportDirectory()).path}/crossings_$state.json');

  /// True when a compact file is saved. Files from before compaction
  /// (a list of maps, ~3× bigger) count as missing so they get replaced.
  static Future<bool> has(String state) async {
    final f = await _file(state);
    if (!await f.exists()) return false;
    final head = await f.openRead(0, 2).transform(utf8.decoder).join();
    return head != '[{';
  }

  /// Fetches every crossing in the state's bounding box and saves it.
  /// Returns the row count. Throws on HTTP failure; a partial download
  /// never replaces a complete file.
  static Future<int> download(String state, double minLat, double maxLat,
      double minLng, double maxLng) async {
    // FRA writes one point several ways (35.741371 vs 35.7413710, or a
    // last digit off): NC has 40.5k rows. Rounding to 5 decimals
    // (~1 m) leaves 32k; stored as [id, lat, lng, street], 4 MB -> 1.5 MB.
    final rows = <String, List<Object>>{};
    // 200 pages = 200k rows; TX, the largest state, is ~60k.
    for (var page = 0; page < 200; page++) {
      final res = await http
          .get(fraCrossingsInBox(minLat, maxLat, minLng, maxLng, page: page))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        throw HttpException('FRA ${res.statusCode} on page $page');
      }
      final data = jsonDecode(res.body) as List<dynamic>;
      for (final e in data) {
        final id = (e['crossingid'] as String? ?? '').trim();
        final la = double.tryParse('${e['latitude']}');
        final lo = double.tryParse('${e['longitude']}');
        if (id.isEmpty || la == null || lo == null) continue;
        final lat = double.parse(la.toStringAsFixed(5));
        final lng = double.parse(lo.toStringAsFixed(5));
        rows.putIfAbsent('$id@$lat,$lng', () =>
            [id, lat, lng, (e['street'] as String?) ?? 'Railway Crossing']);
      }
      if (data.length < kFraPageSize) break;
    }
    final file = await _file(state);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(rows.values.toList()), flush: true);
    await tmp.rename(file.path);
    return rows.length;
  }

  /// Saved crossings within ±0.225° (~25 km) of [lat],[lng], across every
  /// downloaded state (boxes of neighbouring states overlap, so keyed by
  /// id + location). Empty when none are saved or on error.
  static Future<List<Map<String, dynamic>>> near(double lat, double lng) async {
    const delta = 0.225;
    final out = <String, Map<String, dynamic>>{};
    try {
      final dir = await getApplicationSupportDirectory();
      final files = dir.listSync().whereType<File>().where((f) =>
          f.path.contains('/crossings_') && f.path.endsWith('.json'));
      for (final f in files) {
        for (final e in jsonDecode(await f.readAsString()) as List<dynamic>) {
          // Compact [id, lat, lng, street]; files saved before that hold maps.
          final m = e is List
              ? {'crossingid': e[0], 'latitude': '${e[1]}',
                 'longitude': '${e[2]}', 'street': e[3]}
              : e as Map<String, dynamic>;
          final la = double.tryParse(m['latitude'] as String? ?? '') ?? 0;
          final lo = double.tryParse(m['longitude'] as String? ?? '') ?? 0;
          if ((la - lat).abs() < delta && (lo - lng).abs() < delta) {
            out['${m['crossingid']}@$la,$lo'] = m;
          }
        }
      }
    } catch (e) {
      log.log('❌ OfflineCrossings.near error: $e');
    }
    return out.values.toList();
  }
}
