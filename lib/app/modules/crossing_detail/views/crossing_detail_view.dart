import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/text_style.dart';
import '../controllers/crossing_detail_controller.dart';

class CrossingDetailView extends GetView<CrossingDetailController> {
  const CrossingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the crossing detail from the arguments map
    final crossingDetail = Get.arguments?['crossingDetail'];

    // Debug: Print the crossingDetail to see available properties
    print('CrossingDetail type: ${crossingDetail?.runtimeType}');
    if (crossingDetail != null) {
      // Try to access common property names that might exist
      try {
        print('id: ${crossingDetail.crossingid}');
      } catch (e) {
        print('No id property');
      }
      try {
        print('name: ${crossingDetail.railroadcode}');
      } catch (e) {
        print('No name property');
      }
      // ... rest of your debug prints
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Icon(
              Icons.directions_railway_filled_rounded,
              color: Colors.blue,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attributes Section
            _buildSectionHeader('ATTRIBUTES'),
            Container(
              margin: EdgeInsets.only(left: 16.w),
              height: 1.h,
              color: Colors.blue,
            ),
            _buildDetailItem(
              'CROSSING ID',
              crossingDetail?.crossingid ?? 'N/A',
            ),
            _buildDivider(),
            _buildDetailItem('Railroad', crossingDetail?.railroadcode ?? 'FEC'),
            _buildDivider(),
            _buildDetailItem(
              'Street Name',
              crossingDetail?.street ?? 'SW 17TH ST',
            ),
            _buildDivider(),
            _buildDetailItem('Type', crossingDetail?.crossingtype ?? 'Public'),
            _buildDivider(),
            _buildDetailItem(
              'Quiet Zone',
              crossingDetail?.quietzone ?? '24 Hour',
            ),
            _buildDivider(),
            // _buildDetailItem('Milepost', crossingDetail?.milepost ?? '0342.550'),
            _buildDivider(),

            SizedBox(height: 20.h),

            // U.S.DOT Records Section
            _buildSectionHeader('U.S.DOT RECORDS'),
            Container(
              margin: EdgeInsets.only(left: 16.w),
              height: 1.h,
              color: Colors.blue,
            ),
            _buildRecordItem(
              'Inventory Record',
              controller.viewInventoryRecord,
            ),
            _buildDivider(),
            _buildRecordItem(
              'Collision Report',
              controller.viewCollisionReport,
            ),
            _buildDivider(),

            SizedBox(height: 20.h),

            // Send FRA Info Section
            _buildSectionHeader('SEND FRA INFO ABOUT THIS CROSSING'),
            Container(
              margin: EdgeInsets.only(left: 16.w),
              height: 1.h,
              color: Colors.blue,
            ),
            _buildActionItem('Email', Icons.email, controller.sendFRAInfo),
            _buildDivider(),

            SizedBox(height: 20.h),

            // Emergency Section
            _buildSectionHeader('REPORT EMERGENCY OR PROBLEM'),
            Container(
              margin: EdgeInsets.only(left: 16.w),
              height: 1.h,
              color: Colors.blue,
            ),
            _buildEmergencyItem(),
            _buildDivider(),

            SizedBox(height: 40.h),
            // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Text(
        title,
        style: styleW500(
          color: Colors.blue,
          size: 16.sp,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: styleW400(
              color: Colors.white,
              size: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: styleW400(
              color: Colors.white,
              size: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyItem() {
    return InkWell(
      onTap: () => controller.callEmergency(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ENS: 800-588-7223',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'Call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.only(left: 16.w),
      height: 1.h,
      color: Colors.grey[800],
    );
  }
}
