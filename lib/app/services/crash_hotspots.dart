import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
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

class CrashHotspots {
  static List<Hotspot>? _all;

  /// Every bundled hotspot, parsed once per isolate.
  static Future<List<Hotspot>> load() async => _all ??= parseHotspots(
      await rootBundle.loadString('assets/data/crash_hotspots_nc.json'));
}
