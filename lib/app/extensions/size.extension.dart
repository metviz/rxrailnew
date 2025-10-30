import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension SizedBoxExtension on int {
  Widget get hp => SizedBox(
        height: toDouble().h,
      );
  Widget get wp => SizedBox(
        width: toDouble().w,
      );
}
