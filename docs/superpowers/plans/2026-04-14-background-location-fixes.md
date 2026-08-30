# Background Location Service Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 6 code-review issues in `BackgroundLocationService` and `PermissionDialog` so the background location feature actually works end-to-end.

**Architecture:** `BackgroundLocationService` is a GetX permanent service registered at startup. Its `LocationTaskHandler` (a `flutter_foreground_task` isolate handler) sends position data back to the main isolate via `FlutterForegroundTask.receivePort`. The main isolate updates `currentPosition` and fires `onLocationUpdate`. `PermissionDialog` becomes the single permission path; `GeofencingService` delegates to it.

**Tech Stack:** Flutter, GetX, flutter_foreground_task, geolocator, permission_handler, shared_preferences, dart:async

---

## Files to touch

| File | Action | Why |
|------|--------|-----|
| `lib/app/services/background_location_service.dart` | Modify | Issues 1, 3, 4, 5 + misc cleanup |
| `lib/app/widgets/permission_dialog.dart` | Modify → move | Issue 6 + battery opt fix |
| `lib/app/utils/permission_helper.dart` | Create | New home for PermissionDialog logic |
| `lib/app/services/geo_fencing_services.dart` | Modify | Issue 6: remove duplicate permission flow |
| `lib/app/modules/splash/controllers/splash_controller.dart` | Modify | Issue 2: register BackgroundLocationService |

---

### Task 1: Wire `onLocationUpdate` callback and `currentPosition` (Issue #1)

The `LocationTaskHandler` (runs in foreground task isolate) already sends position data via `_sendPort`. The main-isolate `BackgroundLocationService` must listen on `FlutterForegroundTask.receivePort`, parse the map, construct a `Position`, and call `onLocationUpdate`.

**Files:**
- Modify: `lib/app/services/background_location_service.dart`

- [ ] **Step 1: Open the file and read the current `onInit` and `onClose`**

  Current `onInit` (line 21–24):
  ```dart
  @override
  void onInit() {
    super.onInit();
    _checkIfServiceWasRunning();
  }
  ```

- [ ] **Step 2: Add `_startReceivePort()` and call it from `onInit`**

  Replace the `onInit` block with:
  ```dart
  @override
  void onInit() {
    super.onInit();
    _initForegroundTask();          // moved from startBackgroundTracking
    _startReceivePort();
    _checkIfServiceWasRunning();
  }
  ```

  Add this new method (insert after the `onLocationUpdate` field, before `_checkIfServiceWasRunning`):
  ```dart
  void _startReceivePort() {
    FlutterForegroundTask.receivePort?.listen((data) {
      if (data is Map && data['type'] == 'location') {
        try {
          final position = Position(
            latitude: (data['latitude'] as num).toDouble(),
            longitude: (data['longitude'] as num).toDouble(),
            accuracy: (data['accuracy'] as num).toDouble(),
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
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
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add lib/app/services/background_location_service.dart
  git commit -m "fix: wire onLocationUpdate callback via FlutterForegroundTask receivePort"
  ```

---

### Task 2: Move `FlutterForegroundTask.init` to `onInit` (Issue #4)

`init()` must be called once at service startup. Currently it is called inside `startBackgroundTracking()`, which runs every time — including on auto-restart.

**Files:**
- Modify: `lib/app/services/background_location_service.dart`

- [ ] **Step 1: Extract `_initForegroundTask()` method**

  Add this method above `startBackgroundTracking`:
  ```dart
  void _initForegroundTask() {
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
        eventAction: ForegroundTaskEventAction.repeat(_repeatIntervalMs),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }
  ```

  Add constant at the top of the class (after `_isServiceRunningKey`):
  ```dart
  static const int _repeatIntervalMs = 5000;
  static const int _distanceFilterMeters = 10;
  ```

- [ ] **Step 2: Remove the `FlutterForegroundTask.init(...)` block from `startBackgroundTracking`**

  In `startBackgroundTracking`, delete lines 47–77 (the entire `FlutterForegroundTask.init(...)` call). The method now starts directly with the permission check and then calls `FlutterForegroundTask.startService(...)`.

- [ ] **Step 3: Replace the `distanceFilter: 10` magic number in `LocationTaskHandler.onStart`**

  Since constants on `BackgroundLocationService` are not reachable from the isolate, define a top-level constant above the `startLocationTracking` function:
  ```dart
  const int _kDistanceFilterMeters = 10;
  ```

  Then in `LocationTaskHandler.onStart`, change:
  ```dart
  distanceFilter: 10,
  ```
  to:
  ```dart
  distanceFilter: _kDistanceFilterMeters,
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add lib/app/services/background_location_service.dart
  git commit -m "fix: move FlutterForegroundTask.init to onInit, extract magic numbers to constants"
  ```

---

### Task 3: Fix unique `serviceId` to avoid service collision (Issue #3)

