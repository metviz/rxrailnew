// import 'package:RXrail/app/utils/app_color.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
//
// import '../../../model/blog_post_model.dart';
// import '../../../model/blog_update_model.dart';
// import '../../../model/safety_tip_model.dart';
// import '../controllers/blog_controller.dart';
//
// class BlogView extends GetView<BlogController> {
//   const BlogView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.colorF1F1F1,
//       body: CustomScrollView(
//         slivers: [
//           // Enhanced App Bar
//           SliverAppBar(
//             expandedHeight: 60.h,
//             floating: false,
//             pinned: true,
//             elevation: 0,
//             backgroundColor: AppColors.colorF1F1F1,
//             leading: IconButton(
//               onPressed: controller.onBackPressed,
//               icon: Icon(
//                 Icons.arrow_back_ios,
//                 size: 20.w,
//                 color: Colors.black87,
//               ),
//             ),
//             title: Text(
//               'Railway Blog',
//               style: TextStyle(
//                 fontSize: 24.sp,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             centerTitle: true,
//             actions: [
//               IconButton(
//                 onPressed: () {},
//                 icon: Icon(
//                   Icons.refresh_rounded,
//                   size: 20.w,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//
//           // Content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(height: 16.h),
//                   _buildFeaturedPosts(),
//                   SizedBox(height: 16.h),
//                   _buildSafetyTips(),
//                   SizedBox(height: 16.h),
//                   _buildUpdates(),
//                   SizedBox(height: 16.h),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFeaturedPosts() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(8.w),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFB200).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12.r),
//               ),
//               child: Icon(
//                 Icons.star_rounded,
//                 color: const Color(0xFFFFB200),
//                 size: 24.w,
//               ),
//             ),
//             SizedBox(width: 12.w),
//             Text(
//               'Featured Posts',
//               style: TextStyle(
//                 fontSize: 24.sp,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFFFFB200),
//               ),
//             ),
//           ],
//         ),
//         Obx(
//           () =>
//               controller.featuredPosts.isEmpty
//                   ? _buildEmptySection('No featured posts available')
//                   : ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: controller.featuredPosts.length,
//                     itemBuilder: (context, index) {
//                       final post = controller.featuredPosts[index];
//                       return _buildFeaturedPostCard(post, index);
//                     },
//                   ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFeaturedPostCard(BlogPost post, int index) {
//     return Hero(
//       tag: 'featured_post_$index',
//       child: Container(
//         margin: EdgeInsets.only(bottom: 20.h),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20.r),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 16,
//               offset: Offset(0, 4.h),
//               spreadRadius: 0,
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20.r),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Enhanced Image Section
//               Container(
//                 width: double.infinity,
//                 height: 220.h,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       const Color(0xFFFFB200).withOpacity(0.3),
//                       const Color(0xFFFFB200).withOpacity(0.6),
//                       const Color(0xFFFFB200).withOpacity(0.8),
//                     ],
//                   ),
//                 ),
//                 child: Stack(
//                   children: [
//                     // Enhanced Railway Pattern
//                     Positioned.fill(
//                       child: CustomPaint(
//                         painter: EnhancedRailwayTrackPainter(),
//                       ),
//                     ),
//
//                     // Decorative Elements
//                     Positioned(
//                       top: 20.h,
//                       right: 30.w,
//                       child: Container(
//                         padding: EdgeInsets.all(8.w),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(20.r),
//                         ),
//                         child: Icon(
//                           Icons.cloud_rounded,
//                           color: Colors.white.withOpacity(0.8),
//                           size: 24.w,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: 40.h,
//                       right: 80.w,
//                       child: Container(
//                         padding: EdgeInsets.all(6.w),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(16.r),
//                         ),
//                         child: Icon(
//                           Icons.cloud_rounded,
//                           color: Colors.white.withOpacity(0.6),
//                           size: 18.w,
//                         ),
//                       ),
//                     ),
//
//                     // Reading time badge
//                     Positioned(
//                       top: 16.h,
//                       left: 16.w,
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 12.w,
//                           vertical: 6.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.6),
//                           borderRadius: BorderRadius.circular(20.r),
//                         ),
//                         child: Text(
//                           '5 min read',
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Content Section
//               Container(
//                 padding: EdgeInsets.all(24.w),
//                 color: Colors.white,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       post.title,
//                       style: TextStyle(
//                         fontSize: 22.sp,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                         height: 1.3,
//                       ),
//                     ),
//                     SizedBox(height: 12.h),
//                     Text(
//                       post.description,
//                       style: TextStyle(
//                         fontSize: 15.sp,
//                         color: Colors.grey.shade600,
//                         height: 1.5,
//                       ),
//                     ),
//                     SizedBox(height: 16.h),
//
//                     // Author and date info
//                     Row(
//                       children: [
//                         CircleAvatar(
//                           radius: 16.r,
//                           backgroundColor: const Color(
//                             0xFFFFB200,
//                           ).withOpacity(0.2),
//                           child: Text(
//                             post.author[0],
//                             style: TextStyle(
//                               fontSize: 14.sp,
//                               fontWeight: FontWeight.bold,
//                               color: const Color(0xFFFFB200),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 12.w),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 post.author,
//                                 style: TextStyle(
//                                   fontSize: 13.sp,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               Text(
//                                 'Recently posted',
//                                 style: TextStyle(
//                                   fontSize: 12.sp,
//                                   color: Colors.grey.shade500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Container(
//                           padding: EdgeInsets.all(8.w),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(12.r),
//                           ),
//                           child: Icon(
//                             Icons.bookmark_border_rounded,
//                             size: 20.w,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSafetyTips() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(8.w),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFB200).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12.r),
//               ),
//               child: Icon(
//                 Icons.security_rounded,
//                 color: const Color(0xFFFFB200),
//                 size: 24.w,
//               ),
//             ),
//             SizedBox(width: 12.w),
//             Text(
//               'Safety Tips',
//               style: TextStyle(
//                 fontSize: 24.sp,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFFFFB200),
//               ),
//             ),
//           ],
//         ),
//         Obx(
//           () =>
//               controller.safetyTips.isEmpty
//                   ? _buildEmptySection('No safety tips available')
//                   : ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: controller.safetyTips.length,
//                     itemBuilder: (context, index) {
//                       final tip = controller.safetyTips[index];
//                       return _buildSafetyTipCard(tip, index);
//                     },
//                   ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSafetyTipCard(SafetyTip tip, int index) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16.h),
//       padding: EdgeInsets.all(20.w),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: Colors.grey.shade100, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: Offset(0, 2.h),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(4.w),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFFB200).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8.r),
//                       ),
//                       child: Icon(
//                         Icons.lightbulb_outline_rounded,
//                         size: 16.w,
//                         color: const Color(0xFFFFB200),
//                       ),
//                     ),
//                     SizedBox(width: 8.w),
//                     Text(
//                       'Tip ${index + 1}',
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight: FontWeight.w500,
//                         color: const Color(0xFFFFB200),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12.h),
//                 Text(
//                   tip.title,
//                   style: TextStyle(
//                     fontSize: 17.sp,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//                 Text(
//                   tip.description,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     color: Colors.grey.shade600,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(width: 16.w),
//           Container(
//             width: 80.w,
//             height: 80.h,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16.r),
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   const Color(0xFFFFB200).withOpacity(0.2),
//                   const Color(0xFFFFB200).withOpacity(0.4),
//                 ],
//               ),
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.train_rounded,
//                 color: const Color(0xFFFFB200),
//                 size: 32.w,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUpdates() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(8.w),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100,
//                 borderRadius: BorderRadius.circular(12.r),
//               ),
//               child: Icon(
//                 Icons.update_rounded,
//                 color: Colors.green.shade600,
//                 size: 24.w,
//               ),
//             ),
//             SizedBox(width: 12.w),
//             Text(
//               'Latest Updates',
//               style: TextStyle(
//                 fontSize: 24.sp,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFFFFB200),
//               ),
//             ),
//           ],
//         ),
//         Obx(
//           () =>
//               controller.updates.isEmpty
//                   ? _buildEmptySection('No updates available')
//                   : ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: controller.updates.length,
//                     itemBuilder: (context, index) {
//                       final update = controller.updates[index];
//                       return _buildUpdateCard(update, index);
//                     },
//                   ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildUpdateCard(BlogUpdate update, int index) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16.h),
//       padding: EdgeInsets.all(20.w),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: Colors.grey.shade100, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: Offset(0, 2.h),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 8.w,
//                         vertical: 4.h,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade100,
//                         borderRadius: BorderRadius.circular(12.r),
//                       ),
//                       child: Text(
//                         'NEW',
//                         style: TextStyle(
//                           fontSize: 10.sp,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green.shade700,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8.w),
//                     Text(
//                       'Today',
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12.h),
//                 Text(
//                   update.title,
//                   style: TextStyle(
//                     fontSize: 17.sp,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//                 Text(
//                   update.description,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     color: Colors.grey.shade600,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(width: 16.w),
//           Container(
//             width: 80.w,
//             height: 80.h,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16.r),
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [Colors.green.shade300, Colors.green.shade500],
//               ),
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.notifications_active_rounded,
//                 color: Colors.white,
//                 size: 32.w,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptySection(String message) {
//     return Container(
//       padding: EdgeInsets.all(40.w),
//       child: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(20.w),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(20.r),
//             ),
//             child: Icon(
//               Icons.article_outlined,
//               size: 48.w,
//               color: Colors.grey.shade400,
//             ),
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             message,
//             style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Enhanced Railway Track Painter
// class EnhancedRailwayTrackPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final trackPaint =
//         Paint()
//           ..color = Colors.black.withOpacity(0.2)
//           ..strokeWidth = 3.0
//           ..style = PaintingStyle.stroke;
//
//     final tiePaint =
//         Paint()
//           ..color = Colors.black.withOpacity(0.15)
//           ..strokeWidth = 2.0
//           ..style = PaintingStyle.stroke;
//
//     // Draw railway tracks with perspective
//     final trackWidth = size.width * 0.5;
//     final trackStart = (size.width - trackWidth) / 2;
//     final trackEnd = trackStart + trackWidth;
//
//     // Create perspective effect
//     final perspectiveStart = trackStart + 20;
//     final perspectiveEnd = trackEnd - 20;
//
//     // Left rail with perspective
//     canvas.drawLine(
//       Offset(trackStart, 0),
//       Offset(perspectiveStart, size.height),
//       trackPaint,
//     );
//
//     // Right rail with perspective
//     canvas.drawLine(
//       Offset(trackEnd, 0),
//       Offset(perspectiveEnd, size.height),
//       trackPaint,
//     );
//
//     // Cross ties with perspective
//     for (double y = 0; y < size.height; y += 25) {
//       final progress = y / size.height;
//       final leftTie = trackStart - 10 + (progress * 15);
//       final rightTie = trackEnd + 10 - (progress * 15);
//
//       canvas.drawLine(Offset(leftTie, y), Offset(rightTie, y), tiePaint);
//     }
//
//     // Add decorative elements
//     final decorPaint =
//         Paint()
//           ..color = Colors.white.withOpacity(0.3)
//           ..style = PaintingStyle.fill;
//
//     // Small decorative circles
//     for (int i = 0; i < 3; i++) {
//       canvas.drawCircle(
//         Offset(size.width * 0.8, size.height * 0.2 * (i + 1)),
//         4 + i * 2,
//         decorPaint,
//       );
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
import 'package:RXrail/app/model/SafetyVideoModel.dart';
import 'package:RXrail/app/utils/app_color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../model/blog_post_model.dart';
import '../../../model/blog_update_model.dart';
import '../../../model/safety_tip_model.dart';
import '../controllers/blog_controller.dart';

