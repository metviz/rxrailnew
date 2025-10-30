import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/text_style.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color buttonColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;

  const CommonButton({
    super.key,
    required this.text,
    required this.onTap,
    this.buttonColor = const Color(0xFF001C73), // Dark Blue
    this.textColor = Colors.white,
    this.borderRadius = 32.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: styleW500(
            color: textColor,
            size: fontSize.sp,
          ),
        ),
      ),
    );
  }
}
