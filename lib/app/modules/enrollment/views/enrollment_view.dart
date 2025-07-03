import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';

import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_bottom_sheet.dart';
import "../controller/enrollment_controller.dart";
import 'widgets/body.dart';

class EnrollmentView extends GetView<EnrollmentController> {
  const EnrollmentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.background,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Get.theme.colorScheme.background,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child:  SafeArea(child: Body()),
      ),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: controller.isLoading.value ? null : () => controller.syncConfiguration(),
        backgroundColor: Color(0xFF036273),
        foregroundColor: Colors.white,
        icon: controller.isLoading.value 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.sync),
        label: Text(controller.isLoading.value ? 'Syncing...' : 'Sync Rates'),
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
