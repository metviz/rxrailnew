import 'package:RXrail/app/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../utils/app_color.dart';
import '../controllers/about_controller.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorF1F1F1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.black87,
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'About',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header section with app icon and name
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFB200).withOpacity(0.1),
                    const Color(0xFFFFB200).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: const Color(0xFFFFB200).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB200),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB200).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(Icons.train, color: Colors.white, size: 40.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'RXrail',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Railway Crossing Safety Assistant',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Content sections
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.info_outline_rounded,
                    title: 'About this app',
                    content:
                        'This app uses OpenStreetMap data to provide alerts for railway crossings. It relies on background GPS to determine your location and proximity to crossings.',
                    iconColor: const Color(0xFF2196F3),
                  ),

                  SizedBox(height: 20.h),

                  _buildInfoCard(
                    icon: Icons.data_usage_rounded,
                    title: 'Data Source',
                    content:
                        'The railway crossing data and map information are sourced from OpenStreetMap and OpenRailwayMap, collaborative, open-source maps. We strive to keep the data accurate and up-to-date, but there may be discrepancies or omissions. We are grateful for the contributions of the OpenStreetMap and OpenRailwayMap communities.',
                    iconColor: const Color(0xFF4CAF50),
                  ),

                  SizedBox(height: 20.h),

                  _buildInfoCard(
                    icon: Icons.palette_outlined,
                    title: 'Design Assistance',
                    content:
                        'This app\'s design was created with assistance from Stitch, an AI design assistant.',
                    iconColor: const Color(0xFF9C27B0),
                  ),

                  SizedBox(height: 20.h),

                  _buildInfoCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Disclaimer',
                    content:
                        """The RXRail App uses publicly available and community-sourced data from OpenStreetMap and OpenRailwayMap to identify railroad crossings and track locations. While every effort is made to ensure accuracy, RXRail cannot guarantee that all data is current, complete, or free of errors.\n
                      By using this app, you acknowledge and agree that:\n
                      The RXRail development team, contributors, and data providers assume no liability for any loss, injury, or damage—direct or indirect—arising from the use of this app or the information it provides.\n
                  Alerts and map data may occasionally be outdated, incomplete, or temporarily inaccurate due to GPS limitations, system constraints, or real-world changes.\n
                  RXRail is a supplemental safety tool, not a replacement for personal awareness, official signage, or local safety warnings.\n
                  In case of an emergency near a railroad crossing, users should contact the railroad emergency number posted at the site or call local emergency services immediately.\n
                  Use of this app constitutes acceptance of these terms and acknowledgment that you do so at your own risk.""",
                    iconColor: const Color(0xFFFF9800),
                    isWarning: true,
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
    bool isWarning = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            isWarning
                ? Border.all(color: iconColor.withOpacity(0.2), width: 1)
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Text(
            content,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 1.6,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
