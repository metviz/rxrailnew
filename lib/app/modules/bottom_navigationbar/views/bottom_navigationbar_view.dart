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
      width: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(color: AppColors.colorFFFFFF),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header
              Container(
                height: 180.h,
                decoration: BoxDecoration(
                  color: Color(0xFFFFC107).withOpacity(0.1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    CircleAvatar(
                      radius: 25.r,
                      backgroundColor: Color(0xFFFFC107).withOpacity(0.2),
                      child: Icon(
                        Icons.train,
                        size: 30.w,
                        color: Color(0xFFFFC107),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'RXrail',
                      style: styleW700(
                        size: 18.sp,
                        color: AppColors.color171712,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Railway Crossing Safety',
                      style: styleW400(
                        size: 14.sp,
                        color: AppColors.color8C8C5E,
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer Items
              _buildDrawerItem(
                icon: Icons.home,
                title: 'Home',
                onTap: () {
                  controller.changePage(0);
                  // Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  Get.toNamed(Routes.ABOUT);
                  // Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.newspaper,
                title: 'News',
                // onTap: () {
                //   Get.toNamed(Routes.NEWS, arguments: {'state': 'NC'});
                //   // Navigator.pop(context);
                // },
                onTap: () {
                  final controller = Get.find<BottomNavigationbarController>();
                  controller.openNews();
                },
              ),
              _buildDrawerItem(
                icon: Icons.article,
                title: 'Safety Videos',
                onTap: () {
                  Get.toNamed(Routes.BLOG);
                  // Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings,
                title: 'Settings',
                onTap: () {
                  controller.changePage(1);
                  Navigator.pop(context);
                },
              ),

              // Divider and Version Info
              Divider(height: 40.h, thickness: 1, color: Colors.grey[200]),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Version 1.0.0',
                  style: styleW400(size: 12.sp, color: Colors.grey),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24.w, color: AppColors.color171712),
      title: Text(
        title,
        style: styleW600(size: 16.sp, color: AppColors.color171712),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
      minLeadingWidth: 0,
      horizontalTitleGap: 8.w,
      onTap: onTap,
    );
  }
}
