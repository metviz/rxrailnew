import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:RXrail/app/services/crossing_cache_service.dart';
import 'package:RXrail/app/services/test_logger.dart';

class BackgroundLocationService extends GetxService {
  static const String _lastPositionKey = 'last_position';
  static const String _isServiceRunningKey = 'is_service_running';
  static const int _repeatIntervalMs = 5000;
  static const int _serviceId = 257;

  final isRunning = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();

  // Callback for location updates
  Function(Position)? onLocationUpdate;
  StreamSubscription<dynamic>? _receivePortSubscription;

  void _startReceivePort() {
    final port = FlutterForegroundTask.receivePort;
    if (port == null) {
      dev.log('⚠️ FlutterForegroundTask.receivePort is null — location updates will not be received');
      return;
    }
    _receivePortSubscription = port.listen((data) {
      if (data is Map && data['type'] == 'location') {
        try {
          final position = Position(
            latitude: (data['latitude'] as num).toDouble(),
            longitude: (data['longitude'] as num).toDouble(),
            accuracy: (data['accuracy'] as num).toDouble(),
            altitude: (data['altitude'] as num? ?? 0).toDouble(),
            heading: (data['heading'] as num? ?? 0).toDouble(),
            speed: (data['speed'] as num? ?? 0).toDouble(),
            timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          currentPosition.value = position;
          onLocationUpdate?.call(position);
        } catch (e) {
          dev.log('Error parsing location from task: $e');
        }
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    TestLogger.init(tag: 'MAIN');
    _initForegroundTask();
    _startReceivePort();
    _checkIfServiceWasRunning();
  }

  Future<void> _checkIfServiceWasRunning() async {
    final prefs = await SharedPreferences.getInstance();
    final wasRunning = prefs.getBool(_isServiceRunningKey) ?? false;

    if (wasRunning) {
      await startBackgroundTracking();
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'railway_crossing_location',
        channelName: 'Railway Crossing Location Tracking',
        channelDescription: 'Continuous location tracking for railway crossing alerts',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_repeatIntervalMs),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<bool> startBackgroundTracking() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        TestLogger.log('❌ Location permission denied', tag: 'MAIN');
        return false;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: 'RXrail Active',
        notificationText: 'Monitoring for railway crossings',
        notificationButtons: [
          const NotificationButton(id: 'stop_tracking', text: 'Stop Tracking'),
        ],
        callback: startLocationTracking,
      );

      if (result is ServiceRequestSuccess) {
        isRunning.value = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isServiceRunningKey, true);
        TestLogger.log('✅ Background location service started', tag: 'MAIN');
        return true;
      }

      return false;
    } catch (e) {
      TestLogger.log('❌ Error starting background service: $e', tag: 'MAIN');
      return false;
    }
  }

  Future<bool> stopBackgroundTracking() async {
    try {
      final result = await FlutterForegroundTask.stopService();

      if (result is ServiceRequestSuccess) {
        isRunning.value = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isServiceRunningKey, false);
        TestLogger.log('✅ Background location service stopped', tag: 'MAIN');
      }

      return result is ServiceRequestSuccess;
    } catch (e) {
      TestLogger.log('❌ Error stopping background service: $e', tag: 'MAIN');
      return false;
    }
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = prefs.getString(_lastPositionKey);

      if (positionJson != null) {
        final data = jsonDecode(positionJson);
        return Position(
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          accuracy: (data['accuracy'] as num).toDouble(),
          altitude: (data['altitude'] as num? ?? 0).toDouble(),
          heading: 0.0,
          speed: 0.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }
    } catch (e) {
      dev.log('Error loading last position: $e');
    }
    return null;
  }

  @override
  void onClose() {
    _receivePortSubscription?.cancel();
    unawaited(stopBackgroundTracking());
    super.onClose();
  }
}

// ── Top-level constants ────────────────────────────────────────────────────────
const String _kLastPositionKey = 'last_position';
const int _kDistanceFilterMeters = 10;

/// Returns distance in meters between two lat/lng points.
double _haversineDistanceMeters(
  double lat1, double lon1,
  double lat2, double lon2,
) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt((1 - a).clamp(0.0, 1.0)));
}

