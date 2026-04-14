import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog {
  static Future<bool> requestBackgroundLocation() async {
    // First check if we already have it
    if (await Permission.locationAlways.isGranted) {
      return true;
    }

    // Show explanation dialog
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

    // Request the permission
    final status = await Permission.locationAlways.request();

    if (!status.isGranted) {
      // Show dialog to open settings
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

    final permStatus = await Permission.ignoreBatteryOptimizations.request();
    return permStatus.isGranted;
  }

  static Future<void> requestAllPermissions() async {
    // Basic location first
    await Permission.location.request();
    
    // Then notification (Android 13+)
    await Permission.notification.request();
    
    // Background location
    final bgGranted = await requestBackgroundLocation();
    
    if (bgGranted) {
      // Battery optimization
      await requestBatteryOptimization();
    }
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
            _buildPermissionRow('Location (While Using)', locationStatus.isGranted),
            _buildPermissionRow('Location (Always)', locationAlwaysStatus.isGranted),
            _buildPermissionRow('Notifications', notificationStatus.isGranted),
            _buildPermissionRow('Battery Optimization', batteryStatus.isGranted),
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

  static Widget _buildPermissionRow(String name, bool granted) {
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
              style: TextStyle(
                color: granted ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
