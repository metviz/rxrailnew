import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../shared_preferences/preference_key.dart';
import '../../../shared_preferences/preference_manager.dart';

class DisclaimerController extends GetxController {
  //TODO: Implement DisclaimerController

  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
  final isChecked = false.obs;

  Future<void> acceptTerms() async {
    await PreferencesManager.setBool(PreferenceKey.isDisclaimerAccepted, true);
    Get.offAllNamed(Routes.BOTTOM_NAVIGATIONBAR);
  }
}
