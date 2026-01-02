import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../crossing/controllers/crossing_controller.dart';

class SettingController extends GetxController {
  late CrossingController crossingController;
  final runInBackground = false.obs;
  // Warnings Section
  final RxBool isWarningsEnabled = true.obs;
  final RxDouble warningDistance = 200.0.obs; // in meters

  // Warning Method Section
  final RxBool isWarningSoundEnabled = true.obs;
  final RxBool isVibrationEnabled = true.obs;

  // Location Section
  final RxBool isLocationPermissionGranted = false.obs;
  final RxBool isLocationPermissionLoading = false.obs;

  // Distance Unit
  final RxString distanceUnit = 'miles'.obs;

  @override
  void onInit() async {
    super.onInit();
    await _loadPreferences();
    _checkLocationPermissionStatus();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    isWarningsEnabled.value = prefs.getBool('isWarningsEnabled') ?? true;
    warningDistance.value = prefs.getDouble('warningDistance') ?? 200.0;
    isWarningSoundEnabled.value = prefs.getBool('isWarningSoundEnabled') ?? true;
    isVibrationEnabled.value = prefs.getBool('isVibrationEnabled') ?? true;
    distanceUnit.value = prefs.getString('distanceUnit') ?? 'miles';
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWarningsEnabled', isWarningsEnabled.value);
    await prefs.setDouble('warningDistance', warningDistance.value);
    await prefs.setBool('isWarningSoundEnabled', isWarningSoundEnabled.value);
    await prefs.setBool('isVibrationEnabled', isVibrationEnabled.value);
    await prefs.setString('distanceUnit', distanceUnit.value);
  }

  Future<void> _checkLocationPermissionStatus() async {
    final status = await Geolocator.checkPermission();
    isLocationPermissionGranted.value = status == LocationPermission.always;
  }

  Future<void> requestLocationPermission() async {
    isLocationPermissionLoading.value = true;

    try {
      var status = await Geolocator.checkPermission();

      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }

      if (status == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Required',
          'Location permission is permanently denied. Please enable it in app settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLocationPermissionGranted.value = false;
        return;
      }

      if (status == LocationPermission.whileInUse) {
        // Show dialog to explain why background permission is needed
        await Get.defaultDialog(
          title: 'Background Permission Needed',
          middleText: "To keep the app working properly, please allow background location access. Tap 'Allow all the time' when asked, or enable it in your device settings",
          textConfirm: 'Open Settings',
          textCancel: 'Cancel',
          confirmTextColor: Colors.white,
          onConfirm: () async {
            Get.back(); // close dialog
            await Geolocator.openAppSettings();
          },
        );

        status = await Geolocator.checkPermission(); // Check again after returning
      }

      isLocationPermissionGranted.value = status == LocationPermission.always;

      if (isLocationPermissionGranted.value) {
        Get.snackbar(
          'Success',
          'Location permission granted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to request location permission: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLocationPermissionLoading.value = false;
      await _savePreferences();
    }
  }


  void toggleWarnings(bool value) {
    isWarningsEnabled.value = value;
    if (!value) {
      isWarningSoundEnabled.value = false;
      isVibrationEnabled.value = false;
    }
    _savePreferences();
  }

  void updateWarningDistance(double value) {
    warningDistance.value = value;
    _savePreferences();
  }

  void toggleWarningSound(bool value) {
    isWarningSoundEnabled.value = value;
    _savePreferences();
  }

  void toggleVibration(bool value) {
    isVibrationEnabled.value = value;
    _savePreferences();
  }

  void updateDistanceUnit(String value) {
    distanceUnit.value = value;
    _savePreferences();
  }
}