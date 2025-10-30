import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/app_color.dart';
import '../../../utils/app_strings.dart';
import '../../../utils/text_style.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedBuilder(
              animation: controller.animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: controller.fadeAnimation,
                  child: SlideTransition(
                    position: controller.slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Header with back button
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.arrow_back_ios_new),
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              AppStrings.createAccountTxt,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Text(
                          AppStrings.joinStartYourJourneyTxt,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 40),

                        Form(
                          key: controller.formKey,
                          child: Column(
                            children: [
                              // Email field
                              _buildInputField(
                                controller: controller.emailController,
                                label: AppStrings.emailSubHintTxt,
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return AppStrings.emptyEmailErrorTxt;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Name field
                              _buildInputField(
                                controller: controller.nameController,
                                label: AppStrings.fullName,
                                icon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return AppStrings.nameErrorTxt;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Gender dropdown
                              _buildGenderDropdown(),

                              const SizedBox(height: 20),

                              // Date of birth field
                              _buildInputField(
                                controller: controller.dobController,
                                label: AppStrings.dateOfBirth,
                                icon: Icons.calendar_today_outlined,
                                readOnly: true,
                                onTap: () => controller.selectDate(context),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return AppStrings.birthDateErrorTxt;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 40),

                              // Register button
                              _buildRegisterButton(),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: Colors.grey[300]),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      AppStrings.orContinueWith,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.grey[300]),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Social login buttons
                              _buildSocialButton(
                                AppStrings.continueWithGmail,
                                Icons.email_outlined,
                                Colors.red[400]!,
                                () => controller.handleSocialLogin('Gmail'),
                              ),

                              const SizedBox(height: 16),

                              _buildSocialButton(
                                AppStrings.continueWithApple,
                                Icons.apple,
                                Colors.black,
                                () => controller.handleSocialLogin('Apple'),
                              ),

                              const SizedBox(height: 40),

                              // Terms and privacy
                              _buildTermsText(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          errorStyle: TextStyle(color: Colors.red[400], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(
        () => DropdownButtonFormField<String>(
          dropdownColor: AppColors.colorFFFFFF,
          value:
              controller.selectedGender.value == 'Select Gender'
                  ? null
                  : controller.selectedGender.value,
          decoration: InputDecoration(
            hintText: AppStrings.gender,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.wc_outlined,
              color: Colors.grey[400],
              size: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
          items:
              ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                );
              }).toList(),
          onChanged: controller.selectGender,
          validator: (value) {
            if (value == null) {
              return AppStrings.genderErrorText;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.colorF7DB05,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: controller.handleRegister,
          child: Center(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        AppStrings.registerBtnTxt,
                        style: styleW700(
                          size: 16.sp,
                          color: AppColors.color171712,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24.w),
              const SizedBox(width: 12),
              Text(
                text,
                style: styleW700(size: 14.sp, color: AppColors.color171712),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.4),
          children: [
            TextSpan(text: AppStrings.termAndConClickTxt),
            TextSpan(
              text: AppStrings.termOfUseTxt,
              style: TextStyle(
                color: Colors.amber[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: AppStrings.andTxt),
            TextSpan(
              text: AppStrings.privacyPolicyTxt,
              style: TextStyle(
                color: Colors.amber[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
