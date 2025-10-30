import 'dart:math' as math;
import 'package:RXrail/app/model/transport_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../../../routes/app_pages.dart';
import '../../../utils/app_assets.dart';
import '../../../utils/app_color.dart';
import '../../../utils/text_style.dart';
import '../controllers/crossing_controller.dart';

class CrossingView extends GetView<CrossingController> {
  const CrossingView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize location when view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeOnPageOpen();
    });

    return Scaffold(
      backgroundColor: AppColors.colorFFFFFF,
      body: WillPopScope(
        onWillPop: () async {
          if (controller.isNavigating.value) {
            Get.dialog(
              AlertDialog(
                title: Text("Exit Navigation"),
                content: Text("Are you sure you want to stop navigation?"),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.stopNavigation();
                      Get.back();
                    },
                    child: Text("Stop"),
                  ),
                ],
              ),
            );
            return false;
          }
          return true;
        },
        child: SafeArea(
          child: Obx(() {
            // Show loading indicator while initializing
            if (controller.isLoading.value &&
                controller.userPosition.value == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16.h),
                    Text("Getting your location..."),
                  ],
                ),
              );
            }
            final userPos = controller.userPosition.value;
            if (userPos == null) {
              return Center(child: Text("Unable to determine location."));
            }

            final userLatLng = LatLng(userPos.latitude, userPos.longitude);

            return Stack(
              children: [
                // Map View
                _buildMapView(context, userLatLng),

                // Navigation controls
                if (controller.isNavigating.value) _buildNavigationControls(),
                // if (controller.isNavigating.value)
                //   Positioned(
                //     left: 8,
                //     right: 8,
                //     bottom: 50,
                //     child: Row(
                //       children: [
                //         InkWell(
                //           onTap: () {
                //             Clipboard.setData(
                //               ClipboardData(
                //                 text: controller.destinationGeocoded,
                //               ),
                //             );
                //           },
                //           child: Container(
                //             height: 50,
                //             padding: EdgeInsets.all(10),
                //             decoration: BoxDecoration(
                //               color: Colors.blue,
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.center,
                //               children: [
                //                 Text(
                //                   "Destination",
                //                   style: TextStyle(
                //                     color: Colors.white,
                //                     fontSize: 14.w,
                //                     fontWeight: FontWeight.w600,
                //                   ),
                //                 ),
                //                 SizedBox(width: 5),
                //                 Icon(Icons.copy_rounded, color: Colors.white),
                //               ],
                //             ),
                //           ),
                //         ),
                //         SizedBox(width: 10),
                //         InkWell(
                //           onTap: () {
                //             Clipboard.setData(
                //               ClipboardData(
                //                 text: controller.routingResponse,
                //               ),
                //             );
                //           },
                //           child: Container(
                //             height: 50,
                //             padding: EdgeInsets.all(10),
                //             decoration: BoxDecoration(
                //               color: Colors.blue,
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.center,
                //               children: [
                //                 Text(
                //                   "Routing Response",
                //                   style: TextStyle(
                //                     color: Colors.white,
                //                     fontSize: 14.w,
                //                     fontWeight: FontWeight.w600,
                //                   ),
                //                 ),
                //                 SizedBox(width: 5),
                //                 Icon(Icons.copy_rounded, color: Colors.white),
                //               ],
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),

                // if (controller.isNavigating.value)
                //   Positioned(
                //     left: 8,
                //     right: 8,
                //     bottom: 110,
                //     child: Row(
                //       children: [
                //         InkWell(
                //           onTap: () {
                //             Clipboard.setData(
                //               ClipboardData(
                //                 text: controller.distanceLogs.toString(),
                //               ),
                //             );
                //           },
                //           child: Container(
                //             height: 50,
                //             padding: EdgeInsets.all(10),
                //             decoration: BoxDecoration(
                //               color: Colors.blue,
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.center,
                //               children: [
                //                 Text(
                //                   "Distance Logs",
                //                   style: TextStyle(
                //                     color: Colors.white,
                //                     fontSize: 14.w,
                //                     fontWeight: FontWeight.w600,
                //                   ),
                //                 ),
                //                 SizedBox(width: 5),
                //                 Icon(Icons.copy_rounded, color: Colors.white),
                //               ],
                //             ),
                //           ),
                //         ),
                //         SizedBox(width: 10),
                //         // InkWell(
                //         //   onTap: () {
                //         //     Clipboard.setData(
                //         //       ClipboardData(
                //         //         text: controller.distanceLogsUpdated.toString(),
                //         //       ),
                //         //     );
                //         //   },
                //         //   child: Container(
                //         //     height: 50,
                //         //     padding: EdgeInsets.all(10),
                //         //     decoration: BoxDecoration(
                //         //       color: Colors.blue,
                //         //       borderRadius: BorderRadius.circular(8),
                //         //     ),
                //         //     child: Row(
                //         //       mainAxisAlignment: MainAxisAlignment.center,
                //         //       children: [
                //         //         Text(
                //         //           "Dist. Logs Updated",
                //         //           style: TextStyle(
                //         //             color: Colors.white,
                //         //             fontSize: 14.w,
                //         //             fontWeight: FontWeight.w600,
                //         //           ),
                //         //         ),
                //         //         SizedBox(width: 5),
                //         //         Icon(Icons.copy_rounded, color: Colors.white),
                //         //       ],
                //         //     ),
                //         //   ),
                //         // ),
                //       ],
                //     ),
                //   ),
                // Route info panel
                // if (controller.isRouteReady.value || controller.isNavigating.value)
                //   _buildRouteInfoPanel(),

                // Nearest crossing bottom sheet
                if (controller.isNavigating.value &&
                    controller.nearestCrossing.value != null &&
                    controller.showNearestCrossingSheet.value)
                  _buildNearestCrossingSheet(),

                // Info window for selected crossing
                if (controller.showInfoWindow.value &&
                    controller.selectedCrossing.value != null)
                  _buildInfoWindow(context),

                // Floating action buttons
                _buildFloatingButtons(context),
              ],
            );
          }),
        ),
      ),
    );
  }

  // Enhance the _buildNavigationControls method:
  Widget _buildNavigationControls() {
    return Positioned(
      top: 20.h,
      right: 20.w,
      child: Column(
        children: [
          // Stop Navigation Button
          FloatingActionButton(
            heroTag: 'stop_nav',
            mini: true,
            onPressed: () {
              controller.stopNavigation();
              controller.speak("Navigation stopped");
            },
            child: Icon(Icons.stop, color: Colors.white),
            backgroundColor: Colors.red,
          ),
          SizedBox(height: 10.h),

          // Recenter Map Button
          Obx(
            () => FloatingActionButton(
              heroTag: 'recenter',
              mini: true,
              onPressed: () => controller.recenterMap(),
              child: Icon(
                controller.hasUserAdjustedZoom.value
                    ? Icons.location_searching
                    : Icons.my_location,
                color: Colors.white,
              ),
              backgroundColor: Colors.blue,
            ),
          ),

          SizedBox(height: 10.h),

          // Refresh Location Button (during navigation)
          FloatingActionButton(
            heroTag: 'refresh_nav',
            mini: true,
            onPressed: () => controller.refreshCurrentLocation(),
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? SizedBox(
                        width: 15.w,
                        height: 15.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Icon(Icons.refresh, color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),

          SizedBox(height: 10.h),

          // Toggle Crossing Sheet Button
          Obx(() {
            return controller.nearestCrossing.value != null
                ? FloatingActionButton(
                  heroTag: 'toggle_sheet',
                  mini: true,
                  onPressed: () => controller.toggleNearestCrossingSheet(),
                  backgroundColor: Colors.blue,
                  child: Obx(
                    () => Icon(
                      controller.showNearestCrossingSheet.value
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.white,
                    ),
                  ),
                )
                : SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Map status indicator
        // Obx(() => Container(
        //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        //   decoration: BoxDecoration(
        //     color: controller.hasOfflineMap.value
        //         ? Colors.green.withOpacity(0.9)
        //         : Colors.orange.withOpacity(0.9),
        //     borderRadius: BorderRadius.circular(20.r),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(
        //         controller.hasOfflineMap.value
        //             ? Icons.offline_pin
        //             : Icons.wifi,
        //         color: Colors.white,
        //         size: 16.sp,
        //       ),
        //       SizedBox(width: 4.w),
        //       Text(
        //         controller.hasOfflineMap.value
        //             ? "Offline Mode"
        //             : "Online Mode",
        //         style: styleW600(size: 12.sp, color: Colors.white),
        //       ),
        //     ],
        //   ),
        // )),
        SizedBox(height: 10.h),
        if (controller.isRouteReady.value && !controller.isNavigating.value)
          Padding(
            padding: EdgeInsets.only(bottom: 30.h, left: 10.w),
            child: FloatingActionButton.extended(
              onPressed: () {
                controller.isNavigating.value = true;
                controller
                    .startNavigationUpdates(); // This will now handle the zoom
                controller.speak("Starting navigation");
              },
              label: Text(
                "Start Navigation",
                style: styleW600(size: 12.sp, color: AppColors.colorFFFFFF),
              ),
              icon: Icon(Icons.directions),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        // FloatingActionButton.extended(
        //   onPressed: () async {
        //     await controller.downloadOfflineMapByCurrentState();
        //     // Refresh offline map availability after download
        //     await controller.checkOfflineMapAvailability();
        //   },
        //   label: Text("Download Offline Map"),
        //   icon: Icon(Icons.download),
        //   backgroundColor: Colors.amberAccent,
        // ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildMapView(BuildContext context, LatLng userLatLng) {
    return Obx(() {
      return FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          minZoom: 14,
          initialCenter: userLatLng,
          initialZoom: controller.isNavigating.value ? 18 : 15,
          initialRotation: controller.mapRotation.value,
          onPositionChanged: (position, _) {
            controller.onMapMoved(position);
          },
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onTap: (_, __) => controller.showInfoWindow.value = false,
        ),
        children: [
          // TileLayer(
          //   urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          //   subdomains: const ['a', 'b', 'c', 'd'],
          //   userAgentPackageName: 'com.example.cross_aware',
          //   // tileProvider: FMTCStore('offline_tiles').getTileProvider(),
          // ),
          // TileLayer(
          //   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          //   subdomains: [],
          //   userAgentPackageName: 'com.example.cross_aware',
          //   tileProvider: FMTCStore('offline_tiles').getTileProvider(),
          // ),
          if (controller.hasOfflineMap.value)
            FutureBuilder<String?>(
              future: controller.getCurrentStateCode(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cross_aware',
                    tileProvider: FMTCStore('offline_tiles_${snapshot.data}').getTileProvider(),
                  );
                }
                // Fallback to online if state detection fails
                return TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.cross_aware',
                );
              },
            )
          else
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.cross_aware',
            ),
          TileLayer(
            urlTemplate: 'https://{s}.tiles.openrailwaymap.org/standard/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            backgroundColor: Colors.transparent,
          ),
          // Route polyline
          PolylineLayer(
            polylines: [
              Polyline(
                points:
                    controller.visibleRoute.isNotEmpty
                        ? controller.visibleRoute
                        : controller.routeCoordinates,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),

          // User position marker with proper rotation
          MarkerLayer(
            markers: [
              Marker(
                point: userLatLng,
                width: 30,
                height: 30,
                child: Obx(() {
                  // Use bearing for navigation mode, otherwise use map rotation
                  final angleRad =
                      controller.isNavigating.value
                          ? (controller.userBearing.value) * (math.pi / 180.0)
                          : (controller.mapRotation.value) * (math.pi / 180.0);

                  return Transform.rotate(
                    angle: angleRad,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.navigation,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
              ),

              if (controller.toLocation.value != null &&
                  controller.isRouteReady.value)
                Marker(
                  point: controller.toLocation.value!,
                  width: 30,
                  height: 30,
                  child: Icon(Icons.location_on, color: Colors.red, size: 30),
                ),

              // Nearby crossings
              ...controller.nearbyLocations
                  .where((_) => controller.currentZoom.value >= 13)
                  .map(
                    (loc) => Marker(
                      point: LatLng(
                        double.parse(loc.latitude!),
                        double.parse(loc.longitude!),
                      ),
                      width: 24,
                      height: 24,
                      child: Tooltip(
                        message: loc.crossingid ?? 'Unknown crossing',
                        child: GestureDetector(
                          onTap: () {
                            controller.selectedCrossing.value = loc;
                            controller.showInfoWindow.value = true;
                          },
                          child: Image.asset(AppAssets.crossingImg),
                        ),
                      ),
                    ),
                  ),

              // Crossings along route (highlighted)
              ...controller.crossingsAlongRoute.map(
                (loc) => Marker(
                  point: LatLng(
                    double.parse(loc.latitude!),
                    double.parse(loc.longitude!),
                  ),
                  width: 30,
                  height: 30,
                  child: Tooltip(
                    message: "Warning! Close to route: ${loc.crossingid}",
                    child: GestureDetector(
                      onTap: () {
                        controller.selectedCrossing.value = loc;
                        controller.showInfoWindow.value = true;
                      },
                      child: Icon(
                        Icons.warning,
                        color: Colors.red.shade900,
                        size: 16.w,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildNearestCrossingSheet() {
    final crossing = controller.nearestCrossing.value;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Nearest Railway Crossing",
                  style: styleW700(size: 16.sp, color: Colors.black),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20.sp),
                  onPressed: () => controller.toggleNearestCrossingSheet(),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Crossing Info
            if (crossing != null) ...[
              _buildCrossingTile(crossing),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.route, size: 16.sp, color: Colors.blue),
                  SizedBox(width: 6.w),
                  Text(
                    "Distance: ",
                    style: styleW600(size: 14.sp, color: Colors.black54),
                  ),
                  Text(
                    controller.formatDistance(
                      controller.distanceToNearestCrossing.value,
                    ),
                    style: styleW600(size: 14.sp, color: Colors.redAccent),
                  ),
                ],
              ),
            ],

            // Upcoming Crossings (if any)
            if (controller.upcomingCrossings.isNotEmpty) ...[
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Upcoming Crossings",
                  style: styleW700(size: 16.sp, color: Colors.black87),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 100.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.upcomingCrossings.length,
                  itemBuilder: (context, index) {
                    return _buildCrossingTile(
                      controller.upcomingCrossings[index],
                    );
                  },
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCrossingTile(TransportLocation crossing) {
    return Container(
      width: 230.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10.r,
                backgroundColor: Colors.redAccent,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 12.sp,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  crossing.street ?? 'Unnamed Street',
                  style: styleW600(size: 14.sp, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            "ID: ${crossing.crossingid}",
            style: styleW500(size: 12.sp, color: Colors.black54),
          ),
          if (crossing.crossingposition != null)
            Text(
              "Position: ${crossing.crossingposition}",
              style: styleW500(size: 12.sp, color: Colors.black54),
            ),
          if (crossing.cityname != null)
            Text(
              "City: ${crossing.cityname}",
              style: styleW500(size: 12.sp, color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoWindow(BuildContext context) {
    return Builder(
      builder: (context) {
        final crossing = controller.selectedCrossing.value!;
        final crossingLatLng = LatLng(
          double.parse(crossing.latitude!),
          double.parse(crossing.longitude!),
        );

        // Convert LatLng to screen coordinates
        final screenPoint = _latLngToScreenPoint(
          crossingLatLng,
          controller.mapController,
          context,
        );

        if (screenPoint == null) {
          return SizedBox.shrink();
        }

        const infoWindowWidth = 280.0;
        const infoWindowHeight = 200.0;
        const markerHeight = 25.0;
        const offset = 1.0;

        final screenSize = MediaQuery.of(context).size;

        double left = screenPoint.dx - (infoWindowWidth / 2);
        if (left < 12) left = 12;
        if (left + infoWindowWidth > screenSize.width - 12) {
          left = screenSize.width - infoWindowWidth - 12;
        }

        double top = screenPoint.dy - infoWindowHeight - markerHeight - offset;
        if (top < 100) {
          top = screenPoint.dy + markerHeight + offset;
        }

        return Positioned(
          left: left,
          top: top,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.black, width: 2),
            ),
            width: infoWindowWidth,
            constraints: BoxConstraints(maxHeight: infoWindowHeight),
            child: _buildCrossingInfoWindow(crossing),
          ),
        );
      },
    );
  }

  Widget _buildCrossingInfoWindow(TransportLocation crossing) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: InkWell(
                onTap: () {
                  controller.showInfoWindow.value = false;
                  Get.toNamed(
                    Routes.CROSSING_DETAIL,
                    arguments: {'crossingDetail': crossing},
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5.h),
                          if (crossing.crossingid != null)
                            _buildCompactDetailRow(
                              "Crossing ID:",
                              crossing.crossingid!,
                            ),
                          SizedBox(height: 5.h),
                          if (crossing.street != null)
                            _buildCompactDetailRow("Street:", crossing.street!),
                          SizedBox(height: 5.h),
                          if (crossing.crossingposition != null)
                            _buildCompactDetailRow(
                              "Position:",
                              crossing.crossingposition!,
                            ),

                          if (crossing.cityname != null ||
                              crossing.statename != null)
                            _buildCompactDetailRow(
                              "Location:",
                              "${crossing.cityname ?? ''}, ${crossing.statename ?? ''}"
                                  .replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: styleW600(size: 14.sp, color: Colors.grey.shade600)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: styleW500(size: 14.sp, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Offset? _latLngToScreenPoint(
    LatLng latLng,
    MapController mapController,
    BuildContext context,
  ) {
    try {
      final camera = mapController.camera;
      final point = camera.project(latLng);
      final pixelOrigin = camera.pixelOrigin;

      final pos = Point<double>(
        point.x - pixelOrigin.x.toDouble(),
        point.y - pixelOrigin.y.toDouble(),
      );

      final screenSize = MediaQuery.of(context).size;
      if (pos.x >= 0 &&
          pos.x <= screenSize.width &&
          pos.y >= 0 &&
          pos.y <= screenSize.height) {
        return Offset(pos.x, pos.y);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
