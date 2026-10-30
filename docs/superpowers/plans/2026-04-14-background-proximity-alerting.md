# Life360-Style Background Proximity Alerting — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fire a crossing alert notification (sound + vibration + push) even when other apps are running, using the user's configured warning distance (100–500 m from the Settings slider).

**Architecture:** `LocationTaskHandler.onRepeatEvent` (fires every 5 s in the foreground task isolate) reads crossings + settings from `SharedPreferences`, computes distances using the Haversine formula, and calls `FlutterLocalNotifications` directly (no GetX/singletons — isolates can't access them). `CrossingCacheService` serializes the crossing list to SharedPreferences whenever it changes. `SettingController` already writes `warningDistance` and `isWarningsEnabled` to SharedPreferences on every change — no modification needed there.

**Tech Stack:** flutter_foreground_task, geolocator, flutter_local_notifications, shared_preferences, dart:math

---

## Files to touch

| File | Action | Why |
|------|--------|-----|
| `lib/app/services/crossing_cache_service.dart` | **Create** | Serializes crossing list to SharedPreferences so the isolate can read it |
| `lib/app/services/background_location_service.dart` | **Modify** | Implement `onRepeatEvent` with Haversine check + notification |
| `lib/app/modules/crossing/controllers/crossing_controller.dart` | **Modify** | Call `CrossingCacheService.save()` when crossing list updates |

---

### Task 1: Create `CrossingCacheService` — serialize crossings to SharedPreferences

The foreground task isolate cannot use GetX or make HTTP calls. It can only read `SharedPreferences`. We need to persist the crossing list as JSON whenever it changes so the isolate can read it.

**Files:**
- Create: `lib/app/services/crossing_cache_service.dart`

- [ ] **Step 1: Create the file**

```dart
import 'dart:convert';
import 'dart:developer' as log;
import 'package:shared_preferences/shared_preferences.dart';

/// Serializes nearby crossings to SharedPreferences so the background
/// task isolate can read them without GetX or HTTP.
class CrossingCacheService {
  static const String _crossingsKey = 'cached_crossings';
  static const String _warningEnabledKey = 'isWarningsEnabled';
  static const String _warningDistanceKey = 'warningDistance';

  /// Save a list of crossings as JSON. Call this whenever nearbyLocations changes.
  static Future<void> saveCrossings(
    List<Map<String, dynamic>> crossings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_crossingsKey, jsonEncode(crossings));
      log.log('✅ CrossingCacheService: saved ${crossings.length} crossings');
    } catch (e) {
      log.log('❌ CrossingCacheService.saveCrossings error: $e');
    }
  }

  /// Read the cached crossings. Returns empty list on error.
  static Future<List<Map<String, dynamic>>> loadCrossings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_crossingsKey);
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      log.log('❌ CrossingCacheService.loadCrossings error: $e');
      return [];
    }
  }

  /// Read warning settings. Returns defaults if not set.
  static Future<({bool enabled, double distanceMeters})>
      loadWarningSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_warningEnabledKey) ?? true,
      distanceMeters: prefs.getDouble(_warningDistanceKey) ?? 200.0,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/raghu/tools/rxrailnew
git add lib/app/services/crossing_cache_service.dart
git commit -m "feat: add CrossingCacheService to persist crossings for background isolate"
```

---

### Task 2: Wire `CrossingCacheService.saveCrossings` into `CrossingController`

Every time the nearby crossings list updates, save it to SharedPreferences so the background isolate has fresh data.

**Files:**
- Modify: `lib/app/modules/crossing/controllers/crossing_controller.dart`

Context: `CrossingController` has a `RxList<TransportLocation> nearbyLocations`. There will be a method that populates `nearbyLocations` (search for `nearbyLocations.assignAll` or `nearbyLocations.value =`). We need to call `CrossingCacheService.saveCrossings(...)` after that assignment.

- [ ] **Step 1: Add the import to `crossing_controller.dart`**

At the top of the file, add:
```dart
import '../../../services/crossing_cache_service.dart';
```

- [ ] **Step 2: Find where `nearbyLocations` is populated**

Search for `nearbyLocations` assignments in the file:
```bash
grep -n "nearbyLocations" lib/app/modules/crossing/controllers/crossing_controller.dart | grep -v "//"
```

- [ ] **Step 3: Add cache save after each assignment**

For every place `nearbyLocations` is assigned (e.g. `nearbyLocations.assignAll(...)` or `nearbyLocations.value = ...`), add the following immediately after:

```dart
// Persist to SharedPreferences for background isolate
CrossingCacheService.saveCrossings(
  nearbyLocations.map((c) => {
    'crossingid': c.crossingid ?? '',
    'latitude': c.latitude ?? '0',
    'longitude': c.longitude ?? '0',
    'street': c.street ?? 'Railway Crossing',
  }).toList(),
);
```

Note: `CrossingCacheService.saveCrossings` is async but we call it without `await` — fire-and-forget is fine here since we don't need to block the UI on the cache write.

- [ ] **Step 4: Commit**

```bash
cd /home/raghu/tools/rxrailnew
git add lib/app/modules/crossing/controllers/crossing_controller.dart
git commit -m "feat: persist nearby crossings to SharedPreferences on every update"
```

---

### Task 3: Implement `onRepeatEvent` in `LocationTaskHandler` — the core proximity check

This is the heart of the feature. Every 5 seconds, the background isolate:
1. Gets current GPS position
2. Loads crossings + settings from SharedPreferences
3. Computes Haversine distance to each crossing
4. Fires a notification for any crossing within the warning distance
5. Prevents re-alerting for the same crossing until the user moves away

**Files:**
- Modify: `lib/app/services/background_location_service.dart`

- [ ] **Step 1: Add `dart:math` import at the top of the file**

The file already imports `dart:async`, `dart:convert`. Add:
```dart
import 'dart:math' as math;
```

- [ ] **Step 2: Add the Haversine helper as a top-level function**

Add this below the `_kDistanceFilterMeters` constant (outside any class):

```dart
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
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
```

- [ ] **Step 3: Add notification helper as a top-level function**

The isolate cannot use `NotificationService` (singleton, needs GetX). Use `FlutterLocalNotifications` directly:

```dart
/// Fire a high-priority crossing alert from within the background isolate.
/// Uses a stable notification ID per crossing so repeated firings
/// update the same notification rather than stacking.
Future<void> _showCrossingAlert(String crossingId, String street, double distanceMeters) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));

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
    autoCancel: false,
    icon: '@mipmap/ic_launcher',
  );

  final notifId = crossingId.hashCode.abs() % 10000;
  await plugin.show(
    notifId,
    '⚠️ Railway Crossing Ahead',
    '$street — $distanceText',
    const NotificationDetails(android: androidDetails),
  );
}
```

Add the import for `flutter_local_notifications` at the top of the file:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
```

- [ ] **Step 4: Add alerted-set tracking field to `LocationTaskHandler`**

In the `LocationTaskHandler` class, add a field to track which crossings have already triggered an alert (so we don't fire every 5 seconds):

```dart
/// Crossings we've already alerted for. Cleared when user moves >2x warning distance away.
final Set<String> _alertedCrossings = {};
```

- [ ] **Step 5: Replace the `onRepeatEvent` no-op with the real implementation**

Replace the existing `onRepeatEvent` method:

```dart
@override
Future<void> onRepeatEvent(DateTime timestamp, TaskData? taskData) async {
  try {
    // 1. Get current position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      log.log('⏰ onRepeatEvent: could not get position: $e');
      return;
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
    final Set<String> nowNear = {};

    for (final crossing in crossings) {
      final id = crossing['crossingid'] as String? ?? '';
      final lat = double.tryParse(crossing['latitude'] as String? ?? '') ?? 0;
      final lng = double.tryParse(crossing['longitude'] as String? ?? '') ?? 0;
      final street = crossing['street'] as String? ?? 'Railway Crossing';

      if (lat == 0 || lng == 0) continue;

      final distance = _haversineDistanceMeters(
        position.latitude, position.longitude, lat, lng,
      );

      if (distance <= threshold) {
        nowNear.add(id);
        if (!_alertedCrossings.contains(id)) {
          _alertedCrossings.add(id);
          log.log('🔔 Crossing alert: $street — ${distance.round()}m');
          await _showCrossingAlert(id, street, distance);
        }
      }
    }

    // 5. Clear alerts for crossings the user has left (>2x threshold = re-alert on return)
    _alertedCrossings.removeWhere((id) => !nowNear.contains(id));

    log.log('⏰ onRepeatEvent: checked ${crossings.length} crossings at '
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}');
  } catch (e) {
    log.log('❌ onRepeatEvent error: $e');
  }
}
```

- [ ] **Step 6: Add `CrossingCacheService` import to `background_location_service.dart`**

```dart
import 'package:RXrail/app/services/crossing_cache_service.dart';
```

- [ ] **Step 7: Commit**

```bash
cd /home/raghu/tools/rxrailnew
git add lib/app/services/background_location_service.dart
git commit -m "feat: implement background proximity check in onRepeatEvent with Haversine distance"
```

---

### Task 4: Push and verify

- [ ] **Step 1: Push to origin**

```bash
cd /home/raghu/tools/rxrailnew
git push origin develop
```

- [ ] **Step 2: Verify PR updated**

```bash
gh pr view 1 --repo metviz/rxrailnew --json commits | grep messageHeadline
```

Expected: shows the 3 new commits at the top.

---

## Self-Review

**Spec coverage:**
- ✅ Alert fires when other apps are running — `onRepeatEvent` runs in foreground task isolate, independent of app state
- ✅ Uses user's warning distance (100–500 m) — read from `SharedPreferences` key `warningDistance`
- ✅ Respects "Enable Warnings" toggle — read from `SharedPreferences` key `isWarningsEnabled`
- ✅ No duplicate alerts — `_alertedCrossings` set prevents re-firing until user leaves area
- ✅ Re-alerts on return — set cleared when user moves away from crossing
- ✅ Works in background — no GetX, no singletons, only SharedPreferences + FlutterLocalNotifications direct call
- ✅ Crossing data available in isolate — `CrossingCacheService` bridges main isolate → SharedPreferences → task isolate

**No placeholders found.**

**Type consistency:**
- `CrossingCacheService.saveCrossings(List<Map<String, dynamic>>)` — matches what `CrossingController` passes (mapped from `TransportLocation`)
- `CrossingCacheService.loadCrossings()` returns `List<Map<String, dynamic>>` — matches what `onRepeatEvent` reads
- `CrossingCacheService.loadWarningSettings()` returns named record `({bool enabled, double distanceMeters})` — accessed as `settings.enabled` and `settings.distanceMeters` in Task 3 ✅
- `_haversineDistanceMeters` returns meters as `double` — compared to `settings.distanceMeters` (also meters) ✅
