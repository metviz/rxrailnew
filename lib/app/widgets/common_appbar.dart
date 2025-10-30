import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../utils/app_color.dart';
import '../utils/text_style.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color titleColor;
  final Color appBarColor;
  final bool backButton;
  final List<Widget> actions;
  final bool? centeredTitle;
  final bool? isAppBarShown;
  final Widget? titleWidget;
  final Widget? leadingWidget;
  final double? leadingSize;
  final Widget? body;
  final Widget? drawer;
  final void Function()? onPressed;

  const CommonAppBar({
    super.key,
    this.title,
    this.isAppBarShown,
    this.drawer,
    this.titleColor = AppColors.color444444,
    this.appBarColor = AppColors.colorF3F3F3,
    this.backButton = true,
    this.actions = const [],
    this.centeredTitle = true,
    this.titleWidget,
    this.leadingWidget,
    this.leadingSize,
    this.body,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      appBar: PreferredSize(
        preferredSize: preferredSize,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // push AppBar to bottom
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 0),
              decoration: BoxDecoration(
                color: AppColors.colorBBBBBB,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 4), // only downward
                    blurRadius: 6, // soft shadow
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: AppBar(
                titleSpacing: 0,
                elevation: 0,
                surfaceTintColor: AppColors.colorFFFFFF,
                automaticallyImplyLeading: backButton,
                leading:
                    leadingWidget ??
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.colorAAAAAA,
                        size: leadingSize ?? 19.w,
                      ),
                      onPressed:
                          onPressed ??
                          () {
                            Get.back();
                          },
                    ),
                title:
                    titleWidget ??
                    Text(
                      title ?? "",
                      style: styleW700(
                        color: AppColors.color444444,
                        size: fontSize16,
                      ),
                    ),
                actions: actions,
                centerTitle: centeredTitle,
              ),
            ),
          ],
        ),
      ),
      body: Container(color: AppColors.colorF1F1F1, child: body),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kToolbarHeight / 4);
}