/// Fire a high-priority crossing alert from within the background isolate.
Future<int> _showCrossingAlert(
  FlutterLocalNotificationsPlugin plugin,
  String crossingId,
  String street,
  double distanceMeters,
) async {
  final distanceText = distanceMeters < 1000
      ? '${distanceMeters.round()}m away'
      : '${(distanceMeters / 1000).toStringAsFixed(1)}km away';

  final prefs = await SharedPreferences.getInstance();
  final soundEnabled = prefs.getBool('isWarningSoundEnabled') ?? true;
  final vibrationEnabled = prefs.getBool('isVibrationEnabled') ?? true;

  final androidDetails = AndroidNotificationDetails(
    'railway_crossing_alerts',
    'Railway Crossing Alerts',
    channelDescription: 'High priority alerts for nearby railway crossings',
    importance: Importance.high,
    priority: Priority.high,
    enableLights: true,
    enableVibration: vibrationEnabled,
    playSound: soundEnabled,
    autoCancel: true,
    icon: '@mipmap/ic_launcher',
  );

  final notifId = crossingId.hashCode.abs() % 10000;
  await plugin.show(
    notifId,
    '⚠️ Railway Crossing Ahead',
    '$street — $distanceText',
    const NotificationDetails(android: androidDetails),
  );
  return notifId;
}