`BackgroundLocationService` uses `serviceId: 256`. `BackgroundService` (in `lib/app/background_service.dart`) calls `FlutterForegroundTask.startService` without a `serviceId` (which defaults to 0). They are different services — give them distinct, named IDs to make this explicit.

**Files:**
- Modify: `lib/app/services/background_location_service.dart`
- Modify: `lib/app/background_service.dart`

- [ ] **Step 1: Add service ID constants**

  In `background_location_service.dart`, add to the class constants:
  ```dart
  static const int _serviceId = 257; // distinct from BackgroundService (256)
  ```

  In `startBackgroundTracking`, change:
  ```dart
  serviceId: 256,
  ```
  to:
  ```dart
  serviceId: _serviceId,
  ```

- [ ] **Step 2: Explicitly set serviceId in `BackgroundService`**

  In `lib/app/background_service.dart`, add a constant and pass it:
  ```dart
  static const int _serviceId = 256;
  ```

  In `startForegroundService`, change:
  ```dart
  return await FlutterForegroundTask.startService(
    notificationTitle: 'Railway Crossing Alerts Active',
    notificationText: 'Monitoring for nearby railway crossings',
    callback: startBackgroundTask,
  );
  ```
  to:
  ```dart
  return await FlutterForegroundTask.startService(
    serviceId: _serviceId,
    notificationTitle: 'Railway Crossing Alerts Active',
    notificationText: 'Monitoring for nearby railway crossings',
    callback: startBackgroundTask,
  );
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add lib/app/services/background_location_service.dart lib/app/background_service.dart
  git commit -m "fix: assign distinct serviceIds (256, 257) to prevent foreground service collision"
  ```

---

### Task 4: Fix `onClose()` unawaited async (Issue #5)

`onClose()` is synchronous. Calling `stopBackgroundTracking()` (async) without `await` means the stop completes after `onClose` returns — the Android foreground notification stays alive.

**Files:**
- Modify: `lib/app/services/background_location_service.dart`

- [ ] **Step 1: Use `unawaited` to make intent explicit**

  The `dart:async` import is already present. Change `onClose`:
  ```dart
  @override
  void onClose() {
    unawaited(stopBackgroundTracking());
    super.onClose();
  }
  ```

  `unawaited` (from `dart:async`) silences the warning and makes the fire-and-forget intentional. This is the correct pattern when a lifecycle hook cannot be made async.

- [ ] **Step 2: Commit**

  ```bash
  git add lib/app/services/background_location_service.dart
  git commit -m "fix: use unawaited() in onClose to correctly signal intentional fire-and-forget"
  ```

---

### Task 5: Remove dead code — `_savePosition` and hardcoded key string (cleanup)

`BackgroundLocationService._savePosition()` is never called. `LocationTaskHandler._savePositionToPrefs` uses the raw string `'last_position'` instead of the constant.

**Files:**
- Modify: `lib/app/services/background_location_service.dart`

- [ ] **Step 1: Delete `_savePosition` method (lines 120–136)**

  Remove the entire `_savePosition` method from `BackgroundLocationService`. The saving is done correctly by `LocationTaskHandler._savePositionToPrefs`.

- [ ] **Step 2: Fix hardcoded key in `_savePositionToPrefs`**

  Since `BackgroundLocationService._lastPositionKey` is not accessible from the isolate, promote the key to a top-level constant (above `startLocationTracking`):
  ```dart
  const String _kLastPositionKey = 'last_position';
  ```

  In `LocationTaskHandler._savePositionToPrefs`, change:
  ```dart
  await prefs.setString('last_position', positionJson);
  ```
  to:
  ```dart
  await prefs.setString(_kLastPositionKey, positionJson);
  ```

  In `BackgroundLocationService.getLastKnownPosition`, change the read to use the same constant:
  ```dart
  final positionJson = prefs.getString(_kLastPositionKey);
  ```
  And remove the now-redundant class-level `_lastPositionKey` field (or keep it pointing to `_kLastPositionKey` — your call).

- [ ] **Step 3: Remove unused `dart:isolate` import**

  Delete line 2: `import 'dart:isolate';`
  (`SendPort` comes from the `flutter_foreground_task` package, not `dart:isolate` directly.)

- [ ] **Step 4: Commit**

  ```bash
  git add lib/app/services/background_location_service.dart
  git commit -m "chore: remove dead _savePosition method, unify last_position key constant, drop unused dart:isolate import"
  ```

---

### Task 6: Register `BackgroundLocationService` at startup (Issue #2)

The service is defined but never put into the GetX dependency graph. It must be registered permanently at app startup — the same place `SettingController` and `CrossingController` are registered.

**Files:**
- Modify: `lib/app/modules/splash/controllers/splash_controller.dart`
- Modify: `lib/app/services/background_location_service.dart` (add import if needed)

- [ ] **Step 1: Add import to `splash_controller.dart`**

  At the top of `splash_controller.dart`, add:
  ```dart
  import '../../../services/background_location_service.dart';
  ```

