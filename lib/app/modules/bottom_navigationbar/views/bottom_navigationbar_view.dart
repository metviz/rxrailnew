import 'package:RXrail/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/app_color.dart';
import '../../../utils/text_style.dart';
import '../../crossing/controllers/crossing_controller.dart';
import '../../crossing/views/crossing_view.dart';
import '../../setting/views/setting_view.dart';
import '../controllers/bottom_navigationbar_controller.dart';

class BottomNavigationbarView extends GetView<BottomNavigationbarController> {
  const BottomNavigationbarView({super.key});

  @override
  Widget build(BuildContext context) {
    final CrossingController crossingController =
        Get.find<CrossingController>();
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: AppColors.colorFFFFFF,
        leading: IconButton(
          icon: Icon(Icons.menu, size: 24.w),
          onPressed: () {
            controller.scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Obx(
          () => Text(
            controller.title.value,
            style: styleW700(size: fontSize18, color: AppColors.color171712),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: [CrossingView(), SettingView()],
        ),
      ),

      /// 👇 FAB with notch effect
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(
        () => SizedBox(
          height: 50.h,
          width: 50.w,
          child: FloatingActionButton(
            elevation: 6,
            heroTag: 'find_route',
            backgroundColor: Color(0xFFFFC107),
            onPressed: () => crossingController.showRouteBottomSheet(context),
            child: Icon(
              crossingController.isNavigating.value
                  ? Icons.navigation
                  : Icons.directions,
              color: AppColors.black,
              size: 28.w,
            ),
          ),
        ),
      ),

      bottomNavigationBar: Obx(
        () => BottomAppBar(
          shape: CircularNotchedRectangle(),
          // notchMargin: 6.0,
          // elevation: 8,
          color: AppColors.colorFFFFFF,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    size: 30.w,
                    color:
                        controller.currentIndex.value == 0
                            ? Color(0xFFFFC107)
                            : AppColors.black,
                  ),
                  onPressed: () => controller.changePage(0),
                ),
                SizedBox(width: 48.w), // leave space for FAB
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    size: 30.w,
                    color:
                        controller.currentIndex.value == 1
                            ? Color(0xFFFFC107)
                            : AppColors.black,
                  ),
                  onPressed: () => controller.changePage(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          // topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFFFF8E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header
              Container(
                height: 190.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    // topRight: Radius.circular(20.r),
                    bottomRight: Radius.circular(40.r),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.train_rounded,
                        size: 36.w,
                        color: AppColors.color171712,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'RXRail',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.color171712,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Railway Crossing Safety',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.color171712,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // Drawer Items
              _buildDrawerItem(
                icon: Icons.home_rounded,
                title: 'Home',
                onTap: () {
                  controller.changePage(0);
                },
              ),
              _buildDrawerItem(
                icon: Icons.info_outline_rounded,
                title: 'About',
                onTap: () {
                  Get.toNamed(Routes.ABOUT);
                },
              ),
              _buildDrawerItem(
                icon: Icons.newspaper_rounded,
                title: 'News',
                onTap: () {
                  final controller = Get.find<BottomNavigationbarController>();
                  controller.openNews();
                },
              ),
              _buildDrawerItem(
                icon: Icons.ondemand_video_rounded,
                title: 'Safety Videos',
                onTap: () {
                  Get.toNamed(Routes.BLOG);
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings_rounded,
                title: 'Settings',
                onTap: () {
                  controller.changePage(1);
                  Navigator.pop(context);
                },
              ),

              SizedBox(height: 20.h),
              Divider(
                thickness: 0.8,
                indent: 20.w,
                endIndent: 20.w,
                color: Colors.grey.shade300,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable drawer item with hover/tap feedback
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      splashColor: Color(0xFFFFC107).withValues(alpha: 0.3),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFFFFC107), size: 22.w),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.color171712,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Widget _buildDrawerItem({
  //   required IconData icon,
  //   required String title,
  //   required VoidCallback onTap,
  // }) {
  //   return ListTile(
  //     leading: Icon(icon, size: 24.w, color: AppColors.color171712),
  //     title: Text(
  //       title,
  //       style: styleW600(size: 16.sp, color: AppColors.color171712),
  //     ),
  //     contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
  //     minLeadingWidth: 0,
  //     horizontalTitleGap: 8.w,
  //     onTap: onTap,
  //   );
  // }
}
