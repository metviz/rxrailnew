import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:RXrail/app/notification_service.dart';
import 'package:RXrail/app/services/background_survival_service.dart';

class PermissionHelper {
  static Future<bool> requestBackgroundLocation() async {
    if (await Permission.locationAlways.isGranted) return true;

    final proceed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Background Location Required'),
        content: const Text(
          'To alert you about railway crossings even when the app is closed, '
          'we need "Allow all the time" location permission.\n\n'
          'This is essential for your safety.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (proceed != true) return false;

    final status = await Permission.locationAlways.request();

    if (!status.isGranted) {
      await Get.dialog(
        AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Please go to Settings and grant "Allow all the time" '
            'location permission for background alerts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  static Future<bool> requestBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;

    final proceed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Battery Optimization'),
        content: const Text(
          'To ensure reliable background alerts, please disable battery '
          'optimization for this app.\n\n'
          'This allows us to monitor railway crossings continuously.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (proceed != true) return false;

    return (await Permission.ignoreBatteryOptimizations.request()).isGranted;
  }

  /// Requests all permissions needed for background railway crossing alerts.
  /// Battery optimization is always requested — it is critical for reliable operation.
  static Future<void> requestAllPermissions() async {
    await Permission.location.request();
    await Permission.notification.request();
    await requestBackgroundLocation();
    await requestBatteryOptimization();
    // NOTE: the OEM "deep sleep" whitelist prompt (requestOemAutoStart) is
    // fired from the home screen's onReady, NOT here — running it inside the
    // splash permission burst races Get.offNamed navigation, which tears the
    // dialog down before it can open Settings.
  }

  /// One-time guided prompt to whitelist the app in the OEM's auto-start /
  /// never-sleeping list. No-op on stock Android or if already shown.
  static Future<void> requestOemAutoStart() async {
    final survival = Get.isRegistered<BackgroundSurvivalService>()
        ? Get.find<BackgroundSurvivalService>()
        : Get.put(BackgroundSurvivalService(), permanent: true);

    final instruction = await survival.maybePromptOemWhitelist();
    if (instruction == null) return; // not an aggressive OEM, or already shown.

    // The user asked to be taken to Settings automatically on first launch.
    // We deliver the instruction as a NOTIFICATION rather than an in-app
    // dialog: once we hand off to the Settings app the dialog is gone, and a
    // Get.dialog fired from this post-splash path is unreliable (the overlay
    // context is often null, so it gets swallowed). The notification persists
    // in the shade, readable while the user is on the App-info screen.
    try {
      await NotificationService().showNotifications(
        'Keep RXrail Alerts Running',
        instruction,
      );
    } catch (_) {
      // Notification is a nicety; never block the navigation on it.
    }

    // Auto-navigate straight to the (reachable) settings page.
    await survival.openAutoStartSettings();
    await survival.markOemPrompted();
  }

  static Future<void> showPermissionStatus() async {
    final locationStatus = await Permission.location.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;
    final notificationStatus = await Permission.notification.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    await Get.dialog(
      AlertDialog(
        title: const Text('Permission Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Location (While Using)', locationStatus.isGranted),
            _buildRow('Location (Always)', locationAlwaysStatus.isGranted),
            _buildRow('Notifications', notificationStatus.isGranted),
            _buildRow('Battery Optimization', batteryStatus.isGranted),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          if (!locationAlwaysStatus.isGranted || !batteryStatus.isGranted)
            ElevatedButton(
              onPressed: () {
                Get.back();
                requestAllPermissions();
              },
              child: const Text('Grant Permissions'),
            ),
        ],
      ),
    );
  }

  static Widget _buildRow(String name, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: granted ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
