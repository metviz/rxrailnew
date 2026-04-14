import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

import 'modules/crossing/controllers/crossing_controller.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const int _serviceId = 256;

   initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'railway_crossing_channel',
        channelName: 'Railway Crossing Alerts',
        channelDescription: 'Notification channel for railway crossing alerts',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> startForegroundService() async {
    if (!await FlutterForegroundTask.isRunningService) {
      final result = await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: 'Railway Crossing Alerts Active',
        notificationText: 'Monitoring for nearby railway crossings',
        callback: startBackgroundTask,
      );
      return result is ServiceRequestSuccess;
    }
    return false;
  }

  Future<bool> stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      final result = await FlutterForegroundTask.stopService();
      return result is ServiceRequestSuccess;
    }
    return false;
  }
}

@pragma('vm:entry-point')
void startBackgroundTask() {
  FlutterForegroundTask.setTaskHandler(BackgroundTaskHandler());
}

class BackgroundTaskHandler extends TaskHandler {
  CrossingController? _controller;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize GetX in the background isolate
    Get.create(() => CrossingController());
    _controller = Get.find<CrossingController>();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _runEvent(timestamp);
  }

  Future<void> _runEvent(DateTime timestamp) async {
    try {
      if (_controller?.userPosition.value != null) {
        await _controller?.checkNearbyCrossings();
      }
      FlutterForegroundTask.sendDataToMain(timestamp.millisecondsSinceEpoch);
    } catch (e) {
      print('Background task error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _controller = null;
  }
}