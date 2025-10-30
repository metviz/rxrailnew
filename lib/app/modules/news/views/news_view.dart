import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../model/news_items.dart';
import '../../../utils/app_color.dart';
import '../controllers/news_controller.dart';
//
// class NewsView extends GetView<NewsController> {
//   const NewsView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.colorF1F1F1,
//       body: CustomScrollView(
//         slivers: [
//           // Modern SliverAppBar with gradient
//           SliverAppBar(
//             expandedHeight: 60.h,
//             floating: false,
//             pinned: true,
//             elevation: 0,
//             backgroundColor: AppColors.colorF1F1F1,
//             leading: IconButton(
//               icon: Icon(
//                 Icons.arrow_back_ios_rounded,
//                 color: AppColors.black,
//                 size: 20.w,
//               ),
//               onPressed: () => Get.back(),
//             ),
//             title: Text(
//               'Latest News',
//               style: TextStyle(
//                 color: AppColors.black,
//                 fontSize: 24.sp,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             centerTitle: true,
//             actions: [
//               IconButton(
//                 icon: Icon(
//                   Icons.refresh_rounded,
//                   color: AppColors.black,
//                   size: 20.w,
//                 ),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//
//           // Content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.all(16.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header section with animation
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 20.w,
//                       vertical: 16.h,
//                     ),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.orange.shade400,
//                           Colors.orange.shade600,
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(16.r),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.orange.withOpacity(0.3),
//                           blurRadius: 12,
//                           offset: Offset(0, 4.h),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(12.w),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(12.r),
//                           ),
//                           child: Icon(
//                             Icons.trending_up_rounded,
//                             color: Colors.white,
//                             size: 24.w,
//                           ),
//                         ),
//                         SizedBox(width: 16.w),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Breaking Updates',
//                                 style: TextStyle(
//                                   fontSize: 20.sp,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               Text(
//                                 'Stay informed with latest news',
//                                 style: TextStyle(
//                                   fontSize: 14.sp,
//                                   color: Colors.white.withOpacity(0.9),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // News items
//                   Obx(
//                     () =>
//                         controller.newsItems.isEmpty
//                             ? _buildEmptyState()
//                             : ListView.separated(
//                               shrinkWrap: true,
//                               physics: const NeverScrollableScrollPhysics(),
//                               itemCount: controller.newsItems.length,
//                               separatorBuilder:
//                                   (context, index) => SizedBox(height: 16.h),
//                               itemBuilder: (context, index) {
//                                 final newsItem = controller.newsItems[index];
//                                 return _buildEnhancedNewsCard(newsItem, index);
//                               },
//                             ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEnhancedNewsCard(NewsItem newsItem, int index) {
//     return Hero(
//       tag: 'news_$index',
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
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
//             children: [
//               // Image section with overlay
//               Container(
//                 height: 100.h,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       Color(0xFFFFC107), // Railroad crossing yellow
//                       Color(0xFFFFD54F), // Lighter yellow
//                       Color(0xFFFFF8E1), // Very light yellow
//                     ],
//                   ),
//                 ),
//                 child: Stack(
//                   children: [
//                     // Animated background pattern
//                     Positioned.fill(
//                       child: CustomPaint(painter: _PatternPainter()),
//                     ),
//
//                     // Content overlay
//                     Positioned.fill(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [
//                               Colors.transparent,
//                               Colors.white.withOpacity(0.3),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Alert type badge
//                     Positioned(
//                       top: 16.h,
//                       left: 16.w,
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 12.w,
//                           vertical: 6.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: _getAlertColor(newsItem.alertType),
//                           borderRadius: BorderRadius.circular(20.r),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               blurRadius: 4,
//                               offset: Offset(0, 2.h),
//                             ),
//                           ],
//                         ),
//                         child: Text(
//                           newsItem.alertType.toUpperCase(),
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     // Main illustration
//                     Positioned(
//                       bottom: 20.h,
//                       right: 20.w,
//                       child: Container(
//                         padding: EdgeInsets.all(16.w),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(16.r),
//                           border: Border.all(
//                             color: Colors.black.withOpacity(0.3),
//                             width: 1.5
//                           ),
//                         ),
//                         child: Icon(
//                           _getIconForAlertType(newsItem.alertType),
//                           color: Colors.black,
//                           size: 32.w,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Content section
//               Padding(
//                 padding: EdgeInsets.all(20.w),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       newsItem.title,
//                       style: TextStyle(
//                         fontSize: 20.sp,
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFF2D3436),
//                         height: 1.3,
//                       ),
//                     ),
//                     SizedBox(height: 12.h),
//                     Text(
//                       newsItem.description,
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         color: const Color(0xFF636E72),
//                         height: 1.5,
//                       ),
//                     ),
//                     SizedBox(height: 16.h),
//
//                     // Action buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {},
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color(0xFFFFC107),
//                               foregroundColor: AppColors.black,
//                               elevation: 0,
//                               padding: EdgeInsets.symmetric(vertical: 12.h),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12.r),
//                               ),
//                             ),
//                             child: Text(
//                               'View Details',
//                               style: TextStyle(
//                                 fontSize: 14.sp,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 12.w),
//                         Container(
//                           decoration: BoxDecoration(
//                             border: Border.all(color: const Color(0xFFE0E0E0)),
//                             borderRadius: BorderRadius.circular(12.r),
//                           ),
//                           child: IconButton(
//                             onPressed: () {},
//                             icon: Icon(
//                               Icons.share_rounded,
//                               color: const Color(0xFF636E72),
//                               size: 20.w,
//                             ),
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
//   Widget _buildEmptyState() {
//     return Container(
//       padding: EdgeInsets.all(40.w),
//       child: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(24.w),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(20.r),
//             ),
//             child: Icon(
//               Icons.newspaper_rounded,
//               size: 64.w,
//               color: Colors.grey.shade400,
//             ),
//           ),
//           SizedBox(height: 24.h),
//           Text(
//             'No News Available',
//             style: TextStyle(
//               fontSize: 20.sp,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           SizedBox(height: 8.h),
//           Text(
//             'Check back later for updates',
//             style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getAlertColor(String alertType) {
//     switch (alertType.toLowerCase()) {
//       case 'urgent':
//         return Colors.red.shade600;
//       case 'warning':
//         return Colors.orange.shade600;
//       case 'info':
//         return Colors.blue.shade600;
//       case 'delay':
//         return Colors.amber.shade600;
//       default:
//         return Colors.green.shade600;
//     }
//   }
//
//   IconData _getIconForAlertType(String alertType) {
//     switch (alertType.toLowerCase()) {
//       case 'urgent':
//         return Icons.priority_high_rounded;
//       case 'warning':
//         return Icons.warning_rounded;
//       case 'info':
//         return Icons.info_rounded;
//       case 'delay':
//         return Icons.schedule_rounded;
//       default:
//         return Icons.train_rounded;
//     }
//   }
//
//   void _viewDetails(NewsItem newsItem) {
//     // Navigate to news details
//     Get.toNamed('/news-details', arguments: newsItem);
//   }
//
//   void _shareNews(NewsItem newsItem) {
//     // Share functionality
//     // Share.share('${newsItem.title}\n\n${newsItem.description}');
//   }
// }
//
// // Custom painter for background pattern
// class _PatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint =
//         Paint()
//           ..color = Colors.white.withOpacity(0.3)
//           ..strokeWidth = 2
//           ..style = PaintingStyle.stroke;
//
//     // Draw geometric pattern
//     for (int i = 0; i < 5; i++) {
//       final y = size.height * 0.2 * i;
//       canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), paint);
//     }
//
//     // Draw circles
//     for (int i = 0; i < 3; i++) {
//       canvas.drawCircle(
//         Offset(size.width * 0.8, size.height * 0.3 * (i + 1)),
//         20 + i * 10,
//         paint,
//       );
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../model/news_items.dart';
import '../controllers/news_controller.dart';

class NewsView extends GetView<NewsController> {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.orange.shade600,
        title: Text(
          "Railroad Incidents in ${controller.state}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.crashes.isEmpty) {
          return const Center(
            child: Text(
              "No incidents found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feed Title
            // if (controller.feedTitle.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Text(
            //       controller.feedTitle.value,
            //       style: const TextStyle(
            //         fontSize: 18,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.black87,
            //       ),
            //     ),
            //   ),

            // News List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: controller.crashes.length,
                itemBuilder: (context, i) {
                  final c = controller.crashes[i];

                  // Badge color based on type
                  Color badgeColor;
                  switch (c.type.toLowerCase()) {
                    case 'official':
                      badgeColor = Colors.blue.shade600;
                      break;
                    case 'news':
                      badgeColor = Colors.orange.shade600;
                      break;
                    default:
                      badgeColor = Colors.grey.shade600;
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => controller.openLink(c.link),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon / image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.train, color: Colors.orange, size: 36),
                            ),
                            const SizedBox(width: 12),

                            // Title & info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badge for type
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      c.type.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // News title
                                  Text(
                                    c.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Source & date
                                  Text(
                                    "${c.source} • ${c.date.toLocal()}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Arrow icon
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
