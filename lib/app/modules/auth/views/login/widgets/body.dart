import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:heroicons/heroicons.dart';

import '../../../../../core/values/strings.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/button_with_text.dart';
import '../../widgets/header.dart';
import 'login_form.dart';

class Body extends GetView<AuthController> {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 29.w),
      child: CustomScrollView(slivers: [
        SliverFillRemaining(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add the circular logo here
              ClipOval(
                child: Image.asset(
                  'assets/openimis-logo.png',
                  // Update the path to your image asset
                  width: 90.w,
                  // Set the desired width
                  height: 90.w,
                  // Set the desired height to match width for a circle
                  fit: BoxFit.cover, // Ensure the image covers the circle
                ),
              ),
              SizedBox(height: 20.h),
              // Add some spacing between the logo and the header
              Header(title: "Login to your account".tr),
              SizedBox(height: 30.h),
              const LoginForm(),
              SizedBox(height: 50.h),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Aligns children vertically
                mainAxisAlignment: MainAxisAlignment
                    .center, // Centers the widgets horizontally
                children: [
                  Expanded(
                    flex: 3, // Adjusted to take more space
                    child: ButtonWithText(
                      btnLabel: AppStrings.loginBtn,
                      firstTextSpan: AppStrings.youDoNotHaveAnAccountYet,
                      secondTextSpan: AppStrings.signup,
                      onTap: controller.onLoginSubmit,
                      onTextTap: controller.onSignUp,
                    ),
                  ),
                  SizedBox(
                      width: 20
                          .w), // Add space between the button and the biometric icon
                ],
              ),
              // Spacer(),
              SizedBox(height: 20.h),
              Obx(() {
                final isBiometricEnabled = controller.isBiometricEnabled.value;
                return isBiometricEnabled
                    ? IconButton(
                        enableFeedback: true,
                        icon: const HeroIcon(
                          color: Colors.teal,
                          HeroIcons.fingerPrint,
                          size: 40,
                          style: HeroIconStyle
                              .solid, // Use solid style for a filled icon
                        ),
                        onPressed: () async {
                          await controller.tryBiometricAuthentication();
                        },
                      )
                    : const SizedBox
                        .shrink(); // If biometric is not enabled, leave the space empty
              }),
            ],
          ),
        )
      ]),
    );
  }
}
