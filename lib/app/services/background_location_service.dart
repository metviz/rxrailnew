import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as log;

class BackgroundLocationService extends GetxService {
  static const String _lastPositionKey = 'last_position';
  static const String _isServiceRunningKey = 'is_service_running';
  
  final isRunning = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();
  
  // Callback for location updates
  Function(Position)? onLocationUpdate;

  @override
  void onInit() {
    super.onInit();
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

  Future<bool> startBackgroundTracking() async {
    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        log.log('❌ Location permission denied');
        return false;
      }

      // Initialize foreground task
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'railway_crossing_location',
          channelName: 'Railway Crossing Location Tracking',
          channelDescription: 'Continuous location tracking for railway crossing alerts',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          buttons: [
            const NotificationButton(
              id: 'stop_tracking',
              text: 'Stop Tracking',
            ),
          ],
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000), // Every 5 seconds
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );

      // Start foreground service
      final started = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'RXrail Active',
        notificationText: 'Monitoring for railway crossings',
        callback: startLocationTracking,
      );

      if (started) {
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
      final stopped = await FlutterForegroundTask.stopService();
      
      if (stopped) {
        isRunning.value = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isServiceRunningKey, false);
        log.log('✅ Background location service stopped');
      }
      
      return stopped;
    } catch (e) {
      log.log('❌ Error stopping background service: $e');
      return false;
    }
  }

  Future<void> _savePosition(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
      });
      await prefs.setString(_lastPositionKey, positionJson);
    } catch (e) {
      log.log('Error saving position: $e');
    }
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = prefs.getString(_lastPositionKey);
      
      if (positionJson != null) {
        final data = jsonDecode(positionJson);
        return Position(
          latitude: data['latitude'],
          longitude: data['longitude'],
          accuracy: data['accuracy'],
          altitude: data['altitude'],
          heading: data['heading'],
          speed: data['speed'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
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
    stopBackgroundTracking();
    super.onClose();
  }
}

// Top-level callback function
@pragma('vm:entry-point')
void startLocationTracking() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;
  SendPort? _sendPort;

  @override
  Future<void> onStart(DateTime timestamp, TaskData? taskData) async {
    _sendPort = taskData?.sendPort;
    log.log('🚀 Location tracking started');
    
    // Start listening to location updates
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        log.log('📍 Location update: ${position.latitude}, ${position.longitude}');
        
        // Save position to SharedPreferences
        await _savePositionToPrefs(position);
        
        // Send to main isolate
        _sendPort?.send({
          'type': 'location',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.millisecondsSinceEpoch,
        });
      },
      onError: (error) {
        log.log('❌ Location stream error: $error');
      },
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, TaskData? taskData) async {
    // Called every 5 seconds - can be used for periodic checks
    log.log('⏰ Periodic check: ${timestamp}');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, TaskData? taskData) async {
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
      await prefs.setString('last_position', positionJson);
    } catch (e) {
      log.log('Error saving position: $e');
    }
  }
}
