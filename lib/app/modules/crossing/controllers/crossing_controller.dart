import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:RXrail/app/model/transport_location.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding/geocoding.dart' as place_mark;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../../../background_service.dart';
import '../../../notification_service.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/app_color.dart';
import '../../../utils/text_style.dart';
import '../../setting/controllers/setting_controller.dart';
import 'dart:developer' as log_print;

// Add this TOP-LEVEL function outside any class (usually in main.dart or a separate file)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    switch (task) {
      case 'checkNearbyCrossings'://9257036604
        return _performBackgroundLocationCheck(inputData);
      case 'locationUpdate':
        return _handleLocationUpdate(inputData);
      default:
        return Future.value(true);
    }
  });
}

// Background task handlers (also top-level functions)
@pragma('vm:entry-point')
Future<bool> _performBackgroundLocationCheck(
  Map<String, dynamic>? inputData,
) async {
  try {
    log_print.log('Background location check executed');
    return Future.value(true);
  } catch (e) {
    log_print.log('Background task error: $e');
    return Future.value(false);
  }
}

@pragma('vm:entry-point')
Future<bool> _handleLocationUpdate(Map<String, dynamic>? inputData) async {
  try {
    // Handle location update logic
    log_print.log('Location update task executed');
    return Future.value(true);
  } catch (e) {
    log_print.log('Location update error: $e');
    return Future.value(false);
  }
}

class CrossingController extends GetxController with WidgetsBindingObserver {
  final BackgroundService _backgroundService = BackgroundService();
  final SettingController settingController = Get.find<SettingController>();
  final player = AudioPlayer();

  // Location tracking
  final Rx<Position?> userPosition = Rxn<Position>();
  final RxDouble userBearing = 0.0.obs;
  StreamSubscription<Position>? _positionStream;
  final RxBool isTrackingLocation = false.obs;

  // Route navigation
  final Rx<LatLng?> fromLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> toLocation = Rx<LatLng?>(null);
  final RxList<LatLng> routeCoordinates = <LatLng>[].obs;
  final RxDouble routeDistance = 0.0.obs;
  final RxDouble routeDuration = 0.0.obs;
  final RxInt currentRouteStep = 0.obs;
  final RxBool isNavigating = false.obs;
  final RxBool isRerouting = false.obs;
  final RxString destinationAddress = ''.obs;

  // Crossings data
  final RxList<TransportLocation> nearbyLocations = <TransportLocation>[].obs;
  final RxList<TransportLocation> crossingsAlongRoute =
      <TransportLocation>[].obs;
  final RxList<TransportLocation> upcomingCrossings = <TransportLocation>[].obs;
  final Rx<TransportLocation?> nearestCrossing = Rx<TransportLocation?>(null);
  final RxDouble distanceToNearestCrossing = 0.0.obs;
  final RxBool showNearestCrossingSheet = true.obs;

  // UI state
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble currentZoom = 15.0.obs;
  final Rx<TransportLocation?> selectedCrossing = Rx<TransportLocation?>(null);
  final RxBool showInfoWindow = false.obs;
  final mapController = MapController();
  final RxString distanceUnit = 'kilometers'.obs;

  // // Notification thresholds (in meters)
  // final double _warningDistance = 500;
  // final double _alertDistance = 200;
  // final double _immediateDistance = 50;

