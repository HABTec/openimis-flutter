import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:heroicons/heroicons.dart';
import 'package:openimis_app/app/modules/settings/views/settings_view.dart';

import '../../../../language/view/language_choose_bottomsheet.dart';
import '../../controllers/auth_controller.dart';
import 'widgets/body.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We use Obx to reactively listen to isFirstTime
    return Obx(() {
      // If isFirstTime is true, show the language selection bottom sheet
      if (AuthController.to.isFirstTime.value) {
        Future.delayed(Duration.zero, () {
          // Ensure the bottom sheet is shown after the frame is built
          showLanguageSelectionBottomSheet(context);
          // Once bottom sheet is shown, set isFirstTime to false
          //AuthController.to.updateIsFirstTime(true);
        });
      }

      return Scaffold(
        backgroundColor: Get.theme.backgroundColor,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Get.theme.backgroundColor,
          elevation: 0,
          toolbarHeight: kToolbarHeight,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Get.to(() => SettingsView()),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.all(6.w),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: HeroIcon(
                HeroIcons.cog6Tooth,
                color: Get.theme.primaryColor,
              ),
            ),
            IconButton(
              onPressed: () {
                showLanguageSelectionBottomSheet(context);
              },
              icon: Icon(
                Icons.language,
                color: Get.theme.primaryColor,
              ),
              tooltip: 'Choose Language',
            ),
          ],
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Get.theme.backgroundColor,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Get.theme.backgroundColor,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: const SafeArea(child: Body()),
        ),
      );
    });
  }
}
