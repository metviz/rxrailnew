import 'package:RXrail/app/modules/setting/controllers/setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../shared_preferences/preference_key.dart';
import '../../../shared_preferences/preference_manager.dart';
import '../../crossing/controllers/crossing_controller.dart';

// class SplashController extends GetxController {
//   @override
//   void onInit() {
//     super.onInit();
//     init();
//   }
//
//   // Future<void> init() async {
//   //   print("🔄 SplashController.init() called");
//   //
//   //   try {
//   //     print("🛠 Initializing Setting and Crossing controllers...");
//   //     final settingController = Get.put(SettingController(), permanent: true);
//   //     final crossingController = Get.put(CrossingController(), permanent: true);
//   //
//   //     try {
//   //       settingController.crossingController = crossingController;
//   //       print("📍 [1] Calling initializeLocationServices...");
//   //       await crossingController.initializeLocationServices();
//   //       print("✅ [1] initializeLocationServices completed");
//   //     } catch (e) {
//   //       print("❌ [1] Error in initializeLocationServices: $e");
//   //     }
//   //
//   //     try {
//   //       print("📍 [2] Calling fetchInitialLocation...");
//   //       await crossingController.fetchInitialLocation();
//   //       print("✅ [2] fetchInitialLocation completed");
//   //     } catch (e) {
//   //       print("❌ [2] Error in fetchInitialLocation: $e");
//   //     }
//   //
//   //     print("⏳ Waiting 2 seconds...");
//   //     await Future.delayed(Duration(seconds: 2));
//   //
//   //     print("🔍 Checking if user is registered...");
//   //     final bool isRegistered = PreferencesManager.getBool(
//   //       PreferenceKey.isRegister,
//   //       false,
//   //     );
//   //
//   //     print("✅ isRegistered: $isRegistered");
//   //
//   //     if (isRegistered) {
//   //       print("➡ Navigating to BottomNavigationBar");
//   //       Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
//   //     } else {
//   //       print("➡ Navigating to RegisterView");
//   //       // Get.offNamed(Routes.REGISTER);
//   //       Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
//   //     }
//   //   } catch (e, stack) {
//   //     print("❌ General error in SplashController.init(): $e");
//   //     print("🔍 Stack trace: $stack");
//   //
//   //     final bool isRegistered = PreferencesManager.getBool(
//   //       PreferenceKey.isRegister,
//   //       false,
//   //     );
//   //
//   //     if (isRegistered) {
//   //       Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
//   //     } else {
//   //       // Get.offNamed(Routes.REGISTER);
//   //       Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
//   //     }
//   //   }
//   // }
//   Future<void> init() async {
//     print("🔄 SplashController.init() called");
//
//     try {
//       print("🛠 Initializing Setting and Crossing controllers...");
//       final settingController = Get.put(SettingController(), permanent: true);
//       final crossingController = Get.put(CrossingController(), permanent: true);
//
//       // 🔁 Link controllers
//       settingController.crossingController = crossingController;
//
//       // ✅ Navigate immediately (non-blocking)
//       final bool isRegistered = PreferencesManager.getBool(
//         PreferenceKey.isRegister,
//         false,
//       );
//
//       Future.delayed(Duration(seconds: 1), () async {
//         try {
//           await crossingController.initializeLocationServices();
//           await crossingController.fetchInitialLocation();
//         } catch (e) {
//           print("⚠️ Location init error: $e");
//         }
//       });
//
//       // 🟢 Continue to main screen instantly
//       Get.offNamed(isRegistered
//           ? Routes.BOTTOM_NAVIGATIONBAR
//           : Routes.REGISTER);
//
//     } catch (e, stack) {
//       print("❌ General error in SplashController.init(): $e");
//       print("🔍 Stack trace: $stack");
//       Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
//     }
//   }
// }
class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    print("🔄 SplashController.init() called");

    try {
      print("🛠 Initializing Setting and Crossing controllers...");
      final settingController = Get.put(SettingController(), permanent: true);
      final crossingController = Get.put(CrossingController(), permanent: true);

      // 🔁 Link controllers
      settingController.crossingController = crossingController;

      final bool isRegistered = PreferencesManager.getBool(
        PreferenceKey.isRegister,
        false,
      );

      // 🔄 Run location setup in background
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await crossingController.initializeLocationServices();
          await crossingController.fetchInitialLocation();
        } catch (e) {
          print("⚠️ Location init error: $e");
        }
      });

      // ✅ Safe navigation (after frame rendered)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("➡ Navigating after frame render...");
        Get.offNamed(
           Routes.BOTTOM_NAVIGATIONBAR
        );
      });

    } catch (e, stack) {
      print("❌ General error in SplashController.init(): $e");
      print("🔍 Stack trace: $stack");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(Routes.BOTTOM_NAVIGATIONBAR);
      });
    }
  }
}
