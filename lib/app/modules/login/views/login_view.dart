
import 'package:RXrail/app/extensions/size.extension.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../utils/app_color.dart';
import '../../../utils/app_strings.dart';
import '../../../utils/text_style.dart';
import '../../../widgets/app_textfield.dart';
import '../../../widgets/common_button.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorF3F3F3,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        AppStrings.loginTxt,
                        style: styleW700(
                          size: 24.sp,
                          color: AppColors.color001E75,
                        ),
                      ),
                    ),
                    20.hp,
                    Center(
                      child: Text(
                        AppStrings.loginSubTxt,
                        style: styleW700(
                          size: 15.sp,
                          color: AppColors.color444444,
                        ),
                      ),
                    ),
                    30.hp,
                    AppTextField(
                      controller: controller.emailController,
                      subHintText: AppStrings.emailSubHintTxt,
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.color001E75),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.emptyEmailErrorTxt;
                        }
                        if (!RegExp(AppStrings.emailRegExp).hasMatch(value)) {
                          return AppStrings.validEmailErrorTxt;
                        }
                        return null;
                      },
                    ),
                    // Password Field with prefix & suffix icons
                 AppTextField(
                      isPasswordField: true,
                      controller: controller.passwordController,
                      subHintText: AppStrings.passwordSubHintTxt,
                      prefixIcon: Icon(Icons.lock, color: AppColors.color001E75),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.emptyPassErrorTxt;
                        }
                        return null;
                      },
                    ),
                    10.hp,
                    InkWell(
                      onTap: () {},
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          AppStrings.forgotPasswordTxt,
                          style: styleW500(
                            size: 12.sp,
                            color: AppColors.color001E75,
                          ),
                        ),
                      ),
                    ),
                    20.hp,
                    CommonButton(
                      text: AppStrings.loginBtnTxt,
                      borderRadius: 10,
                      onTap: () {
                        // Your logic here
                      },
                    ),
                    20.hp,
                    RichText(
                      text: TextSpan(
                        text: AppStrings.dontHaveAccountTxt,
                        style: styleW400(
                          size: 12.sp,
                          color: AppColors.color444444,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.signUpTxt,
                            style: styleW500(
                              size: 12.sp,
                              color: AppColors.color001E75,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.toNamed(Routes.REGISTER);
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 16.w),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: AppStrings.termAndConClickTxt,
                  style: styleW400(size: 12.sp, color: AppColors.color444444),
                  children: [
                    TextSpan(
                      text: AppStrings.termOfUseTxt,
                      style: styleW500(size: 12.sp, color: AppColors.color001E75),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              // Your logic here
                            },
                    ),
                    TextSpan(
                      text: AppStrings.andTxt,
                      style: styleW400(size: 12.sp, color: AppColors.color444444),
                    ),
                    TextSpan(
                      text: AppStrings.privacyPolicyTxt,
                      style: styleW500(size: 12.sp, color: AppColors.color001E75),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              // Your logic here
                            },
                    ),
                  ],
                ),
              ),
            ),
            30.hp,
          ],
        ),
      ),
    );
  }
}
