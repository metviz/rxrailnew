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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Download Offline Map",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () async {
                await controller.crossingController
                    .downloadOfflineMapByCurrentState();
                await controller.crossingController
                    .checkOfflineMapAvailability();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon(Icons.download_rounded, color: AppColors.black, size: 18.sp),
                    // SizedBox(width: 8.w),
                    Text(
                      "Download",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
}
