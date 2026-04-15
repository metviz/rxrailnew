import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as log;
import 'package:RXrail/app/services/crossing_cache_service.dart';

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
      log.log('⚠️ FlutterForegroundTask.receivePort is null — location updates will not be received');
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
          log.log('Error parsing location from task: $e');
        }
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    _initForegroundTask();
    _startReceivePort();
    _checkIfServiceWasRunning();
  }

  Future<void> _checkIfServiceWasRunning() async {
    final prefs = await SharedPreferences.getInstance();
    final wasRunning = prefs.getBool(_isServiceRunningKey) ?? false;
    
    if (wasRunning) {
      // Restart service if it was running before app restart
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
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log.log('❌ Location permission denied');
        return false;
      }

      // Start foreground service
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
        log.log('✅ Background location service started');
        return true;
      }

      return false;
    } catch (e) {
      log.log('❌ Error starting background service: $e');
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
        log.log('✅ Background location service stopped');
      }

      return result is ServiceRequestSuccess;
    } catch (e) {
      log.log('❌ Error stopping background service: $e');
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
      log.log('Error loading last position: $e');
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

// Top-level constants
const String _kLastPositionKey = 'last_position';
const int _kDistanceFilterMeters = 10;

/// Returns distance in meters between two lat/lng points.
double _haversineDistanceMeters(
  double lat1, double lon1,
  double lat2, double lon2,
) {
  const r = 6371000.0; // Earth radius in meters
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
/// Uses a stable notification ID per crossing so repeated firings
/// update the same notification rather than stacking.
/// Shows a crossing alert and returns the notification ID used.
Future<int> _showCrossingAlert(
  FlutterLocalNotificationsPlugin plugin,
  String crossingId,
  String street,
  double distanceMeters,
) async {
  final distanceText = distanceMeters < 1000
      ? '${distanceMeters.round()}m away'
      : '${(distanceMeters / 1000).toStringAsFixed(1)}km away';

  const androidDetails = AndroidNotificationDetails(
    'railwaycrossingalerts',
    'Railway Crossing Alerts',
    channelDescription: 'High priority alerts for nearby railway crossings',
    importance: Importance.high,
    priority: Priority.high,
    enableLights: true,
    enableVibration: true,
    playSound: true,
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

// Top-level callback function
@pragma('vm:entry-point')
void startLocationTracking() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;

  /// How many times we've alerted for each crossing this visit. Reset when user leaves.
  final Map<String, int> _alertCount = {};

  /// Notification IDs currently shown, keyed by crossing ID. Used to cancel on exit.
  final Map<String, int> _activeNotifIds = {};

  static const int _maxAlertsPerVisit = 2;

  final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();
  bool _notifInitialized = false;

  Position? _lastPosition;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    log.log('🚀 Location tracking started');
    
    // Start listening to location updates
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _kDistanceFilterMeters, // Update every 10 meters
    );

    // Initialize notification plugin once
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifPlugin.initialize(const InitializationSettings(android: androidInit));
    _notifInitialized = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        log.log('📍 Location update: ${position.latitude}, ${position.longitude}');
        _lastPosition = position;
        
        // Save position to SharedPreferences
        await _savePositionToPrefs(position);
        
        // Send to main isolate
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
      },
      onError: (error) {
        log.log('❌ Location stream error: $error');
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _checkProximity();
  }

  Future<void> _checkProximity() async {
    try {
      // 1. Use stream position, fall back to last saved SharedPreferences position
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
              timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
            print('⏰ _checkProximity: using saved position ${position.latitude}, ${position.longitude}');
          } catch (_) {}
        }
        if (position == null) {
          print('⏰ _checkProximity: no position available yet');
          return;
        }
      }

      // 2. Load settings from SharedPreferences (isolate-safe)
      final settings = await CrossingCacheService.loadWarningSettings();
      if (!settings.enabled) return;

      // 3. Load crossings from SharedPreferences
      final crossings = await CrossingCacheService.loadCrossings();
      if (crossings.isEmpty) {
        log.log('⏰ onRepeatEvent: no cached crossings');
        return;
      }

      // 4. Check each crossing
      final double threshold = settings.distanceMeters;
      final Set<String> stillNear = {}; // hysteresis zone: within 2x threshold

      for (final crossing in crossings) {
        final id = crossing['crossingid'] as String? ?? '';
        if (id.isEmpty) continue;
        final lat = double.tryParse(crossing['latitude'] as String? ?? '') ?? 0;
        final lng = double.tryParse(crossing['longitude'] as String? ?? '') ?? 0;
        final street = crossing['street'] as String? ?? 'Railway Crossing';

        if (lat == 0 || lng == 0) continue;

        final distance = _haversineDistanceMeters(
          position.latitude, position.longitude, lat, lng,
        );

        if (distance <= threshold * 2) {
          stillNear.add(id); // within hysteresis zone — keep alert state
        }
        if (distance <= threshold) {
          final count = _alertCount[id] ?? 0;
          if (count < _maxAlertsPerVisit) {
            _alertCount[id] = count + 1;
            print('🔔 BG Crossing alert #${count + 1}: $street — ${distance.round()}m');
            if (_notifInitialized) {
              final notifId = await _showCrossingAlert(_notifPlugin, id, street, distance);
              _activeNotifIds[id] = notifId;
            }
          }
        }
      }

      // 5. When user leaves hysteresis zone: cancel notification + reset alert count
      final departed = _alertCount.keys.where((id) => !stillNear.contains(id)).toList();
      for (final id in departed) {
        final notifId = _activeNotifIds.remove(id);
        if (notifId != null) {
          await _notifPlugin.cancel(notifId);
          print('🔕 Cancelled notification for crossing $id');
        }
        _alertCount.remove(id);
      }

      print('⏰ BG checked ${crossings.length} crossings, threshold=${threshold.round()}m, '
          'pos=${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}');
    } catch (e) {
      log.log('❌ onRepeatEvent error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    log.log('🛑 Location tracking stopped');
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
    // Handle notification tap - you can send data to open the app
    FlutterForegroundTask.launchApp('/');
  }

  Future<void> _savePositionToPrefs(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
      });
      await prefs.setString(_kLastPositionKey, positionJson);
    } catch (e) {
      log.log('Error saving position: $e');
    }
  }
}
