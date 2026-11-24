import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:RXrail/app/services/background_location_service.dart'
    show isCrossingAhead;

/// A crash-prone place from kavach's crash analysis (Wake County junctions
/// and NC fatal road-miles). Built by tool/build_crash_hotspots.py.
typedef Hotspot = ({double lat, double lng, String label, bool stretch});

/// SharedPreferences key for the settings toggle. Off by default.
const String kCrashHotspotsEnabledKey = 'isCrashHotspotsEnabled';

/// A junction is a point; a stretch is a ~1-mile road piece known only by
/// its centroid, so it alerts from farther out.
// ponytail: centroid + radius, so a stretch also fires from a parallel road
// heading the same way. Shipping the road geometry and map-matching fixes it.
const double kJunctionRadius = 300.0;
const double kStretchRadius = 800.0;

/// Below this (~18 km/h) the user is not driving: no alert at home, on foot
/// or in a car park beside a hotspot.
const double kHotspotMinSpeed = 5.0;

/// One alert per hotspot per trip, near enough.
const Duration kHotspotCooldown = Duration(minutes: 30);

String hotspotKey(Hotspot h) => '${h.lat},${h.lng}';

List<Hotspot> parseHotspots(String json) => [
      for (final e in jsonDecode(json) as List<dynamic>)
        (
          lat: (e[0] as num).toDouble(),
          lng: (e[1] as num).toDouble(),
          label: e[2] as String,
          stretch: e[3] == 's',
        ),
    ];

/// The nearest hotspot in range and ahead that has not alerted within
/// [kHotspotCooldown], or null. [alerted] maps [hotspotKey] to alert time.
Hotspot? pickHotspot(Position position, List<Hotspot> spots,
    Map<String, DateTime> alerted, DateTime now) {
  if (position.speed < kHotspotMinSpeed) return null;
  Hotspot? best;
  var bestDistance = double.infinity;
  for (final h in spots) {
    final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, h.lat, h.lng);
    if (distance > (h.stretch ? kStretchRadius : kJunctionRadius)) continue;
    if (distance >= bestDistance) continue;
    if (!isCrossingAhead(position, h.lat, h.lng)) continue;
    final last = alerted[hotspotKey(h)];
    if (last != null && now.difference(last) < kHotspotCooldown) continue;
    best = h;
    bestDistance = distance;
  }
  return best;
}

/// Per-state files published from this repository's `hotspots/` directory
/// (built by tool/build_crash_hotspots.py).
Uri hotspotsUri(String state) => Uri.parse(
    'https://raw.githubusercontent.com/metviz/rxrailnew/main/hotspots/$state.json');

/// Bundled states plus downloaded ones; a downloaded state wins over its
/// bundled copy unless it fails to parse. Both map state code -> file text.
List<Hotspot> mergeHotspots(
    Map<String, String> bundled, Map<String, String> downloaded) {
  final byState = <String, List<Hotspot>>{
    for (final e in bundled.entries) e.key: parseHotspots(e.value),
  };
  for (final e in downloaded.entries) {
    try {
      byState[e.key] = parseHotspots(e.value);
    } catch (_) {
      // Keep whatever was bundled for this state.
    }
  }
  return [for (final spots in byState.values) ...spots];
}

class CrashHotspots {
  static const _prefix = 'hotspots_';

  /// Crash history moves slowly; a file older than this is fetched again.
  static const Duration maxAge = Duration(days: 180);

  static List<Hotspot>? _all;
  static String _loadedFrom = '';

  static Future<List<File>> _files() async {
    final dir = await getApplicationSupportDirectory();
    return dir.listSync().whereType<File>().where((f) {
      final name = f.uri.pathSegments.last;
      return name.startsWith(_prefix) && name.endsWith('.json');
    }).toList();
  }

  static Future<File> _file(String state) async => File(
      '${(await getApplicationSupportDirectory()).path}/$_prefix$state.json');

  /// True when [state]'s file is saved and younger than [maxAge].
  static Future<bool> has(String state) async {
    final f = await _file(state);
    return await f.exists() &&
        DateTime.now().difference(await f.lastModified()) < maxAge;
  }

  /// Fetches and saves [state]'s hotspots; returns the count. Throws on
  /// HTTP failure or an unparseable body, leaving any saved file in place.
  static Future<int> download(String state) async {
    final res =
        await http.get(hotspotsUri(state)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw HttpException('hotspots ${res.statusCode} for $state');
    }
    final count = parseHotspots(res.body).length;
    final file = await _file(state);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(res.body, flush: true);
    await tmp.rename(file.path);
    return count;
  }

  /// Bundled NC plus every downloaded state. Cached per isolate and
  /// re-read when the saved files change: the UI isolate downloads, the
  /// background isolate alerts.
  static Future<List<Hotspot>> load() async {
    final files = await _files();
    final stamp = [
      for (final f in files) '${f.path}@${f.lastModifiedSync()}',
    ].join('|');
    final cached = _all;
    if (cached != null && stamp == _loadedFrom) return cached;
    final all = mergeHotspots({
      'NC': await rootBundle.loadString('assets/data/crash_hotspots_nc.json'),
    }, {
      for (final f in files)
        f.uri.pathSegments.last
                .substring(_prefix.length)
                .replaceAll('.json', ''):
            await f.readAsString(),
    });
    _loadedFrom = stamp;
    return _all = all;
  }
}