  // Timer for periodic checks
  Timer? _navigationTimer;
  Timer? _backgroundTimer;
  Timer? _rerouteTimer;
  bool hasNotifiedApproaching = false;
  final RxBool isRouteReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    initializeOnPageOpen();
  }


  // Future<void> downloadOfflineMap({required double radiusMiles}) async {
  //   if (userPosition.value == null) {
  //     Get.snackbar("Error", "User location not available");
  //     return;
  //   }
  //
  //   final pos = userPosition.value!;
  //   final radiusKm = radiusMiles * 1.60934;
  //
  //   final lat = pos.latitude;
  //   final lng = pos.longitude;
  //
  //   // approximate lat/lng deltas for a bounding box
  //   final latDelta = radiusKm / 111.32;
  //   final lngDelta = radiusKm / (111.32 * math.cos(lat * math.pi / 180));
  //
  //   final minLat = lat - latDelta;
  //   final maxLat = lat + latDelta;
  //   final minLng = lng - lngDelta;
  //   final maxLng = lng + lngDelta;
  //
  //   final bounds = LatLngBounds(
  //     LatLng(minLat, minLng),
  //     LatLng(maxLat, maxLng),
  //   );
  //
  //   try {
  //     // Initialize store
  //     final store = FMTCStore('offline_tiles');
  //     await store.manage.create();
  //
  //     // Create rectangle region
  //     final region = RectangleRegion(bounds);
  //
  //     final downloadable = region.toDownloadable(
  //       minZoom: 9,
  //       maxZoom: 14,
  //       options: TileLayer(
  //         urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  //         subdomains: [],
  //         userAgentPackageName: 'com.example.cross_aware', // your app id
  //       ),
  //     );
  //
  //     // Start download
  //     final progressStream = store.download.startForeground(
  //       region: downloadable,
  //       parallelThreads: 5,
  //       skipExistingTiles: true,
  //       skipSeaTiles: true,
  //     );
  //
  //     progressStream.listen((DownloadProgress prog) {
  //       final percent = prog.percentageProgress; // 0..100
  //       Get.snackbar(
  //         "Downloading tiles",
  //         "${percent.toStringAsFixed(1)}% — ${prog.successfulTiles}/${prog.maxTiles} downloaded\nRemaining: ${prog.remainingTiles}",
  //         snackPosition: SnackPosition.BOTTOM,
  //         duration: const Duration(seconds: 2),
  //       );
  //     }, onError: (e) {
  //       Get.snackbar(
  //         "Download Error",
  //         e.toString(),
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //       );
  //     }, onDone: () {
  //       Get.snackbar(
  //         "Download Complete",
  //         "Offline tiles ready",
  //         backgroundColor: Colors.green,
  //         colorText: Colors.white,
  //       );
  //     });
  //   } catch (e) {
  //     Get.snackbar(
  //       "Error",
  //       e.toString(),
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   }
  // }
  Future<String?> getCurrentStateCode() async {
    if (userPosition.value == null) return null;

    final lat = userPosition.value!.latitude;
    final lng = userPosition.value!.longitude;

    final Map<String, LatLngBounds> stateBounds = {
      'AL': LatLngBounds(LatLng(30.2, -88.5), LatLng(35.0, -84.9)),
      'AK': LatLngBounds(LatLng(51.2, -179.1), LatLng(71.5, -129.9)),
      'AZ': LatLngBounds(LatLng(31.3, -114.8), LatLng(37.0, -109.0)),
      'AR': LatLngBounds(LatLng(33.0, -94.6), LatLng(36.5, -89.6)),
      'CA': LatLngBounds(LatLng(32.5, -124.4), LatLng(42.0, -114.1)),
      'CO': LatLngBounds(LatLng(36.9, -109.1), LatLng(41.0, -102.0)),
      'CT': LatLngBounds(LatLng(40.9, -73.7), LatLng(42.1, -71.8)),
      'DE': LatLngBounds(LatLng(38.4, -75.8), LatLng(39.8, -75.0)),
      'FL': LatLngBounds(LatLng(24.3, -87.7), LatLng(31.1, -79.8)),
      'GA': LatLngBounds(LatLng(30.3, -85.6), LatLng(35.0, -80.8)),
      'HI': LatLngBounds(LatLng(18.9, -160.3), LatLng(22.4, -154.8)),
      'ID': LatLngBounds(LatLng(42.0, -117.3), LatLng(49.0, -111.0)),
      'IL': LatLngBounds(LatLng(36.9, -91.5), LatLng(42.5, -87.0)),
      'IN': LatLngBounds(LatLng(37.8, -88.1), LatLng(41.8, -84.7)),
      'IA': LatLngBounds(LatLng(40.3, -96.6), LatLng(43.5, -90.1)),
      'KS': LatLngBounds(LatLng(36.9, -102.1), LatLng(40.0, -94.6)),
      'KY': LatLngBounds(LatLng(36.5, -89.6), LatLng(39.1, -81.9)),
      'LA': LatLngBounds(LatLng(28.9, -94.0), LatLng(33.0, -88.8)),
      'ME': LatLngBounds(LatLng(43.0, -71.1), LatLng(47.5, -66.8)),
      'MD': LatLngBounds(LatLng(37.9, -79.5), LatLng(39.8, -75.0)),
      'MA': LatLngBounds(LatLng(41.18, -73.5), LatLng(42.88, -69.9)),
      'MI': LatLngBounds(LatLng(41.7, -90.4), LatLng(48.3, -82.4)),
      'MN': LatLngBounds(LatLng(43.5, -97.3), LatLng(49.3, -89.5)),
      'MS': LatLngBounds(LatLng(30.2, -91.6), LatLng(35.0, -88.1)),
      'MO': LatLngBounds(LatLng(36.0, -95.8), LatLng(40.6, -89.1)),
      'MT': LatLngBounds(LatLng(44.4, -116.1), LatLng(49.0, -104.0)),
      'NE': LatLngBounds(LatLng(40.0, -104.1), LatLng(43.0, -95.3)),
      'NV': LatLngBounds(LatLng(35.0, -120.0), LatLng(42.0, -114.0)),
      'NH': LatLngBounds(LatLng(42.7, -72.6), LatLng(45.3, -70.6)),
      'NJ': LatLngBounds(LatLng(38.9, -75.6), LatLng(41.4, -73.9)),
      'NM': LatLngBounds(LatLng(31.3, -109.1), LatLng(37.0, -103.0)),
      'NY': LatLngBounds(LatLng(40.4, -79.8), LatLng(45.0, -71.8)),
      'NC': LatLngBounds(LatLng(33.8, -84.3), LatLng(36.6, -75.4)),
      'ND': LatLngBounds(LatLng(45.9, -104.1), LatLng(49.0, -96.5)),
      'OH': LatLngBounds(LatLng(38.2, -84.8), LatLng(41.98, -80.5)),
      'OK': LatLngBounds(LatLng(33.6, -103.0), LatLng(37.0, -94.4)),
      'OR': LatLngBounds(LatLng(41.9, -124.6), LatLng(46.3, -116.5)),
      'PA': LatLngBounds(LatLng(39.7, -80.6), LatLng(42.5, -74.6)),
      'RI': LatLngBounds(LatLng(41.1, -71.9), LatLng(42.0, -71.1)),
      'SC': LatLngBounds(LatLng(32.0, -83.4), LatLng(35.2, -78.5)),
      'SD': LatLngBounds(LatLng(42.5, -104.1), LatLng(45.9, -96.4)),
      'TN': LatLngBounds(LatLng(35.0, -90.3), LatLng(36.7, -81.6)),
      'TX': LatLngBounds(LatLng(25.8, -106.6), LatLng(36.5, -93.5)),
      'UT': LatLngBounds(LatLng(37.0, -114.1), LatLng(42.0, -109.0)),
      'VT': LatLngBounds(LatLng(42.7, -73.4), LatLng(45.0, -71.5)),
      'VA': LatLngBounds(LatLng(36.5, -83.7), LatLng(39.5, -75.2)),
      'WA': LatLngBounds(LatLng(45.5, -124.8), LatLng(49.0, -116.9)),
      'WV': LatLngBounds(LatLng(37.2, -82.6), LatLng(40.6, -77.7)),
      'WI': LatLngBounds(LatLng(42.4, -92.9), LatLng(47.3, -86.8)),
      'WY': LatLngBounds(LatLng(41.0, -111.1), LatLng(45.0, -104.0)),
      'DC': LatLngBounds(LatLng(38.79, -77.12), LatLng(38.995, -76.91)),
    };

    for (final entry in stateBounds.entries) {
      final bounds = entry.value;
      if (lat >= bounds.southWest.latitude &&
          lat <= bounds.northEast.latitude &&
          lng >= bounds.southWest.longitude &&
          lng <= bounds.northEast.longitude) {
        return entry.key;
      }
    }
    return null;
  }
  Future<void> downloadOfflineMapByCurrentState() async {
    if (userPosition.value == null) {
      Get.snackbar(
        "Error",
        "User location not available.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final lat = userPosition.value!.latitude;
    final lng = userPosition.value!.longitude;

    final Map<String, LatLngBounds> stateBounds = {
      'AL': LatLngBounds(LatLng(30.2, -88.5), LatLng(35.0, -84.9)),
      'AK': LatLngBounds(LatLng(51.2, -179.1), LatLng(71.5, -129.9)),
      'AZ': LatLngBounds(LatLng(31.3, -114.8), LatLng(37.0, -109.0)),
      'AR': LatLngBounds(LatLng(33.0, -94.6), LatLng(36.5, -89.6)),
      'CA': LatLngBounds(LatLng(32.5, -124.4), LatLng(42.0, -114.1)),
      'CO': LatLngBounds(LatLng(36.9, -109.1), LatLng(41.0, -102.0)),
      'CT': LatLngBounds(LatLng(40.9, -73.7), LatLng(42.1, -71.8)),
      'DE': LatLngBounds(LatLng(38.4, -75.8), LatLng(39.8, -75.0)),
      'FL': LatLngBounds(LatLng(24.3, -87.7), LatLng(31.1, -79.8)),
      'GA': LatLngBounds(LatLng(30.3, -85.6), LatLng(35.0, -80.8)),
      'HI': LatLngBounds(LatLng(18.9, -160.3), LatLng(22.4, -154.8)),
      'ID': LatLngBounds(LatLng(42.0, -117.3), LatLng(49.0, -111.0)),
      'IL': LatLngBounds(LatLng(36.9, -91.5), LatLng(42.5, -87.0)),
      'IN': LatLngBounds(LatLng(37.8, -88.1), LatLng(41.8, -84.7)),
      'IA': LatLngBounds(LatLng(40.3, -96.6), LatLng(43.5, -90.1)),
      'KS': LatLngBounds(LatLng(36.9, -102.1), LatLng(40.0, -94.6)),
      'KY': LatLngBounds(LatLng(36.5, -89.6), LatLng(39.1, -81.9)),
      'LA': LatLngBounds(LatLng(28.9, -94.0), LatLng(33.0, -88.8)),
      'ME': LatLngBounds(LatLng(43.0, -71.1), LatLng(47.5, -66.8)),
      'MD': LatLngBounds(LatLng(37.9, -79.5), LatLng(39.8, -75.0)),
      'MA': LatLngBounds(LatLng(41.18, -73.5), LatLng(42.88, -69.9)),
      'MI': LatLngBounds(LatLng(41.7, -90.4), LatLng(48.3, -82.4)),
      'MN': LatLngBounds(LatLng(43.5, -97.3), LatLng(49.3, -89.5)),
      'MS': LatLngBounds(LatLng(30.2, -91.6), LatLng(35.0, -88.1)),
      'MO': LatLngBounds(LatLng(36.0, -95.8), LatLng(40.6, -89.1)),
      'MT': LatLngBounds(LatLng(44.4, -116.1), LatLng(49.0, -104.0)),
      'NE': LatLngBounds(LatLng(40.0, -104.1), LatLng(43.0, -95.3)),
      'NV': LatLngBounds(LatLng(35.0, -120.0), LatLng(42.0, -114.0)),
      'NH': LatLngBounds(LatLng(42.7, -72.6), LatLng(45.3, -70.6)),
      'NJ': LatLngBounds(LatLng(38.9, -75.6), LatLng(41.4, -73.9)),
      'NM': LatLngBounds(LatLng(31.3, -109.1), LatLng(37.0, -103.0)),
      'NY': LatLngBounds(LatLng(40.4, -79.8), LatLng(45.0, -71.8)),
      'NC': LatLngBounds(LatLng(33.8, -84.3), LatLng(36.6, -75.4)),
      'ND': LatLngBounds(LatLng(45.9, -104.1), LatLng(49.0, -96.5)),
      'OH': LatLngBounds(LatLng(38.2, -84.8), LatLng(41.98, -80.5)),
      'OK': LatLngBounds(LatLng(33.6, -103.0), LatLng(37.0, -94.4)),
      'OR': LatLngBounds(LatLng(41.9, -124.6), LatLng(46.3, -116.5)),
      'PA': LatLngBounds(LatLng(39.7, -80.6), LatLng(42.5, -74.6)),
      'RI': LatLngBounds(LatLng(41.1, -71.9), LatLng(42.0, -71.1)),
      'SC': LatLngBounds(LatLng(32.0, -83.4), LatLng(35.2, -78.5)),
      'SD': LatLngBounds(LatLng(42.5, -104.1), LatLng(45.9, -96.4)),
      'TN': LatLngBounds(LatLng(35.0, -90.3), LatLng(36.7, -81.6)),
      'TX': LatLngBounds(LatLng(25.8, -106.6), LatLng(36.5, -93.5)),
      'UT': LatLngBounds(LatLng(37.0, -114.1), LatLng(42.0, -109.0)),
      'VT': LatLngBounds(LatLng(42.7, -73.4), LatLng(45.0, -71.5)),
      'VA': LatLngBounds(LatLng(36.5, -83.7), LatLng(39.5, -75.2)),
      'WA': LatLngBounds(LatLng(45.5, -124.8), LatLng(49.0, -116.9)),
      'WV': LatLngBounds(LatLng(37.2, -82.6), LatLng(40.6, -77.7)),
      'WI': LatLngBounds(LatLng(42.4, -92.9), LatLng(47.3, -86.8)),
      'WY': LatLngBounds(LatLng(41.0, -111.1), LatLng(45.0, -104.0)),
      'DC': LatLngBounds(LatLng(38.79, -77.12), LatLng(38.995, -76.91)),
    };

    // 🧭 Step 2: Find which state user is in
    String? currentStateCode;
    for (final entry in stateBounds.entries) {
      final bounds = entry.value;
      if (lat >= bounds.southWest.latitude &&
          lat <= bounds.northEast.latitude &&
          lng >= bounds.southWest.longitude &&
          lng <= bounds.northEast.longitude) {
        currentStateCode = entry.key;
        break;
      }
    }

    if (currentStateCode == null) {
      Get.snackbar(
        "Error",
        "Could not determine your U.S. state.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 🗺️ Step 3: Download tiles for detected state
    await downloadOfflineMapForState(currentStateCode);
  }
  // Future<void> downloadOfflineMapForState(String stateCode) async {
  //   final Map<String, LatLngBounds> stateBounds = {
  //     'AL': LatLngBounds(LatLng(30.2, -88.5), LatLng(35.0, -84.9)),
  //     'AK': LatLngBounds(LatLng(51.2, -179.1), LatLng(71.5, -129.9)),
  //     'AZ': LatLngBounds(LatLng(31.3, -114.8), LatLng(37.0, -109.0)),
  //     'AR': LatLngBounds(LatLng(33.0, -94.6), LatLng(36.5, -89.6)),
  //     'CA': LatLngBounds(LatLng(32.5, -124.4), LatLng(42.0, -114.1)),
  //     'CO': LatLngBounds(LatLng(36.9, -109.1), LatLng(41.0, -102.0)),
  //     'CT': LatLngBounds(LatLng(40.9, -73.7), LatLng(42.1, -71.8)),
  //     'DE': LatLngBounds(LatLng(38.4, -75.8), LatLng(39.8, -75.0)),
  //     'FL': LatLngBounds(LatLng(24.3, -87.7), LatLng(31.1, -79.8)),
  //     'GA': LatLngBounds(LatLng(30.3, -85.6), LatLng(35.0, -80.8)),
  //     'HI': LatLngBounds(LatLng(18.9, -160.3), LatLng(22.4, -154.8)),
  //     'ID': LatLngBounds(LatLng(42.0, -117.3), LatLng(49.0, -111.0)),
  //     'IL': LatLngBounds(LatLng(36.9, -91.5), LatLng(42.5, -87.0)),
  //     'IN': LatLngBounds(LatLng(37.8, -88.1), LatLng(41.8, -84.7)),
  //     'IA': LatLngBounds(LatLng(40.3, -96.6), LatLng(43.5, -90.1)),
  //     'KS': LatLngBounds(LatLng(36.9, -102.1), LatLng(40.0, -94.6)),
  //     'KY': LatLngBounds(LatLng(36.5, -89.6), LatLng(39.1, -81.9)),
  //     'LA': LatLngBounds(LatLng(28.9, -94.0), LatLng(33.0, -88.8)),
  //     'ME': LatLngBounds(LatLng(43.0, -71.1), LatLng(47.5, -66.8)),
  //     'MD': LatLngBounds(LatLng(37.9, -79.5), LatLng(39.8, -75.0)),
  //     'MA': LatLngBounds(LatLng(41.18, -73.5), LatLng(42.88, -69.9)),
  //     'MI': LatLngBounds(LatLng(41.7, -90.4), LatLng(48.3, -82.4)),
  //     'MN': LatLngBounds(LatLng(43.5, -97.3), LatLng(49.3, -89.5)),
  //     'MS': LatLngBounds(LatLng(30.2, -91.6), LatLng(35.0, -88.1)),
  //     'MO': LatLngBounds(LatLng(36.0, -95.8), LatLng(40.6, -89.1)),
  //     'MT': LatLngBounds(LatLng(44.4, -116.1), LatLng(49.0, -104.0)),
  //     'NE': LatLngBounds(LatLng(40.0, -104.1), LatLng(43.0, -95.3)),
  //     'NV': LatLngBounds(LatLng(35.0, -120.0), LatLng(42.0, -114.0)),
  //     'NH': LatLngBounds(LatLng(42.7, -72.6), LatLng(45.3, -70.6)),
  //     'NJ': LatLngBounds(LatLng(38.9, -75.6), LatLng(41.4, -73.9)),
  //     'NM': LatLngBounds(LatLng(31.3, -109.1), LatLng(37.0, -103.0)),
  //     'NY': LatLngBounds(LatLng(40.4, -79.8), LatLng(45.0, -71.8)),
  //     'NC': LatLngBounds(LatLng(33.8, -84.3), LatLng(36.6, -75.4)),
  //     'ND': LatLngBounds(LatLng(45.9, -104.1), LatLng(49.0, -96.5)),
  //     'OH': LatLngBounds(LatLng(38.2, -84.8), LatLng(41.98, -80.5)),
  //     'OK': LatLngBounds(LatLng(33.6, -103.0), LatLng(37.0, -94.4)),
  //     'OR': LatLngBounds(LatLng(41.9, -124.6), LatLng(46.3, -116.5)),
  //     'PA': LatLngBounds(LatLng(39.7, -80.6), LatLng(42.5, -74.6)),
  //     'RI': LatLngBounds(LatLng(41.1, -71.9), LatLng(42.0, -71.1)),
  //     'SC': LatLngBounds(LatLng(32.0, -83.4), LatLng(35.2, -78.5)),
  //     'SD': LatLngBounds(LatLng(42.5, -104.1), LatLng(45.9, -96.4)),
  //     'TN': LatLngBounds(LatLng(35.0, -90.3), LatLng(36.7, -81.6)),
  //     'TX': LatLngBounds(LatLng(25.8, -106.6), LatLng(36.5, -93.5)),
  //     'UT': LatLngBounds(LatLng(37.0, -114.1), LatLng(42.0, -109.0)),
  //     'VT': LatLngBounds(LatLng(42.7, -73.4), LatLng(45.0, -71.5)),
  //     'VA': LatLngBounds(LatLng(36.5, -83.7), LatLng(39.5, -75.2)),
  //     'WA': LatLngBounds(LatLng(45.5, -124.8), LatLng(49.0, -116.9)),
  //     'WV': LatLngBounds(LatLng(37.2, -82.6), LatLng(40.6, -77.7)),
  //     'WI': LatLngBounds(LatLng(42.4, -92.9), LatLng(47.3, -86.8)),
  //     'WY': LatLngBounds(LatLng(41.0, -111.1), LatLng(45.0, -104.0)),
  //     'DC': LatLngBounds(LatLng(38.79, -77.12), LatLng(38.995, -76.91)),
  //   };
  //
  //   final bounds = stateBounds[stateCode]!;
  //   // await FMTC.initialise();
  //   // await FMTCObjectBoxBackend().initialise();
  //
  //   final store = FMTCStore('offline_tiles_$stateCode');
  //   final exists = await store.manage.ready;
  //   if (exists) {
  //     final stats = await store.stats.all;
  //     if (stats.length > 0) {
  //       Get.snackbar(
  //         "Map Already Downloaded",
  //         "$stateCode offline map already exists with ${stats.length} tiles (${stats.size.toStringAsFixed(2)} MB)",
  //         backgroundColor: Colors.blue,
  //         colorText: Colors.white,
  //       );
  //       return; // Exit if you don't want to re-download
  //     }
  //   }
  //
  //   // Create store if it doesn't exist
  //   if (!exists) {
  //     await store.manage.create();
  //   }
  //
  //   final region = RectangleRegion(bounds);
  //   final downloadable = region.toDownloadable(
  //     minZoom: 9,
  //     maxZoom: 14,
  //     options: TileLayer(
  //       urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  //       userAgentPackageName: 'com.example.cross_aware',
  //     ),
  //   );
  //
  //   final progressStream = store.download.startForeground(
  //     region: downloadable,
  //     parallelThreads: 5,
  //     skipExistingTiles: true,
  //   );
  //
  //   progressStream.listen(
  //         (DownloadProgress prog) {
  //       final percent = prog.percentageProgress;
  //       if (percent.isFinite) {
  //         Get.snackbar(
  //           "Downloading $stateCode Map",
  //           "${percent.toStringAsFixed(1)}% — ${prog.successfulTiles}/${prog.maxTiles} downloaded\nRemaining: ${prog.remainingTiles}",
  //           snackPosition: SnackPosition.BOTTOM,
  //           duration: const Duration(seconds: 2),
  //         );
  //       }
  //     },
  //     onError: (e) {
  //       Get.snackbar(
  //         "Download Error",
  //         e.toString(),
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //       );
  //     },
  //     onDone: () {
  //       Get.snackbar(
  //         "Download Complete",
  //         "$stateCode offline map ready!",
  //         backgroundColor: Colors.green,
  //         colorText: Colors.white,
  //       );
  //     },
  //   );
  // }
  // ✅ COMPLETELY REWRITTEN download method
  Future<void> downloadOfflineMapForState(String stateCode) async {
    if (isDownloadingOfflineMap.value) {
      Get.snackbar(
        "Download in Progress",
        "Please wait for the current download to complete",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final Map<String, LatLngBounds> stateBounds = {
      'AL': LatLngBounds(LatLng(30.2, -88.5), LatLng(35.0, -84.9)),
      'AK': LatLngBounds(LatLng(51.2, -179.1), LatLng(71.5, -129.9)),
      'AZ': LatLngBounds(LatLng(31.3, -114.8), LatLng(37.0, -109.0)),
      'AR': LatLngBounds(LatLng(33.0, -94.6), LatLng(36.5, -89.6)),
      'CA': LatLngBounds(LatLng(32.5, -124.4), LatLng(42.0, -114.1)),
      'CO': LatLngBounds(LatLng(36.9, -109.1), LatLng(41.0, -102.0)),
      'CT': LatLngBounds(LatLng(40.9, -73.7), LatLng(42.1, -71.8)),
      'DE': LatLngBounds(LatLng(38.4, -75.8), LatLng(39.8, -75.0)),
      'FL': LatLngBounds(LatLng(24.3, -87.7), LatLng(31.1, -79.8)),
      'GA': LatLngBounds(LatLng(30.3, -85.6), LatLng(35.0, -80.8)),
      'HI': LatLngBounds(LatLng(18.9, -160.3), LatLng(22.4, -154.8)),
      'ID': LatLngBounds(LatLng(42.0, -117.3), LatLng(49.0, -111.0)),
      'IL': LatLngBounds(LatLng(36.9, -91.5), LatLng(42.5, -87.0)),
      'IN': LatLngBounds(LatLng(37.8, -88.1), LatLng(41.8, -84.7)),
      'IA': LatLngBounds(LatLng(40.3, -96.6), LatLng(43.5, -90.1)),
      'KS': LatLngBounds(LatLng(36.9, -102.1), LatLng(40.0, -94.6)),
      'KY': LatLngBounds(LatLng(36.5, -89.6), LatLng(39.1, -81.9)),
      'LA': LatLngBounds(LatLng(28.9, -94.0), LatLng(33.0, -88.8)),
      'ME': LatLngBounds(LatLng(43.0, -71.1), LatLng(47.5, -66.8)),
      'MD': LatLngBounds(LatLng(37.9, -79.5), LatLng(39.8, -75.0)),
      'MA': LatLngBounds(LatLng(41.18, -73.5), LatLng(42.88, -69.9)),
      'MI': LatLngBounds(LatLng(41.7, -90.4), LatLng(48.3, -82.4)),
      'MN': LatLngBounds(LatLng(43.5, -97.3), LatLng(49.3, -89.5)),
      'MS': LatLngBounds(LatLng(30.2, -91.6), LatLng(35.0, -88.1)),
      'MO': LatLngBounds(LatLng(36.0, -95.8), LatLng(40.6, -89.1)),
      'MT': LatLngBounds(LatLng(44.4, -116.1), LatLng(49.0, -104.0)),
      'NE': LatLngBounds(LatLng(40.0, -104.1), LatLng(43.0, -95.3)),
      'NV': LatLngBounds(LatLng(35.0, -120.0), LatLng(42.0, -114.0)),
      'NH': LatLngBounds(LatLng(42.7, -72.6), LatLng(45.3, -70.6)),
      'NJ': LatLngBounds(LatLng(38.9, -75.6), LatLng(41.4, -73.9)),
      'NM': LatLngBounds(LatLng(31.3, -109.1), LatLng(37.0, -103.0)),
      'NY': LatLngBounds(LatLng(40.4, -79.8), LatLng(45.0, -71.8)),
      'NC': LatLngBounds(LatLng(33.8, -84.3), LatLng(36.6, -75.4)),
      'ND': LatLngBounds(LatLng(45.9, -104.1), LatLng(49.0, -96.5)),
      'OH': LatLngBounds(LatLng(38.2, -84.8), LatLng(41.98, -80.5)),
      'OK': LatLngBounds(LatLng(33.6, -103.0), LatLng(37.0, -94.4)),
      'OR': LatLngBounds(LatLng(41.9, -124.6), LatLng(46.3, -116.5)),
      'PA': LatLngBounds(LatLng(39.7, -80.6), LatLng(42.5, -74.6)),
      'RI': LatLngBounds(LatLng(41.1, -71.9), LatLng(42.0, -71.1)),
      'SC': LatLngBounds(LatLng(32.0, -83.4), LatLng(35.2, -78.5)),
      'SD': LatLngBounds(LatLng(42.5, -104.1), LatLng(45.9, -96.4)),
      'TN': LatLngBounds(LatLng(35.0, -90.3), LatLng(36.7, -81.6)),
      'TX': LatLngBounds(LatLng(25.8, -106.6), LatLng(36.5, -93.5)),
      'UT': LatLngBounds(LatLng(37.0, -114.1), LatLng(42.0, -109.0)),
      'VT': LatLngBounds(LatLng(42.7, -73.4), LatLng(45.0, -71.5)),
      'VA': LatLngBounds(LatLng(36.5, -83.7), LatLng(39.5, -75.2)),
      'WA': LatLngBounds(LatLng(45.5, -124.8), LatLng(49.0, -116.9)),
      'WV': LatLngBounds(LatLng(37.2, -82.6), LatLng(40.6, -77.7)),
      'WI': LatLngBounds(LatLng(42.4, -92.9), LatLng(47.3, -86.8)),
      'WY': LatLngBounds(LatLng(41.0, -111.1), LatLng(45.0, -104.0)),
      'DC': LatLngBounds(LatLng(38.79, -77.12), LatLng(38.995, -76.91)),
    };

    final bounds = stateBounds[stateCode];
    if (bounds == null) {
      Get.snackbar("Error", "Invalid state code");
      return;
    }

    final store = FMTCStore('offline_tiles_$stateCode');

    try {
      // Check if already downloaded
      final exists = await store.manage.ready;
      if (exists) {
        final stats = await store.stats.all;
        if (stats.length > 0) {
          final shouldRedownload = await Get.dialog<bool>(
            AlertDialog(
              title: Text("Map Already Downloaded"),
              content: Text(
                "$stateCode offline map already exists with ${stats.length} tiles.\n\nDo you want to re-download?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: Text("Re-download", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (shouldRedownload != true) return;

          await store.manage.delete();
        }
      }

      if (!exists || !(await store.manage.ready)) {
        await store.manage.create();
      }

      // ✅ Enable wake lock to prevent CPU sleep
      await WakelockPlus.enable();
      log_print.log("✅ Wake lock enabled");

      // ✅ Initialize and start foreground service
      await _initForegroundService();
      await _startDownloadForegroundService(stateCode);
      log_print.log("✅ Foreground service started");

      // Set download state
      isDownloadingOfflineMap.value = true;
      _currentDownloadingState = stateCode;
      offlineMapDownloadProgress.value = 0.0;
      downloadedTiles.value = 0;
      totalTiles.value = 0;
      _lastStreamUpdate = DateTime.now();

      final region = RectangleRegion(bounds);
      final downloadable = region.toDownloadable(
        minZoom: 9,
        maxZoom: 14,
        options: TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.cross_aware',
        ),
      );

      final progressStream = store.download.startForeground(
        region: downloadable,
        parallelThreads: 5,
        skipExistingTiles: true,
        maxBufferLength: 500,
      );

      await _downloadSubscription?.cancel();

      _downloadSubscription = progressStream.listen(
            (DownloadProgress prog) {
          _lastStreamUpdate = DateTime.now();
          downloadedTiles.value = prog.successfulTiles;
          totalTiles.value = prog.maxTiles;

          final percent = prog.percentageProgress;
          if (percent.isFinite) {
            offlineMapDownloadProgress.value = percent;

            log_print.log(
                "📥 ${DateTime.now().toString().split(' ')[1]} - "
                    "${percent.toStringAsFixed(1)}% - "
                    "${prog.successfulTiles}/${prog.maxTiles} tiles - "
                    "Background: $_isAppInBackground"
            );
          }
        },
        onError: (e) {
          log_print.log("❌ Download error: $e");
          _cleanupDownload(stateCode, isError: true, error: e.toString());
        },
        onDone: () {
          log_print.log("✅ Download complete for $stateCode");
          _cleanupDownload(stateCode, isComplete: true);
        },
        cancelOnError: false,
      );

      // ✅ START MONITORING TIMER - This ensures updates even when stream pauses
      _startDownloadMonitorTimer(stateCode);

    } catch (e) {
      log_print.log("❌ Download initialization error: $e");
      _cleanupDownload(stateCode, isError: true, error: e.toString());
    }
  }
  // ✅ Start periodic notification updates
  void _startDownloadMonitorTimer(String stateCode) {
    _downloadMonitorTimer?.cancel();

    _downloadMonitorTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!isDownloadingOfflineMap.value) {
        log_print.log("⏹️ Monitor: Download not active, stopping timer");
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final timeSinceLastUpdate = now.difference(_lastStreamUpdate ?? now).inSeconds;

      log_print.log(
          "🔄 Monitor tick: ${offlineMapDownloadProgress.value.toStringAsFixed(1)}% - "
              "${downloadedTiles.value}/${totalTiles.value} tiles - "
              "Last update: ${timeSinceLastUpdate}s ago - "
              "Background: $_isAppInBackground"
      );

      // ✅ Update foreground notification
      await _updateForegroundNotification(
        stateCode,
        offlineMapDownloadProgress.value,
        downloadedTiles.value,
        totalTiles.value,
      );

      // ⚠️ If no updates for 30 seconds, something is wrong
      if (timeSinceLastUpdate > 30) {
        log_print.log("⚠️ No stream updates for 30s - download may be stuck!");
      }
    });

    log_print.log("✅ Download monitor timer started");
  }


  // void _stopDownloadNotificationTimer() {
  //   log_print.log("🛑 Stopping notification timer");
  //   _downloadNotificationTimer?.cancel();
  //   _downloadNotificationTimer = null;
  // }
  // ✅ Show initial notification
  // Future<void> _showDownloadStartNotification(String stateCode) async {
  //   try {
  //     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //       'offline_map_download',
  //       'Offline Map Download',
  //       channelDescription: 'Shows progress of offline map download',
  //       importance: Importance.low,
  //       priority: Priority.low,
  //       ongoing: true,
  //       autoCancel: false,
  //       showProgress: true,
  //       maxProgress: 100,
  //       progress: 0,
  //       enableLights: false,
  //       enableVibration: false,
  //       playSound: false,
  //       icon: '@mipmap/ic_launcher',
  //     );
  //
  //     const NotificationDetails notificationDetails = NotificationDetails(
  //       android: androidDetails,
  //     );
  //
  //     await flutterLocalNotificationsPlugin.show(
  //       999,
  //       "Downloading $stateCode Map",
  //       "Starting download...",
  //       notificationDetails,
  //     );
  //
  //     log_print.log("📢 Initial download notification shown");
  //   } catch (e) {
  //     log_print.log("Notification error: $e");
  //   }
  // }
  Future<void> _cleanupDownload(
      String stateCode, {
        bool isComplete = false,
        bool isError = false,
        bool isCancelled = false,
        String? error,
      }) async {
    log_print.log("🧹 Cleaning up download...");

    _downloadMonitorTimer?.cancel();
    _downloadMonitorTimer = null;

    isDownloadingOfflineMap.value = false;
    _currentDownloadingState = null;

    // Disable wake lock
    await WakelockPlus.disable();
    log_print.log("✅ Wake lock disabled");

    // Stop foreground service
    await _stopDownloadForegroundService();
    log_print.log("✅ Foreground service stopped");

    if (isComplete) {
      offlineMapDownloadProgress.value = 100.0;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'offline_map_complete',
        'Download Complete',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        998,
        "✅ Download Complete",
        "$stateCode offline map ready! (${downloadedTiles.value} tiles)",
        notificationDetails,
      );

      if (Get.context != null && Get.context!.mounted) {
        Get.snackbar(
          "Download Complete",
          "$stateCode offline map ready!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      await checkOfflineMapAvailability();
    } else if (isError) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'offline_map_error',
        'Download Error',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        997,
        "❌ Download Failed",
        error ?? "Download failed",
        notificationDetails,
      );
    } else if (isCancelled) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'offline_map_cancelled',
        'Download Cancelled',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        996,
        "Download Cancelled",
        "$stateCode download cancelled",
        notificationDetails,
      );
    }
  }
  // ✅ Update notification with progress
  Future<void> _updateDownloadProgressNotification(
      String stateCode,
      double percent,
      int downloaded,
      int total,
      ) async {
    try {
      final percentInt = percent.toInt();

      log_print.log(
          "📢 Updating notification: $percentInt% - $downloaded/$total tiles"
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'offline_map_download',
        'Offline Map Download',
        channelDescription: 'Shows progress of offline map download',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: percentInt,
        enableLights: false,
        enableVibration: false,
        playSound: false,
        icon: '@mipmap/ic_launcher',
        onlyAlertOnce: true,
        visibility: NotificationVisibility.public, // ✅ Show on lock screen
        channelShowBadge: false,
      );

       NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        999, // Same ID to update existing notification
        "📥 Downloading $stateCode Map",
        "$percentInt% • $downloaded/$total tiles",
        notificationDetails,
      );

      log_print.log("✅ Notification updated successfully");
    } catch (e) {
      log_print.log("❌ Notification update error: $e");
    }
  }
  // ✅ Updated cancel method
  Future<void> cancelOfflineMapDownload() async {
    if (!isDownloadingOfflineMap.value) return;

    try {
      await _downloadSubscription?.cancel();
      _downloadSubscription = null;

      if (_currentDownloadingState != null) {
        final store = FMTCStore('offline_tiles_$_currentDownloadingState');
        await store.download.cancel();

        await _cleanupDownload(_currentDownloadingState!, isCancelled: true);
      }

      Get.snackbar(
        "Download Cancelled",
        "Offline map download has been cancelled",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      log_print.log("Error cancelling download: $e");
    }
  }
//   // ✅ Show completion notification
//   Future<void> _showDownloadCompleteNotification(String stateCode, int tiles) async {
//     try {
//       const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//         'offline_map_download_complete',
//         'Download Complete',
//         channelDescription: 'Notification when download completes',
//         importance: Importance.high,
//         priority: Priority.high,
//         ongoing: false,
//         autoCancel: true,
//         enableLights: true,
//         enableVibration: true,
//         playSound: true,
//         icon: '@mipmap/ic_launcher',
//       );
//
//       const NotificationDetails notificationDetails = NotificationDetails(
//         android: androidDetails,
//       );
//
//       // Cancel ongoing notification
//       await flutterLocalNotificationsPlugin.cancel(999);
//
//       // Show completion notification
//       await flutterLocalNotificationsPlugin.show(
//         998,
//         "✅ Download Complete",
//         "$stateCode offline map ready! ($tiles tiles downloaded)",
//         notificationDetails,
//       );
//     } catch (e) {
//       log_print.log("Completion notification error: $e");
//     }
//   }
// // ✅ Show error notification
//   Future<void> _showDownloadErrorNotification(String stateCode, String error) async {
//     try {
//       const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//         'offline_map_download_error',
//         'Download Error',
//         channelDescription: 'Notification when download fails',
//         importance: Importance.high,
//         priority: Priority.high,
//         ongoing: false,
//         autoCancel: true,
//         enableLights: true,
//         enableVibration: true,
//         playSound: true,
//         icon: '@mipmap/ic_launcher',
//       );
//
//       const NotificationDetails notificationDetails = NotificationDetails(
//         android: androidDetails,
//       );
//
//       // Cancel ongoing notification
//       await flutterLocalNotificationsPlugin.cancel(999);
//
//       // Show error notification
//       await flutterLocalNotificationsPlugin.show(
//         997,
//         "❌ Download Failed",
//         "$stateCode map download failed: $error",
//         notificationDetails,
//       );
//     } catch (e) {
//       log_print.log("Error notification error: $e");
//     }
//   }
//   // ✅ Cancel download
//   Future<void> cancelOfflineMapDownload() async {
//     if (!isDownloadingOfflineMap.value) return;
//
//     try {
//       _stopDownloadNotificationTimer();
//
//       await _downloadSubscription?.cancel();
//       _downloadSubscription = null;
//
//       if (_currentDownloadingState != null) {
//         final store = FMTCStore('offline_tiles_$_currentDownloadingState');
//         await store.download.cancel();
//       }
//
//       isDownloadingOfflineMap.value = false;
//       final cancelledState = _currentDownloadingState;
//       _currentDownloadingState = null;
//       offlineMapDownloadProgress.value = 0.0;
//
//       // Clear notifications
//       await flutterLocalNotificationsPlugin.cancel(999);
//
//       // Show cancellation notification
//       const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//         'offline_map_download_cancelled',
//         'Download Cancelled',
//         importance: Importance.low,
//         priority: Priority.low,
//         autoCancel: true,
//         icon: '@mipmap/ic_launcher',
//       );
//
//       const NotificationDetails notificationDetails = NotificationDetails(
//         android: androidDetails,
//       );
//
//       await flutterLocalNotificationsPlugin.show(
//         996,
//         "Download Cancelled",
//         "$cancelledState map download cancelled",
//         notificationDetails,
//       );
//
//       Get.snackbar(
//         "Download Cancelled",
//         "Offline map download has been cancelled",
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//     } catch (e) {
//       log_print.log("Error cancelling download: $e");
//     }
//   }
//   Future<void> _updateDownloadNotification(
//       String stateCode,
//       double percent,
//       int downloaded,
//       int total,
//       int remaining,
//       ) async {
//     try {
//        AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//         'offline_map_download',
//         'Offline Map Download',
//         channelDescription: 'Shows progress of offline map download',
//         importance: Importance.low,
//         priority: Priority.low,
//         ongoing: true, // ✅ Makes notification persistent
//         autoCancel: false,
//         showProgress: true,
//         maxProgress: 100,
//         progress: percent.toInt(),
//         enableLights: false,
//         enableVibration: false,
//         icon: '@mipmap/ic_launcher',
//       );
//
//        NotificationDetails notificationDetails = NotificationDetails(
//         android: androidDetails,
//       );
//
//       await flutterLocalNotificationsPlugin.show(
//         999, // Unique ID for download notifications
//         "Downloading $stateCode Map",
//         "${percent.toStringAsFixed(1)}% • $downloaded/$total tiles",
//         notificationDetails,
//       );
//     } catch (e) {
//       log_print.log("Notification error: $e");
//     }
//   }
  Future<bool> checkIfOfflineMapExists(String stateCode) async {
    try {
      final store = FMTCStore('offline_tiles_$stateCode');

      // Check if the store exists
      final exists = await store.manage.ready;

      if (exists) {
        // Optionally, check if it has any tiles
        final stats = await store.stats.all;
        return stats.length > 0; // Returns true if tiles exist
      }

      return false;
    } catch (e) {
      print('Error checking offline map: $e');
      return false;
    }
  }
  Future<bool> isOfflineMapAvailable() async {
    try {
      final stateCode = await getCurrentStateCode();
      if (stateCode == null) return false;

      final store = FMTCStore('offline_tiles_$stateCode');
      final exists = await store.manage.ready;

      if (exists) {
        final stats = await store.stats.all;
        return stats.length > 0;
      }
      return false;
    } catch (e) {
      print('Error checking offline map: $e');
      return false;
    }
  }
  // Add observable variable
  final hasOfflineMap = false.obs;
  StreamSubscription<DownloadProgress>? _downloadSubscription;
  final RxBool isDownloadingOfflineMap = false.obs;
  final RxDouble offlineMapDownloadProgress = 0.0.obs;
  final RxInt downloadedTiles = 0.obs;
  final RxInt totalTiles = 0.obs;
  String? _currentDownloadingState;
  Timer? _downloadMonitorTimer;
  bool _isAppInBackground = false;
  DateTime? _lastStreamUpdate;
  // Timer? _downloadNotificationTimer;
  // int _lastNotifiedPercent = 0;
  // bool _isAppInBackground = false;
  // final currentStateCode = Rxn<String>();
  // final isDownloadingOfflineMap = false.obs;
  // final offlineMapDownloadProgress = 0.0.obs;
  // final offlineMapTileCount = 0.obs;
  // final offlineMapSize = 0.0.obs;
// ✅ Initialize foreground service
  Future<void> _initForegroundService() async {
    fg.FlutterForegroundTask.init(
      androidNotificationOptions:  fg.AndroidNotificationOptions(
        channelId: 'offline_map_download',
        channelName: 'Offline Map Download',
        channelDescription: 'Shows progress of offline map download',
        channelImportance:  fg.NotificationChannelImportance.LOW,
        priority:  fg.NotificationPriority.LOW,
        iconData: const  fg.NotificationIconData(
          resType:  fg.ResourceType.mipmap,
          resPrefix:  fg.ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const  fg.IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const  fg.ForegroundTaskOptions(
        interval: 2000, // Update every 2 seconds
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

// ✅ Start foreground service
  Future<void> _startDownloadForegroundService(String stateCode) async {
    if (await  fg.FlutterForegroundTask.isRunningService) {
      await  fg.FlutterForegroundTask.restartService();
    } else {
      await  fg.FlutterForegroundTask.startService(
        notificationTitle: 'Downloading $stateCode Map',
        notificationText: 'Starting download...',
      );
    }
  }

// ✅ Update foreground notification
  Future<void> _updateForegroundNotification(
      String stateCode,
      double percent,
      int downloaded,
      int total,
      ) async {
    await  fg.FlutterForegroundTask.updateService(
      notificationTitle: '📥 Downloading $stateCode Map',
      notificationText: '${percent.toStringAsFixed(0)}% • $downloaded/$total tiles',
    );
  }

// ✅ Stop foreground service
  Future<void> _stopDownloadForegroundService() async {
    await  fg.FlutterForegroundTask.stopService();
  }
// Check on init
  Future<void> checkOfflineMapAvailability() async {
    hasOfflineMap.value = await isOfflineMapAvailable();
  }
  void initializeOnPageOpen() async{
    log_print.log("🔄 Initializing location on page open");

    // Check if location tracking is already active
    if (!isTrackingLocation.value || _positionStream == null) {
      log_print.log("📍 Starting fresh location tracking");
      initializeLocationServices();
    } else {
      log_print.log("📍 Location tracking already active, refreshing location");
      // Force refresh current location
      fetchInitialLocation();

      // Ensure map is centered on current location
      if (userPosition.value != null) {
        final userLatLng = LatLng(
          userPosition.value!.latitude,
          userPosition.value!.longitude,
        );
        mapController.move(userLatLng, currentZoom.value);
      }
    }
    // Check offline map availability
    log_print.log("🗺️ Checking offline map availability");
    await checkOfflineMapAvailability();
    log_print.log("🗺️ Offline map available: ${hasOfflineMap.value}");
  }

  // Enhanced location refresh method
  Future<void> refreshCurrentLocation() async {
    try {
      log_print.log("🔄 Manually refreshing location");

      // Show loading state
      isLoading.value = true;

      // Get fresh location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      userPosition.value = position;

      // Update map to current location
      final userLatLng = LatLng(position.latitude, position.longitude);
      isProgrammaticMove.value = true;
      mapController.move(userLatLng, currentZoom.value);
      isProgrammaticMove.value = false;
      hasUserAdjustedZoom.value = false;

      // Fetch crossings for new location
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final cityName =
          placemarks.isNotEmpty ? placemarks[0].locality?.toUpperCase() : '';
      await fetchLocations(cityName: cityName ?? "");

      log_print.log("✅ Location refreshed successfully");

      // Show success feedback
      Get.snackbar(
        "Location Updated",
        "Your current location has been refreshed",
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log_print.log("❌ Error refreshing location: $e");
      Get.snackbar(
        "Location Error",
        "Failed to refresh location: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add this to ensure location tracking stays active
  void ensureLocationService() {
    if (_positionStream == null || !isTrackingLocation.value) {
      log_print.log("🔄 Restarting location service");
      _initLocationTracking();
    }
  }
//08/10/2025
//   Future<void> initializeLocationServices() async {
//     log_print.log(
//       "📡 [CrossingController] initializeLocationServices() started",
//     );
//     // ✅ Step 0: Permission check first
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       Get.snackbar(
//         "Location Service Off",
//         "Please enable location services to continue",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//
//     if (permission != LocationPermission.always &&
//         permission != LocationPermission.whileInUse) {
//       Get.snackbar(
//         "Permission Required",
//         "Please allow location permission to use navigation",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return; // ❌ Stop here, don't run next steps
//     }
//     try {
//       log_print.log("⚙️ Step 1: Initializing background service...");
//       await _backgroundService.initialize();
//       log_print.log("✅ Step 1: Background service initialized");
//
//       log_print.log("🔔 Step 2: Initializing notification service...");
//       await NotificationService().init();
//       log_print.log("✅ Step 2: Notification service initialized");
//
//       log_print.log("🎧 Step 3: Initializing audio...");
//       await _initAudio();
//       log_print.log("✅ Step 3: Audio initialized");
//
//       log_print.log("🛰️ Step 4: Starting location tracking FIRST...");
//       await _initLocationTracking();
//       log_print.log("✅ Step 4: Location tracking started");
//
//       log_print.log("📍 Step 5: Fetching initial location...");
//       await fetchInitialLocation();
//       log_print.log("✅ Step 5: Initial location fetched");
//
//       log_print.log("📦 Step 6: Loading preferences...");
//       _loadPreferences();
//       log_print.log("✅ Step 6: Preferences loaded");
//
//       log_print.log("🔄 Step 7: Registering background tasks...");
//       _registerBackgroundTasks();
//       log_print.log("✅ Step 7: Background tasks registered");
//
//       log_print.log(
//         "✅ [CrossingController] initializeLocationServices() complete",
//       );
//     } catch (e) {
//       errorMessage.value = "Failed to initialize services: $e";
//       log_print.log("⚠ Service initialization error: $e");
//     }
//   }
//08/10/2025 new
  Future<void> initializeLocationServices() async {
    log_print.log("📡 [CrossingController] initializeLocationServices() started");

    // ✅ Step 0: Permission check FIRST
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          "Location Service Off",
          "Please enable location services to continue",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        Get.snackbar(
          "Permission Required",
          "Please allow location permission to use navigation",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } catch (e) {
      log_print.log("❌ Permission error: $e");
      return;
    }

    // ✅ Initialize services with error handling
    try {
      log_print.log("⚙️ Step 1: Initializing background service...");
      await _backgroundService.initialize();
      log_print.log("✅ Step 1: Background service initialized");
    } catch (e) {
      log_print.log("⚠️ Background service error (non-critical): $e");
    }

    try {
      log_print.log("🔔 Step 2: Initializing notification service...");
      await NotificationService().init();
      log_print.log("✅ Step 2: Notification service initialized");
    } catch (e) {
      log_print.log("⚠️ Notification service error (non-critical): $e");
    }

    try {
      log_print.log("🎧 Step 3: Initializing audio...");
      await _initAudio();
      log_print.log("✅ Step 3: Audio initialized");
    } catch (e) {
      log_print.log("⚠️ Audio initialization failed (non-critical): $e");
      // Don't stop - audio પછીથી પણ initialize થઈ શકે
    }

    // ✅ CRITICAL: Location tracking must start regardless of above errors
    try {
      log_print.log("🛰️ Step 4: Starting location tracking (CRITICAL)...");
      await _initLocationTracking();
      log_print.log("✅ Step 4: Location tracking started");
    } catch (e) {
      log_print.log("❌ CRITICAL: Location tracking failed: $e");
      errorMessage.value = "Failed to start location tracking: $e";
      return; // Only stop if location tracking fails
    }

    try {
      log_print.log("📍 Step 5: Fetching initial location...");
      await fetchInitialLocation();
      log_print.log("✅ Step 5: Initial location fetched");
    } catch (e) {
      log_print.log("⚠️ Initial location fetch failed: $e");
      // Continue anyway - stream will update
    }

    try {
      log_print.log("📦 Step 6: Loading preferences...");
      _loadPreferences();
      log_print.log("✅ Step 6: Preferences loaded");
    } catch (e) {
      log_print.log("⚠️ Preferences load failed: $e");
    }

    try {
      log_print.log("📄 Step 7: Registering background tasks...");
      _registerBackgroundTasks();
      log_print.log("✅ Step 7: Background tasks registered");
    } catch (e) {
      log_print.log("⚠️ Background tasks registration failed: $e");
    }

    log_print.log("✅✅✅ [CrossingController] INITIALIZATION COMPLETE ✅✅✅");
  }
  Future<void> fetchInitialLocation() async {
    try {
      log_print.log("📍 Fetching initial location...");

      if (userPosition.value != null) {
        log_print.log(
          "✅ Using position from stream: ${userPosition.value!.latitude}, ${userPosition.value!.longitude}",
        );

        final placemarks = await geocoding.placemarkFromCoordinates(
          userPosition.value!.latitude,
          userPosition.value!.longitude,
        );
        final cityName =
            placemarks.isNotEmpty ? placemarks[0].locality?.toUpperCase() : '';

        log_print.log("🏙️ City detected: $cityName");
        await fetchLocations(cityName: cityName ?? "");
        return;
      }

      log_print.log("🎯 Getting current position...");
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high, // similar to before
          distanceFilter: 0, // meters before updates trigger
        ),
      );

      userPosition.value = pos;
      log_print.log(
        "✅ Got initial position: ${pos.latitude}, ${pos.longitude}",
      );

      final placemarks = await geocoding.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final cityName =
          placemarks.isNotEmpty ? placemarks[0].locality?.toUpperCase() : '';

      log_print.log("🏙️ City for crossings: $cityName");
      await fetchLocations(cityName: cityName ?? "");
    } catch (e) {
      log_print.log("❌ Error in fetchInitialLocation: $e");
      errorMessage.value = e.toString();
    }
  }

  // Updated app lifecycle methods
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        log_print.log("🟢 App resumed - FOREGROUND MODE");

        if (isDownloadingOfflineMap.value) {
          log_print.log(
              "📥 Download status: ${offlineMapDownloadProgress.value.toStringAsFixed(1)}% - "
                  "${downloadedTiles.value}/${totalTiles.value}"
          );
        }
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _isAppInBackground = true;
        log_print.log("🟡 App paused - BACKGROUND MODE");

        if (isDownloadingOfflineMap.value) {
          log_print.log(
              "📥 Download active: ${offlineMapDownloadProgress.value.toStringAsFixed(1)}% - "
                  "${downloadedTiles.value}/${totalTiles.value}"
          );
        }
      case AppLifecycleState.inactive:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _onAppDetached();
        break;
    }
  }

  // In the _onAppResumed method:
  void _onAppResumed() {
    log_print.log("App resumed - stopping background service");

    stopBackgroundDebugTimer();

    if (settingController.runInBackground.value) {
      _backgroundService.stopForegroundService();
    }
    Workmanager().cancelByUniqueName("railwayCrossingCheck");
  }

  void _onAppPaused() {
    log_print.log("🟡 App paused - keeping location stream ACTIVE");

    // Start debug timer
    startBackgroundDebugTimer();

    if (settingController.runInBackground.value) {
      _backgroundService.startForegroundService();
      _saveLocationToPrefs();
    }

    _updateBackgroundNotification();

    log_print.log("✅ Background mode active, location stream: ${_positionStream != null ? 'RUNNING' : 'NULL'}");
    debugLocationStream(); // Log initial state
  }

  void _onAppDetached() {
    log_print.log("App detached - ensuring background service is running");
    if (settingController.runInBackground.value) {
      _backgroundService.startForegroundService();
      _saveLocationToPrefs();
      // Re-register background tasks
      _registerBackgroundTasks();
    }
  }
//13/10/2025
  // Save current location to SharedPreferences for background use
  // Future<void> _saveLocationToPrefs() async {
  //   if (userPosition.value != null) {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setDouble('lastKnownLat', userPosition.value!.latitude);
  //     await prefs.setDouble('lastKnownLng', userPosition.value!.longitude);
  //     await prefs.setInt(
  //       'lastLocationTime',
  //       DateTime.now().millisecondsSinceEpoch,
  //     );
  //
  //     // Save nearby locations data
  //     final locationsJson =
  //         nearbyLocations
  //             .map(
  //               (loc) => {
  //                 'latitude': loc.latitude,
  //                 'longitude': loc.longitude,
  //                 'street': loc.street,
  //                 'totalswitchingtrains': loc.totalswitchingtrains,
  //               },
  //             )
  //             .toList();
  //     await prefs.setString('nearbyLocations', json.encode(locationsJson));
  //
  //     // Save settings
  //     await prefs.setBool(
  //       'isWarningsEnabled',
  //       settingController.isWarningsEnabled.value,
  //     );
  //     await prefs.setDouble(
  //       'warningDistance',
  //       settingController.warningDistance.value,
  //     );
  //     await prefs.setBool(
  //       'isVibrationEnabled',
  //       settingController.isVibrationEnabled.value,
  //     );
  //     await prefs.setBool(
  //       'isWarningSoundEnabled',
  //       settingController.isWarningSoundEnabled.value,
  //     );
  //
  //     log_print.log(
  //       "Location and settings saved to preferences for background use",
  //     );
  //   }
  // }
  Future<void> _saveLocationToPrefs() async {
    if (userPosition.value != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lastKnownLat', userPosition.value!.latitude);
      await prefs.setDouble('lastKnownLng', userPosition.value!.longitude);
      await prefs.setInt(
        'lastLocationTime',
        DateTime.now().millisecondsSinceEpoch,
      );

      // ✅ Save navigation state
      await prefs.setBool('isNavigating', isNavigating.value);

      // ✅ Save route coordinates if navigating
      if (isNavigating.value && routeCoordinates.isNotEmpty) {
        final routeJson = routeCoordinates
            .map((coord) => {'lat': coord.latitude, 'lng': coord.longitude})
            .toList();
        await prefs.setString('routeCoordinates', json.encode(routeJson));

        // Save crossings along route
        final crossingsJson = crossingsAlongRoute
            .map((loc) => {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'street': loc.street,
          'totalswitchingtrains': loc.totalswitchingtrains,
        })
            .toList();
        await prefs.setString('crossingsAlongRoute', json.encode(crossingsJson));
      }

      // Save nearby locations data
      final locationsJson = nearbyLocations
          .map((loc) => {
        'latitude': loc.latitude,
        'longitude': loc.longitude,
        'street': loc.street,
        'totalswitchingtrains': loc.totalswitchingtrains,
      })
          .toList();
      await prefs.setString('nearbyLocations', json.encode(locationsJson));

      // Save settings
      await prefs.setBool(
        'isWarningsEnabled',
        settingController.isWarningsEnabled.value,
      );
      await prefs.setDouble(
        'warningDistance',
        settingController.warningDistance.value,
      );
      await prefs.setBool(
        'isVibrationEnabled',
        settingController.isVibrationEnabled.value,
      );
      await prefs.setBool(
        'isWarningSoundEnabled',
        settingController.isWarningSoundEnabled.value,
      );

      log_print.log(
        "Location, route data, and settings saved to preferences for background use",
      );
    }
  }
  Future<void> _initAudio() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    await player.setAsset('assets/sounds/train_crossing_signal_73823.mp3');
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    distanceUnit.value = prefs.getString('distanceUnit') ?? 'kilometers';
    destinationAddress.value = prefs.getString('destinationAddress') ?? '';
    if (destinationAddress.value.isNotEmpty) {
      final toLocations = await geocoding.locationFromAddress(
        destinationAddress.value,
      );
      if (toLocations.isNotEmpty) {
        toLocation.value = LatLng(
          toLocations.first.latitude,
          toLocations.first.longitude,
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('distanceUnit', distanceUnit.value);
    await prefs.setString('destinationAddress', destinationAddress.value);
  }

  // void updateDistanceUnit(String unit) {
  //   distanceUnit.value = unit;
  //   _savePreferences();
  // }

  void updateDistanceUnit(String unit) {
    distanceUnit.value = unit;
    _savePreferences();

    // Also update the setting controller
    try {
      final SettingController settingController = Get.find<SettingController>();
      settingController.updateDistanceUnit(unit);
    } catch (e) {
      log_print.log('Error syncing distance unit with settings: $e');
    }
  }

  String formatDistance(double meters) {
    // Get the current distance unit from settings controller
    final unit = settingController.distanceUnit.value;

    switch (unit) {
      case 'meters':
        return '${meters.toStringAsFixed(0)} m';
      case 'miles':
        return '${(meters * 0.000621371).toStringAsFixed(1)} mi';
      case 'kilometers':
      default:
        return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  void onClose() {
    // Cancel all timers
    _navigationTimer?.cancel();
    _backgroundTimer?.cancel();
    _rerouteTimer?.cancel();

    // Cancel position stream if it exists
    _positionStream?.cancel();
    _positionStream = null;

    // Dispose audio player
    player.dispose();
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    super.onClose();
  }

  void _registerBackgroundTasks() {
    try {
      Workmanager().initialize(
        callbackDispatcher, // Use the global callback dispatcher
        isInDebugMode: false,
      );

      // Register periodic task for checking railway crossings
      Workmanager().registerPeriodicTask(
        "railwayCrossingCheck",
        "railwayCrossingCheck",
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresStorageNotLow: false,
          requiresCharging: false,
        ),
      );

      // Register one-off task for immediate background service
      Workmanager().registerOneOffTask(
        "startBackgroundService",
        "startBackgroundService",
      );

      log_print.log("Background tasks registered successfully");
    } catch (e) {
      log_print.log("Error registering background tasks: $e");
    }
  }

  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    isTrackingLocation.value = false;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  LatLng? _lastUserLatLng;

  //   Future<void> _initLocationTracking() async {
  //     try {
  //       // Initialize notifications
  //       const AndroidInitializationSettings initializationSettingsAndroid =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');
  //
  //       final InitializationSettings initializationSettings =
  //       InitializationSettings(android: initializationSettingsAndroid);
  //
  //       await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  //
  //       // Location settings - use high accuracy and smaller distance filter
  //       final locationSettings = LocationSettings(
  //         accuracy: LocationAccuracy.bestForNavigation,
  //         distanceFilter: 10, // Update more frequently (in meters)
  //       );
  //
  //       // Show persistent notification
  //       const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //       AndroidNotificationDetails(
  //         'location_channel',
  //         'Location Tracking',
  //         channelDescription: 'Tracking railway crossings nearby',
  //         importance: Importance.low,
  //         priority: Priority.low,
  //         ongoing: true,
  //         enableLights: false,
  //         enableVibration: false,
  //         autoCancel: false,
  //         showWhen: false,
  //         icon: '@mipmap/ic_launcher',
  //       );
  //
  //       const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //         android: androidPlatformChannelSpecifics,
  //       );
  //
  //       await flutterLocalNotificationsPlugin.show(
  //         0,
  //         'Railway Crossing Alerts Active',
  //         'Monitoring railway crossings in background',
  //         platformChannelSpecifics,
  //       );
  //
  //       // Cancel any existing stream
  //       await _positionStream?.cancel();
  //       Position? lastKnownPosition;
  //       // Initialize the new position stream
  //       // _positionStream = Geolocator.getPositionStream(
  //       //   locationSettings: locationSettings,
  //       // ).listen((Position position) {
  //       //   final hasMoved =
  //       //       lastKnownPosition == null ||
  //       //       _calculateDistance(
  //       //                 lastKnownPosition!.latitude,
  //       //                 lastKnownPosition!.longitude,
  //       //                 position.latitude,
  //       //                 position.longitude,
  //       //               ) *
  //       //               1000 >
  //       //           3; // moved >3m
  //       //
  //       //   if (!hasMoved) return;
  //       //
  //       //   lastKnownPosition = position;
  //       //
  //       //   userPosition.value = position;
  //       //   userBearing.value = position.heading;
  //       //   // Prefer course from GPS when speed >= 1.5 m/s; else keep last rotation
  //       //   final speed = position.speed; // m/s
  //       //   if (speed >= 1.5) {
  //       //     // Bearing from last fix to current fix
  //       //     if (_lastUserLatLng != null) {
  //       //       final b = _calculateBearing(
  //       //         _lastUserLatLng!.latitude,
  //       //         _lastUserLatLng!.longitude,
  //       //         position.latitude,
  //       //         position.longitude,
  //       //       );
  //       //       mapRotation.value = b;
  //       //     }
  //       //   } else if (position.headingAccuracy > 0 &&
  //       //       position.headingAccuracy < 10) {
  //       //     // Only trust compass when fairly accurate
  //       //     mapRotation.value = position.heading;
  //       //   }
  //       //   _lastUserLatLng = LatLng(position.latitude, position.longitude);
  //       //
  //       //   if (isNavigating.value) {
  //       //     final userLatLng = LatLng(position.latitude, position.longitude);
  //       //
  //       //     if (!hasUserAdjustedZoom.value) {
  //       //       isProgrammaticMove.value = true;
  //       //       mapController.move(userLatLng, 18);
  //       //       isProgrammaticMove.value = false;
  //       //     }
  //       //   }
  //       //   userBearing.value = position.heading;
  //       //   _saveLocationToPrefs();
  //       //
  //       //   if (isNavigating.value) {
  //       //     _checkProximityToCrossings();
  //       //     _checkRouteDeviation();
  //       //     _updateRouteProgress();
  //       //     _provideVoiceNavigation(); // add here; remove from any timer
  //       //   } else {
  //       //     checkNearbyCrossings();
  //       //   }
  //       // });
  // // Replace your location stream filtering with this improved version
  //       _positionStream = Geolocator.getPositionStream(
  //         locationSettings: locationSettings,
  //       ).listen((Position position) {
  //         // Skip positions with poor accuracy
  //         if (position.accuracy > 50) {
  //           print('Skipping position with poor accuracy: ${position.accuracy}m');
  //           return;
  //         }
  //
  //         // More sophisticated movement detection
  //         final hasMoved = _hasUserMovedSignificantlyNew(position);
  //         if (!hasMoved) return;
  //
  //         // Update position
  //         lastKnownPosition = position;
  //         userPosition.value = position;
  //
  //         // Handle bearing updates with speed consideration
  //         _updateBearing(position);
  //
  //         // Save location for background use
  //         _saveLocationToPrefs();
  //
  //         if (isNavigating.value) {
  //           // Only update map if user hasn't manually adjusted zoom recently
  //           if (!hasUserAdjustedZoom.value) {
  //             _updateMapPosition(position);
  //           }
  //
  //           // Update route progress with debouncing
  //           _debouncedRouteUpdate();
  //
  //           _checkProximityToCrossings();
  //           _checkRouteDeviation();
  //           _provideVoiceNavigation();
  //         } else {
  //           checkNearbyCrossings();
  //         }
  //       });
  //       isTrackingLocation.value = true;
  //     } catch (e) {
  //       errorMessage.value = "Failed to initialize location tracking: $e";
  //       print("Location tracking initialization error: $e");
  //       isTrackingLocation.value = false;
  //       _positionStream = null;
  //     }
  //   }
  //   Future<void> _initLocationTracking() async {
  //     try {
  //       // Initialize notifications
  //       const AndroidInitializationSettings initializationSettingsAndroid =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');
  //
  //       final InitializationSettings initializationSettings =
  //       InitializationSettings(android: initializationSettingsAndroid);
  //
  //       await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  //
  //       // Location settings - use high accuracy and smaller distance filter
  //       final locationSettings = LocationSettings(
  //         accuracy: LocationAccuracy.bestForNavigation,
  //         distanceFilter: 1, // Update more frequently (in meters)
  //       );
  //
  //       // Show persistent notification
  //       const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //       AndroidNotificationDetails(
  //         'location_channel',
  //         'Location Tracking',
  //         channelDescription: 'Tracking railway crossings nearby',
  //         importance: Importance.low,
  //         priority: Priority.low,
  //         ongoing: true,
  //         enableLights: false,
  //         enableVibration: false,
  //         autoCancel: false,
  //         showWhen: false,
  //         icon: '@mipmap/ic_launcher',
  //       );
  //
  //       const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //         android: androidPlatformChannelSpecifics,
  //       );
  //
  //       await flutterLocalNotificationsPlugin.show(
  //         0,
  //         'Railway Crossing Alerts Active',
  //         'Monitoring railway crossings in background',
  //         platformChannelSpecifics,
  //       );
  //
  //       // Cancel any existing stream
  //       await _positionStream?.cancel();
  //
  //       // Initialize the new position stream - REPLACE THE ENTIRE STREAM WITH THIS:
  //       _positionStream = Geolocator.getPositionStream(
  //         locationSettings: locationSettings,
  //       ).listen((Position position) {
  //         // Debug log
  //         print('📍 Location Update: '
  //             'Lat: ${position.latitude.toStringAsFixed(6)}, '
  //             'Lng: ${position.longitude.toStringAsFixed(6)}, '
  //             'Speed: ${position.speed.toStringAsFixed(1)} m/s, '
  //             'Accuracy: ${position.accuracy.toStringAsFixed(1)}m');
  //
  //         // Skip positions with poor accuracy
  //         if (position.accuracy > 50) {
  //           print('Skipping position with poor accuracy: ${position.accuracy}m');
  //           return;
  //         }
  //
  //         // More sophisticated movement detection
  //         final hasMoved = _hasUserMovedSignificantlyNew(position);
  //         if (!hasMoved) {
  //           print('User has not moved significantly, skipping update');
  //           return;
  //         }
  //
  //         // Update position
  //         userPosition.value = position;
  //
  //         // CRITICAL: Update bearing and map rotation (missing from your current version)
  //         final speed = position.speed; // m/s
  //         if (speed >= 1.5) {
  //           // Bearing from last fix to current fix
  //           if (_lastUserLatLng != null) {
  //             final bearing = _calculateBearing(
  //               _lastUserLatLng!.latitude,
  //               _lastUserLatLng!.longitude,
  //               position.latitude,
  //               position.longitude,
  //             );
  //             mapRotation.value = bearing;
  //           }
  //         } else if (position.headingAccuracy > 0 && position.headingAccuracy < 10) {
  //           // Only trust compass when fairly accurate
  //           mapRotation.value = position.heading;
  //         }
  //
  //         _lastUserLatLng = LatLng(position.latitude, position.longitude);
  //         userBearing.value = position.heading;
  //
  //         // Save location for background use
  //         _saveLocationToPrefs();
  //
  //         if (isNavigating.value) {
  //           // Only update map if user hasn't manually adjusted zoom recently
  //           if (!hasUserAdjustedZoom.value) {
  //             isProgrammaticMove.value = true;
  //             mapController.move(
  //               LatLng(position.latitude, position.longitude),
  //               18,
  //             );
  //             isProgrammaticMove.value = false;
  //           }
  //
  //           // Update route progress with debouncing
  //           _debouncedRouteUpdate();
  //
  //           _checkProximityToCrossings();
  //           _checkRouteDeviation();
  //           _provideVoiceNavigation();
  //         } else {
  //           checkNearbyCrossings();
  //         }
  //       });
  //
  //       isTrackingLocation.value = true;
  //       print('✅ Location tracking initialized successfully');
  //
  //     } catch (e) {
  //       errorMessage.value = "Failed to initialize location tracking: $e";
  //       print("❌ Location tracking initialization error: $e");
  //       isTrackingLocation.value = false;
  //       _positionStream = null;
  //     }
  //   }

  // Future<void> _initLocationTracking() async {
  //   try {
  //     log_print.log("🔧 Starting location tracking initialization...");
  //
  //     // Check permissions first
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       throw Exception("Location services disabled");
  //     }
  //
  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission != LocationPermission.whileInUse &&
  //           permission != LocationPermission.always) {
  //         throw Exception("Location permission denied");
  //       }
  //     }
  //
  //     // Initialize notifications
  //     const AndroidInitializationSettings initializationSettingsAndroid =
  //         AndroidInitializationSettings('@mipmap/ic_launcher');
  //
  //     final InitializationSettings initializationSettings =
  //         InitializationSettings(android: initializationSettingsAndroid);
  //
  //     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  //
  //     // Location settings - LESS STRICT for initial updates
  //     final locationSettings = LocationSettings(
  //       accuracy: LocationAccuracy.high,
  //       distanceFilter: 1,
  //     );
  //
  //     // Show persistent notification
  //     const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //         AndroidNotificationDetails(
  //           'location_channel',
  //           'Location Tracking',
  //           channelDescription: 'Tracking railway crossings nearby',
  //           importance: Importance.low,
  //           priority: Priority.low,
  //           ongoing: true,
  //           enableLights: false,
  //           enableVibration: false,
  //           autoCancel: false,
  //           showWhen: false,
  //           icon: '@mipmap/ic_launcher',
  //         );
  //
  //     const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //       android: androidPlatformChannelSpecifics,
  //     );
  //
  //     await flutterLocalNotificationsPlugin.show(
  //       0,
  //       'Railway Crossing Alerts Active',
  //       'Monitoring railway crossings in background',
  //       platformChannelSpecifics,
  //     );
  //
  //     // Cancel any existing stream
  //     await _positionStream?.cancel();
  //
  //     log_print.log("🎯 Setting up position stream...");
  //
  //     // FIXED: Position stream with better filtering
  //     _positionStream = Geolocator.getPositionStream(
  //       locationSettings: locationSettings,
  //     ).listen((Position position) {
  //       log_print.log(
  //         '📍 RAW Location Update: '
  //         'Lat: ${position.latitude.toStringAsFixed(6)}, '
  //         'Lng: ${position.longitude.toStringAsFixed(6)}, '
  //         'Speed: ${position.speed.toStringAsFixed(1)} m/s, '
  //         'Accuracy: ${position.accuracy.toStringAsFixed(1)}m',
  //       );
  //
  //       // RELAXED accuracy filter for navigation
  //       if (position.accuracy > 100) {
  //         // Increased from 50 to 100
  //         log_print.log(
  //           'Skipping position with poor accuracy: ${position.accuracy}m',
  //         );
  //         return;
  //       }
  //
  //       // ALWAYS update position during navigation, regardless of movement
  //       if (isNavigating.value) {
  //         userPosition.value = position;
  //         log_print.log('🚗 NAVIGATION MODE: Force updating position');
  //       } else {
  //         // Only filter movement when NOT navigating
  //         final hasMoved = _hasUserMovedSignificantlyNew(position);
  //         if (!hasMoved) {
  //           log_print.log('User has not moved significantly, skipping update');
  //           return;
  //         }
  //         userPosition.value = position;
  //       }
  //
  //       // Update bearing and map rotation
  //       final speed = position.speed; // m/s
  //       if (speed >= 1.0) {
  //         // Reduced from 1.5 to 1.0
  //         if (_lastUserLatLng != null) {
  //           final bearing = _calculateBearing(
  //             _lastUserLatLng!.latitude,
  //             _lastUserLatLng!.longitude,
  //             position.latitude,
  //             position.longitude,
  //           );
  //           mapRotation.value = bearing;
  //         }
  //       } else if (position.headingAccuracy > 0 &&
  //           position.headingAccuracy < 15) {
  //         mapRotation.value = position.heading;
  //       }
  //
  //       _lastUserLatLng = LatLng(position.latitude, position.longitude);
  //       userBearing.value = position.heading;
  //
  //       // Save location for background use
  //       _saveLocationToPrefs();
  //
  //       if (isNavigating.value) {
  //         // IMMEDIATE map updates during navigation
  //         if (!hasUserAdjustedZoom.value) {
  //           isProgrammaticMove.value = true;
  //           mapController.move(
  //             LatLng(position.latitude, position.longitude),
  //             18,
  //           );
  //           isProgrammaticMove.value = false;
  //         }
  //
  //         // Process route updates immediately
  //         _updateRouteProgress();
  //         _checkProximityToCrossings();
  //         _checkRouteDeviation();
  //         _provideVoiceNavigation();
  //       } else {
  //         checkNearbyCrossings();
  //       }
  //     });
  //
  //     isTrackingLocation.value = true;
  //     log_print.log('✅ Location tracking initialized successfully');
  //   } catch (e) {
  //     errorMessage.value = "Failed to initialize location tracking: $e";
  //     log_print.log("❌ Location tracking initialization error: $e");
  //     isTrackingLocation.value = false;
  //     _positionStream = null;
  //   }
  // }

  Position? _lastSignificantPosition;

  // void _updateBearing(Position position) {
  //   final speed = position.speed;
  //
  //   if (speed >= 2.0) { // Moving fast enough to trust course
  //     // Use GPS course when moving
  //     if (_lastUserLatLng != null) {
  //       final bearing = _calculateBearing(
  //         _lastUserLatLng!.latitude,
  //         _lastUserLatLng!.longitude,
  //         position.latitude,
  //         position.longitude,
  //       );
  //       mapRotation.value = bearing;
  //     }
  //   } else if (position.headingAccuracy < 15 && position.headingAccuracy > 0) {
  //     // Use compass when stationary, but only if accurate
  //     mapRotation.value = position.heading;
  //   }
  //
  //   _lastUserLatLng = LatLng(position.latitude, position.longitude);
  //   userBearing.value = position.heading;
  // }

  /// 08/10/2025 OLD
  // bool _hasUserMovedSignificantlyNew(Position newPosition) {
  //   if (_lastSignificantPosition == null) {
  //     _lastSignificantPosition = newPosition;
  //     return true;
  //   }
  //
  //   final distance =
  //       _calculateDistance(
  //         _lastSignificantPosition!.latitude,
  //         _lastSignificantPosition!.longitude,
  //         newPosition.latitude,
  //         newPosition.longitude,
  //       ) *
  //       1000; // meters
  //
  //   final timeDiff =
  //       newPosition.timestamp
  //           .difference(_lastSignificantPosition!.timestamp)
  //           .inSeconds;
  //
  //   // REDUCED thresholds for more frequent updates during navigation
  //   final threshold =
  //       newPosition.speed > 2.0 ? 5.0 : 3.0; // Much smaller thresholds
  //
  //   if (distance > threshold || timeDiff > 5) {
  //     // Reduced time threshold
  //     _lastSignificantPosition = newPosition;
  //     return true;
  //   }
  //
  //   return false;
  // }
  /// 08/10/2025 NEW
  // Position? _lastSignificantPosition;
  DateTime? _lastUpdateTime;

  bool _hasUserMovedSignificantlyNew(Position newPosition) {
    // First update - always accept
    if (_lastSignificantPosition == null) {
      _lastSignificantPosition = newPosition;
      _lastUpdateTime = DateTime.now();
      log_print.log('✅ First position accepted');
      return true;
    }

    final distance = _calculateDistance(
      _lastSignificantPosition!.latitude,
      _lastSignificantPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    ) * 1000; // meters

    final timeDiff = DateTime.now().difference(_lastUpdateTime!).inSeconds;

    // ✅ VERY RELAXED - Update frequently
    bool shouldUpdate = false;

    // Update if moved > 2 meters OR 2 seconds passed
    if (distance > 2.0 || timeDiff > 2) {
      shouldUpdate = true;
    }

    // During navigation, always update
    if (isNavigating.value && distance > 0.5) {
      shouldUpdate = true;
    }

    if (shouldUpdate) {
      _lastSignificantPosition = newPosition;
      _lastUpdateTime = DateTime.now();
      log_print.log('✅ Movement accepted: ${distance.toStringAsFixed(1)}m, ${timeDiff}s');
    } else {
      log_print.log('⏸️ Movement rejected: ${distance.toStringAsFixed(1)}m, ${timeDiff}s');
    }

    return shouldUpdate;
  }
  // void _updateMapPosition(Position position) {
  //   isProgrammaticMove.value = true;
  //   mapController.move(
  //       LatLng(position.latitude, position.longitude),
  //       18
  //   );
  //   isProgrammaticMove.value = false;
  // }
  // Debounce route updates to avoid too frequent processing
  //   Timer? _routeUpdateTimer;
  // void _debouncedRouteUpdate() {
  //   _routeUpdateTimer?.cancel();
  //   _routeUpdateTimer = Timer(Duration(milliseconds: 1000), () { // Increased to 1 second
  //     _updateRouteProgress();
  //   });
  // }

  final RxDouble mapRotation = 0.0.obs;

  void recenterMap() {
    if (userPosition.value != null) {
      isProgrammaticMove.value = true;
      mapController.move(
        LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
        18,
      );
      mapRotation.value = 0;
      isProgrammaticMove.value = false;
      hasUserAdjustedZoom.value = false;
    }
  }

  // Method to handle background service start
  Future<void> startBackgroundService() async {
    if (settingController.runInBackground.value) {
      await _backgroundService.startForegroundService();
      _registerBackgroundTasks();
      log_print.log("Background service started");
    }
  }

  // Method to handle background service stop
  Future<void> stopBackgroundService() async {
    await _backgroundService.stopForegroundService();
    Workmanager().cancelAll();

    // Cancel the persistent notification
    await flutterLocalNotificationsPlugin.cancel(0);
    log_print.log("Background service stopped");
  }

  //(07/10/2025) OLD
  // Future<void> checkNearbyCrossings() async {
  //   log_print.log("checkNearbyCrossings -----");
  //   if (userPosition.value == null || nearbyLocations.isEmpty) return;
  //   if (!settingController.isWarningsEnabled.value) return;
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   TransportLocation? closest;
  //   double minDistance = double.infinity;
  //
  //   for (final crossing in nearbyLocations) {
  //     final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
  //     final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;
  //
  //     if (crossingLat == 0 || crossingLng == 0) continue;
  //
  //     final distance =
  //         _calculateDistance(
  //           userLatLng.latitude,
  //           userLatLng.longitude,
  //           crossingLat,
  //           crossingLng,
  //         ) *
  //         1000;
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //       closest = crossing;
  //     }
  //
  //     // Use the warning distance from settings
  //     if (distance < settingController.warningDistance.value) {
  //       final message =
  //           "Warning: Nearby Railway Crossing - ${crossing.street ?? 'railway crossing'} (${formatDistance(distance)})";
  //       log_print.log("Should show notification: $message");
  //
  //       // Always show notification
  //       await NotificationService().showNotifications(
  //         "Railway Crossing Warning",
  //         message,
  //       );
  //
  //       // Play sound if enabled
  //       if (settingController.isWarningSoundEnabled.value) {
  //         await player.stop();
  //         await player.setVolume(1.0);
  //         await player.play();
  //       }
  //
  //       // Vibrate if enabled
  //       if (settingController.isVibrationEnabled.value &&
  //           (await Vibration.hasVibrator())) {
  //         if (distance < 50) {
  //           Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
  //         } else {
  //           Vibration.vibrate(duration: 500);
  //         }
  //       }
  //     }
  //   }
  //
  //   // Update nearest crossing
  //   if (closest != null) {
  //     nearestCrossing.value = closest;
  //     distanceToNearestCrossing.value = minDistance;
  //   }
  // }
  //(07/10/2025) NEW
  // Enhanced checkNearbyCrossings method
  // Future<void> checkNearbyCrossings() async {
  //   log_print.log("checkNearbyCrossings -----");
  //   if (userPosition.value == null || nearbyLocations.isEmpty) return;
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   TransportLocation? closest;
  //   double minDistance = double.infinity;
  //
  //   for (final crossing in nearbyLocations) {
  //     final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
  //     final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;
  //
  //     if (crossingLat == 0 || crossingLng == 0) continue;
  //
  //     final distance =
  //         _calculateDistance(
  //           userLatLng.latitude,
  //           userLatLng.longitude,
  //           crossingLat,
  //           crossingLng,
  //         ) *
  //         1000;
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //       closest = crossing;
  //     }
  //
  //     // ✅ CRITICAL CHANGE: Always trigger alerts within 100m, regardless of navigation state
  //     if (distance < 100) {
  //       log_print.log(
  //         "🔔 Within 100m of crossing: ${crossing.street}, distance: ${distance.toStringAsFixed(1)}m",
  //       );
  //       await _triggerProximityAlert(crossing, distance);
  //     }
  //   }
  //
  //   // Update nearest crossing
  //   if (closest != null) {
  //     nearestCrossing.value = closest;
  //     distanceToNearestCrossing.value = minDistance;
  //   }
  // }
//08/10/2025
  Future<void> checkNearbyCrossings() async {
    log_print.log('╔══════════════════════════════════════╗');
    log_print.log('║  checkNearbyCrossings() - START     ║');
    log_print.log('╚══════════════════════════════════════╝');

    if (userPosition.value == null) {
      log_print.log('❌ ABORT: userPosition is NULL');
      return;
    }

    if (nearbyLocations.isEmpty) {
      log_print.log('❌ ABORT: nearbyLocations is EMPTY');
      log_print.log('   💡 TIP: Make sure fetchLocations() was called');
      return;
    }

    final userLatLng = LatLng(
      userPosition.value!.latitude,
      userPosition.value!.longitude,
    );

    log_print.log('📍 User Location: ${userLatLng.latitude}, ${userLatLng.longitude}');
    log_print.log('📢 Total crossings to check: ${nearbyLocations.length}');
    log_print.log('⚠️  Warning distance: ${settingController.warningDistance.value}m');
    log_print.log('🔔 Warnings enabled: ${settingController.isWarningsEnabled.value}');
    log_print.log('─────────────────────────────────────');

    TransportLocation? closest;
    double minDistance = double.infinity;
    int alertCount = 0;

    for (int i = 0; i < nearbyLocations.length; i++) {
      final crossing = nearbyLocations[i];
      final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
      final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;

      if (crossingLat == 0 || crossingLng == 0) {
        log_print.log('⚠️  Crossing $i: Invalid coordinates, skipping');
        continue;
      }

      final distance = _calculateDistance(
        userLatLng.latitude,
        userLatLng.longitude,
        crossingLat,
        crossingLng,
      ) * 1000; // meters

      log_print.log(
        '📍 Crossing ${i + 1}/${nearbyLocations.length}: '
            '${crossing.street ?? "Unknown"} - ${distance.toStringAsFixed(1)}m',
      );

      if (distance < minDistance) {
        minDistance = distance;
        closest = crossing;
      }

      // ✅ Check if within alert distance
      final alertDistance = settingController.warningDistance.value;

      if (distance < alertDistance) {
        log_print.log('🚨🚨🚨 ALERT TRIGGERED for ${crossing.street}! 🚨🚨🚨');
        await _triggerProximityAlert(crossing, distance);
        alertCount++;
      }
    }

    // Update nearest crossing
    if (closest != null) {
      nearestCrossing.value = closest;
      distanceToNearestCrossing.value = minDistance;
      log_print.log('─────────────────────────────────────');
      log_print.log('✅ Nearest: ${closest.street} at ${minDistance.toStringAsFixed(1)}m');
    }

    log_print.log('─────────────────────────────────────');
    log_print.log('📊 SUMMARY: ${alertCount} alerts triggered');
    log_print.log('╚══════════════════════════════════════╝');
  }
  Future<void> fetchUserLocation() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = "Location services are disabled.";
        isLoading.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        Get.snackbar(
          'Permission Denied',
          'Please allow location access in settings to enable live navigation.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high, // similar to before
          distanceFilter: 0, // meters before updates trigger
        ),
      );
      userPosition.value = pos;

      final currentCityName = await geocoding
          .placemarkFromCoordinates(pos.latitude, pos.longitude)
          .then((placemarks) {
            return placemarks.isNotEmpty
                ? placemarks[0].locality?.toUpperCase() ?? ''
                : '';
          });

      await fetchLocations(cityName: currentCityName);
    } catch (e) {
      errorMessage.value = "Error getting location: $e";
      isLoading.value = false;
    }
  }

  Future<void> fetchLocations({String? cityName = ""}) async {
    try {
      final endpoint =
          "https://data.transportation.gov/resource/vhwz-raag.json?cityname=$cityName";
      final res = await http.get(Uri.parse(endpoint));

      if (res.statusCode == 200 && userPosition.value != null) {
        var data = json.decode(res.body);
        final Map<String, TransportLocation> uniqueLocations = {};

        for (var e in data) {
          if (e['latitude'] == null || e['longitude'] == null) continue;
          if ((e['crossingposition'] ?? '').toString().trim().toLowerCase() !=
              'at grade') {
            continue;
          }

          final switchingTrains =
              int.tryParse(e['totalswitchingtrains']?.toString() ?? '0') ?? 0;
          if (switchingTrains == 0) continue;

          final lat = e['latitude'];
          final lng = e['longitude'];
          final street = (e['street'] ?? '').toString().trim().toLowerCase();
          final key = "$lat,$lng,$street";

          final location = TransportLocation.fromJson(e);
          final newRevisionDate =
              DateTime.tryParse(e['revisiondate'] ?? '') ?? DateTime(1900);

          if (!uniqueLocations.containsKey(key) ||
              newRevisionDate.isAfter(
                DateTime.tryParse(uniqueLocations[key]!.revisiondate ?? '') ??
                    DateTime(1900),
              )) {
            uniqueLocations[key] = location;
          }
        }

        nearbyLocations.assignAll(uniqueLocations.values.toList());
      } else {
        errorMessage.value = "Failed to fetch data.";
      }
    } catch (e) {
      errorMessage.value = "Fetch error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  String destinationGeocoded = '';

  // Future<void> findRoute(String toAddress) async {
  //   try {
  //     routeCoordinates.clear();
  //     crossingsAlongRoute.clear();
  //     upcomingCrossings.clear();
  //     nearestCrossing.value = null;
  //     errorMessage.value = '';
  //     _hasNotifiedApproaching = false;
  //
  //     if (userPosition.value == null) {
  //       throw Exception("Current location not available");
  //     }
  //
  //     final fromLoc = geocoding.Location(
  //       latitude: userPosition.value!.latitude,
  //       longitude: userPosition.value!.longitude,
  //       timestamp: DateTime.now(),
  //     );
  //
  //     final toLocations = await geocoding.locationFromAddress(toAddress);
  //     if (toLocations.isEmpty) {
  //       throw Exception("Could not find destination address");
  //     }
  //     destinationGeocoded = 'Destination geocoded to: ${toLocations.first.latitude}, ${toLocations.first.longitude}';
  //     log_print.log(
  //       "$destinationGeocoded",
  //     );
  //
  //     final toLoc = toLocations.first;
  //
  //     fromLocation.value = LatLng(fromLoc.latitude!, fromLoc.longitude!);
  //     toLocation.value = LatLng(toLoc.latitude!, toLoc.longitude!);
  //     destinationAddress.value = toAddress;
  //     await _savePreferences();
  //
  //     final route = await _getOSRMRoute(fromLocation.value!, toLocation.value!);
  //
  //     if (route['coordinates'] == null || route['coordinates'].isEmpty) {
  //       throw Exception("No route found between these locations");
  //     }
  //
  //     routeCoordinates.assignAll(route['coordinates']);
  //     routeDistance.value = route['distance'] ?? 0.0;
  //     routeDuration.value = route['duration'] ?? 0.0;
  //
  //     await _checkCrossingsAlongRoute();
  //     _sortCrossingsByDistance();
  //
  //     // Start navigation with initial position
  //     _updateRouteProgress();
  //
  //     // Start navigation updates
  //     // isNavigating.value = true;
  //     isRouteReady.value = true;
  //     showNearestCrossingSheet.value = true;
  //     startNavigationUpdates();
  //   } catch (e) {
  //     errorMessage.value = "Route finding error: ${e.toString()}";
  //     routeCoordinates.clear();
  //     crossingsAlongRoute.clear();
  //     isNavigating.value = false;
  //     throw e;
  //   }
  // }
  Future<void> findRoute(String toAddress) async {
    try {
      routeCoordinates.clear();
      crossingsAlongRoute.clear();
      upcomingCrossings.clear();
      nearestCrossing.value = null;
      errorMessage.value = '';
      hasNotifiedApproaching = false;

      if (userPosition.value == null) {
        throw Exception("Current location not available");
      }

      final fromLoc = geocoding.Location(
        latitude: userPosition.value!.latitude,
        longitude: userPosition.value!.longitude,
        timestamp: DateTime.now(),
      );

      final toLocations = await geocoding.locationFromAddress(toAddress);
      if (toLocations.isEmpty) {
        throw Exception("Could not find destination address");
      }
      destinationGeocoded =
          'Destination geocoded to: ${toLocations.first.latitude}, ${toLocations.first.longitude}';
      log_print.log(destinationGeocoded);

      final toLoc = toLocations.first;

      fromLocation.value = LatLng(fromLoc.latitude, fromLoc.longitude);
      toLocation.value = LatLng(toLoc.latitude, toLoc.longitude);
      destinationAddress.value = toAddress;
      await _savePreferences();

      final route = await _getOSRMRoute(fromLocation.value!, toLocation.value!);

      if (route['coordinates'] == null || route['coordinates'].isEmpty) {
        throw Exception("No route found between these locations");
      }

      routeCoordinates.assignAll(route['coordinates']);
      routeDistance.value = route['distance'] ?? 0.0;
      routeDuration.value = route['duration'] ?? 0.0;

      await _checkCrossingsAlongRoute();
      _sortCrossingsByDistance();

      // Start navigation with initial position
      _updateRouteProgress();

      // ✅ CRITICAL FIX: Set route as ready but DON'T start navigation immediately
      isRouteReady.value = true;
      showNearestCrossingSheet.value = true;

      // ❌ REMOVE THIS LINE: Don't start navigation automatically
      // startNavigationUpdates();
    } catch (e) {
      errorMessage.value = "Route finding error: ${e.toString()}";
      routeCoordinates.clear();
      crossingsAlongRoute.clear();
      isNavigating.value = false;
      isRouteReady.value = false; // Also reset this on error
      rethrow;
    }
  }

  // void _checkRouteDeviation() {
  //   if (!isNavigating.value ||
  //       userPosition.value == null ||
  //       routeCoordinates.isEmpty)
  //     return;
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // Find nearest point on route
  //   double minDistance = double.infinity;
  //   for (final point in routeCoordinates) {
  //     final distance =
  //         _calculateDistance(
  //           userLatLng.latitude,
  //           userLatLng.longitude,
  //           point.latitude,
  //           point.longitude,
  //         ) *
  //         1000; // convert to meters
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //     }
  //   }
  //
  //   // If deviated more than 100m, trigger reroute
  //   if (minDistance > 100) {
  //     if (!isRerouting.value) {
  //       isRerouting.value = true;
  //       _rerouteTimer?.cancel();
  //       _rerouteTimer = Timer(Duration(seconds: 3), () async {
  //         if (isRerouting.value && isNavigating.value) {
  //           await _performReroute();
  //           isRerouting.value = false;
  //         }
  //       });
  //
  //       NotificationService().showNotifications(
  //         "Route Deviation",
  //         "You have deviated from the route. Rerouting...",
  //       );
  //     }
  //   } else {
  //     isRerouting.value = false;
  //     _rerouteTimer?.cancel();
  //   }
  // }
  // void _checkRouteDeviation() {
  //   if (!isNavigating.value || userPosition.value == null || routeCoordinates.isEmpty) return;
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // Find nearest point on route
  //   double minDistance = double.infinity;
  //   for (final point in routeCoordinates) {
  //     final distance = _calculateDistance(
  //       userLatLng.latitude,
  //       userLatLng.longitude,
  //       point.latitude,
  //       point.longitude,
  //     ) * 1000; // meters
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //     }
  //   }
  //
  //   // If deviated more than 50m, reroute immediately
  //   if (minDistance > 50) {
  //     if (!isRerouting.value) {
  //       isRerouting.value = true;
  //       _performReroute().then((_) {
  //         isRerouting.value = false;
  //       });
  //       NotificationService().showNotifications(
  //         "Route Deviation",
  //         "You have deviated from the route. Rerouting...",
  //       );
  //     }
  //   }
  // }
  // void _checkRouteDeviation() {
  //   if (!isNavigating.value || userPosition.value == null || routeCoordinates.isEmpty) return;
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // Find nearest point on route more efficiently
  //   double minDistance = double.infinity;
  //   final searchStart = math.max(0, currentRouteStep.value - 10);
  //   final searchEnd = math.min(routeCoordinates.length, currentRouteStep.value + 30);
  //
  //   for (int i = searchStart; i < searchEnd; i++) {
  //     final distance = _calculateDistance(
  //       userLatLng.latitude,
  //       userLatLng.longitude,
  //       routeCoordinates[i].latitude,
  //       routeCoordinates[i].longitude,
  //     ) * 1000; // meters
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //     }
  //   }
  //
  //   // Progressive deviation thresholds based on speed and accuracy
  //   final speed = userPosition.value!.speed;
  //   final accuracy = userPosition.value!.accuracy;
  //
  //   // Dynamic threshold: higher when moving fast or GPS is less accurate
  //   double deviationThreshold = 75; // Base threshold
  //   if (speed > 15) deviationThreshold = 120; // Highway speeds
  //   if (accuracy > 20) deviationThreshold += accuracy; // Add GPS uncertainty
  //
  //   log_print.log('Deviation check: ${minDistance.toStringAsFixed(1)}m from route, threshold: ${deviationThreshold.toStringAsFixed(1)}m');
  //
  //   // Only reroute if significantly deviated AND some time has passed
  //   if (minDistance > deviationThreshold) {
  //     final now = DateTime.now();
  //     if (_lastDeviationTime == null || now.difference(_lastDeviationTime!).inSeconds > 30) {
  //       _lastDeviationTime = now;
  //
  //       if (!isRerouting.value) {
  //         isRerouting.value = true;
  //         log_print.log('Triggering reroute: ${minDistance.toStringAsFixed(1)}m deviation');
  //
  //         // Delay reroute slightly to avoid GPS noise
  //         Timer(Duration(seconds: 3), () async {
  //           if (isRerouting.value && isNavigating.value) {
  //             await _performReroute();
  //             isRerouting.value = false;
  //           }
  //         });
  //
  //         NotificationService().showNotifications(
  //           "Route Deviation",
  //           "You have deviated from the route. Rerouting in 3 seconds...",
  //         );
  //       }
  //     }
  //   } else {
  //     // Back on route
  //     _lastDeviationTime = null;
  //     if (isRerouting.value && minDistance < deviationThreshold * 0.6) {
  //       isRerouting.value = false;
  //     }
  //   }
  // }
  void _checkRouteDeviation() {
    if (!isNavigating.value ||
        userPosition.value == null ||
        routeCoordinates.isEmpty)
      return;

    final userLatLng = LatLng(
      userPosition.value!.latitude,
      userPosition.value!.longitude,
    );

    // search segment window for perpendicular distance
    final searchStart = math.max(0, currentRouteStep.value - 10);
    final searchEnd = math.min(
      routeCoordinates.length - 1,
      currentRouteStep.value + 500,
    );

    double minDistance = double.infinity;
    for (int i = searchStart; i < searchEnd; i++) {
      final segDist = _distanceToSegment(
        userLatLng,
        routeCoordinates[i],
        routeCoordinates[i + 1],
      );
      if (segDist < minDistance) minDistance = segDist;
    }

    final speed = userPosition.value!.speed;
    final accuracy = userPosition.value!.accuracy;

    // dynamic threshold (meters)
    double deviationThreshold = 50.0; // default
    if (speed > 15) deviationThreshold = 120.0;
    if (accuracy > 20) deviationThreshold += accuracy;

    log_print.log(
      'Deviation check: ${(minDistance * 1000).toStringAsFixed(1)}m, threshold: ${deviationThreshold}m',
    );

    if (minDistance * 1000 > deviationThreshold) {
      if (!isRerouting.value) {
        isRerouting.value = true;
        _rerouteTimer?.cancel();
        // short debounce to avoid flapping; quick reroute
        _rerouteTimer = Timer(Duration(milliseconds: 800), () async {
          if (isRerouting.value && isNavigating.value) {
            await _performReroute();
          }
          isRerouting.value = false;
        });

        NotificationService().showNotifications(
          "Route Deviation",
          "You have deviated from the route. Rerouting...",
        );
        log_print.log('Triggering quick reroute (debounced 800ms)');
      }
    } else {
      // if user back on route, cancel pending reroute
      _rerouteTimer?.cancel();
      if (isRerouting.value &&
          (minDistance * 1000) < deviationThreshold * 0.6) {
        isRerouting.value = false;
      }
    }
  }

  // Add this instance variable
  DateTime? _lastDeviationTime;

  // Future<void> _performReroute() async {
  //   if (destinationAddress.value.isEmpty || !isNavigating.value) return;
  //
  //   try {
  //     // Clear existing route but keep destination
  //     final destination = toLocation.value;
  //     routeCoordinates.clear();
  //     crossingsAlongRoute.clear();
  //     upcomingCrossings.clear();
  //
  //     // Get new route from current position
  //     if (userPosition.value != null && destination != null) {
  //       final route = await _getOSRMRoute(
  //         LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
  //         destination,
  //       );
  //
  //       if (route['coordinates'] != null && route['coordinates'].isNotEmpty) {
  //         routeCoordinates.assignAll(route['coordinates']);
  //         await _checkCrossingsAlongRoute();
  //         _sortCrossingsByDistance();
  //         _updateRouteProgress();
  //
  //         NotificationService().showNotifications(
  //           "Route Updated",
  //           "New route calculated successfully",
  //         );
  //       } else {
  //         throw Exception("Could not calculate new route");
  //       }
  //     }
  //   } catch (e) {
  //     NotificationService().showNotifications(
  //       "Reroute Failed",
  //       "Could not calculate new route: ${e.toString()}",
  //     );
  //     // If reroute fails, stop navigation
  //     stopNavigation();
  //   }
  // }
  // Future<void> _performReroute() async {
  //   if (destinationAddress.value.isEmpty || !isNavigating.value) return;
  //
  //   try {
  //     final destination = toLocation.value;
  //     if (userPosition.value != null && destination != null) {
  //       final route = await _getOSRMRoute(
  //         LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
  //         destination,
  //       );
  //
  //       if (route['coordinates'] != null && route['coordinates'].isNotEmpty) {
  //         routeCoordinates.assignAll(route['coordinates']);
  //         await _checkCrossingsAlongRoute();
  //         _sortCrossingsByDistance();
  //         _updateRouteProgress();
  //
  //         NotificationService().showNotifications(
  //           "Route Updated",
  //           "New route calculated successfully",
  //         );
  //       } else {
  //         throw Exception("Could not calculate new route");
  //       }
  //     }
  //   } catch (e) {
  //     NotificationService().showNotifications(
  //       "Reroute Failed",
  //       "Could not calculate new route: ${e.toString()}",
  //     );
  //     stopNavigation();
  //   }
  // }

  // Future<void> _performReroute() async {
  //   if (destinationAddress.value.isEmpty || !isNavigating.value) return;
  //
  //   try {
  //     final destination = toLocation.value;
  //     if (userPosition.value != null && destination != null) {
  //       final from = LatLng(
  //         userPosition.value!.latitude,
  //         userPosition.value!.longitude,
  //       );
  //       final route = await _getOSRMRoute(from, destination);
  //
  //       if (route['coordinates'] != null &&
  //           (route['coordinates'] as List).isNotEmpty) {
  //         routeCoordinates.assignAll(route['coordinates']);
  //         // recompute along-route metrics
  //         _computeCumulativeDistances();
  //         // reset step and visible route (keep buffer)
  //         currentRouteStep.value = 0;
  //         final end = math.min(routeCoordinates.length, 800);
  //         visibleRoute.assignAll(routeCoordinates.sublist(0, end));
  //
  //         await _checkCrossingsAlongRoute();
  //         _sortCrossingsByDistance();
  //         _updateRouteProgress();
  //
  //         // recentre map to current location quickly
  //         if (userPosition.value != null && !hasUserAdjustedZoom.value) {
  //           isProgrammaticMove.value = true;
  //           mapController.move(from, 18);
  //           isProgrammaticMove.value = false;
  //         }
  //
  //         NotificationService().showNotifications(
  //           "Route Updated",
  //           "New route calculated successfully",
  //         );
  //       } else {
  //         throw Exception("Could not calculate new route");
  //       }
  //     }
  //   } catch (e) {
  //     NotificationService().showNotifications(
  //       "Reroute Failed",
  //       "Could not calculate new route: ${e.toString()}",
  //     );
  //     log_print.log('Reroute error: $e');
  //     // do NOT immediately stop navigation; allow user to remain on last route
  //   } finally {
  //     isRerouting.value = false;
  //   }
  // }
  Future<void> _performReroute() async {
    if (destinationAddress.value.isEmpty || !isNavigating.value) return;

    try {
      final destination = toLocation.value;
      if (userPosition.value != null && destination != null) {
        final from = LatLng(
          userPosition.value!.latitude,
          userPosition.value!.longitude,
        );
        final route = await _getOSRMRoute(from, destination);

        if (route['coordinates'] != null &&
            (route['coordinates'] as List).isNotEmpty) {
          // RESET everything when rerouting
          routeCoordinates.assignAll(route['coordinates']);
          visibleRoute.assignAll(route['coordinates']);
          currentRouteStep.value = 0; // Reset to start

          await _checkCrossingsAlongRoute();
          _sortCrossingsByDistance();
          _updateRouteProgress();

          // Recenter map to current location
          if (userPosition.value != null && !hasUserAdjustedZoom.value) {
            isProgrammaticMove.value = true;
            mapController.move(from, 18);
            isProgrammaticMove.value = false;
          }

          NotificationService().showNotifications(
            "Route Updated",
            "New route calculated successfully",
          );
        } else {
          throw Exception("Could not calculate new route");
        }
      }
    } catch (e) {
      NotificationService().showNotifications(
        "Reroute Failed",
        "Could not calculate new route: ${e.toString()}",
      );
      log_print.log('Reroute error: $e');
    } finally {
      isRerouting.value = false;
    }
  }

  // 5. Add method to ensure location tracking stays active
  void ensureLocationTrackingActive() {
    if (_positionStream == null || _positionStream!.isPaused) {
      log_print.log("🔄 Restarting location tracking...");
      _initLocationTracking();
    }
  }

  // Keep this part (initial zoom/follow):
  // void startNavigationUpdates() {
  //   isNavigating.value = true;
  //
  //   // Ensure location tracking is active
  //   ensureLocationTrackingActive();
  //
  //   if (userPosition.value != null) {
  //     isProgrammaticMove.value = true;
  //     mapController.move(
  //       LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
  //       18,
  //     );
  //     isProgrammaticMove.value = false;
  //     hasUserAdjustedZoom.value = false;
  //   }
  //
  //   log_print.log("🚗 Navigation started - location tracking ensured");
  // }
  void startNavigationUpdates() {
    isNavigating.value = true;
    isRouteReady.value = true; // Keep this true during navigation

    // Ensure location tracking is active
    ensureLocationTrackingActive();

    if (userPosition.value != null) {
      isProgrammaticMove.value = true;
      mapController.move(
        LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
        18,
      );
      isProgrammaticMove.value = false;
      hasUserAdjustedZoom.value = false;
    }

    log_print.log("🚗 Navigation started - location tracking ensured");
  }

  // _navigationTimer?.cancel();
  //   _navigationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
  //     if (isNavigating.value && userPosition.value != null) {
  //       _updateRouteProgress();
  //       _checkProximityToCrossings();
  //       _provideVoiceNavigation();
  //       if (!hasUserAdjustedZoom.value) {
  //         isProgrammaticMove.value = true;
  //         mapController.move(
  //           LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
  //           18,
  //         );
  //         isProgrammaticMove.value = false;
  //       }
  //     } else {
  //       timer.cancel();
  //     }
  //   });
  // }
  //(07/10/2025) OLD
  // Future<void> _checkProximityToCrossings() async {
  //   if (userPosition.value == null || crossingsAlongRoute.isEmpty) return;
  //   if (!settingController.isWarningsEnabled.value) {
  //     return; // Skip if warnings disabled
  //   }
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // Find nearest crossing
  //   TransportLocation? closest;
  //   double minDistance = double.infinity;
  //
  //   for (final crossing in crossingsAlongRoute) {
  //     final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
  //     final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;
  //
  //     if (crossingLat == 0 || crossingLng == 0) continue;
  //
  //     final distance =
  //         _calculateDistance(
  //           userLatLng.latitude,
  //           userLatLng.longitude,
  //           crossingLat,
  //           crossingLng,
  //         ) *
  //         1000; // convert to meters
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //       closest = crossing;
  //     }
  //
  //     // Use the warning distance from settings
  //     if (distance < settingController.warningDistance.value) {
  //       final message =
  //           "Warning: Railway Crossing Ahead - ${crossing.street ?? 'railway crossing'} (${formatDistance(distance)})";
  //
  //       // Always show notification regardless of sound setting
  //       await NotificationService().showNotifications(
  //         "Railway Crossing Warning",
  //         message,
  //       );
  //
  //       // Play sound if enabled
  //       if (settingController.isWarningSoundEnabled.value) {
  //         await player.stop();
  //         await player.setVolume(1.0);
  //         await player.play();
  //       }
  //
  //       // Vibrate if enabled
  //       if (settingController.isVibrationEnabled.value &&
  //           await Vibration.hasVibrator()) {
  //         if (distance < 50) {
  //           // Immediate danger
  //           Vibration.vibrate(
  //             pattern: [500, 1000, 500, 1000],
  //           ); // Strong vibration pattern
  //         } else {
  //           Vibration.vibrate(duration: 500); // Standard vibration
  //         }
  //       }
  //     }
  //   }
  //
  //   // Update nearest crossing
  //   if (closest != null) {
  //     nearestCrossing.value = closest;
  //     distanceToNearestCrossing.value = minDistance;
  //   }
  // }
  //(07/10/2025) NEW
  // Modify _checkProximityToCrossings to use consistent alert method
  //13/10/2025
  // Future<void> _checkProximityToCrossings() async {
  //   if (userPosition.value == null || crossingsAlongRoute.isEmpty) return;
  //   if (!settingController.isWarningsEnabled.value) {
  //     return; // Skip if warnings disabled
  //   }
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // Find nearest crossing
  //   TransportLocation? closest;
  //   double minDistance = double.infinity;
  //
  //   for (final crossing in crossingsAlongRoute) {
  //     final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
  //     final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;
  //
  //     if (crossingLat == 0 || crossingLng == 0) continue;
  //
  //     final distance = _calculateDistance(
  //       userLatLng.latitude,
  //       userLatLng.longitude,
  //       crossingLat,
  //       crossingLng,
  //     ) * 1000;
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //       closest = crossing;
  //     }
  //
  //     // Use consistent 100m threshold
  //     if (distance < 100) {
  //       await _triggerProximityAlert(crossing, distance);
  //     }
  //   }
  //
  //   // Update nearest crossing
  //   if (closest != null) {
  //     nearestCrossing.value = closest;
  //     distanceToNearestCrossing.value = minDistance;
  //   }
  // }
  Future<void> _checkProximityToCrossings() async {
    if (userPosition.value == null) return;

    // ✅ Check crossings even if crossingsAlongRoute is empty (app might have restarted)
    final crossingsToCheck = crossingsAlongRoute.isNotEmpty
        ? crossingsAlongRoute
        : nearbyLocations;

    if (crossingsToCheck.isEmpty) return;
    if (!settingController.isWarningsEnabled.value) return;

    final userLatLng = LatLng(
      userPosition.value!.latitude,
      userPosition.value!.longitude,
    );

    TransportLocation? closest;
    double minDistance = double.infinity;

    for (final crossing in crossingsToCheck) {
      final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
      final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;

      if (crossingLat == 0 || crossingLng == 0) continue;

      final distance = _calculateDistance(
        userLatLng.latitude,
        userLatLng.longitude,
        crossingLat,
        crossingLng,
      ) * 1000;

      if (distance < minDistance) {
        minDistance = distance;
        closest = crossing;
      }

      // Trigger alert within threshold
      if (distance < settingController.warningDistance.value) {
        log_print.log("🔔 Proximity alert: ${crossing.street} at ${distance.toStringAsFixed(1)}m");
        await _triggerProximityAlert(crossing, distance);
      }
    }

    // Update nearest crossing
    if (closest != null) {
      nearestCrossing.value = closest;
      distanceToNearestCrossing.value = minDistance;

      // ✅ Update background notification with nearest crossing
      if (!Get.context!.mounted) { // App is in background
        await _updateBackgroundNotification();
      }
    }
  }
  String distanceTemp = '';
  List<String> distanceLogs = [];
  String routeProgressStart = 'Update route progress';

  // void _updateRouteProgress() {
  //   log_print.log("$routeProgressStart");
  //   if (userPosition.value == null || routeCoordinates.isEmpty) return;
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // Find the closest point on the route to the user
  //   double minDistance = double.infinity;
  //   int closestIndex = -1;
  //
  //   for (int i = 0; i < routeCoordinates.length; i++) {
  //     final distance = _calculateDistance(
  //       userLatLng.latitude,
  //       userLatLng.longitude,
  //       routeCoordinates[i].latitude,
  //       routeCoordinates[i].longitude,
  //     );
  //
  //     distanceTemp = distance.toString();
  //      log_print.log("distanceTemp----------${distanceTemp}");
  //
  //     distanceLogs.add(distanceTemp);
  //     log_print.log("distanceLogs----------${distanceLogs}");
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //       closestIndex = i;
  //     }
  //   }
  //   // Only proceed if we're reasonably close to the route (within 20 meters)
  //   if (minDistance * 1000 > 20) return;
  //
  //   // Only if we're moving forward along the route
  //   if (closestIndex > currentRouteStep.value && closestIndex >= 0) {
  //     // Check if the closest route point is already behind the user
  //     final pointAheadDistance =
  //         _calculateDistance(
  //           routeCoordinates[closestIndex].latitude,
  //           routeCoordinates[closestIndex].longitude,
  //           userLatLng.latitude,
  //           userLatLng.longitude,
  //         ) *
  //         1000; // meters
  //
  //     // If negative or less than -30, it means we're at least 30m past it
  //     // if (pointAheadDistance < -30) {
  //     final removedPoints = closestIndex - currentRouteStep.value;
  //     routeCoordinates.removeRange(0, removedPoints);
  //     currentRouteStep.value = closestIndex;
  //     // }
  //   }
  //
  //   _updateUpcomingCrossings();
  // }
  // Trimmed route that updates as you move
  final RxList<LatLng> visibleRoute = <LatLng>[].obs;
  final List<double> _cumulativeDistances = <double>[]; // meters
  void _computeCumulativeDistances() {
    _cumulativeDistances.clear();
    if (routeCoordinates.isEmpty) return;
    _cumulativeDistances.add(0.0);
    for (int i = 1; i < routeCoordinates.length; i++) {
      final d =
          _calculateDistance(
            routeCoordinates[i - 1].latitude,
            routeCoordinates[i - 1].longitude,
            routeCoordinates[i].latitude,
            routeCoordinates[i].longitude,
          ) *
          1000.0; // to meters
      _cumulativeDistances.add(_cumulativeDistances[i - 1] + d);
    }
  }

  double _distanceToSegment(LatLng p, LatLng v, LatLng w) {
    final vx = v.latitude, vy = v.longitude;
    final wx = w.latitude, wy = w.longitude;
    final px = p.latitude, py = p.longitude;

    // convert lat/lng differences to approximate meters via haversine is heavier;
    // use projection formula on lat/lon (good enough for short segments)
    final dx = wx - vx;
    final dy = wy - vy;
    if (dx == 0 && dy == 0) {
      // v == w
      return _calculateDistance(px, py, vx, vy);
    }
    // t = projection parameter
    final t = ((px - vx) * dx + (py - vy) * dy) / (dx * dx + dy * dy);
    final tClamped = t.clamp(0.0, 1.0);
    final projX = vx + tClamped * dx;
    final projY = vy + tClamped * dy;
    return _calculateDistance(px, py, projX, projY);
  }

  // void _updateRouteProgress() {
  //   if (userPosition.value == null || routeCoordinates.isEmpty) return;
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // search window around the current step (more ahead room)
  //   final searchStart = math.max(0, currentRouteStep.value - 5);
  //   final searchEnd = math.min(routeCoordinates.length, currentRouteStep.value + 200);
  //
  //   double minDistance = double.infinity;
  //   int closestIndex = -1;
  //
  //   // first try the window
  //   for (int i = searchStart; i < searchEnd; i++) {
  //     final d = _calculateDistance(
  //       userLatLng.latitude,
  //       userLatLng.longitude,
  //       routeCoordinates[i].latitude,
  //       routeCoordinates[i].longitude,
  //     );
  //     if (d < minDistance) {
  //       minDistance = d;
  //       closestIndex = i;
  //     }
  //   }
  //
  //   // If nothing found in window (rare), fall back to full route scan:
  //   if (closestIndex < 0) {
  //     for (int i = 0; i < routeCoordinates.length; i++) {
  //       final d = _calculateDistance(
  //         userLatLng.latitude,
  //         userLatLng.longitude,
  //         routeCoordinates[i].latitude,
  //         routeCoordinates[i].longitude,
  //       );
  //       if (d < minDistance) {
  //         minDistance = d;
  //         closestIndex = i;
  //       }
  //     }
  //   }
  //
  //   // If user is very far from route, skip progress update (avoid bad trimming)
  //   if (minDistance * 1000 > 250) {
  //     log_print.log('User too far from route: ${(minDistance * 1000).toStringAsFixed(1)}m');
  //     return;
  //   }
  //
  //   if (closestIndex >= 0) {
  //     final oldStep = currentRouteStep.value;
  //
  //     // Only advance forward — never move the "current step" backwards (prevents re-expanding)
  //     if (closestIndex > oldStep) {
  //       // check along-route distance progressed (requires cumulative distances)
  //       double progressedMeters = 0.0;
  //       if (_cumulativeDistances.isNotEmpty &&
  //           oldStep < _cumulativeDistances.length &&
  //           closestIndex < _cumulativeDistances.length) {
  //         progressedMeters = _cumulativeDistances[closestIndex] - _cumulativeDistances[oldStep];
  //       }
  //
  //       // require a small along-route progress (e.g., > 8 meters) before trimming
  //       if (progressedMeters > 8.0) {
  //         final trimIndex = math.max(0, closestIndex - 3); // keep 3 points behind
  //         final endIndex = math.min(routeCoordinates.length, trimIndex + 800); // cap visible length
  //         visibleRoute.assignAll(routeCoordinates.sublist(trimIndex, endIndex));
  //         currentRouteStep.value = trimIndex;
  //         log_print.log('🔄 Route trimmed to index $trimIndex (progressed ${progressedMeters.toStringAsFixed(1)}m)');
  //       }
  //     } else if (visibleRoute.isEmpty) {
  //       // initial fill
  //       final endIndex = math.min(routeCoordinates.length, closestIndex + 800);
  //       visibleRoute.assignAll(routeCoordinates.sublist(closestIndex, endIndex));
  //     }
  //   }
  //
  //   _updateUpcomingCrossings();
  //
  //   if (kDebugMode && isNavigating.value) {
  //     log_print.log('📊 Route Progress updated: step ${currentRouteStep.value}/${routeCoordinates.length}, distanceFromRoute ${(minDistance * 1000).toStringAsFixed(1)}m, visible ${visibleRoute.length}');
  //   }
  // }

  void _updateRouteProgress() {
    if (userPosition.value == null || routeCoordinates.isEmpty) return;

    final userLatLng = LatLng(
      userPosition.value!.latitude,
      userPosition.value!.longitude,
    );

    double minDistance = double.infinity;
    int closestIndex = -1;

    // Search more efficiently
    final searchStart = math.max(0, currentRouteStep.value - 5);
    final searchEnd = math.min(routeCoordinates.length, searchStart + 50);

    for (int i = searchStart; i < searchEnd; i++) {
      final distance = _calculateDistance(
        userLatLng.latitude,
        userLatLng.longitude,
        routeCoordinates[i].latitude,
        routeCoordinates[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // More lenient distance check - allow up to 200m from route
    if (minDistance * 1000 > 200) {
      log_print.log(
        'User too far from route: ${(minDistance * 1000).toStringAsFixed(1)}m',
      );
      return;
    }

    // Always update if we found a valid point
    if (closestIndex >= 0) {
      final oldStep = currentRouteStep.value;
      currentRouteStep.value = closestIndex;
      visibleRoute.assignAll(routeCoordinates.sublist(closestIndex));
      // Trim route more aggressively for better performance
      // if (closestIndex > oldStep) {
      //   final trimPoint = math.max(0, closestIndex); // Keep 3 points behind
      //   visibleRoute.assignAll(routeCoordinates.sublist(trimPoint));
      //   log_print.log(
      //     '🔄 Route trimmed: keeping ${visibleRoute.length} points from index $trimPoint',
      //   );
      // } else if (visibleRoute.isEmpty) {
      //   // Initialize visible route if empty
      //   visibleRoute.assignAll(routeCoordinates.sublist(closestIndex));
      // }
    }

    _updateUpcomingCrossings();

    if (kDebugMode && isNavigating.value) {
      log_print.log(
        '📊 Route Progress: Step $closestIndex/${routeCoordinates.length}, '
        'Distance from route: ${(minDistance * 1000).toStringAsFixed(1)}m, '
        'Visible points: ${visibleRoute.length}',
      );
    }
  }

  // void _updateRouteProgress() {
  //   if (userPosition.value == null || routeCoordinates.isEmpty) return;
  //
  //   final userLatLng = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   double minDistance = double.infinity;
  //   int closestIndex = -1;
  //
  //   // Search for closest point on route
  //   final searchStart = math.max(0, currentRouteStep.value - 5);
  //   final searchEnd = math.min(routeCoordinates.length, currentRouteStep.value + 100);
  //
  //   for (int i = searchStart; i < searchEnd; i++) {
  //     final distance = _calculateDistance(
  //       userLatLng.latitude,
  //       userLatLng.longitude,
  //       routeCoordinates[i].latitude,
  //       routeCoordinates[i].longitude,
  //     );
  //
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //       closestIndex = i;
  //     }
  //   }
  //
  //   // Only proceed if we're reasonably close to the route
  //   if (minDistance * 1000 > 150) {
  //     log_print.log('User too far from route: ${(minDistance * 1000).toStringAsFixed(1)}m');
  //     return;
  //   }
  //
  //   if (closestIndex >= 0) {
  //     // Only advance if we've moved forward significantly
  //     if (closestIndex > currentRouteStep.value ) { // Require moving at least 5 points ahead
  //       // Calculate how far we've progressed along the route
  //       double progressDistance = 0.0;
  //       for (int i = currentRouteStep.value; i < closestIndex; i++) {
  //         if (i + 1 < routeCoordinates.length) {
  //           progressDistance += _calculateDistance(
  //             routeCoordinates[i].latitude,
  //             routeCoordinates[i].longitude,
  //             routeCoordinates[i + 1].latitude,
  //             routeCoordinates[i + 1].longitude,
  //           ) * 1000; // Convert to meters
  //         }
  //       }
  //
  //       // Only trim if we've progressed at least 20 meters along the route
  //       if (progressDistance > 0.5) {
  //         // Update current step
  //         currentRouteStep.value = closestIndex;
  //
  //         // CRITICAL FIX: Properly trim the route
  //         // Keep a small buffer behind (10 points) and reasonable ahead distance
  //         final trimStart = math.max(0, closestIndex);
  //         final remainingRoute = routeCoordinates.sublist(trimStart);
  //
  //         // Update both the main route and visible route
  //         routeCoordinates.assignAll(remainingRoute);
  //         visibleRoute.assignAll(remainingRoute);
  //
  //         // Adjust currentRouteStep relative to new trimmed route
  //         currentRouteStep.value = closestIndex - trimStart;
  //
  //         log_print.log('🔥 Route trimmed: Removed ${trimStart} points, keeping ${remainingRoute.length} points');
  //         log_print.log('📍 New current step: ${currentRouteStep.value}');
  //       }
  //     } else if (visibleRoute.isEmpty) {
  //       // Initialize visible route if empty
  //       visibleRoute.assignAll(routeCoordinates);
  //     }
  //   }
  //
  //   _updateUpcomingCrossings();
  //
  //   if (kDebugMode && isNavigating.value) {
  //     log_print.log(
  //         '📊 Route Progress: Step ${currentRouteStep.value}/${routeCoordinates.length}, '
  //             'Distance from route: ${(minDistance * 1000).toStringAsFixed(1)}m, '
  //             'Total route points: ${routeCoordinates.length}'
  //     );
  //   }
  // }
  // // Add these instance variables to your controller
  //   LatLng? _lastTrimLocation;
  //   DateTime? _lastTrimTime;
  // // Add this helper method to improve performance
  //   bool _hasUserMovedSignificantly() {
  //     if (_lastTrimLocation == null || userPosition.value == null) return true;
  //
  //     final distance = _calculateDistance(
  //       _lastTrimLocation!.latitude,
  //       _lastTrimLocation!.longitude,
  //       userPosition.value!.latitude,
  //       userPosition.value!.longitude,
  //     ) * 1000;
  //
  //     return distance > 15; // Only process if moved more than 15 meters
  //   }
  List<String> distanceLogsUpdated = [];

  void _updateUpcomingCrossings() {
    upcomingCrossings.assignAll(
      crossingsAlongRoute.where((crossing) {
        final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
        final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;

        // Check if crossing is ahead on the route
        for (final point in routeCoordinates) {
          final distance =
              _calculateDistance(
                point.latitude,
                point.longitude,
                crossingLat,
                crossingLng,
              ) *
              1000; // convert to meters
          distanceLogsUpdated.add(distance.toString());
          log_print.log("distanceLogsUpdated----------$distanceLogsUpdated");
          if (distance < 300) {
            // 300m threshold
            return true;
          }
        }
        return false;
      }).toList(),
    );

    _sortCrossingsByDistance();
  }

  void _sortCrossingsByDistance() {
    if (userPosition.value == null) return;

    final userLatLng = LatLng(
      userPosition.value!.latitude,
      userPosition.value!.longitude,
    );

    crossingsAlongRoute.sort((a, b) {
      final latA = double.tryParse(a.latitude ?? '0') ?? 0;
      final lngA = double.tryParse(a.longitude ?? '0') ?? 0;
      final latB = double.tryParse(b.latitude ?? '0') ?? 0;
      final lngB = double.tryParse(b.longitude ?? '0') ?? 0;

      final distA = _calculateDistance(
        userLatLng.latitude,
        userLatLng.longitude,
        latA,
        lngA,
      );
      final distB = _calculateDistance(
        userLatLng.latitude,
        userLatLng.longitude,
        latB,
        lngB,
      );

      return distA.compareTo(distB);
    });

    upcomingCrossings.sort((a, b) {
      final latA = double.tryParse(a.latitude ?? '0') ?? 0;
      final lngA = double.tryParse(a.longitude ?? '0') ?? 0;
      final latB = double.tryParse(b.latitude ?? '0') ?? 0;
      final lngB = double.tryParse(b.longitude ?? '0') ?? 0;

      final distA = _calculateDistance(
        userLatLng.latitude,
        userLatLng.longitude,
        latA,
        lngA,
      );
      final distB = _calculateDistance(
        userLatLng.latitude,
        userLatLng.longitude,
        latB,
        lngB,
      );

      return distA.compareTo(distB);
    });
  }

  Future<void> _checkCrossingsAlongRoute() async {
    if (routeCoordinates.isEmpty || nearbyLocations.isEmpty) return;

    final nearby = <TransportLocation>[];

    for (final crossing in nearbyLocations) {
      final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
      final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;
      if (crossingLat == 0 || crossingLng == 0) continue;

      double minDistance = double.infinity;
      for (final routePoint in routeCoordinates) {
        final distance =
            _calculateDistance(
              routePoint.latitude,
              routePoint.longitude,
              crossingLat,
              crossingLng,
            ) *
            1000;

        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      if (minDistance < 300) {
        nearby.add(crossing);
      }
    }

    crossingsAlongRoute.assignAll(nearby);

    if (nearby.isNotEmpty) {
      await NotificationService().showNotifications(
        "Railroad Crossing Alert",
        "Your route is close to ${nearby.length} railroad crossing(s).",
      );
    }
  }

  final RxList<Map<String, dynamic>> navSteps = <Map<String, dynamic>>[].obs;
  final RxInt currentStepIndex = 0.obs;
  String routingResponse = '';

  // Future<Map<String, dynamic>> _getOSRMRoute(LatLng from, LatLng to) async {
  //   try {
  //     final url = Uri.parse(
  //       'https://router.project-osrm.org/route/v1/driving/'
  //           '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
  //           '?overview=full&steps=true&geometries=polyline',
  //     );
  //
  //     final response = await http.get(url);
  //     if (response.statusCode != 200) {
  //       throw Exception("Failed to get route: ${response.statusCode}");
  //     }
  //
  //     final data = json.decode(response.body);
  //     if (data['routes'] == null || data['routes'].isEmpty) {
  //       throw Exception("No route found");
  //     }
  //
  //     final route = data['routes'][0];
  //     final legs = route['legs'] as List;
  //     final steps = legs.isNotEmpty ? legs[0]['steps'] as List : [];
  //
  //     navSteps.assignAll(
  //       steps.map((s) {
  //         final stepMap = Map<String, dynamic>.from(s as Map);
  //
  //         // Convert step geometry to LatLng if coordinates exist
  //         if (stepMap['geometry'] != null && stepMap['geometry']['coordinates'] != null) {
  //           final coords = stepMap['geometry']['coordinates'] as List;
  //           if (coords.isNotEmpty) {
  //             // Use the first coordinate as the step location
  //             stepMap['location'] = LatLng(
  //               coords[0][1].toDouble(), // latitude
  //               coords[0][0].toDouble(), // longitude
  //             );
  //           }
  //         }
  //
  //         // Fallback: use maneuver location if available
  //         if (stepMap['location'] == null && stepMap['maneuver'] != null) {
  //           final maneuver = stepMap['maneuver'] as Map;
  //           if (maneuver['location'] != null) {
  //             final loc = maneuver['location'] as List;
  //             stepMap['location'] = LatLng(
  //               loc[1].toDouble(), // latitude
  //               loc[0].toDouble(), // longitude
  //             );
  //           }
  //         }
  //
  //         return stepMap;
  //       }).toList(),
  //     );
  //
  //     return {
  //       'coordinates': _decodePolyline(route['geometry'] ?? ''),
  //       'distance': (route['distance'] as num?)?.toDouble(),
  //       'duration': ((route['duration'] as num?)?.toDouble() ?? 0) / 60.0,
  //       'steps': steps,
  //     };
  //   } catch (e) {
  //     log_print.log("OSRM error: $e");
  //     rethrow;
  //   }
  // }
  Future<Map<String, dynamic>> _getOSRMRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&steps=true&geometries=polyline',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception("Failed to get route: ${response.statusCode}");
      }

      final data = json.decode(response.body);
      if (data['routes'] == null || data['routes'].isEmpty) {
        throw Exception("No route found");
      }

      final route = data['routes'][0];
      final legs = route['legs'] as List;
      final steps = legs.isNotEmpty ? legs[0]['steps'] as List : [];

      // Improved step processing with proper location conversion
      navSteps.assignAll(
        steps.map((s) {
          final stepMap = Map<String, dynamic>.from(s as Map);

          // Extract location from maneuver if available
          if (stepMap['maneuver'] != null) {
            final maneuver = stepMap['maneuver'] as Map;
            if (maneuver['location'] != null) {
              final loc = maneuver['location'] as List;
              if (loc.length >= 2) {
                stepMap['location'] = LatLng(
                  _parseDouble(loc[1]), // latitude
                  _parseDouble(loc[0]), // longitude
                );
              }
            }
          }

          return stepMap;
        }).toList(),
      );

      // Get the geometry and decode it properly
      final geometry = route['geometry'] as String?;
      final coordinates = geometry != null ? _decodePolyline(geometry) : [];

      return {
        'coordinates': coordinates,
        'distance': _parseDouble(route['distance']),
        'duration': _parseDouble(route['duration']) / 60.0,
        'steps': steps,
      };
    } catch (e) {
      log_print.log("OSRM error: $e");
      rethrow;
    }
  }

  // Helper method to safely parse numbers that could be int or string
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // List<LatLng> _decodePolyline(String polyline) {
  //   List<LatLng> points = [];
  //   int index = 0, len = polyline.length;
  //   int lat = 0, lng = 0;
  //
  //   while (index < len) {
  //     int b, shift = 0, result = 0;
  //     do {
  //       b = polyline.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1f) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  //     lat += dLat;
  //
  //     shift = 0;
  //     result = 0;
  //     do {
  //       b = polyline.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1f) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  //     lng += dLng;
  //
  //     points.add(LatLng(lat / 1E5, lng / 1E5));
  //   }
  //
  //   return points;
  // }
  // Improved polyline decoding that handles string/int values
  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Radius of Earth in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  bool hasNotifiedClose = false;
  bool hasNotifiedImmediate = false;

  // Add this method with your other helper methods
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * (pi / 180);
    final y = sin(dLon) * cos(lat2 * (pi / 180));
    final x =
        cos(lat1 * (pi / 180)) * sin(lat2 * (pi / 180)) -
        sin(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * cos(dLon);
    return atan2(y, x) * (180 / pi);
  }

  // void stopNavigation() {
  //   isNavigating.value = false;
  //   isRouteReady.value = false; // ✅ Reset this when navigation stops
  //   _navigationTimer?.cancel();
  //   _rerouteTimer?.cancel();
  //   upcomingCrossings.clear();
  //   nearestCrossing.value = null;
  //   showNearestCrossingSheet.value = false;
  //   routeCoordinates.clear();
  //   crossingsAlongRoute.clear();
  //   hasNotifiedApproaching = false;
  //   hasNotifiedClose = false;
  //   hasNotifiedImmediate = false;
  //   _announcedTurns.clear();
  //
  //   if (userPosition.value != null) {
  //     mapController.move(
  //       LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
  //       15,
  //     );
  //   }
  //
  //   hasUserAdjustedZoom.value = false;
  // }
  void stopNavigation() {
    isNavigating.value = false;
    isRouteReady.value = false;

    // Cancel all timers
    _navigationTimer?.cancel();
    _backgroundTimer?.cancel();
    _rerouteTimer?.cancel();

    // Stop vibration immediately and completely
    _stopAllVibration();

    // Clear ALL route-related data
    routeCoordinates.clear();
    visibleRoute.clear();
    crossingsAlongRoute.clear();
    upcomingCrossings.clear();
    nearestCrossing.value = null;
    navSteps.clear();

    // Reset navigation state
    currentRouteStep.value = 0;
    currentStepIndex.value = 0;
    showNearestCrossingSheet.value = false;

    // Reset notification flags
    hasNotifiedApproaching = false;
    hasNotifiedClose = false;
    hasNotifiedImmediate = false;
    _announcedTurns.clear();

    // Stop any playing audio
    player.stop();

    // Reset destination but keep the address for potential reuse
    // destinationAddress.value = ''; // Don't clear this if you want to reuse
    toLocation.value = null;

    // Reset map to normal view
    if (userPosition.value != null) {
      isProgrammaticMove.value = true;
      mapController.move(
        LatLng(userPosition.value!.latitude, userPosition.value!.longitude),
        15,
      );
      isProgrammaticMove.value = false;
    }

    hasUserAdjustedZoom.value = false;

    // CRITICAL: Stop any ongoing vibration patterns
    Vibration.cancel();

    log_print.log(
      "🛑 Navigation stopped - all data cleared and vibrations stopped",
    );
  }

  // Enhanced vibration stopping
  Future<void> _stopAllVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.cancel();
        // Add a small delay and cancel again to ensure it stops
        await Future.delayed(Duration(milliseconds: 100));
        Vibration.cancel();
      }
    } catch (e) {
      log_print.log("Error stopping vibration: $e");
    }
  }

  void toggleNearestCrossingSheet() {
    showNearestCrossingSheet.value = !showNearestCrossingSheet.value;
  }

  RxBool isProgrammaticMove = false.obs;
  LatLng? _lastFetchCenter;

  void onMapMoved(MapPosition position) {
    final zoom = position.zoom ?? 10.0;
    currentZoom.value = zoom;

    if (isNavigating.value && !isProgrammaticMove.value) {
      hasUserAdjustedZoom.value = true;
    }

    final newCenter = position.center;
    if (newCenter != null &&
        (_lastFetchCenter == null ||
            _calculateDistance(
                  _lastFetchCenter!.latitude,
                  _lastFetchCenter!.longitude,
                  newCenter.latitude,
                  newCenter.longitude,
                ) >
                2.0)) // 2 km threshold
    {
      _lastFetchCenter = newCenter;
      _fetchCrossingsForViewArea(newCenter);
    }
  }

  Future<void> _fetchCrossingsForViewArea(LatLng center) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        center.latitude,
        center.longitude,
      );
      final city =
          placemarks.isNotEmpty ? placemarks[0].locality?.toUpperCase() : '';
      await fetchLocations(cityName: city ?? "");
    } catch (e) {
      log_print.log("Failed to fetch crossings for new area: $e");
    }
  }

  // // Show background notification
  // Future<void> _showBackgroundNotification(
  //     String title,
  //     String body,
  //     bool isVibrationEnabled,
  //     double distance,
  //     ) async {
  //   try {
  //     final AndroidNotificationDetails androidPlatformChannelSpecifics =
  //     AndroidNotificationDetails(
  //       'railway_crossing_alerts',
  //       'Railway Crossing Alerts',
  //       channelDescription: 'Notifications for nearby railway crossings',
  //       importance: Importance.high,
  //       priority: Priority.high,
  //       enableLights: true,
  //       enableVibration: isVibrationEnabled,
  //       vibrationPattern:
  //       distance < 50
  //           ? Int64List.fromList([500, 1000, 500, 1000])
  //           : Int64List.fromList([500]),
  //       autoCancel: true,
  //       showWhen: true,
  //     );
  //
  //     NotificationDetails platformChannelSpecifics = NotificationDetails(
  //       android: androidPlatformChannelSpecifics,
  //     );
  //
  //     final FlutterLocalNotificationsPlugin localNotifications =
  //     FlutterLocalNotificationsPlugin();
  //
  //     await localNotifications.show(
  //       DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
  //       title,
  //       body,
  //       platformChannelSpecifics,
  //     );
  //
  //     log_print.log("Background notification shown: $title - $body");
  //   } catch (e) {
  //     log_print.log("Error showing background notification: $e");
  //   }
  // }

  // Calculate distance in background
  // double _calculateDistanceInBackground(
  //     double lat1,
  //     double lon1,
  //     double lat2,
  //     double lon2,
  //     ) {
  //   const R = 6371; // Radius of Earth in km
  //   final dLat = (lat2 - lat1) * (pi / 180.0);
  //   final dLon = (lon2 - lon1) * (pi / 180.0);
  //   final a =
  //       sin(dLat / 2) * sin(dLat / 2) +
  //           cos(lat1 * (pi / 180.0)) *
  //               cos(lat2 * (pi / 180.0)) *
  //               sin(dLon / 2) *
  //               sin(dLon / 2);
  //   final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  //   return R * c;
  // }

  Future<void> speak(String text) async {
    if (settingController.isWarningSoundEnabled.value) {
      await NotificationService().speak(text);
    }
  }

  final RxMap<String, bool> _announcedTurns = <String, bool>{}.obs;

  // final double _farTurnAnnouncementDistance = 200; // meters
  // final double _nearTurnAnnouncementDistance = 50; // meters
  //10/10/2025
  // void _provideVoiceNavigation() {
  //   if (userPosition.value == null || navSteps.isEmpty) return;
  //
  //   final user = LatLng(
  //     userPosition.value!.latitude,
  //     userPosition.value!.longitude,
  //   );
  //
  //   // Advance to the next step if we passed the current one
  //   while (currentStepIndex.value < navSteps.length) {
  //     final step = navSteps[currentStepIndex.value];
  //
  //     // Safe location extraction
  //     LatLng? stepLocation;
  //     if (step['location'] is LatLng) {
  //       stepLocation = step['location'] as LatLng;
  //     } else if (step['maneuver'] != null) {
  //       final maneuver = step['maneuver'] as Map;
  //       if (maneuver['location'] is List) {
  //         final loc = maneuver['location'] as List;
  //         if (loc.length >= 2) {
  //           stepLocation = LatLng(_parseDouble(loc[1]), _parseDouble(loc[0]));
  //         }
  //       }
  //     }
  //
  //     if (stepLocation == null) {
  //       currentStepIndex.value++;
  //       continue;
  //     }
  //
  //     final d =
  //         _calculateDistance(
  //           user.latitude,
  //           user.longitude,
  //           stepLocation.latitude,
  //           stepLocation.longitude,
  //         ) *
  //         1000.0; // meters
  //
  //     if (d < 15) {
  //       currentStepIndex.value++;
  //       continue;
  //     }
  //
  //     // Announce at 200m and 50m for the *current* step
  //     final key = "${currentStepIndex.value}";
  //     if (d <= 200 && d > 50 && (_announcedTurns[key] != true)) {
  //       final dir = _formatManeuver(step);
  //       speak("$dir in 200 meters");
  //       _announcedTurns[key] = true;
  //     } else if (d <= 50 && (_announcedTurns["${key}_now"] != true)) {
  //       final dir = _formatManeuver(step);
  //       speak("Now $dir");
  //       _announcedTurns["${key}_now"] = true;
  //     }
  //     break;
  //   }
  // }
  void _provideVoiceNavigation() {
    if (userPosition.value == null || navSteps.isEmpty) return;

    final user = LatLng(
      userPosition.value!.latitude,
      userPosition.value!.longitude,
    );

    // Find current step based on route progress
    int closestStepIndex = _findClosestStepIndex(user);

    if (closestStepIndex < 0 || closestStepIndex >= navSteps.length) return;

    final step = navSteps[closestStepIndex];
    final distanceToStep = _calculateDistanceToStep(user, step);

    // Announce turns at appropriate distances
    if (distanceToStep > 0) {
      _announceStepIfNeeded(step, closestStepIndex, distanceToStep);
    }
  }
  double _calculateDistanceToStep(LatLng userPosition, Map<String, dynamic> step) {
    final stepLocation = _extractStepLocation(step);
    if (stepLocation == null) return -1;

    return _calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      stepLocation.latitude,
      stepLocation.longitude,
    ) * 1000;
  }
  void _announceStepIfNeeded(Map<String, dynamic> step, int stepIndex, double distance) {
    final stepKey = stepIndex.toString();
    final maneuverType = _getManeuverType(step);

    // Skip "continue" steps for minor maneuvers
    if (maneuverType == 'continue' || maneuverType == 'depart') {
      return;
    }

    

    // Announce at 200m for significant turns
    if (distance <= 200 && distance > 50 && !_announcedTurns.containsKey(stepKey)) {
      final instruction = _getTurnInstruction(step);
      speak("$instruction in 200 meters");
      _announcedTurns[stepKey] = true;
      log_print.log("🔊 Voice: $instruction in 200 meters");
    }
    // Announce at 50m
    else if (distance <= 50 && !_announcedTurns.containsKey('${stepKey}_now')) {
      final instruction = _getTurnInstruction(step);
      speak("Now $instruction");
      _announcedTurns['${stepKey}_now'] = true;
      log_print.log("🔊 Voice: Now $instruction");
    }
  }
  String _getManeuverType(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map?;
    if (maneuver != null && maneuver['type'] is String) {
      return (maneuver['type'] as String).toLowerCase();
    }
    return 'continue';
  }

  String _getTurnInstruction(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map?;

    if (maneuver != null) {
      final type = (maneuver['type'] as String? ?? '').toLowerCase();
      final modifier = (maneuver['modifier'] as String? ?? '').toLowerCase();

      // Handle specific turn types
      if (type.contains('turn') || type.contains('merge') || type.contains('fork')) {
        if (modifier.contains('left')) return "turn left";
        if (modifier.contains('right')) return "turn right";
        if (modifier.contains('slight left')) return "slight left";
        if (modifier.contains('slight right')) return "slight right";
        if (modifier.contains('sharp left')) return "sharp left";
        if (modifier.contains('sharp right')) return "sharp right";
        return "turn";
      }

      if (type.contains('roundabout')) return "enter roundabout";
      if (type.contains('rotary')) return "enter rotary";
      if (type.contains('exit roundabout')) return "exit roundabout";
      if (type.contains('arrive')) return "you have arrived";
    }

    // Fallback to instruction text
    final instruction = (step['instruction'] as String? ?? '').toLowerCase();
    if (instruction.contains('turn left')) return "turn left";
    if (instruction.contains('turn right')) return "turn right";
    if (instruction.contains('keep left')) return "keep left";
    if (instruction.contains('keep right')) return "keep right";

    return "continue";
  }
  int _findClosestStepIndex(LatLng userPosition) {
    double minDistance = double.infinity;
    int closestIndex = -1;

    for (int i = currentStepIndex.value; i < navSteps.length; i++) {
      final step = navSteps[i];
      final stepLocation = _extractStepLocation(step);

      if (stepLocation == null) continue;

      final distance = _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        stepLocation.latitude,
        stepLocation.longitude,
      ) * 1000;

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  LatLng? _extractStepLocation(Map<String, dynamic> step) {
    try {
      // Method 1: Try to get from maneuver location (most reliable)
      if (step['maneuver'] != null) {
        final maneuver = step['maneuver'] as Map;
        if (maneuver['location'] != null && maneuver['location'] is List) {
          final loc = maneuver['location'] as List;
          if (loc.length >= 2) {
            return LatLng(
              _parseDouble(loc[1]), // latitude
              _parseDouble(loc[0]), // longitude
            );
          }
        }
      }

      // Method 2: Try geometry coordinates
      if (step['geometry'] != null && step['geometry']['coordinates'] != null) {
        final coords = step['geometry']['coordinates'] as List;
        if (coords.isNotEmpty && coords[0] is List) {
          final firstCoord = coords[0] as List;
          if (firstCoord.length >= 2) {
            return LatLng(
              _parseDouble(firstCoord[1]), // latitude
              _parseDouble(firstCoord[0]), // longitude
            );
          }
        }
      }

      // Method 3: Try intersections
      if (step['intersections'] != null && step['intersections'] is List) {
        final intersections = step['intersections'] as List;
        if (intersections.isNotEmpty) {
          final firstIntersection = intersections[0] as Map;
          if (firstIntersection['location'] != null && firstIntersection['location'] is List) {
            final loc = firstIntersection['location'] as List;
            if (loc.length >= 2) {
              return LatLng(
                _parseDouble(loc[1]), // latitude
                _parseDouble(loc[0]), // longitude
              );
            }
          }
        }
      }
    } catch (e) {
      log_print.log("Error extracting step location: $e");
    }

    return null;
  }
  String _formatManeuver(Map<String, dynamic> step) {
    final type = ((step['instruction'] as String?) ?? '').toLowerCase();
    final mod = ((step['modifier'] as String?) ?? '').toLowerCase();

    if (type.contains('turn')) {
      if (mod.contains('left')) return "turn left";
      if (mod.contains('right')) return "turn right";
      return "turn";
    }
    if (type.contains('roundabout')) return "enter the roundabout";
    if (type.contains('merge')) return "merge";
    if (type.contains('fork'))
      return "keep ${mod.isNotEmpty ? mod : 'straight'}";
    if (type.contains('depart')) return "head straight";
    if (type.contains('arrive')) return "you have arrived";
    return "continue";
  }

  // String formatDistance(double meters) {
  //
  //   // Get the current distance unit from settings controller
  //   final unit = settingController.distanceUnit.value;
  //
  //   switch (unit) {
  //     case 'meters':
  //       return '${meters.toStringAsFixed(0)} m';
  //     case 'miles':
  //       return '${(meters * 0.000621371).toStringAsFixed(1)} mi';
  //     case 'kilometers':
  //     default:
  //       return '${(meters / 1000).toStringAsFixed(1)} km';
  //   }
  // }
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: styleW500(size: 14.sp, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  // void showRouteBottomSheet(BuildContext context) {
  //   final toController = TextEditingController(text: destinationAddress.value);
  //   final RxBool isLoading = false.obs;
  //   final RxString locationDetails = ''.obs;
  //   final RxList<place_mark.Location> locationSuggestions =
  //       <place_mark.Location>[].obs;
  //
  //   // Function to update location details
  //   Future<void> updateLocationSuggestions(String query) async {
  //     if (query.isEmpty) {
  //       locationSuggestions.clear();
  //       return;
  //     }
  //
  //     try {
  //       final locations = await place_mark.locationFromAddress(query);
  //       locationSuggestions.assignAll(locations);
  //     } catch (e) {
  //       locationSuggestions.clear();
  //     }
  //   }
  //
  //   // If there's already a destination, load its details
  //   if (destinationAddress.value.isNotEmpty) {
  //     updateLocationSuggestions(destinationAddress.value);
  //   }
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder:
  //         (context) => Container(
  //           height: MediaQuery.of(context).size.height * 0.9,
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.1),
  //                 blurRadius: 10,
  //                 spreadRadius: 2,
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             children: [
  //               // Handle bar
  //               Container(
  //                 width: 40.w,
  //                 height: 4.h,
  //                 margin: EdgeInsets.symmetric(vertical: 12.h),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[300],
  //                   borderRadius: BorderRadius.circular(2.r),
  //                 ),
  //               ),
  //
  //               // Header
  //               Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 20.w),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       "Find Route",
  //                       style: styleW700(size: 20.sp, color: Colors.black),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => Navigator.pop(context),
  //                       icon: Icon(Icons.close, size: 24.sp),
  //                       style: IconButton.styleFrom(
  //                         backgroundColor: Colors.grey[100],
  //                         shape: CircleBorder(),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //
  //               Divider(color: Colors.grey[200], thickness: 1),
  //
  //               // Content
  //               Expanded(
  //                 child: SingleChildScrollView(
  //                   keyboardDismissBehavior:
  //                       ScrollViewKeyboardDismissBehavior.onDrag,
  //                   padding: EdgeInsets.only(
  //                     left: 20.w,
  //                     right: 20.w,
  //                     top: 20.h,
  //                     bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
  //                   ),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       // Current location indicator
  //                       Container(
  //                         padding: EdgeInsets.all(16.w),
  //                         decoration: BoxDecoration(
  //                           color: Color(0xFFFFC107).withValues(alpha: 0.05),
  //                           borderRadius: BorderRadius.circular(12.r),
  //                           border: Border.all(
  //                             color: Color(0xFFFFC107),
  //                             width: 1.5,
  //                           ),
  //                         ),
  //                         child: Row(
  //                           children: [
  //                             Icon(
  //                               Icons.my_location,
  //                               color: Colors.blue,
  //                               size: 20.sp,
  //                             ),
  //                             SizedBox(width: 8.w),
  //                             Expanded(
  //                               child: Text(
  //                                 "Using current location as starting point",
  //                                 style: styleW500(
  //                                   size: 14.sp,
  //                                   color: Colors.black87,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //
  //                       SizedBox(height: 20.h),
  //
  //                       // To address input
  //                       Text(
  //                         "Destination",
  //                         style: styleW600(size: 16.sp, color: Colors.black87),
  //                       ),
  //                       SizedBox(height: 8.h),
  //                       Container(
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(12.r),
  //                           border: Border.all(color: Colors.grey[300]!),
  //                           color: Colors.grey[50],
  //                         ),
  //                         child: TextField(
  //                           controller: toController,
  //                           decoration: InputDecoration(
  //                             hintText: "Enter destination address",
  //                             hintStyle: styleW400(
  //                               size: 14.sp,
  //                               color: Colors.grey[500],
  //                             ),
  //                             prefixIcon: Container(
  //                               padding: EdgeInsets.all(12.w),
  //                               child: CircleAvatar(
  //                                 radius: 6.r,
  //                                 backgroundColor: Colors.red,
  //                               ),
  //                             ),
  //                             border: InputBorder.none,
  //                             contentPadding: EdgeInsets.symmetric(
  //                               horizontal: 16.w,
  //                               vertical: 16.h,
  //                             ),
  //                           ),
  //                           style: styleW500(
  //                             size: 14.sp,
  //                             color: Colors.black87,
  //                           ),
  //                           onChanged: (value) async {
  //                             if (value.length > 5) {
  //                               await updateLocationSuggestions(value);
  //                             }
  //                           },
  //                         ),
  //                       ),
  //
  //                       // Location details preview
  //                       Obx(
  //                         () =>
  //                             locationSuggestions.isNotEmpty
  //                                 ? Container(
  //                                   constraints: BoxConstraints(
  //                                     maxHeight: 200.h,
  //                                   ),
  //                                   child: ListView.builder(
  //                                     shrinkWrap: true,
  //                                     itemCount: locationSuggestions.length,
  //                                     itemBuilder: (context, index) {
  //                                       final location =
  //                                           locationSuggestions[index];
  //
  //                                       return FutureBuilder<
  //                                         List<geocoding.Placemark>
  //                                       >(
  //                                         future: geocoding
  //                                             .placemarkFromCoordinates(
  //                                               location.latitude,
  //                                               location.longitude,
  //                                             ),
  //                                         builder: (context, snapshot) {
  //                                           if (!snapshot.hasData) {
  //                                             return SizedBox();
  //                                           }
  //
  //                                           final placeMark =
  //                                               snapshot.data!.first;
  //                                           final address =
  //                                               "${placeMark.street ?? ''}, ${placeMark.locality ?? ''}, ${placeMark.administrativeArea ?? ''}";
  //
  //                                           return ListTile(
  //                                             leading: Icon(
  //                                               Icons.location_on,
  //                                               color: Color(0xFFFFC107),
  //                                             ),
  //                                             title: Text(
  //                                               address,
  //                                               style: styleW500(size: 12.sp),
  //                                             ),
  //                                             onTap: () {
  //                                               toController.text = address;
  //                                               locationDetails.value = address;
  //                                               locationSuggestions.clear();
  //                                               FocusScope.of(
  //                                                 context,
  //                                               ).unfocus();
  //                                             },
  //                                           );
  //                                         },
  //                                       );
  //                                     },
  //                                   ),
  //                                 )
  //                                 : SizedBox(),
  //                       ),
  //
  //                       SizedBox(height: 30.h),
  //
  //                       // Info card
  //                       Container(
  //                         padding: EdgeInsets.all(16.w),
  //                         decoration: BoxDecoration(
  //                           color: Colors.orange.withValues(alpha: 0.1),
  //                           borderRadius: BorderRadius.circular(12.r),
  //                           border: Border.all(
  //                             color: Colors.orange.withValues(alpha: 0.3),
  //                           ),
  //                         ),
  //                         child: Row(
  //                           children: [
  //                             Icon(
  //                               Icons.info_outline,
  //                               color: Colors.orange,
  //                               size: 20.sp,
  //                             ),
  //                             SizedBox(width: 12.w),
  //                             Expanded(
  //                               child: Text(
  //                                 "We'll check for railway crossings along your route and provide safety alerts.",
  //                                 style: styleW400(
  //                                   size: 13.sp,
  //                                   color: Colors.orange[800],
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //
  //                       SizedBox(height: 30.h),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //
  //               // Bottom action buttons
  //               Container(
  //                 padding: EdgeInsets.all(20.w),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   border: Border(top: BorderSide(color: Colors.grey[200]!)),
  //                 ),
  //                 child: Obx(
  //                   () => Column(
  //                     children: [
  //                       // Find Route Button
  //                       SizedBox(
  //                         width: double.infinity,
  //                         height: 50.h,
  //                         child: ElevatedButton(
  //                           onPressed:
  //                               isLoading.value
  //                                   ? null
  //                                   : () async {
  //                                     if (toController.text.trim().isEmpty) {
  //                                       _showSnackBar(
  //                                         context,
  //                                         "Please enter destination address",
  //                                         isError: true,
  //                                       );
  //                                       return;
  //                                     }
  //
  //                                     isLoading.value = true;
  //
  //                                     try {
  //                                       await findRoute(
  //                                         toController.text.trim(),
  //                                       );
  //                                       isLoading.value = false;
  //                                       Navigator.pop(context);
  //                                       speak("Route found. Ready to navigate");
  //                                     } catch (e) {
  //                                       isLoading.value = false;
  //                                       _showSnackBar(
  //                                         context,
  //                                         "Error: ${e.toString()}",
  //                                         isError: true,
  //                                       );
  //                                     }
  //                                   },
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: Color(0xFFFFC107),
  //                             foregroundColor: AppColors.black,
  //                             elevation: 0,
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(12.r),
  //                             ),
  //                           ),
  //                           child:
  //                               isLoading.value
  //                                   ? Row(
  //                                     mainAxisAlignment:
  //                                         MainAxisAlignment.center,
  //                                     children: [
  //                                       SizedBox(
  //                                         width: 20.w,
  //                                         height: 20.h,
  //                                         child: CircularProgressIndicator(
  //                                           strokeWidth: 2,
  //                                           valueColor:
  //                                               AlwaysStoppedAnimation<Color>(
  //                                                 Colors.white,
  //                                               ),
  //                                         ),
  //                                       ),
  //                                       SizedBox(width: 12.w),
  //                                       Text(
  //                                         "Finding Route...",
  //                                         style: styleW600(
  //                                           size: 16.sp,
  //                                           color: AppColors.black,
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   )
  //                                   : Row(
  //                                     mainAxisAlignment:
  //                                         MainAxisAlignment.center,
  //                                     children: [
  //                                       Icon(Icons.directions, size: 20.sp),
  //                                       SizedBox(width: 8.w),
  //                                       Text(
  //                                         "Find Route",
  //                                         style: styleW600(
  //                                           size: 16.sp,
  //                                           color: AppColors.black,
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                         ),
  //                       ),
  //
  //                       SizedBox(height: 12.h),
  //
  //                       // Cancel Button
  //                       SizedBox(
  //                         width: double.infinity,
  //                         height: 50.h,
  //                         child: OutlinedButton(
  //                           onPressed:
  //                               isLoading.value
  //                                   ? null
  //                                   : () => Navigator.pop(context),
  //                           style: OutlinedButton.styleFrom(
  //                             side: BorderSide(color: Colors.grey[300]!),
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(12.r),
  //                             ),
  //                           ),
  //                           child: Text(
  //                             "Cancel",
  //                             style: styleW500(
  //                               size: 16.sp,
  //                               color: Colors.grey[600],
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //   );
  // }
  void showRouteBottomSheet(BuildContext context) {
    final toController = TextEditingController(text: destinationAddress.value);
    final RxBool isLoading = false.obs;
    final RxString locationDetails = ''.obs;
    final RxList<place_mark.Location> locationSuggestions =
        <place_mark.Location>[].obs;
    final RxString currentLocationText = 'Getting location...'.obs;

    // Function to update location details
    Future<void> updateLocationSuggestions(String query) async {
      if (query.isEmpty) {
        locationSuggestions.clear();
        return;
      }

      try {
        final locations = await place_mark.locationFromAddress(query);
        locationSuggestions.assignAll(locations);
      } catch (e) {
        locationSuggestions.clear();
      }
    }

    // Function to refresh current location and update display
    Future<void> refreshCurrentLocationInSheet() async {
      try {
        currentLocationText.value = 'Refreshing location...';

        // Refresh the location using your existing method
        await refreshCurrentLocation();

        // Get address for display
        if (userPosition.value != null) {
          final placemarks = await geocoding.placemarkFromCoordinates(
            userPosition.value!.latitude,
            userPosition.value!.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            currentLocationText.value =
                "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
          } else {
            currentLocationText.value =
                "Lat: ${userPosition.value!.latitude.toStringAsFixed(4)}, "
                "Lng: ${userPosition.value!.longitude.toStringAsFixed(4)}";
          }
        }
      } catch (e) {
        currentLocationText.value = 'Error getting location';
        log_print.log('Error refreshing location in sheet: $e');
      }
    }

    // Initialize current location display when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshCurrentLocationInSheet();
    });

    // If there's already a destination, load its details
    if (destinationAddress.value.isNotEmpty) {
      updateLocationSuggestions(destinationAddress.value);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Find Route",
                        style: styleW700(size: 20.sp, color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: 24.sp),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.grey[200], thickness: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      top: 20.h,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current location indicator with refresh button
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFC107).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Color(0xFFFFC107),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Starting Point",
                                      style: styleW600(
                                        size: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Obx(
                                      () => Text(
                                        currentLocationText.value,
                                        style: styleW500(
                                          size: 13.sp,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                onPressed:
                                    () => refreshCurrentLocationInSheet(),
                                icon: Icon(Icons.refresh, size: 20.sp),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: CircleBorder(),
                                ),
                                tooltip: 'Refresh location',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // To address input
                        Text(
                          "Destination",
                          style: styleW600(size: 16.sp, color: Colors.black87),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey[300]!),
                            color: Colors.grey[50],
                          ),
                          child: TextField(
                            controller: toController,
                            decoration: InputDecoration(
                              hintText: "Enter destination address",
                              hintStyle: styleW400(
                                size: 14.sp,
                                color: Colors.grey[500],
                              ),
                              prefixIcon: Container(
                                padding: EdgeInsets.all(12.w),
                                child: CircleAvatar(
                                  radius: 6.r,
                                  backgroundColor: Colors.red,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                            ),
                            style: styleW500(
                              size: 14.sp,
                              color: Colors.black87,
                            ),
                            onChanged: (value) async {
                              if (value.length > 5) {
                                await updateLocationSuggestions(value);
                              }
                            },
                          ),
                        ),

                        // Location details preview
                        Obx(
                          () =>
                              locationSuggestions.isNotEmpty
                                  ? Container(
                                    constraints: BoxConstraints(
                                      maxHeight: 200.h,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: locationSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final location =
                                            locationSuggestions[index];

                                        return FutureBuilder<
                                          List<geocoding.Placemark>
                                        >(
                                          future: geocoding
                                              .placemarkFromCoordinates(
                                                location.latitude,
                                                location.longitude,
                                              ),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return SizedBox();
                                            }

                                            final placeMark =
                                                snapshot.data!.first;
                                            final address =
                                                "${placeMark.street ?? ''}, ${placeMark.locality ?? ''}, ${placeMark.administrativeArea ?? ''}";

                                            return ListTile(
                                              leading: Icon(
                                                Icons.location_on,
                                                color: Color(0xFFFFC107),
                                              ),
                                              title: Text(
                                                address,
                                                style: styleW500(size: 12.sp),
                                              ),
                                              onTap: () {
                                                toController.text = address;
                                                locationDetails.value = address;
                                                locationSuggestions.clear();
                                                FocusScope.of(
                                                  context,
                                                ).unfocus();
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  )
                                  : SizedBox(),
                        ),

                        SizedBox(height: 30.h),

                        // Info card
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  "We'll check for railway crossings along your route and provide safety alerts.",
                                  style: styleW400(
                                    size: 13.sp,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ),

                // Bottom action buttons
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Obx(
                    () => Column(
                      children: [
                        // Find Route Button
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed:
                                isLoading.value
                                    ? null
                                    : () async {
                                      if (toController.text.trim().isEmpty) {
                                        _showSnackBar(
                                          context,
                                          "Please enter destination address",
                                          isError: true,
                                        );
                                        return;
                                      }

                                      isLoading.value = true;

                                      try {
                                        await findRoute(
                                          toController.text.trim(),
                                        );
                                        isLoading.value = false;
                                        Navigator.pop(context);
                                        speak("Route found. Ready to navigate");
                                      } catch (e) {
                                        isLoading.value = false;
                                        _showSnackBar(
                                          context,
                                          "Error: ${e.toString()}",
                                          isError: true,
                                        );
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFC107),
                              foregroundColor: AppColors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child:
                                isLoading.value
                                    ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          "Finding Route...",
                                          style: styleW600(
                                            size: 16.sp,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ],
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.directions, size: 20.sp),
                                        SizedBox(width: 8.w),
                                        Text(
                                          "Find Route",
                                          style: styleW600(
                                            size: 16.sp,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Cancel Button
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: OutlinedButton(
                            onPressed:
                                isLoading.value
                                    ? null
                                    : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: styleW500(
                                size: 16.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  final RxBool hasUserAdjustedZoom = false.obs;

  //(07/10/2025)OLD
  //   Future<void> checkBackgroundCrossings(Position position) async {
  //     try {
  //       if (!settingController.isWarningsEnabled.value) return;
  //
  //       // ✅ ADD THIS CHECK: Only check background crossings when NOT actively navigating
  //       if (isNavigating.value) return; // Let navigation mode handle crossing checks
  //
  //       final userLatLng = LatLng(position.latitude, position.longitude);
  //
  //       for (final crossing in nearbyLocations) {
  //         final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
  //         final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;
  //
  //         if (crossingLat == 0 || crossingLng == 0) continue;
  //
  //         final distance = _calculateDistance(
  //           userLatLng.latitude,
  //           userLatLng.longitude,
  //           crossingLat,
  //           crossingLng,
  //         ) * 1000;
  //
  //         final warningDistance = settingController.warningDistance.value;
  //
  //         if (distance < warningDistance) {
  //           await _triggerCrossingWarning(crossing, distance, position);
  //         }
  //       }
  //     } catch (e) {
  //       log_print.log("Background crossing check error: $e");
  //     }
  //   }

  //(07/10/2025)NEW
  // Modify the background crossing check to work consistently
  Future<void> checkBackgroundCrossings(Position position) async {
    try {
      if (!settingController.isWarningsEnabled.value) return;

      // ✅ REMOVED the navigation check - now works in both modes
      final userLatLng = LatLng(position.latitude, position.longitude);

      for (final crossing in nearbyLocations) {
        final crossingLat = double.tryParse(crossing.latitude ?? '0') ?? 0;
        final crossingLng = double.tryParse(crossing.longitude ?? '0') ?? 0;

        if (crossingLat == 0 || crossingLng == 0) continue;

        final distance =
            _calculateDistance(
              userLatLng.latitude,
              userLatLng.longitude,
              crossingLat,
              crossingLng,
            ) *
            1000;

        // Use 100m threshold for background alerts
        if (distance < 100) {
          log_print.log(
            "🔔 Background alert: Within 100m of ${crossing.street}",
          );
          await _triggerProximityAlert(crossing, distance);
        }
      }
    } catch (e) {
      log_print.log("Background crossing check error: $e");
    }
  }

  // Enhanced warning trigger
  Future<void> _triggerCrossingWarning(
    TransportLocation crossing,
    double distance,
    Position position,
  ) async {
    // ✅ ADD EARLY RETURN: Don't trigger warnings if navigation was just stopped
    // and route is being cleared
    if (routeCoordinates.isEmpty &&
        !isNavigating.value &&
        crossingsAlongRoute.isEmpty) {
      log_print.log("Skipping warning - navigation stopped or no active route");
      return;
    }

    final message =
        "Railway Crossing ${distance < 100 ? 'AHEAD' : 'NEARBY'} - "
        "${crossing.street ?? 'railway crossing'} "
        "(${formatDistance(distance)})";

    await NotificationService().showNotifications(
      "🚂 Railway Crossing Alert",
      message,
    );

    if (settingController.isWarningSoundEnabled.value) {
      await player.stop();
      await player.setVolume(1.0);
      await player.play();
    }

    // ✅ DOUBLE CHECK before vibrating
    if (settingController.isVibrationEnabled.value &&
        (await Vibration.hasVibrator() ?? false)) {
      if (distance < 50) {
        Vibration.vibrate(pattern: [500, 500, 500, 1000]);
      } else if (distance < 100) {
        Vibration.vibrate(pattern: [300, 700, 300, 700]);
      } else {
        Vibration.vibrate(duration: 500);
      }
    }

    if (settingController.isWarningSoundEnabled.value) {
      final voiceMessage =
          distance < 100
              ? "Warning! Railway crossing ahead in ${formatDistance(distance)}"
              : "Railway crossing nearby in ${formatDistance(distance)}";
      await speak(voiceMessage);
    }
  }

  // Enhanced location stream with background support
  //   Future<void> _initLocationTracking() async {
  //     try {
  //       log_print.log("🔧 Starting enhanced location tracking...");
  //
  //       // Check permissions
  //       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //       if (!serviceEnabled) {
  //         throw Exception("Location services disabled");
  //       }
  //
  //       LocationPermission permission = await Geolocator.checkPermission();
  //       if (permission == LocationPermission.denied) {
  //         permission = await Geolocator.requestPermission();
  //         if (permission != LocationPermission.whileInUse &&
  //             permission != LocationPermission.always) {
  //           throw Exception("Location permission denied");
  //         }
  //       }
  //
  //       // Request background permissions if needed
  //       if (settingController.runInBackground.value) {
  //         await Permission.locationAlways.request();
  //       }
  //
  //       // Enhanced location settings for background
  //       final locationSettings = LocationSettings(
  //         accuracy: LocationAccuracy.bestForNavigation,
  //         distanceFilter: 5, // More frequent updates for navigation
  //         timeLimit: const Duration(seconds: 10), // Timeout for updates
  //       );
  //
  //       // Cancel any existing stream
  //       await _positionStream?.cancel();
  //
  //       log_print.log("🎯 Setting up enhanced position stream...");
  //
  //       _positionStream = Geolocator.getPositionStream(
  //         locationSettings: locationSettings,
  //       ).listen((Position position) {
  //         log_print.log(
  //           '📍 Enhanced Location: '
  //               'Lat: ${position.latitude.toStringAsFixed(6)}, '
  //               'Lng: ${position.longitude.toStringAsFixed(6)}, '
  //               'Bearing: ${position.heading.toStringAsFixed(1)}°, '
  //               'Speed: ${position.speed.toStringAsFixed(1)} m/s',
  //         );
  //
  //         // Skip poor accuracy positions
  //         if (position.accuracy > 50) {
  //           log_print.log('Skipping poor accuracy position: ${position.accuracy}m');
  //           return;
  //         }
  //
  //         // Always update position
  //         userPosition.value = position;
  //         userBearing.value = position.heading;
  //
  //         // Enhanced bearing calculation for navigation
  //         _updateEnhancedBearing(position);
  //
  //         _lastUserLatLng = LatLng(position.latitude, position.longitude);
  //
  //         // Save for background use
  //         _saveLocationToPrefs();
  //
  //         if (isNavigating.value) {
  //           // Navigation mode - frequent updates
  //           if (!hasUserAdjustedZoom.value) {
  //             isProgrammaticMove.value = true;
  //             mapController.move(
  //               LatLng(position.latitude, position.longitude),
  //               18,
  //             );
  //             isProgrammaticMove.value = false;
  //           }
  //
  //           // Immediate route updates
  //           _updateRouteProgress();
  //           _checkProximityToCrossings();
  //           _checkRouteDeviation();
  //           _provideVoiceNavigation();
  //         } else {
  //           // Background/standalone mode - check crossings
  //           checkNearbyCrossings();
  //
  //           // Additional background checks
  //           checkBackgroundCrossings(position);
  //         }
  //       }, onError: (error) {
  //         log_print.log("Location stream error: $error");
  //       });
  //
  //       isTrackingLocation.value = true;
  //       log_print.log('✅ Enhanced location tracking initialized');
  //
  //     } catch (e) {
  //       errorMessage.value = "Failed to initialize location tracking: $e";
  //       log_print.log("❌ Location tracking error: $e");
  //       isTrackingLocation.value = false;
  //       _positionStream = null;
  //     }
  //   }
  /// 08/10/2025 old
//   Future<void> _initLocationTracking() async {
//     try {
//       log_print.log("🔧 Starting location tracking initialization...");
//
//       // Check permissions first
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         throw Exception("Location services disabled");
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission != LocationPermission.whileInUse &&
//             permission != LocationPermission.always) {
//           throw Exception("Location permission denied");
//         }
//       }
//
//       // Initialize notifications
//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//
//       final InitializationSettings initializationSettings =
//           InitializationSettings(android: initializationSettingsAndroid);
//
//       await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//
//       // Location settings - LESS STRICT for initial updates
//       final locationSettings = LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 1,
//       );
//
//       // Show persistent notification
//       const AndroidNotificationDetails androidPlatformChannelSpecifics =
//           AndroidNotificationDetails(
//             'location_channel',
//             'Location Tracking',
//             channelDescription: 'Tracking railway crossings nearby',
//             importance: Importance.low,
//             priority: Priority.low,
//             ongoing: true,
//             enableLights: false,
//             enableVibration: false,
//             autoCancel: false,
//             showWhen: false,
//             icon: '@mipmap/ic_launcher',
//           );
//
//       const NotificationDetails platformChannelSpecifics = NotificationDetails(
//         android: androidPlatformChannelSpecifics,
//       );
//
//       await flutterLocalNotificationsPlugin.show(
//         0,
//         'Railway Crossing Alerts Active',
//         'Monitoring railway crossings in background',
//         platformChannelSpecifics,
//       );
//
//       // Cancel any existing stream
//       await _positionStream?.cancel();
//
//       log_print.log("🎯 Setting up position stream...");
//       //(07/10/2025) OLD
//       // FIXED: Position stream with better filtering
//       // _positionStream = Geolocator.getPositionStream(
//       //   locationSettings: locationSettings,
//       // ).listen((Position position) {
//       //   log_print.log(
//       //     '📍 RAW Location Update: '
//       //     'Lat: ${position.latitude.toStringAsFixed(6)}, '
//       //     'Lng: ${position.longitude.toStringAsFixed(6)}, '
//       //     'Speed: ${position.speed.toStringAsFixed(1)} m/s, '
//       //     'Accuracy: ${position.accuracy.toStringAsFixed(1)}m',
//       //   );
//       //
//       //   // RELAXED accuracy filter for navigation
//       //   if (position.accuracy > 100) {
//       //     // Increased from 50 to 100
//       //     log_print.log(
//       //       'Skipping position with poor accuracy: ${position.accuracy}m',
//       //     );
//       //     return;
//       //   }
//       //
//       //   // ALWAYS update position during navigation, regardless of movement
//       //   if (isNavigating.value) {
//       //     userPosition.value = position;
//       //     log_print.log('🚗 NAVIGATION MODE: Force updating position');
//       //   } else {
//       //     // Only filter movement when NOT navigating
//       //     final hasMoved = _hasUserMovedSignificantlyNew(position);
//       //     if (!hasMoved) {
//       //       log_print.log('User has not moved significantly, skipping update');
//       //       return;
//       //     }
//       //     userPosition.value = position;
//       //   }
//       //
//       //   // Update bearing and map rotation
//       //   final speed = position.speed; // m/s
//       //   if (speed >= 1.0) {
//       //     // Reduced from 1.5 to 1.0
//       //     if (_lastUserLatLng != null) {
//       //       final bearing = _calculateBearing(
//       //         _lastUserLatLng!.latitude,
//       //         _lastUserLatLng!.longitude,
//       //         position.latitude,
//       //         position.longitude,
//       //       );
//       //       mapRotation.value = bearing;
//       //     }
//       //   } else if (position.headingAccuracy > 0 &&
//       //       position.headingAccuracy < 15) {
//       //     mapRotation.value = position.heading;
//       //   }
//       //
//       //   _lastUserLatLng = LatLng(position.latitude, position.longitude);
//       //   userBearing.value = position.heading;
//       //
//       //   // Save location for background use
//       //   _saveLocationToPrefs();
//       //
//       //   if (isNavigating.value) {
//       //     // IMMEDIATE map updates during navigation
//       //     if (!hasUserAdjustedZoom.value) {
//       //       isProgrammaticMove.value = true;
//       //       mapController.move(
//       //         LatLng(position.latitude, position.longitude),
//       //         18,
//       //       );
//       //       isProgrammaticMove.value = false;
//       //     }
//       //
//       //     // Process route updates immediately
//       //     _updateRouteProgress();
//       //     _checkProximityToCrossings();
//       //     _checkRouteDeviation();
//       //     _provideVoiceNavigation();
//       //   } else {
//       //     checkNearbyCrossings();
//       //   }
//       // });
// //(07/10/2025) New
//       // FIXED: Position stream with consistent crossing checks
//       _positionStream = Geolocator.getPositionStream(
//         locationSettings: locationSettings,
//       ).listen((Position position) {
//         log_print.log(
//           '📍 RAW Location Update: '
//               'Lat: ${position.latitude.toStringAsFixed(6)}, '
//               'Lng: ${position.longitude.toStringAsFixed(6)}, '
//               'Speed: ${position.speed.toStringAsFixed(1)} m/s, '
//               'Accuracy: ${position.accuracy.toStringAsFixed(1)}m',
//         );
//
//         // RELAXED accuracy filter for navigation
//         if (position.accuracy > 100) {
//           log_print.log(
//             'Skipping position with poor accuracy: ${position.accuracy}m',
//           );
//           return;
//         }
//
//         // ALWAYS update position during navigation, regardless of movement
//         if (isNavigating.value) {
//           userPosition.value = position;
//           log_print.log('🚗 NAVIGATION MODE: Force updating position');
//         } else {
//           // Only filter movement when NOT navigating
//           final hasMoved = _hasUserMovedSignificantlyNew(position);
//           if (!hasMoved) {
//             log_print.log('User has not moved significantly, skipping update');
//             return;
//           }
//           userPosition.value = position;
//         }
//
//         // Update bearing and map rotation
//         final speed = position.speed; // m/s
//         if (speed >= 1.0) {
//           if (_lastUserLatLng != null) {
//             final bearing = _calculateBearing(
//               _lastUserLatLng!.latitude,
//               _lastUserLatLng!.longitude,
//               position.latitude,
//               position.longitude,
//             );
//             mapRotation.value = bearing;
//           }
//         } else if (position.headingAccuracy > 0 &&
//             position.headingAccuracy < 15) {
//           mapRotation.value = position.heading;
//         }
//
//         _lastUserLatLng = LatLng(position.latitude, position.longitude);
//         userBearing.value = position.heading;
//
//         // Save location for background use
//         _saveLocationToPrefs();
//
//         if (isNavigating.value) {
//           // IMMEDIATE map updates during navigation
//           if (!hasUserAdjustedZoom.value) {
//             isProgrammaticMove.value = true;
//             mapController.move(
//               LatLng(position.latitude, position.longitude),
//               18,
//             );
//             isProgrammaticMove.value = false;
//           }
//
//           // Process route updates immediately
//           _updateRouteProgress();
//           _checkProximityToCrossings();
//           _checkRouteDeviation();
//           _provideVoiceNavigation();
//         } else {
//           // ✅ ALWAYS check crossings, even when not navigating
//           checkNearbyCrossings();
//
//           // Additional background checks for app state
//           if (Get.currentRoute == Routes.CROSSING) {
//             checkBackgroundCrossings(position);
//           }
//         }
//       });
//       isTrackingLocation.value = true;
//       log_print.log('✅ Location tracking initialized successfully');
//     } catch (e) {
//       errorMessage.value = "Failed to initialize location tracking: $e";
//       log_print.log("❌ Location tracking initialization error: $e");
//       isTrackingLocation.value = false;
//       _positionStream = null;
//     }
//   }
//08/10/2025 new
  Future<void> _initLocationTracking() async {
    try {
      log_print.log('🔧 Starting location tracking initialization...');

      // Cancel existing stream
      await _positionStream?.cancel();
      _positionStream = null;

      // // ✅ Show persistent notification FIRST
      // try {
      //   const AndroidInitializationSettings initializationSettingsAndroid =
      //   AndroidInitializationSettings('@mipmap/ic_launcher');
      //
      //   final InitializationSettings initializationSettings =
      //   InitializationSettings(android: initializationSettingsAndroid);
      //
      //   await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      //
      //   const AndroidNotificationDetails androidDetails =
      //   AndroidNotificationDetails(
      //     'location_channel',
      //     'Location Tracking',
      //     channelDescription: 'Tracking railway crossings nearby',
      //     importance: Importance.low,
      //     priority: Priority.low,
      //     ongoing: true,
      //     enableLights: false,
      //     enableVibration: false,
      //     autoCancel: false,
      //     showWhen: false,
      //     icon: '@mipmap/ic_launcher',
      //   );
      //
      //   const NotificationDetails notificationDetails = NotificationDetails(
      //     android: androidDetails,
      //   );
      //
      //   await flutterLocalNotificationsPlugin.show(
      //     0,
      //     'Railway Crossing Alerts Active',
      //     'Monitoring railway crossings in background',
      //     notificationDetails,
      //   );
      //   log_print.log('✅ Persistent notification shown');
      // } catch (e) {
      //   log_print.log('⚠️ Notification setup failed: $e');
      // }
      // ✅ Enhanced notification that updates with navigation status
      await _updateBackgroundNotification();
      // ✅ AGGRESSIVE location settings
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // No filtering at GPS level
      );

      log_print.log('🎯 Creating position stream...');

      // ✅ START THE STREAM
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
            (Position position) {
              // ✅ ALWAYS LOG - even in background
              final timestamp = DateTime.now().toIso8601String();
              log_print.log('📍📍📍 LOCATION UPDATE [$timestamp] 📍📍📍');
              log_print.log('Lat: ${position.latitude.toStringAsFixed(6)}');
              log_print.log('Lng: ${position.longitude.toStringAsFixed(6)}');
              log_print.log('Accuracy: ${position.accuracy.toStringAsFixed(1)}m');
              log_print.log('Speed: ${position.speed.toStringAsFixed(1)} m/s');
              log_print.log('Is Navigating: ${isNavigating.value}');
              log_print.log('Crossings Along Route: ${crossingsAlongRoute.length}');
              log_print.log('Nearby Locations: ${nearbyLocations.length}');

          // Skip extremely poor accuracy
          if (position.accuracy > 100) {
            log_print.log('⚠️ Poor accuracy, skipping');
            return;
          }

          // Check if movement is significant
          final hasMoved = _hasUserMovedSignificantlyNew(position);
          if (!hasMoved) {
            log_print.log('⏸️ No significant movement');
            return;
          }

          // ✅ UPDATE POSITION
          userPosition.value = position;
          userBearing.value = position.heading;
          log_print.log('✅ Position updated in state');

          // Update bearing
          final speed = position.speed;
          if (speed >= 1.0 && _lastUserLatLng != null) {
            final bearing = _calculateBearing(
              _lastUserLatLng!.latitude,
              _lastUserLatLng!.longitude,
              position.latitude,
              position.longitude,
            );
            mapRotation.value = bearing;
            log_print.log('🧭 Bearing updated: ${bearing.toStringAsFixed(1)}°');
          }

          _lastUserLatLng = LatLng(position.latitude, position.longitude);

          // Save for background
          _saveLocationToPrefs();

          // ✅✅✅ MOST IMPORTANT: CHECK CROSSINGS
          log_print.log('🔍 CALLING checkNearbyCrossings()...');
          checkNearbyCrossings();

          // Navigation updates
          if (isNavigating.value) {
            log_print.log('🚗 Navigation mode active');

            if (!hasUserAdjustedZoom.value) {
              isProgrammaticMove.value = true;
              mapController.move(
                LatLng(position.latitude, position.longitude),
                18,
              );
              isProgrammaticMove.value = false;
            }

            _updateRouteProgress();
            _checkProximityToCrossings();
            _checkRouteDeviation();
            _provideVoiceNavigation();
            // ✅ Update notification in background
            _updateBackgroundNotification();

          }
              log_print.log('─────────────────────────────────────');
        },
        onError: (error) {
          log_print.log('❌ Location stream ERROR: $error');
        },
        cancelOnError: false, // Keep stream alive on errors
      );

      isTrackingLocation.value = true;
      log_print.log('✅✅✅ LOCATION TRACKING ACTIVE ✅✅✅');

    } catch (e) {
      errorMessage.value = 'Failed to initialize location tracking: $e';
      log_print.log('❌ Fatal location tracking error: $e');
      isTrackingLocation.value = false;
      _positionStream = null;
      rethrow;
    }
  }

  Future<void> _updateBackgroundNotification() async {
    try {
      String title = 'Railway Crossing Alerts Active';
      String body = 'Monitoring railway crossings in background';

      // ✅ Show navigation status in notification
      if (isNavigating.value) {
        if (nearestCrossing.value != null) {
          final distance = distanceToNearestCrossing.value;
          title = 'Navigation Active';
          body = 'Nearest crossing: ${nearestCrossing.value!.street ?? "Unknown"} (${formatDistance(distance)})';
        } else {
          title = 'Navigation Active';
          body = 'Navigating to ${destinationAddress.value}';
        }
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'location_channel',
        'Location Tracking',
        channelDescription: 'Tracking railway crossings nearby',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        enableLights: false,
        enableVibration: false,
        autoCancel: false,
        showWhen: false,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        0, // Use ID 0 for persistent notification
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      log_print.log('Error updating background notification: $e');
    }
  }
// ==========================================
// 5. TESTING HELPER (Temporary)
// ==========================================
// આ method ઉમેરો testing માટે
//   Future<void> testCrossingAlert() async {
//     log_print.log('🧪 TESTING CROSSING ALERT');
//
//     if (nearbyLocations.isEmpty) {
//       log_print.log('❌ No crossings available for testing');
//       return;
//     }
//
//     // First crossing લઈને test કરો
//     final testCrossing = nearbyLocations.first;
//     await _triggerProximityAlert(testCrossing, 75.0); // 75m distance for testing
//
//     log_print.log('✅ Test alert triggered');
//   }
  // Enhanced bearing calculation
  //10/10/2025
  // void _updateEnhancedBearing(Position position) {
  //   final speed = position.speed;
  //
  //   if (speed >= 1.0) {
  //     // Moving
  //     if (_lastUserLatLng != null) {
  //       final bearing = _calculateBearing(
  //
  //
  //
  //         _lastUserLatLng!.latitude,
  //         _lastUserLatLng!.longitude,
  //         position.latitude,
  //         position.longitude,
  //       );
  //       mapRotation.value = bearing;
  //       userBearing.value = bearing; // Update user bearing too
  //     }
  //   } else if (position.headingAccuracy > 0 && position.headingAccuracy < 15) {
  //     // Use compass when stationary with good accuracy
  //     mapRotation.value = position.heading;
  //     userBearing.value = position.heading;
  //   }
  //
  //   log_print.log(
  //     '🧭 Bearing updated: ${mapRotation.value.toStringAsFixed(1)}°',
  //   );
  // }
  void _updateEnhancedBearing(Position position) {
    final speed = position.speed;

    if (speed >= 1.0) {
      // Moving - use GPS course for smooth rotation
      if (_lastUserLatLng != null) {
        final bearing = _calculateBearing(
          _lastUserLatLng!.latitude,
          _lastUserLatLng!.longitude,
          position.latitude,
          position.longitude,
        );

        // Smooth transition for map rotation
        final currentRotation = mapRotation.value;
        final rotationDiff = (bearing - currentRotation).abs();

        if (rotationDiff > 180) {
          // Handle crossing 360° boundary
          mapRotation.value = bearing > currentRotation ? bearing - 360 : bearing + 360;
        } else {
          // Smooth interpolation
          mapRotation.value = currentRotation + (bearing - currentRotation) * 0.3;
        }

        // Normalize to 0-360
        mapRotation.value = mapRotation.value % 360;
        userBearing.value = bearing;

        log_print.log('🧭 Enhanced bearing: ${mapRotation.value.toStringAsFixed(1)}°');
      }
    } else if (position.headingAccuracy > 0 && position.headingAccuracy < 15) {
      // Use compass when stationary with good accuracy
      mapRotation.value = position.heading;
      userBearing.value = position.heading;
    }

    // Apply rotation to map controller
    if (isNavigating.value && !hasUserAdjustedZoom.value) {
      mapController.rotate(mapRotation.value);
    }
  }
  // Enhanced initialization that runs on page open and location refresh
  //   void initializeOnPageOpen() {
  //     log_print.log("🔄 Enhanced initialization on page open");
  //
  //     // Force refresh location and services
  //     WidgetsBinding.instance.addPostFrameCallback((_) async {
  //       await initializeLocationServices();
  //       await refreshCurrentLocation();
  //
  //       // Ensure background service is ready
  //       if (settingController.runInBackground.value) {
  //         await startBackgroundService();
  //       }
  //     });
  //   }

  // Enhanced refresh that works like the current location button
  //   Future<void> refreshCurrentLocation() async {
  //     try {
  //       log_print.log("🔄 Manually refreshing location with reinitialization");
  //
  //       // Show loading state
  //       isLoading.value = true;
  //
  //       // Stop existing tracking
  //       await _positionStream?.cancel();
  //
  //       // Reinitialize everything
  //       await initializeLocationServices();
  //
  //       // Force fresh location
  //       final position = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.best,
  //       );
  //
  //       userPosition.value = position;
  //
  //       // Update map with proper orientation
  //       final userLatLng = LatLng(position.latitude, position.longitude);
  //       isProgrammaticMove.value = true;
  //       mapController.move(userLatLng, currentZoom.value);
  //       isProgrammaticMove.value = false;
  //       hasUserAdjustedZoom.value = false;
  //
  //       // Reset bearing to current heading
  //       mapRotation.value = position.heading;
  //       userBearing.value = position.heading;
  //
  //       // Fetch fresh crossings data
  //       final placemarks = await geocoding.placemarkFromCoordinates(
  //         position.latitude,
  //         position.longitude,
  //       );
  //       final cityName = placemarks.isNotEmpty ? placemarks[0].locality?.toUpperCase() : '';
  //       await fetchLocations(cityName: cityName ?? "");
  //
  //       log_print.log("✅ Location refreshed with reinitialization");
  //
  //       // Show success feedback
  //       // Get.snackbar(
  //       //   "Location Updated",
  //       //   "Your current location and orientation have been refreshed",
  //       //   snackPosition: SnackPosition.BOTTOM,
  //       //   duration: Duration(seconds: 2),
  //       //   backgroundColor: Colors.green,
  //       //   colorText: Colors.white,
  //       // );
  //
  //     } catch (e) {
  //       log_print.log("❌ Error refreshing location: $e");
  //       // Get.snackbar(
  //       //   "Location Error",
  //       //   "Failed to refresh location: $e",
  //       //   snackPosition: SnackPosition.BOTTOM,
  //       //   duration: Duration(seconds: 3),
  //       //   backgroundColor: Colors.red,
  //       //   colorText: Colors.white,
  //       // );
  //     } finally {
  //       isLoading.value = false;
  //     }
  //   }
  // Add this method to handle proximity alerts consistently
  /// 08/10/2025 OLD
  // Future<void> _triggerProximityAlert(
  //   TransportLocation crossing,
  //   double distance,
  // ) async {
  //   if (!settingController.isWarningsEnabled.value) return;
  //
  //   final message =
  //       "You are near this crossing - ${crossing.street ?? 'railway crossing'} "
  //       "(${formatDistance(distance)})";
  //
  //   // Always show notification
  //   await NotificationService().showNotifications(
  //     "🚂 Railway Crossing Alert",
  //     message,
  //   );
  //
  //   // Play sound if enabled
  //   if (settingController.isWarningSoundEnabled.value) {
  //     await player.stop();
  //     await player.setVolume(1.0);
  //     await player.play();
  //   }
  //
  //   // Vibrate if enabled
  //   if (settingController.isVibrationEnabled.value &&
  //       (await Vibration.hasVibrator() ?? false)) {
  //     if (distance < 50) {
  //       Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
  //     } else {
  //       Vibration.vibrate(duration: 500);
  //     }
  //   }
  //
  //   // Voice alert if enabled
  //   if (settingController.isWarningSoundEnabled.value) {
  //     await speak("Warning! You are near a railway crossing");
  //   }
  // }
 // 08/10/2025 NEW
  //13/10/2025
  final Map<String, DateTime> _lastAlertTimes = {};
  final Duration _alertCooldown = Duration(seconds: 30);
  //
  // Future<void> _triggerProximityAlert(
  //     TransportLocation crossing,
  //     double distance,
  //     ) async {
  //   log_print.log('🚨 _triggerProximityAlert() called for ${crossing.street}');
  //
  //   if (!settingController.isWarningsEnabled.value) {
  //     log_print.log('⚠️ Warnings disabled in settings, skipping');
  //     return;
  //   }
  //
  //   // Cooldown check
  //   final crossingKey = '${crossing.latitude}_${crossing.longitude}';
  //
  //   if (_lastAlertTimes.containsKey(crossingKey)) {
  //     final lastAlert = _lastAlertTimes[crossingKey]!;
  //     final timeSinceLastAlert = DateTime.now().difference(lastAlert);
  //
  //     if (timeSinceLastAlert < _alertCooldown) {
  //       log_print.log('⏳ Cooldown active (${timeSinceLastAlert.inSeconds}s/${_alertCooldown.inSeconds}s), skipping');
  //       return;
  //     }
  //   }
  //
  //   // Record alert time
  //   _lastAlertTimes[crossingKey] = DateTime.now();
  //   log_print.log('✅ Cooldown cleared, proceeding with alert');
  //
  //   // Determine alert level
  //   String alertLevel = '';
  //   if (distance < 50) {
  //     alertLevel = 'IMMEDIATE';
  //   } else if (distance < 100) {
  //     alertLevel = 'CLOSE';
  //   } else if (distance < 200) {
  //     alertLevel = 'APPROACHING';
  //   } else {
  //     alertLevel = 'NEARBY';
  //   }
  //
  //   final message = '$alertLevel: Railway Crossing - ${crossing.street ?? "Unknown crossing"} (${formatDistance(distance)})';
  //   log_print.log('📝 Alert message: $message');
  //
  //   // 1. Notification
  //   try {
  //     await NotificationService().showNotifications(
  //       '🚂 Railway Crossing Alert',
  //       message,
  //     );
  //     log_print.log('✅ Notification sent');
  //   } catch (e) {
  //     log_print.log('❌ Notification failed: $e');
  //   }
  //
  //   // 2. Sound
  //   if (settingController.isWarningSoundEnabled.value) {
  //     try {
  //       await player.stop();
  //       await player.setVolume(1.0);
  //       await player.play();
  //       log_print.log('✅ Sound played');
  //     } catch (e) {
  //       log_print.log('❌ Sound failed: $e');
  //     }
  //   } else {
  //     log_print.log('⏭️  Sound disabled in settings');
  //   }
  //
  //   // 3. Vibration
  //   if (settingController.isVibrationEnabled.value) {
  //     try {
  //       final hasVibrator = await Vibration.hasVibrator() ?? false;
  //       if (hasVibrator) {
  //         if (distance < 50) {
  //           Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
  //         } else if (distance < 100) {
  //           Vibration.vibrate(pattern: [0, 300, 300, 300]);
  //         } else {
  //           Vibration.vibrate(duration: 500);
  //         }
  //         log_print.log('✅ Vibration triggered');
  //       } else {
  //         log_print.log('⚠️ No vibrator available');
  //       }
  //     } catch (e) {
  //       log_print.log('❌ Vibration failed: $e');
  //     }
  //   } else {
  //     log_print.log('⏭️  Vibration disabled in settings');
  //   }
  //
  //   // 4. Voice
  //   if (settingController.isWarningSoundEnabled.value) {
  //     try {
  //       String voiceMessage = '';
  //       if (distance < 50) {
  //         voiceMessage = 'Warning! Railway crossing very close, only ${formatDistance(distance)} ahead';
  //       } else if (distance < 100) {
  //         voiceMessage = 'Caution! Railway crossing ahead in ${formatDistance(distance)}';
  //       } else {
  //         voiceMessage = 'Railway crossing approaching in ${formatDistance(distance)}';
  //       }
  //       await speak(voiceMessage);
  //       log_print.log('✅ Voice alert spoken: $voiceMessage');
  //     } catch (e) {
  //       log_print.log('❌ Voice failed: $e');
  //     }
  //   } else {
  //     log_print.log('⏭️  Voice disabled in settings');
  //   }
  //
  //   log_print.log('✅ Alert complete for ${crossing.street}');
  // }
  Future<void> _triggerProximityAlert(
      TransportLocation crossing,
      double distance,
      ) async {
    log_print.log('🚨 _triggerProximityAlert() called for ${crossing.street}');

    if (!settingController.isWarningsEnabled.value) {
      log_print.log('⚠️ Warnings disabled in settings, skipping');
      return;
    }

    // Cooldown check
    final crossingKey = '${crossing.latitude}_${crossing.longitude}';

    if (_lastAlertTimes.containsKey(crossingKey)) {
      final lastAlert = _lastAlertTimes[crossingKey]!;
      final timeSinceLastAlert = DateTime.now().difference(lastAlert);

      if (timeSinceLastAlert < _alertCooldown) {
        log_print.log('⏳ Cooldown active, skipping');
        return;
      }
    }

    // Record alert time
    _lastAlertTimes[crossingKey] = DateTime.now();

    // Determine alert level
    String alertLevel = '';
    if (distance < 50) {
      alertLevel = 'IMMEDIATE';
    } else if (distance < 100) {
      alertLevel = 'CLOSE';
    } else if (distance < 200) {
      alertLevel = 'APPROACHING';
    } else {
      alertLevel = 'NEARBY';
    }

    final message = '$alertLevel: Railway Crossing - ${crossing.street ?? "Unknown crossing"} (${formatDistance(distance)})';
    log_print.log('📢 Alert message: $message');

    // ✅ Use HIGH PRIORITY notification channel for alerts
    const AndroidNotificationDetails androidAlertDetails = AndroidNotificationDetails(
      'railway_crossing_alerts', // Different channel from persistent notification
      'Railway Crossing Alerts',
      channelDescription: 'High priority alerts for nearby railway crossings',
      importance: Importance.high, // ✅ HIGH priority
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails alertNotificationDetails = NotificationDetails(
      android: androidAlertDetails,
    );

    // Show alert notification (different ID from persistent notification)
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      '🚂 Railway Crossing Alert',
      message,
      alertNotificationDetails,
    );
    log_print.log('✅ Notification sent');

    // Sound
    if (settingController.isWarningSoundEnabled.value) {
      try {
        await player.stop();
        await player.setVolume(1.0);
        await player.play();
        log_print.log('✅ Sound played');
      } catch (e) {
        log_print.log('❌ Sound failed: $e');
      }
    }

    // Vibration
    if (settingController.isVibrationEnabled.value) {
      try {
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          if (distance < 50) {
            Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
          } else if (distance < 100) {
            Vibration.vibrate(pattern: [0, 300, 300, 300]);
          } else {
            Vibration.vibrate(duration: 500);
          }
          log_print.log('✅ Vibration triggered');
        }
      } catch (e) {
        log_print.log('❌ Vibration failed: $e');
      }
    }

    // Voice (only if app is in foreground)
    if (settingController.isWarningSoundEnabled.value && Get.context?.mounted == true) {
      try {
        String voiceMessage = '';
        if (distance < 50) {
          voiceMessage = 'Warning! Railway crossing very close, only ${formatDistance(distance)} ahead';
        } else if (distance < 100) {
          voiceMessage = 'Caution! Railway crossing ahead in ${formatDistance(distance)}';
        } else {
          voiceMessage = 'Railway crossing approaching in ${formatDistance(distance)}';
        }
        await speak(voiceMessage);
        log_print.log('✅ Voice alert spoken: $voiceMessage');
      } catch (e) {
        log_print.log('❌ Voice failed: $e');
      }
    }

    log_print.log('✅ Alert complete for ${crossing.street}');
  }
// ==========================================
// TESTING BUTTON (Add to your UI)
// ==========================================
  Future<void> testBackgroundAlert() async {
    log_print.log('');
    log_print.log('🧪🧪🧪 MANUAL BACKGROUND TEST 🧪🧪🧪');
    log_print.log('═══════════════════════════════════════');
    log_print.log('Current State:');
    log_print.log('  • App in background: ${!Get.context!.mounted}');
    log_print.log('  • Location stream active: ${_positionStream != null}');
    log_print.log('  • User position: ${userPosition.value?.latitude}, ${userPosition.value?.longitude}');
    log_print.log('  • Is navigating: ${isNavigating.value}');
    log_print.log('  • Nearby crossings: ${nearbyLocations.length}');
    log_print.log('  • Route crossings: ${crossingsAlongRoute.length}');
    log_print.log('  • Warnings enabled: ${settingController.isWarningsEnabled.value}');
    log_print.log('─────────────────────────────────────');

    if (nearbyLocations.isEmpty) {
      log_print.log('❌ No crossings available for testing');

      // Try to fetch crossings
      log_print.log('🔄 Attempting to fetch crossings...');
      if (userPosition.value != null) {
        final placemarks = await geocoding.placemarkFromCoordinates(
          userPosition.value!.latitude,
          userPosition.value!.longitude,
        );
        final cityName = placemarks.isNotEmpty ? placemarks[0].locality?.toUpperCase() : '';
        await fetchLocations(cityName: cityName ?? "");
        log_print.log('✅ Crossings fetched: ${nearbyLocations.length}');
      }
    }

    if (nearbyLocations.isNotEmpty) {
      final testCrossing = nearbyLocations.first;
      log_print.log('Testing with crossing: ${testCrossing.street}');
      log_print.log('Location: ${testCrossing.latitude}, ${testCrossing.longitude}');

      await _triggerProximityAlert(testCrossing, 75.0);

      log_print.log('✅ Test alert triggered');
    }

    log_print.log('═══════════════════════════════════════');
  }

// ✅ Add this to check stream status
  void debugLocationStream() {
    log_print.log('');
    log_print.log('🔍 LOCATION STREAM DEBUG');
    log_print.log('═══════════════════════════════════════');
    log_print.log('Stream Status:');
    log_print.log('  • Stream exists: ${_positionStream != null}');
    log_print.log('  • Stream paused: ${_positionStream?.isPaused ?? "N/A"}');
    log_print.log('  • Tracking active: ${isTrackingLocation.value}');
    log_print.log('  • Last position time: ${userPosition.value?.timestamp}');
    log_print.log('  • Position age: ${userPosition.value != null ? DateTime.now().difference(userPosition.value!.timestamp).inSeconds : "N/A"}s');
    log_print.log('═══════════════════════════════════════');
    log_print.log('');
  }

// ✅ Call this every 10 seconds when app is in background
  Timer? _debugTimer;

  void startBackgroundDebugTimer() {
    _debugTimer?.cancel();
    _debugTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!Get.context!.mounted) { // App is in background
        debugLocationStream();
        log_print.log('⏰ Background check: Location updates ${DateTime.now().difference(userPosition.value?.timestamp ?? DateTime.now()).inSeconds}s ago');
      }
    });
  }

  void stopBackgroundDebugTimer() {
    _debugTimer?.cancel();
  }

  Future<void> testCrossingAlert() async {
    log_print.log('═══════════════════════════════════════');
    log_print.log('🧪 MANUAL TEST ALERT');
    log_print.log('═══════════════════════════════════════');

    log_print.log('User position: ${userPosition.value?.latitude}, ${userPosition.value?.longitude}');
    log_print.log('Nearby crossings count: ${nearbyLocations.length}');
    log_print.log('Warnings enabled: ${settingController.isWarningsEnabled.value}');

    if (nearbyLocations.isEmpty) {
      log_print.log('❌ No crossings available for testing');
      Get.snackbar(
        'Test Failed',
        'No crossings loaded. Make sure location services are working.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final testCrossing = nearbyLocations.first;
    log_print.log('Testing with crossing: ${testCrossing.street}');

    await _triggerProximityAlert(testCrossing, 75.0);

    Get.snackbar(
      'Test Alert Sent',
      'Check notifications and console logs',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    log_print.log('✅ Test complete');
    log_print.log('═══════════════════════════════════════');
  }
}
