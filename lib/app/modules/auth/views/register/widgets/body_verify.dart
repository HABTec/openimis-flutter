import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/values/strings.dart';
import '../../../../../domain/enums/user_type.dart';
import '../../../../../routes/app_pages.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/button_with_text.dart';
import '../../widgets/header.dart';
import 'employee_form.dart';
import 'employer_form.dart';

class BodyVerify extends GetView<AuthController> {
  const BodyVerify({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50.h),
            const Header(title: AppStrings.createAnAccount),
            SizedBox(height: 30.h),
            // if (controller.registerType == RegisterType.CUSTOMER)
            //   const EmployeeForm(),
            EmployeeForm(),
            SizedBox(height: 50.h),
            Obx(() {
              return controller.registerState.when(
                idle: () => ButtonWithText(
                    btnLabel: AppStrings.signup,
                    firstTextSpan: AppStrings.alreadyHaveAnAccount,
                    secondTextSpan: AppStrings.signIn,
                    onTap: () async {
                      controller.verifyInsuree();
                    },
                    onTextTap: () {
                      Get.toNamed('/login');
                    }),
                loading: () => ElevatedButton(
                  onPressed: null, // Disable button while loading
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white), // Set color for indicator
                  ),
                ),
                failure: (reason) => Column(
                  children: [
                    ButtonWithText(
                        btnLabel: AppStrings.signupTryAgain,
                        firstTextSpan: AppStrings.signIn,
                        secondTextSpan: AppStrings.signIn,
                        onTap: () async {
                          controller.verifyInsuree();
                        },
                        onTextTap: () {
                          Get.toNamed('/login');
                        }),
                    SizedBox(height: 10.h),
                    Text("Error: $reason"),
                  ],
                ),
                success: (data) {
                  Timer(Duration(seconds: 1), () {
                    Get.toNamed(Routes
                        .OTP); // Navigate to the OTP route after the delay
                  });

                  return ButtonWithText(
                    btnLabel: AppStrings.signup,
                    firstTextSpan: AppStrings.alreadyHaveAnAccount,
                    secondTextSpan: AppStrings.signIn,
                    onTap: () async {
                      controller.verifyInsuree();
                    },
                    onTextTap: () {
                      Get.toNamed('/login');
                    },
                  );

                  //   Container(
                  //   child: Center(child: Text("Validate OTP now"),),
                  // ); // Return an empty container as a placeholder
                },
              );
            }),

            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}