// ── Background isolate entry point ─────────────────────────────────────────────
@pragma('vm:entry-point')
void startLocationTracking() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;

  final Map<String, int> _alertCount = {};
  final Map<String, int> _activeNotifIds = {};
  static const int _maxAlertsPerVisit = 2;

  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notifInitialized = false;

  Position? _lastPosition;
  DateTime? _lastFraFetch;
  bool _checkInProgress = false;
  static const String _kLastFraFetchKey = 'bg_last_fra_fetch';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await TestLogger.init(tag: 'BG');
    await TestLogger.log('🚀 Location tracking started', tag: 'BG');
    // Restore persisted throttle timestamp so restarts don't bypass the 30-min limit
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastFraFetchKey);
    if (raw != null) _lastFraFetch = DateTime.tryParse(raw);

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: _kDistanceFilterMeters,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifPlugin
        .initialize(const InitializationSettings(android: androidInit));
    _notifInitialized = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        _lastPosition = position;
        await _savePositionToPrefs(position);
        FlutterForegroundTask.sendDataToMain({
          'type': 'location',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': position.timestamp.millisecondsSinceEpoch,
        });
        // Check proximity on every GPS fix, not just on the repeat timer.
        // At driving speed (~60 km/h = 17 m/s) the 5 s timer fires every
        // ~85 m — a crossing zone could be entered and exited between ticks.
        // Guard against concurrent executions (GPS fixes can arrive faster
        // than _checkProximity completes at highway speed).
        if (_checkInProgress) return;
        _checkInProgress = true;
        _checkProximity(source: 'GPS').whenComplete(() => _checkInProgress = false);
      },
      onError: (error) {
        TestLogger.log('❌ Location stream error: $error', tag: 'BG');
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_checkInProgress) return;
    _checkInProgress = true;
    _checkProximity(source: 'TIMER').whenComplete(() => _checkInProgress = false);
  }

  Future<void> _checkProximity({String source = 'TIMER'}) async {
    try {
      // 1. Resolve position
      Position? position = _lastPosition;
      if (position == null) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_kLastPositionKey);
        if (raw != null) {
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            position = Position(
              latitude: (data['latitude'] as num).toDouble(),
              longitude: (data['longitude'] as num).toDouble(),
              accuracy: (data['accuracy'] as num? ?? 0).toDouble(),
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                  data['timestamp'] as int),
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
            await TestLogger.log(
              '[$source] using saved position '
              '${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}',
              tag: 'BG',
            );
          } catch (_) {}
        }
        if (position == null) {
          await TestLogger.log('[$source] no position yet — skipping', tag: 'BG');
          return;
        }
      }

      // 2. Accuracy gate — skip noisy fixes
      if (position.accuracy > 50) {
        await TestLogger.log(
          '[$source] accuracy=${position.accuracy.round()}m > 50m — skipping',
          tag: 'BG',
        );
        return;
      }

      // 3. Load settings
      final settings = await CrossingCacheService.loadWarningSettings();
      if (!settings.enabled) return;

      // 4. Load crossings — fetch from FRA if cache is empty
      List<Map<String, dynamic>> crossings =
          await CrossingCacheService.loadCrossings();
      if (crossings.isEmpty) {
        crossings = await _fetchAndCacheCrossings(position);
        if (crossings.isEmpty) {
          await TestLogger.log('[$source] no cached crossings', tag: 'BG');
          return;
        }
      }

      final double threshold = settings.distanceMeters;
      final Set<String> stillNear = {};

      for (final crossing in crossings) {
        final id = crossing['crossingid'] as String? ?? '';
        if (id.isEmpty) continue;
        final lat = double.tryParse(crossing['latitude'] as String? ?? '') ?? 0;
        final lng =
            double.tryParse(crossing['longitude'] as String? ?? '') ?? 0;
        final street = crossing['street'] as String? ?? 'Railway Crossing';
        if (lat == 0 || lng == 0) continue;

        final distance = _haversineDistanceMeters(
          position.latitude, position.longitude, lat, lng,
        );

        if (distance <= threshold * 2) stillNear.add(id);

        if (distance <= threshold) {
          final count = _alertCount[id] ?? 0;
          if (count < _maxAlertsPerVisit) {
            _alertCount[id] = count + 1;
            await TestLogger.log(
              '[$source] 🔔 ALERT #${count + 1} — $street ${distance.round()}m '
              '(acc=${position.accuracy.round()}m spd=${position.speed.toStringAsFixed(1)}m/s)',
              tag: 'BG',
            );
            if (_notifInitialized) {
              final notifId =
                  await _showCrossingAlert(_notifPlugin, id, street, distance);
              _activeNotifIds[id] = notifId;
            }
          }
        }
      }

      // 5. Hysteresis — cancel notifications when user departs
      final departed =
          _alertCount.keys.where((id) => !stillNear.contains(id)).toList();
      for (final id in departed) {
        final notifId = _activeNotifIds.remove(id);
        if (notifId != null) {
          await _notifPlugin.cancel(notifId);
          await TestLogger.log('[$source] 🔕 departed crossing $id', tag: 'BG');
        }
        _alertCount.remove(id);
      }

      await TestLogger.log(
        '[$source] checked ${crossings.length} crossings '
        'threshold=${threshold.round()}m '
        'pos=${position.latitude.toStringAsFixed(5)},${position.longitude.toStringAsFixed(5)} '
        'acc=${position.accuracy.round()}m '
        'spd=${position.speed.toStringAsFixed(1)}m/s',
        tag: 'BG',
      );
    } catch (e) {
      await TestLogger.log('[$source] ❌ error: $e', tag: 'BG');
    }
  }

  // Fetch at-grade crossings from FRA API when cache is empty.
  // Throttled to once per 30 minutes to avoid hammering the API.
  Future<List<Map<String, dynamic>>> _fetchAndCacheCrossings(
      Position position) async {
    final now = DateTime.now();
    if (_lastFraFetch != null &&
        now.difference(_lastFraFetch!).inMinutes < 30) {
      return [];
    }
    // Set before attempt so failures don't cause hammering every 5 seconds.
    // Persisted to SharedPreferences so the throttle survives service restarts.
    _lastFraFetch = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastFraFetchKey, now.toIso8601String());
    try {
      const double delta = 0.225; // ~25 km
      final latMin = position.latitude - delta;
      final latMax = position.latitude + delta;
      final lngMin = position.longitude - delta;
      final lngMax = position.longitude + delta;

      // Use Uri constructor so query parameters are properly encoded
      final uri = Uri.https(
        'data.transportation.gov',
        '/resource/vhwz-raag.json',
        {
          '\$where': 'latitude>${latMin.toStringAsFixed(6)}'
              ' AND latitude<${latMax.toStringAsFixed(6)}'
              ' AND longitude>${lngMin.toStringAsFixed(6)}'
              ' AND longitude<${lngMax.toStringAsFixed(6)}',
          '\$limit': '10000',
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        await TestLogger.log(
            '[BG] FRA fetch failed: ${res.statusCode}', tag: 'BG');
        return [];
      }

      final data = jsonDecode(res.body) as List<dynamic>;
      final crossings = <Map<String, dynamic>>[];
      for (final e in data) {
        if (e['latitude'] == null || e['longitude'] == null) continue;
        if ((e['crossingposition'] ?? '').toString().trim().toLowerCase() !=
            'at grade') continue;
        final id = (e['crossingid'] as String? ?? '').trim();
        if (id.isEmpty) continue;
        crossings.add({
          'crossingid': id,
          'latitude': e['latitude'].toString(),
          'longitude': e['longitude'].toString(),
          'street': e['street'] ?? 'Railway Crossing',
        });
      }

      await CrossingCacheService.saveCrossings(crossings);
      await TestLogger.log(
          '[BG] fetched ${crossings.length} crossings from FRA', tag: 'BG');
      return crossings;
    } catch (e) {
      await TestLogger.log('[BG] FRA fetch error: $e', tag: 'BG');
      return [];
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await TestLogger.log('🛑 Location tracking stopped', tag: 'BG');
    await _positionStream?.cancel();
    _positionStream = null;
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_tracking') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  Future<void> _savePositionToPrefs(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
      });
      await prefs.setString(_kLastPositionKey, positionJson);
    } catch (e) {
      dev.log('Error saving position: $e');
    }
  }
}
