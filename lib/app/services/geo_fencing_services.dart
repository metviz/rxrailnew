import 'dart:math';
import 'package:RXrail/app/model/transport_location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

import '../modules/crossing/controllers/crossing_controller.dart';
import '../notification_service.dart';


class GeofencingService extends GetxService {
  // Timer for background tracking
  Timer? _locationTimer;

  // List of locations to monitor
  final RxList<TransportLocation> locationsToMonitor = <TransportLocation>[].obs;

  // Keep track of which locations we've already notified about
  final Set<String> _notifiedLocations = {};

  // Current position
  final Rxn<Position> currentPosition = Rxn<Position>();

  // Status
  final isActive = false.obs;
  final errorMessage = ''.obs;

  // Configuration
  final double _geofenceRadiusKm = 5.0;
  final int _updateIntervalSeconds = 30; // Check every 30 seconds

  @override
  void onInit() {
    super.onInit();
    // Start with any existing locations if provided
    _initBackgroundTracking();
  }

  Future<void> _initBackgroundTracking() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = "Location services are disabled.";
        return;
      }

      // Check for basic location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage.value = "Location permission denied.";
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage.value = "Location permissions are permanently denied, we cannot request permissions.";
        return;
      }

      // Get initial position
      try {
        final position = await Geolocator.getCurrentPosition();
        currentPosition.value = position;
      } catch (e) {
        print("Error getting position: $e");
        errorMessage.value = "Could not get current position: $e";
      }
    } catch (e) {
      print("Error in init background tracking: $e");
      errorMessage.value = "Error initializing tracking: $e";
    }
  }

  Future<bool> requestBackgroundPermission() async {
    bool hasPermission = false;

    // First check if we already have the permission
    if (await Permission.locationAlways.isGranted) {
      return true;
    }

    // Request the permission
    try {
      final status = await Permission.locationAlways.request();
      hasPermission = status.isGranted;

      if (!hasPermission) {
        // Show a dialog explaining why we need background permission
        Get.dialog(
          AlertDialog(
            title: Text('Background Location Required'),
            content: Text(
                'To receive notifications about nearby rail crossings even when the app is not open, ' +
                    'please grant "Allow all the time" location permission in settings.'
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  openAppSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error requesting background permission: $e");
    }

    return hasPermission;
  }

  Future<void> startGeofencing() async {
    if (isActive.value) return; // Already running

    try {
      // Check if we have background permission for proper geofencing
      bool hasBackgroundPermission = false;

      // Only check for background permission on Android
      if (!kIsWeb && GetPlatform.isAndroid) {
        hasBackgroundPermission = await requestBackgroundPermission();
        if (!hasBackgroundPermission) {
          print("Warning: Running without background location permission");
          // We'll continue but notify the user
          NotificationService().showNotifications(
              "Limited Geofencing",
              "For full background alerts, grant 'Allow all the time' permission in settings."
          );
        }
      }

      // Start the location timer regardless - it will work in foreground
      _locationTimer = Timer.periodic(
          Duration(seconds: _updateIntervalSeconds),
              (_) => _checkLocations()
      );
      isActive.value = true;

      // Get initial position and check locations
      try {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
        );
        currentPosition.value = position;
        _checkLocations();
      } catch (e) {
        print("Error getting position: $e");
      }
    } catch (e) {
      print("Error starting geofencing: $e");
      errorMessage.value = "Error starting geofencing: $e";
    }
  }

  void stopGeofencing() {
    try {
      _locationTimer?.cancel();
      _locationTimer = null;
      isActive.value = false;
    } catch (e) {
      print("Error stopping geofencing: $e");
    }
  }

  // Update the list of locations to monitor
  void updateLocations(List<TransportLocation> locations) {
    try {
      locationsToMonitor.assignAll(locations);
      // Clear notifications for locations no longer in the list
      _notifiedLocations.removeWhere((id) =>
      !locationsToMonitor.any((location) => location.crossingid == id));

      if (isActive.value) {
        _checkLocations(); // Check immediately after updating locations
      }
    } catch (e) {
      print("Error updating locations: $e");
    }
  }

  Future<void> _checkLocations() async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      currentPosition.value = position;

      // Check each location
      for (final location in locationsToMonitor) {
        final distance = _calculateDistance(
            position.latitude,
            position.longitude,
            double.parse(location.latitude!),
            double.parse(location.longitude!)
        );

        // If within geofence radius and not yet notified
        if (distance <= _geofenceRadiusKm && !_notifiedLocations.contains(location.crossingid)) {
          // Add to notified set
          _notifiedLocations.add(location.crossingid!);

          // Show notification
          await NotificationService().showNotifications(
            "Rail Crossing Nearby",
            "You are now within ${distance.toStringAsFixed(1)}km of ${location.street}",
          );
        }
        // If user has left the geofence area, remove from notified set to allow re-notification
        else if (distance > _geofenceRadiusKm && _notifiedLocations.contains(location.crossingid)) {
          _notifiedLocations.remove(location.crossingid);
        }
      }
    } catch (e) {
      print("Error checking locations: $e");
      errorMessage.value = "Error checking locations: $e";
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of Earth in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  @override
  void onClose() {
    stopGeofencing();
    super.onClose();
  }
}

// // Move the TransportLocation class here if needed, otherwise import it
// class TransportLocation {
//   final String name;
//   final double latitude;
//   final double longitude;
//   final String crossingId;
//
//   TransportLocation({
//     required this.name,
//     required this.latitude,
//     required this.longitude,
//     required this.crossingId,
//   });
//
//   factory TransportLocation.fromJson(Map<String, dynamic> json) {
//     return TransportLocation(
//       crossingId: json['crossingid'] ?? '',
//       name: json['facilityname'] ?? 'Unknown',
//       latitude: double.tryParse(json['latitude'] ?? '') ?? 0.0,
//       longitude: double.tryParse(json['longitude'] ?? '') ?? 0.0,
//     );
//   }
// }