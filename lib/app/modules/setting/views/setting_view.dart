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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32.h),

            // Warnings Section
            _buildSectionTitle('Warnings'),
            SizedBox(height: 24.h),

            // Warnings Toggle
            _buildToggleItem(
              title: 'Warnings',
              subtitle: 'Enable or disable warnings',
              value: controller.isWarningsEnabled,
              onChanged: controller.toggleWarnings,
            ),

            SizedBox(height: 32.h),

            // Warning Distance
            _buildDistanceSection(),

            SizedBox(height: 32.h),

            // Distance Unit
            _buildDistanceUnitSection(),

            SizedBox(height: 48.h),

            // Warning Method Section
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

            SizedBox(height: 48.h),
            // Offline Maps Section
            _buildSectionTitle('Offline Maps'),
            SizedBox(height: 24.h),

            _buildOfflineMapSection(),
            SizedBox(height: 48.h),
            // Location Section
            _buildSectionTitle('Location'),
            SizedBox(height: 24.h),

            // Location Permissions
            _buildLocationPermissionItem(),

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
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            GestureDetector(
              onTap: () async {
                await controller.crossingController.downloadOfflineMapByCurrentState();
                await controller.crossingController.checkOfflineMapAvailability();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "Download",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
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
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
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
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Obx(
          () => Switch(
            value: value.value,
            onChanged: onChanged,
            activeColor: AppColors.colorFFFFFF,
            activeTrackColor: Color(0xFFFFC107),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text(
        //           'Warning Distance',
        //           style: TextStyle(
        //             fontSize: 18.sp,
        //             fontWeight: FontWeight.w600,
        //             color: Colors.black,
        //           ),
        //         ),
        //         SizedBox(height: 4.h),
        //         Text(
        //           'Set the distance at which warnings are\ntriggered',
        //           style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
        //         ),
        //       ],
        //     ),
        //     Obx(
        //       () => Text(
        //         '${controller.warningDistance.value.round()}m',
        //         style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
        //       ),
        //     ),
        //   ],
        // ),
        SizedBox(height: 16.h),

        // Distance Slider
        Row(
          children: [
            Text(
              'Warning Distance (100m - 500m)',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            Spacer(),
            Obx(
              () => Text(
                '${controller.warningDistance.value.round()}',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        Obx(
          () => SliderTheme(
            data: SliderTheme.of(Get.context!).copyWith(
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.black,
              overlayColor: Colors.black.withOpacity(0.1),
              trackHeight: 4.h,
            ),
            child: Slider(
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
              SizedBox(width: 12.w),
              _buildUnitButton(
                'kilometers',
                controller.distanceUnit.value == 'kilometers',
              ),
              SizedBox(width: 12.w),
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
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFFC107) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              unit.capitalizeFirst!,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.black,
                fontWeight: FontWeight.w500,
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
                    fontSize: 18.sp,
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
            GestureDetector(
              onTap:
                  isGranted
                      ? null
                      : () => controller.requestLocationPermission(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isGranted ? Colors.grey[300] : Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isGranted ? 'Allowed' : 'Allow',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isGranted ? Colors.grey[700] : AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