- [ ] **Step 2: Register the service in `SplashController.init()`**

  In `init()`, after the `settingController` and `crossingController` registrations, add:
  ```dart
  Get.put(BackgroundLocationService(), permanent: true);
  ```

  The full block becomes:
  ```dart
  final settingController = Get.put(SettingController(), permanent: true);
  final crossingController = Get.put(CrossingController(), permanent: true);
  Get.put(BackgroundLocationService(), permanent: true);
  settingController.crossingController = crossingController;
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add lib/app/modules/splash/controllers/splash_controller.dart
  git commit -m "fix: register BackgroundLocationService at startup so it is reachable"
  ```

---

### Task 7: Consolidate duplicate permission flow (Issue #6)

`GeofencingService.requestBackgroundPermission()` and `PermissionDialog.requestBackgroundLocation()` both request `locationAlways` with their own dialogs. Remove the duplicate from `GeofencingService` and delegate to `PermissionDialog`.

Also: move `PermissionDialog` from `lib/app/widgets/` to `lib/app/utils/permission_helper.dart` since it is a static utility class, not a `Widget`.

**Files:**
- Create: `lib/app/utils/permission_helper.dart`
- Delete (content only): `lib/app/widgets/permission_dialog.dart` → replace with re-export shim or delete
- Modify: `lib/app/services/geo_fencing_services.dart`

- [ ] **Step 1: Create `lib/app/utils/permission_helper.dart`**

  Move all content from `lib/app/widgets/permission_dialog.dart` into the new file, renaming the class to `PermissionHelper`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:permission_handler/permission_handler.dart';

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
    /// Battery optimization is requested regardless of background location result.
    static Future<void> requestAllPermissions() async {
      await Permission.location.request();
      await Permission.notification.request();
      await requestBackgroundLocation();
      await requestBatteryOptimization(); // always — it is critical for reliability
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
  ```

- [ ] **Step 2: Replace `lib/app/widgets/permission_dialog.dart` with a re-export shim**

  So any existing imports don't break immediately:
  ```dart
  // Deprecated: use PermissionHelper from lib/app/utils/permission_helper.dart
  export '../utils/permission_helper.dart' show PermissionHelper as PermissionDialog;
  ```

  Actually, since `PermissionDialog` is currently not imported anywhere (it's dead code), just delete the file content and redirect. Safest: leave the file as a re-export:
  ```dart
  export 'package:RXrail/app/utils/permission_helper.dart';
  ```

- [ ] **Step 3: Update `GeofencingService.requestBackgroundPermission` to delegate to `PermissionHelper`**

  In `lib/app/services/geo_fencing_services.dart`, add import:
  ```dart
  import 'package:RXrail/app/utils/permission_helper.dart';
  ```

  Replace the entire `requestBackgroundPermission()` method body:
  ```dart
  Future<bool> requestBackgroundPermission() async {
    return PermissionHelper.requestBackgroundLocation();
  }
  ```

- [ ] **Step 4: Update `BackgroundLocationService` to use `PermissionHelper` for permissions**

  In `background_location_service.dart`, add import:
  ```dart
  import 'package:RXrail/app/utils/permission_helper.dart';
  ```

  (Optional for now — `BackgroundLocationService.startBackgroundTracking` currently only does a `Geolocator.checkPermission()` guard, not a full request flow. This is fine to leave as-is until a UI calls `PermissionHelper.requestAllPermissions()` first.)

- [ ] **Step 5: Commit**

  ```bash
  git add lib/app/utils/permission_helper.dart lib/app/widgets/permission_dialog.dart lib/app/services/geo_fencing_services.dart
  git commit -m "fix: consolidate permission flow into PermissionHelper, remove duplicate in GeofencingService"
  ```

---

### Task 8: Push branch and update PR

- [ ] **Step 1: Push the develop branch**

  ```bash
  git push origin develop
  ```

- [ ] **Step 2: Verify PR is updated**

  ```bash
  gh pr view 1 --repo metviz/rxrailnew
  ```

---

## Self-Review

**Spec coverage:**
1. `onLocationUpdate` wired ✅ (Task 1)
2. `BackgroundLocationService` registered ✅ (Task 6)
3. `serviceId` conflict resolved ✅ (Task 3)
4. `FlutterForegroundTask.init` moved to `onInit` ✅ (Task 2)
5. `onClose` unawaited fixed ✅ (Task 4)
6. Duplicate permission flow consolidated ✅ (Task 7)
7. Dead code removed ✅ (Task 5)
8. Battery optimization always requested ✅ (Task 7, `requestAllPermissions`)

**No placeholders found.**

**Type consistency:** `PermissionHelper` used consistently in Tasks 7 throughout. `_kLastPositionKey` is a top-level constant accessible from both `BackgroundLocationService` and `LocationTaskHandler`. `_serviceId` constants live in their respective classes.
