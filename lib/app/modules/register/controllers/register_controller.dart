import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../shared_preferences/preference_key.dart';
import '../../../shared_preferences/preference_manager.dart';

class RegisterController extends GetxController  with GetTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final dobController = TextEditingController();

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  final selectedGender = 'Select Gender'.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
    ));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    animationController.forward();
  }

  @override
  void onClose() {
    animationController.dispose();
    emailController.dispose();
    nameController.dispose();
    dobController.dispose();
    super.onClose();
  }

  void selectGender(String? gender) {
    if (gender != null) {
      selectedGender.value = gender;
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dobController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> handleRegister() async {
    // if (formKey.currentState!.validate()) {
    //   isLoading.value = true;
    //
    //   // Add haptic feedback for better user experience
    //   HapticFeedback.lightImpact();
    //
    //   // Simulate registration process
    //   await Future.delayed(const Duration(seconds: 2));
    //
    //   isLoading.value = false;
    //
    //   // Show success message
    //   Get.snackbar(
    //     'Success',
    //     'Account created successfully!',
    //     backgroundColor: Colors.green[500],
    //     colorText: Colors.white,
    //     snackPosition: SnackPosition.BOTTOM,
    //     borderRadius: 12,
    //     margin: const EdgeInsets.all(16),
    //   );
    // }


    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      try {
        // Your registration logic here...

        // After successful registration, set the preference
        await PreferencesManager.setBool(PreferenceKey.isRegister, true);

        // Navigate to next screen or show success message
        Get.toNamed(Routes.BOTTOM_NAVIGATIONBAR);// Example navigation
      } catch (e) {
        Get.snackbar('Error', 'Registration failed: ${e.toString()}');
      } finally {
        isLoading.value = false;
      }
    }
  }

  void handleSocialLogin(String provider) {
    Get.snackbar(
      'Info',
      'Continue with $provider clicked',
      backgroundColor: Colors.blue[500],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }
}
