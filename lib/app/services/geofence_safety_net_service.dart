import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:native_geofence/native_geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:RXrail/app/services/background_watchdog_service.dart';
import 'package:RXrail/app/services/crossing_cache_service.dart';
import 'package:RXrail/app/services/test_logger.dart';

/// P3 — true OS-level geofencing as a cold-start safety net.
///
/// The foreground service (P0–P2) keeps precise alerting alive while the app
/// lives. But if the OS fully kills the process, nothing wakes it until the
/// user reopens the app. This registers the nearest FRA crossings as native
/// OS geofences; Android delivers an ENTER transition to a headless callback
/// EVEN AFTER the process is dead, which resurrects the foreground service so
/// precise alerting resumes before the user reaches the crossing.
///
/// This is the mechanism Life360 relies on. The FGS stays primary; geofences
/// are purely the resurrection layer.
class GeofenceSafetyNetService {
  static const String _tag = 'GEOFENCE';

  /// Android allows max 100 geofences per app; leave headroom for safety.
  static const int _maxGeofences = 90;

  /// Wake radius is intentionally larger than the warning distance: it must
  /// fire early enough that the resurrected FGS has time to cold-start and
  /// begin precise alerting before the user is on top of the crossing
  /// (geofence ENTER latency + process start at highway speed).
  static const double _wakeRadiusMeters = 2000;

  /// Re-register the nearest set once the user drifts this far from the center
  /// we last registered around (mirrors the FRA bbox refetch threshold).
  static const double _resyncThresholdMeters = 8000;

  static const String _lastSyncLatKey = 'geofence_sync_lat';
  static const String _lastSyncLngKey = 'geofence_sync_lng';

  /// In-memory guard so we don't reload+rescore the crossing list on every
  /// 10 m location fix. The persisted region threshold does the real work; this
  /// just caps how often we bother checking.
  static DateTime? _lastAttempt;
  static const Duration _minAttemptGap = Duration(seconds: 90);

  /// Serializes registration. Concurrent syncs (FRA-fetch trigger + movement
  /// trigger firing together) each do removeAll+add-N, which transiently blows
  /// past Android's 100-geofence cap ("Maximum package geofence allowance").
  static bool _syncing = false;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    try {
      await NativeGeofenceManager.instance.initialize();
      TestLogger.log('✅ geofence manager initialized', tag: _tag);
    } catch (e) {
      TestLogger.log('⚠️ geofence init failed: $e', tag: _tag);
    }
  }

  /// Registers the [_maxGeofences] crossings nearest to (lat,lng) as OS
  /// geofences. No-op if the user is still within the previously registered
  /// region (unless [force]). Call on app start and on significant movement.
  static Future<void> syncGeofences(
    double lat,
    double lng, {
    bool force = false,
  }) async {
    if (!Platform.isAndroid) return;
    if (_syncing) return; // another registration in flight — don't race the cap.

    final prefs = await SharedPreferences.getInstance();
    if (!force) {
      final sLat = prefs.getDouble(_lastSyncLatKey);
      final sLng = prefs.getDouble(_lastSyncLngKey);
      if (sLat != null &&
          sLng != null &&
          _haversineMeters(lat, lng, sLat, sLng) < _resyncThresholdMeters) {
        return; // still inside the registered region — nothing to do.
      }
    }

    final crossings = await CrossingCacheService.loadCrossings();
    if (crossings.isEmpty) {
      TestLogger.log('no cached crossings — skipping geofence sync', tag: _tag);
      return;
    }

    _syncing = true;

    // Score by distance, keep the nearest N.
    final scored = <_ScoredCrossing>[];
    for (final c in crossings) {
      final clat = _toDouble(c['latitude']);
      final clng = _toDouble(c['longitude']);
      if (clat == null || clng == null) continue;
      final id = (c['crossingid'] ?? c['crossingId'] ?? '$clat,$clng')
          .toString();
      scored.add(_ScoredCrossing(
        id: id,
        lat: clat,
        lng: clng,
        distance: _haversineMeters(lat, lng, clat, clng),
      ));
    }
    scored.sort((a, b) => a.distance.compareTo(b.distance));
    final nearest = scored.take(_maxGeofences).toList();

    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
      var registered = 0;
      for (final n in nearest) {
        try {
          await NativeGeofenceManager.instance.createGeofence(
            Geofence(
              id: n.id,
              location: Location(latitude: n.lat, longitude: n.lng),
              radiusMeters: _wakeRadiusMeters,
              triggers: const {GeofenceEvent.enter},
              iosSettings: const IosGeofenceSettings(initialTrigger: false),
              androidSettings: const AndroidGeofenceSettings(
                initialTriggers: {},
                notificationResponsiveness: Duration(seconds: 0),
              ),
            ),
            geofenceWakeCallback,
          );
          registered++;
        } catch (e) {
          TestLogger.log('⚠️ geofence ${n.id} failed: $e', tag: _tag);
        }
      }
      await prefs.setDouble(_lastSyncLatKey, lat);
      await prefs.setDouble(_lastSyncLngKey, lng);
      TestLogger.log('📍 registered $registered wake geofences', tag: _tag);
    } catch (e) {
      TestLogger.log('❌ geofence sync failed: $e', tag: _tag);
    } finally {
      _syncing = false;
    }
  }

  /// Throttled entry for the live location stream — keeps the registered
  /// region centered on the user as they drive, without thrashing on every fix.
  static Future<void> maybeSyncFromMovement(double lat, double lng) async {
    if (!Platform.isAndroid) return;
    final now = DateTime.now();
    if (_lastAttempt != null && now.difference(_lastAttempt!) < _minAttemptGap) {
      return;
    }
    _lastAttempt = now;
    await syncGeofences(lat, lng);
  }

  static Future<void> clear() async {
    if (!Platform.isAndroid) return;
    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
    } catch (_) {}
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class _ScoredCrossing {
  final String id;
  final double lat;
  final double lng;
  final double distance;
  const _ScoredCrossing({
    required this.id,
    required this.lat,
    required this.lng,
    required this.distance,
  });
}

/// Headless entry point invoked by the OS when a crossing geofence is entered —
/// runs in its own background isolate, possibly with the app process otherwise
/// dead. MUST be top-level and annotated. Resurrects the foreground service so
/// precise alerting takes over from here.
@pragma('vm:entry-point')
Future<void> geofenceWakeCallback(GeofenceCallbackParams params) async {
  try {
    TestLogger.log(
      '🛰️ geofence ${params.event.name} — ${params.geofences.length} region(s)',
      tag: 'GEOFENCE',
    );
    if (params.event == GeofenceEvent.enter) {
      await BackgroundWatchdogService.resurrectForegroundService(
        notificationText: 'Approaching a railway crossing',
      );
    }
  } catch (e) {
    TestLogger.log('❌ geofence wake failed: $e', tag: 'GEOFENCE');
  }
}
