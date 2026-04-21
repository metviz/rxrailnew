import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../modules/news/controllers/news_controller.dart';
import '../../../routes/app_pages.dart';

class BottomNavigationbarController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxString title = 'RXrail'.obs;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final RxString currentState = ''.obs;
  void changePage(int index) {
    currentIndex.value = index;
    title.value = index == 0 ? 'RailRX' : 'Settings';
  }
  @override
  void onInit() {
    super.onInit();
    _getCurrentLocationState(); // auto-fetch when controller initializes
  }
  /// ✅ Fetch current location and get state abbreviation (like "NC")
  Future<void> _getCurrentLocationState() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        currentState.value = 'CA'; // default fallback
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final state = placemarks.first.administrativeArea ?? 'CA';
        currentState.value = state;
        debugPrint('📍 Current State: $state');
      } else {
        currentState.value = 'CA';
      }
    } catch (e) {
      debugPrint('⚠️ Error getting location: $e');
      currentState.value = 'CA';
    }
  }
  /// ✅ Drawer item action for News
  void openNews() {
    // Force-delete cached controller so onInit re-runs with fresh state argument
    Get.delete<NewsController>(force: true);

    void navigate() {
      final s = currentState.value.isEmpty ? 'North Carolina' : currentState.value;
      debugPrint('📰 Opening News for state: "$s"');
      Get.toNamed(Routes.NEWS, arguments: {'state': s});
    }

    if (currentState.value.isEmpty) {
      _getCurrentLocationState().then((_) => navigate());
    } else {
      navigate();
    }
  }
}