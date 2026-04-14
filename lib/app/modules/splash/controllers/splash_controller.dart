import 'package:RXrail/app/modules/setting/controllers/setting_controller.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../shared_preferences/preference_key.dart';
import '../../../shared_preferences/preference_manager.dart';
import '../../crossing/controllers/crossing_controller.dart';
import '../../../services/background_location_service.dart';
import 'package:flutter/material.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    print("🔄 SplashController.init() called");

    try {
      // Initialize controllers
      final settingController = Get.put(SettingController(), permanent: true);
      final crossingController = Get.put(CrossingController(), permanent: true);
      Get.put(BackgroundLocationService(), permanent: true);
      settingController.crossingController = crossingController;

      // Read stored flag
      final bool isTermsAccepted = PreferencesManager.getBool(
        PreferenceKey.isDisclaimerAccepted,
        false,
      );

      // Run location setup in background
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await crossingController.initializeLocationServices();
          await crossingController.fetchInitialLocation();
          // Start background proximity alerting after permissions are granted
          final bgService = Get.find<BackgroundLocationService>();
          await bgService.startBackgroundTracking();
        } catch (e) {
          print("⚠️ Location init error: $e");
        }
      });

      // Navigate based on acceptance
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isTermsAccepted) {
          print("➡ Navigating to Disclaimer page");
          Get.offNamed(Routes.DISCLAIMER);
        } else {
          print("✅ Terms already accepted → going to BottomBar");
          Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
        }
      });
    } catch (e, stack) {
      print("❌ Error in SplashController.init(): $e");
      print(stack);
      Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
    }
  }
}
