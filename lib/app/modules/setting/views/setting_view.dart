import 'package:RXrail/app/utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/setting_controller.dart';

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32.h),

            // Warnings Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // light shadow
                    blurRadius: 12, // soft blur
                    spreadRadius: 1, // subtle spread
                    offset: const Offset(0, 4), // slight downward shadow
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Warnings'),
                    SizedBox(height: 20.h),
                    // Warnings Toggle
                    _buildToggleItem(
                      title: 'Warnings',
                      subtitle: 'Enable or disable warnings',
                      value: controller.isWarningsEnabled,
                      onChanged: controller.toggleWarnings,
                    ),
                    SizedBox(height: 20.h),
                    // Warning Distance
                    _buildDistanceSection(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Distance Unit
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // light shadow
                    blurRadius: 12, // soft blur
                    spreadRadius: 1, // subtle spread
                    offset: const Offset(0, 4), // slight downward shadow
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: _buildDistanceUnitSection(),
              ),
            ),

            SizedBox(height: 20.h),

            // Warning Method Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // light shadow
                    blurRadius: 12, // soft blur
                    spreadRadius: 1, // subtle spread
                    offset: const Offset(0, 4), // slight downward shadow
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Warning Method'),
                    SizedBox(height: 24.h),

                    // Warning Sound
                    _buildToggleItem(
                      title: 'Warning Sound',
                      subtitle: 'Select the sound for warnings',
                      value: controller.isWarningSoundEnabled,
                      onChanged: controller.toggleWarningSound,
                    ),

                    SizedBox(height: 24.h),

                    // Vibration Intensity
                    _buildToggleItem(
                      title: 'Vibration Alerts',
                      subtitle: 'Enable or disable vibration alerts',
                      value: controller.isVibrationEnabled,
                      onChanged: controller.toggleVibration,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25.h),
            // Offline Maps Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // light shadow
                    blurRadius: 12, // soft blur
                    spreadRadius: 1, // subtle spread
                    offset: const Offset(0, 4), // slight downward shadow
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Offline Maps'),
                    SizedBox(height: 12.h),

                    _buildOfflineMapSection(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 25.h),
            // Test Logs Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: _buildTestLogsSection(),
              ),
            ),
            SizedBox(height: 25.h),
            // Location Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // light shadow
                    blurRadius: 12, // soft blur
                    spreadRadius: 1, // subtle spread
                    offset: const Offset(0, 4), // slight downward shadow
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Location'),
                    SizedBox(height: 24.h),

                    // Location Permissions
                    _buildLocationPermissionItem(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineMapSection() {
    final cc = controller.crossingController;
    return Obx(() {
      final isDownloading = cc.isDownloadingOfflineMap.value;
      final hasMap = cc.hasOfflineMap.value;
      final hasPartial = cc.hasPartialDownload.value;
      final progress = cc.offlineMapDownloadProgress.value;
      final downloaded = cc.downloadedTiles.value;
      final total = cc.totalTiles.value;
      final partialDownloaded = cc.partialDownloadedTiles.value;
      final partialTotal = cc.partialTotalTiles.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: label + action button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Download Offline Map",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (hasPartial && !isDownloading && !hasMap)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Row(
                          children: [
                            Icon(Icons.pause_circle_outline,
                                color: Colors.blue, size: 13.sp),
                            SizedBox(width: 4.w),
                            Text(
                              partialTotal > 0
                                  ? "Paused — $partialDownloaded / $partialTotal tiles"
                                  : "Download paused",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (hasMap && !isDownloading)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 13.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  "Map downloaded",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (cc.offlineMapLastUpdated.value != null)
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Text(
                                  "Last updated: ${_formatMapDate(cc.offlineMapLastUpdated.value!)}",
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (isDownloading)
                InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () => cc.cancelOfflineMapDownload(),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else if (hasPartial)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: () async {
                        await cc.resumeOfflineMapDownload();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Text(
                          "Resume",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: () async {
                        await cc.downloadOfflineMapByCurrentState();
                        await cc.checkOfflineMapAvailability();
                      },
                      child: Text(
                        "Restart",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () async {
                    await cc.downloadOfflineMapByCurrentState();
                    await cc.checkOfflineMapAvailability();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      hasMap ? "Re-download" : "Download",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Progress area — only shown while downloading
          if (isDownloading) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  total > 0
                      ? "$downloaded / $total tiles"
                      : "Preparing download…",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "${progress.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6.h,
                backgroundColor: Colors.grey[200],
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required RxBool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value.value,
              onChanged: onChanged,
              activeColor: AppColors.colorFFFFFF,
              activeTrackColor: Color(0xFFFFC107),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Row(
          children: [
            Text(
              'Warning Distance (100=500m)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Spacer(),
            Obx(
              () => Text(
                '${controller.warningDistance.value.round()}',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(
          () => SliderTheme(
            data: SliderTheme.of(Get.context!).copyWith(
              activeTrackColor: Color(0xFFFFC107),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Color(0xFFFFC107),
              overlayColor: Colors.black.withOpacity(0.1),
              trackHeight: 3.h,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              padding: EdgeInsets.all(8.w),
              value: controller.warningDistance.value,
              min: 100,
              max: 500,
              onChanged: controller.updateWarningDistance,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance Unit',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        Obx(
          () => Row(
            children: [
              _buildUnitButton(
                'meters',
                controller.distanceUnit.value == 'meters',
              ),
              SizedBox(width: 10.w),
              _buildUnitButton(
                'kilometers',
                controller.distanceUnit.value == 'kilometers',
              ),
              SizedBox(width: 10.w),
              _buildUnitButton(
                'miles',
                controller.distanceUnit.value == 'miles',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitButton(String unit, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.updateDistanceUnit(unit),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFC107) : Colors.white,
            borderRadius: BorderRadius.circular(5.r),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              unit.capitalizeFirst!,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? Colors.black : Colors.grey[800],
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestLogsSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.refreshLogInfo());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Test Logs'),
        SizedBox(height: 10.h),
        Text(
          'Logs are saved to device storage while the app runs. '
          'Connect via USB and run the ADB command to retrieve them.',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 12.h),

        // File path + size
        Obx(() => Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.logFilePath.value.isEmpty
                        ? 'No log file yet — start tracking to begin'
                        : controller.logFilePath.value,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[700],
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (controller.logFilePath.value.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Size: ${controller.logFileSize.value}',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            )),

        SizedBox(height: 12.h),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () => controller.copyAdbCommand(),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Copy ADB Command',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () => controller.clearLogs(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationPermissionItem() {
    return Obx(() {
      final isGranted = controller.isLocationPermissionGranted.value;
      final isLoading = controller.isLocationPermissionLoading.value;

      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Permissions',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isGranted
                      ? 'Background location access enabled'
                      : 'Manage location permissions for\nbackground GPS',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap:
                  isGranted
                      ? null
                      : () => controller.requestLocationPermission(),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient:
                      isGranted
                          ? null
                          : LinearGradient(
                            colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  color: isGranted ? Colors.grey[300] : null,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    if (!isGranted)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGranted ? 'Allowed' : 'Allow',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isGranted ? Colors.grey[700] : AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  String _formatMapDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
