import 'dart:io' show Platform;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:RXrail/app/services/background_location_service.dart'
    show startLocationTracking;
import 'package:RXrail/app/services/test_logger.dart';

/// P2 — periodic watchdog that resurrects the foreground location service if
/// the OS froze/killed it while the user still expects tracking.
///
/// Life360 pattern: never trust that one foreground service stays up forever.
/// A 15-minute WorkManager job (the Android minimum for periodic work) checks
/// `isRunningService` and restarts when the persisted intent says it should be
/// running. Belt-and-suspenders on top of the foreground service's own
/// auto-restart receivers.
class BackgroundWatchdogService {
  static const String _taskUnique = 'rxrail_fg_watchdog';
  static const String _taskName = 'fgWatchdog';
  static const String _tag = 'WATCHDOG';

  /// SharedPreferences key written by BackgroundLocationService when the user
  /// turns tracking on/off — the source of truth for "should be running".
  static const String _isServiceRunningKey = 'is_service_running';

  /// Call once at app start (after WidgetsFlutterBinding). Idempotent.
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().initialize(watchdogDispatcher, isInDebugMode: false);
    } catch (e) {
      TestLogger.log('⚠️ watchdog init failed: $e', tag: _tag);
    }
  }

  /// Registers the recurring check. Safe to call repeatedly (keep-existing).
  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().registerPeriodicTask(
        _taskUnique,
        _taskName,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.not_required),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
      TestLogger.log('🐕 watchdog registered (15m)', tag: _tag);
    } catch (e) {
      TestLogger.log('⚠️ watchdog register failed: $e', tag: _tag);
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().cancelByUniqueName(_taskUnique);
    } catch (_) {}
  }
}

/// WorkManager background isolate entry point. MUST be top-level + annotated.
@pragma('vm:entry-point')
void watchdogDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldRun =
          prefs.getBool(BackgroundWatchdogService._isServiceRunningKey) ??
              false;
      if (!shouldRun) return true; // user turned tracking off — nothing to do.

      if (await FlutterForegroundTask.isRunningService) {
        return true; // alive — healthy.
      }

      // Frozen/killed while it should be running → resurrect it.
      TestLogger.log('🐕 service down — restarting', tag: 'WATCHDOG');
      _initForegroundTask();
      await FlutterForegroundTask.startService(
        serviceId: 257,
        notificationTitle: 'RXrail Active',
        notificationText: 'Monitoring for railway crossings',
        callback: startLocationTracking,
      );
    } catch (e) {
      TestLogger.log('🐕 watchdog restart failed: $e', tag: 'WATCHDOG');
    }
    return true;
  });
}

/// Mirrors BackgroundLocationService._initForegroundTask so the watchdog
/// isolate can start the service without the main service object.
void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'railway_crossing_location',
      channelName: 'Railway Crossing Location Tracking',
      channelDescription:
          'Continuous location tracking for railway crossing alerts',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
}