class BlogView extends GetView<BlogController> {
  const BlogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorF1F1F1,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 60.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.colorF1F1F1,
            leading: IconButton(
              onPressed: controller.onBackPressed,
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20.w,
                color: Colors.black87,
              ),
            ),
            title: Text(
              'Safety Videos',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            centerTitle: true,
            // actions: [
            //   IconButton(
            //     onPressed: controller.loadSafetyVideos,
            //     icon: Icon(
            //       Icons.refresh_rounded,
            //       size: 20.w,
            //       color: Colors.black87,
            //     ),
            //   ),
            // ],
          ),

          // Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.red.shade600,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Safety Videos',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Obx(() => controller.isLoadingVideos.value
                          ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                        ),
                      )
                          : const SizedBox()),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),

// Then, below, use SliverList for the videos:
          Obx(
                () => controller.safetyVideos.isEmpty
                ? SliverToBoxAdapter(
              child: _buildEmptySection('No safety videos available'),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildVideoCard(
                  controller.safetyVideos[index],
                  index,
                ),
                childCount: controller.safetyVideos.length,
              ),
            ),
          ),


        ],
      ),
    );
  }

  // ======================= SAFETY VIDEOS =======================

  Widget _buildSafetyVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.red.shade600,
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Safety Videos',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Obx(() => controller.isLoadingVideos.value
                ? SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.red.shade600),
              ),
            )
                : const SizedBox()),
          ],
        ),
        SizedBox(height: 16.h),
        Obx(
              () => controller.safetyVideos.isEmpty
              ? _buildEmptySection('No safety videos available')
              : ListView.builder(
                physics: NeverScrollableScrollPhysics(), // disable inner scroll
                shrinkWrap: true,                         // take only needed height
                // scrollDirection: Axis.horizontal,
                itemCount: controller.safetyVideos.length,
                itemBuilder: (context, index) {
                  final video = controller.safetyVideos[index];
                  return _buildVideoCard(video, index);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(SafetyVideoModel video, int index) {
    return GestureDetector(
      onTap: () => controller.openVideo(video.url!),
      child: Container(
        // width: 280.w,
        margin: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                  child: Container(
                    height: 140.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade300,
                          Colors.red.shade500,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: video.thumbnail!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300, // optional placeholder
                            ),
                            errorWidget: (context, url, error) => CustomPaint(
                              painter: VideoBackgroundPainter(),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 40.w,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12.w,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          video.duration!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Video Details
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14.w,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          video.source!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================= FEATURED POSTS =======================

  Widget _buildFeaturedPosts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB200).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.star_rounded,
                color: const Color(0xFFFFB200),
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Featured Posts',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFB200),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Obx(
              () => controller.featuredPosts.isEmpty
              ? _buildEmptySection('No featured posts available')
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.featuredPosts.length,
            itemBuilder: (context, index) {
              final post = controller.featuredPosts[index];
              return _buildFeaturedPostCard(post, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPostCard(BlogPost post, int index) {
    return Hero(
      tag: 'featured_post_$index',
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 220.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFB200).withOpacity(0.3),
                      const Color(0xFFFFB200).withOpacity(0.6),
                      const Color(0xFFFFB200).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: EnhancedRailwayTrackPainter(),
                      ),
                    ),
                    Positioned(
                      top: 20.h,
                      right: 30.w,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.cloud_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 24.w,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16.h,
                      left: 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '5 min read',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(24.w),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      post.description,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          backgroundColor:
                          const Color(0xFFFFB200).withOpacity(0.2),
                          child: Text(
                            post.author[0],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFB200),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Recently posted',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.bookmark_border_rounded,
                            size: 20.w,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================= SAFETY TIPS =======================

  Widget _buildSafetyTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB200).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.security_rounded,
                color: const Color(0xFFFFB200),
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Safety Tips',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFB200),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Obx(
              () => controller.safetyTips.isEmpty
              ? _buildEmptySection('No safety tips available')
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.safetyTips.length,
            itemBuilder: (context, index) {
              final tip = controller.safetyTips[index];
              return _buildSafetyTipCard(tip, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyTipCard(SafetyTip tip, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB200).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16.w,
                        color: const Color(0xFFFFB200),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Tip ${index + 1}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFFB200),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  tip.title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  tip.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFB200).withOpacity(0.2),
                  const Color(0xFFFFB200).withOpacity(0.4),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.train_rounded,
                color: const Color(0xFFFFB200),
                size: 32.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================= LATEST UPDATES =======================

  Widget _buildUpdates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.update_rounded,
                color: Colors.green.shade600,
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Latest Updates',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Obx(
              () => controller.updates.isEmpty
              ? _buildEmptySection('No updates available')
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.updates.length,
            itemBuilder: (context, index) {
              final update = controller.updates[index];
              return _buildUpdateCard(update, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard(BlogUpdate update, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.new_releases_rounded,
              color: Colors.green.shade600,
              size: 28.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  update.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ======================= CUSTOM PAINTERS =======================

class VideoBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.red.withOpacity(0.3),
          Colors.red.shade900.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.2,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class EnhancedRailwayTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final railPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final sleeperPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.6,
        size.width * 0.6,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.1,
        size.width,
        0,
      );

    canvas.drawPath(path, railPaint);

    for (double i = 0; i < size.width; i += 24) {
      canvas.drawLine(
        Offset(i, size.height - (i * 0.4)),
        Offset(i + 12, size.height - (i * 0.4) - 8),
        sleeperPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


