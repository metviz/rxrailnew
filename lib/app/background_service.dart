import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

import 'modules/crossing/controllers/crossing_controller.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

   initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'railway_crossing_channel',
        channelName: 'Railway Crossing Alerts',
        channelDescription: 'Notification channel for railway crossing alerts',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> startForegroundService() async {
    if (!await FlutterForegroundTask.isRunningService) {
      return await FlutterForegroundTask.startService(
        notificationTitle: 'Railway Crossing Alerts Active',
        notificationText: 'Monitoring for nearby railway crossings',
        callback: startBackgroundTask,
      );
    }
    return false;
  }

  Future<bool> stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return await FlutterForegroundTask.stopService();
    }
    return false;
  }
}

@pragma('vm:entry-point')
void startBackgroundTask() {
  FlutterForegroundTask.setTaskHandler(BackgroundTaskHandler());
}

class BackgroundTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  CrossingController? _controller;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    // Initialize GetX in the background isolate
    Get.create(() => CrossingController());
    _controller = Get.find<CrossingController>();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      if (_controller?.userPosition.value != null) {
        await _controller?.checkNearbyCrossings();
      }

      // Send data to the main isolate
      _sendPort?.send(timestamp);
    } catch (e) {
      print('Background task error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Clean up resources
    _controller = null;
  }

  // 👇 add this new method
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // Optional: can be left empty if not used
    // print('[log] 🔁 onRepeatEvent triggered at $timestamp');
  }
}