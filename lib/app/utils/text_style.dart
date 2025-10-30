import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_color.dart';
import 'app_strings.dart';

const double fontSize5 = 5;
const double fontSize6 = 6;
const double fontSize8 = 8;
const double fontSize9 = 9;
const double fontSize10 = 10;
const double fontSize11 = 11;
const double fontSize12 = 12;
const double fontSize13 = 13;
const double fontSize132 = 13.2;
const double fontSize14 = 14;
const double fontSize142 = 14.2;
const double fontSize144 = 14.4;
const double fontSize15 = 15;
const double fontSize156 = 15.6;
const double fontSize16 = 16;
const double fontSize168 = 16.8;
const double fontSize17 = 17;
const double fontSize18 = 18;
const double fontSize20 = 20;
const double fontSize21 = 21;
const double fontSize216 = 21.6;
const double fontSize22 = 22;
const double fontSize24 = 24;
const double fontSize25 = 25;
const double fontSize26 = 26;
const double fontSize27 = 27;
const double fontSize28 = 28;
const double fontSize30 = 30;
const double fontSize312 = 31.2;
const double fontSize32 = 32;
const double fontSize36 = 36;
const double fontSize38 = 38;
const double fontSize384 = 38.4;
const double fontSize40 = 40;
const double fontSize50 = 50;


// App Bar Title
TextStyle appBarTitle() => TextStyle(
  color: AppColors.color444444,
  fontSize: fontSize16.sp,
  fontFamily: AppStrings.fontFamily,
  fontWeight: FontWeight.w700,
  height: 0.08,
);

TextStyle caption() => TextStyle(
  color: AppColors.color444444,
  fontSize: fontSize36.sp,
  fontFamily: AppStrings.fontFamily,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.60,
);

/// Heading Style
TextStyle headingStyle({ double? fontSize}) => TextStyle(
  color: AppColors.color444444,
  fontSize: fontSize?.sp ?? fontSize20.sp,
  fontFamily: AppStrings.fontFamily,
  fontWeight: FontWeight.w700,
  height: 0.05,
);

/// Title Large Style
TextStyle titleStyle({double? height, Color? color}) => TextStyle(
  color: color ?? AppColors.color444444,
  fontSize: 20.sp,
  fontFamily: AppStrings.fontFamily,
  fontWeight: FontWeight.w700,
  height: height ?? 1.40,
  letterSpacing: -0.40,
);

TextStyle styleW700(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    color: color ?? AppColors.color444444,
    fontSize: size.sp,
    fontWeight: FontWeight.w700,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleW800(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    color: color ?? AppColors.color444444,
    fontSize: size.sp,
    fontWeight: FontWeight.w800,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleW600(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    color: color ?? AppColors.color444444,
    fontSize: size.sp,
    fontWeight: FontWeight.w600,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleW500(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    color: color ?? AppColors.color444444,
    fontSize: size.sp,
    fontWeight: FontWeight.w500,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleRegular(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    color: color ?? AppColors.color444444,
    fontSize: size.sp,
    fontWeight: FontWeight.normal,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleW400(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    fontSize: size.sp,
    color: color ?? AppColors.color444444,
    fontWeight: FontWeight.w400,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleW300(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    fontSize: size.sp,
    color: color ?? AppColors.color444444,
    fontWeight: FontWeight.w300,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleBold(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    fontSize: size.sp,
    color: color ?? AppColors.color444444,
    fontWeight: FontWeight.bold,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}

TextStyle styleW900(
    {double size = fontSize16,
      Color? color,
      double? height,
      double? letterSpacing,
      TextDecoration? decoration,
      TextOverflow? overflow}) {
  return TextStyle(
    fontFamily: AppStrings.fontFamily,
    fontSize: size.sp,
    color: color ?? AppColors.color444444,
    fontWeight: FontWeight.w900,
    height: height ?? 0.00,
    letterSpacing: letterSpacing ?? 00,
    decoration: decoration,
    overflow: overflow,
  );
}
