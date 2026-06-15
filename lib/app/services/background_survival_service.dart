import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:RXrail/app/services/test_logger.dart';

/// Coordinates the OS-level permissions/exemptions an app needs so a
/// foreground location service is NOT killed by Doze + OEM battery managers.
///
/// Life360 model: assume the OS *wants* to kill you, then defeat each killer
/// up front during onboarding. This service owns that gauntlet.
///
/// P0 — battery optimization exemption (this pass).
/// P1 — OEM auto-start / "deep sleep" whitelist (added next).
/// P2 — watchdog restart (added next).
class BackgroundSurvivalService extends GetxService {
  static const String _kBatteryPromptedKey = 'survival_battery_prompted';
  static const String _kOemPromptedKey = 'survival_oem_prompted';

  static const String _tag = 'SURVIVAL';

  static const MethodChannel _oemChannel =
      MethodChannel('com.rxrail.app/oem_survival');

  /// OEMs that ship an aggressive, separate "app sleep" manager which a
  /// battery-optimization exemption does NOT disable. These need the extra
  /// auto-start / never-sleeping whitelist step.
  static const Set<String> _aggressiveOems = {
    'samsung', 'xiaomi', 'redmi', 'poco', 'huawei', 'honor',
    'oppo', 'vivo', 'oneplus', 'realme', 'iqoo', 'asus', 'letv',
  };

  /// True once the app is exempt from battery optimization (survives Doze).
  final isBatteryExempt = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Best-effort refresh so UI can reflect current state without prompting.
    refreshBatteryExemptStatus();
  }

  /// Reads current exemption state WITHOUT prompting the user.
  Future<bool> refreshBatteryExemptStatus() async {
    if (!Platform.isAndroid) {
      isBatteryExempt.value = true;
      return true;
    }
    try {
      final exempt =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      isBatteryExempt.value = exempt;
      return exempt;
    } catch (e) {
      TestLogger.log('⚠️ battery-exempt check failed: $e', tag: _tag);
      return false;
    }
  }

  // ── P0: battery optimization exemption ────────────────────────────────────

  /// Requests the battery optimization exemption.
  ///
  /// First attempt uses the system dialog (one tap, no Settings detour). If the
  /// user already dismissed it once, or the dialog is unavailable, falls back
  /// to opening the Settings screen directly.
  ///
  /// Returns the resulting exemption state. Safe to call repeatedly — exits
  /// immediately if already exempt.
  Future<bool> ensureBatteryExemption() async {
    if (!Platform.isAndroid) return true;

    if (await refreshBatteryExemptStatus()) {
      TestLogger.log('✅ already exempt from battery optimization', tag: _tag);
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(_kBatteryPromptedKey) ?? false;

    try {
      if (!alreadyPrompted) {
        // System dialog: "Allow RXrail to run in the background?" — one tap.
        TestLogger.log('🔋 requesting battery-opt exemption dialog', tag: _tag);
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        await prefs.setBool(_kBatteryPromptedKey, true);
      } else {
        // Already dismissed once — send them straight to the Settings toggle.
        TestLogger.log('🔋 opening battery-opt settings (re-ask)', tag: _tag);
        await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      }
    } catch (e) {
      TestLogger.log('❌ battery-opt request failed: $e', tag: _tag);
    }

    // User may have toggled it in Settings; re-read the truth.
    return refreshBatteryExemptStatus();
  }

  // ── P1: OEM auto-start / "deep sleep" whitelist ───────────────────────────

  /// Lowercase OEM manufacturer (e.g. "samsung"), or "" off-Android/on error.
  Future<String> getManufacturer() async {
    if (!Platform.isAndroid) return '';
    try {
      return (await _oemChannel.invokeMethod<String>('getManufacturer')) ?? '';
    } catch (e) {
      TestLogger.log('⚠️ getManufacturer failed: $e', tag: _tag);
      return '';
    }
  }

  /// True when this device's OEM has an "app sleep" manager separate from Doze
  /// (Samsung deep-sleep, MIUI autostart, Huawei protected apps, …).
  Future<bool> hasAggressiveOemKiller() async {
    final m = await getManufacturer();
    return _aggressiveOems.any(m.contains);
  }

  /// Opens the OEM auto-start / never-sleeping whitelist screen. Native side
  /// walks a prioritized intent list and falls back to app-details settings,
  /// so this never dead-ends. Returns true if a screen was launched.
  Future<bool> openAutoStartSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _oemChannel.invokeMethod<bool>('openAutoStartSettings')) ??
          false;
    } catch (e) {
      TestLogger.log('❌ openAutoStartSettings failed: $e', tag: _tag);
      return false;
    }
  }

  /// Returns the manufacturer-specific whitelist instruction IF this device
  /// needs the one-time prompt (aggressive OEM and not yet shown), else null.
  ///
  /// Does NOT set the "prompted" flag — the caller must call [markOemPrompted]
  /// only AFTER the dialog has actually been shown and acted on. This way a
  /// dialog that gets swallowed by a route transition retries next launch
  /// instead of being silently consumed forever.
  Future<String?> maybePromptOemWhitelist({bool force = false}) async {
    if (!Platform.isAndroid) return null;

    final manufacturer = await getManufacturer();
    final isAggressive = _aggressiveOems.any(manufacturer.contains);
    if (!isAggressive) return null;

    final prefs = await SharedPreferences.getInstance();
    if (!force && (prefs.getBool(_kOemPromptedKey) ?? false)) return null;

    TestLogger.log('📵 OEM whitelist needed ($manufacturer)', tag: _tag);
    return oemWhitelistInstruction(manufacturer);
  }

  /// Records that the one-time OEM prompt has been completed.
  Future<void> markOemPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOemPromptedKey, true);
  }

  /// Human-readable, manufacturer-specific path to the never-sleeping list.
  String oemWhitelistInstruction(String manufacturer) {
    final m = manufacturer.toLowerCase();
    if (m.contains('samsung')) {
      // The global "Never sleeping apps" list is locked behind a privileged
      // permission no 3rd-party app can hold, so we land the user on RXrail's
      // App info page — the Battery toggle there has the same effect.
      return 'Tap "Battery" → turn ON "Allow background activity" and '
          'set usage to "Unrestricted".\n\n'
          'This stops the phone from putting RXrail to sleep.';
    }
    if (m.contains('xiaomi') ||
        m.contains('redmi') ||
        m.contains('poco')) {
      return 'Security app → Permissions → Autostart → enable RXrail.\n\n'
          'Then Settings → Battery → app → No restrictions.';
    }
    if (m.contains('huawei') || m.contains('honor')) {
      return 'Settings → Battery → App launch → RXrail → Manage manually → '
          'enable Auto-launch, Secondary launch, and Run in background.';
    }
    if (m.contains('oppo') || m.contains('realme')) {
      return 'Settings → Battery → App Battery Management → RXrail → '
          'allow Background running & Auto-launch.';
    }
    if (m.contains('vivo') || m.contains('iqoo')) {
      return 'Settings → Battery → Background power consumption → '
          'allow RXrail. Also enable Auto-start.';
    }
    if (m.contains('oneplus')) {
      return 'Settings → Battery → Battery optimization → RXrail → '
          "Don't optimize. Disable Advanced/Deep optimization for RXrail.";
    }
    return 'Open your phone\'s battery/app-management settings and allow '
        'RXrail to run in the background and auto-start.';
  }
}
