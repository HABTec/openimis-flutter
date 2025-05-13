import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:heroicons/heroicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openimis_app/app/modules/root/views/widgets/partners.dart';
import 'package:openimis_app/app/modules/settings/views/settings_view.dart';

import '../../../../core/theme/theme_service.dart';
import '../../../../language/language_service.dart';
import '../../../../language/view/language_dropdown.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/custom_avatar.dart';
import '../../../Insuree/views/notification.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../home/controllers/home_controller.dart';
import '../../controllers/root_controller.dart';

class MenuView extends GetView<RootController> {
  const MenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final themeService = Get.find<ThemeService>();
    final authController = Get.find<AuthController>();

    return SafeArea(
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            SizedBox(height: 20.h),
            MenuItem(
              icon: HeroIcons.user,
              title: "Profile",
              onTap: () => Get.toNamed(Routes.PROFILE),
              //onTap: () => Get.toNamed(Routes.CUSTOMER_PROFILE),
            ),
            MenuItem(
                icon: HeroIcons.bell,
                title: "Notifications",
                onTap: () => Get.toNamed(Routes.NOTICES)),
            Row(
              children: [
                Expanded(
                  child: MenuItem(
                    icon: HeroIcons.language,
                    title: 'selected_language'.tr,
                    subtitle: 'selected'.tr,
                  ),
                ),
                LanguageDropdown(languageService: languageService),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                MenuItem(
                  icon: HeroIcons.sun,
                  title: "Theme",
                  subtitle: themeService.isDarkTheme.value ? "Dark" : "Light",
                ),
                Switch(
                  value: themeService.isDarkTheme.value,
                  onChanged: (value) {
                    themeService.toggleTheme();
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Obx(
              () {
                final isBiometricEnabled =
                    authController.isBiometricEnabled.value;
                return SwitchListTile(
                  title: Text("Enable Biometric Authentication"),
                  value: isBiometricEnabled,
                  onChanged: (value) {
                    authController.toggleBiometric(value);
                  },
                );
              },
            ),
            MenuItem(
              icon: HeroIcons.heart,
              title: "Supported Partners",
              onTap: () => Get.to(() => PartnersPage()),
            ),
            MenuItem(
              icon: HeroIcons.heart,
              title: "Notifications",
              onTap: () => Get.to(() => NotificationSettingsPage()),
            ),
            const Spacer(),
            MenuItem(
              icon: HeroIcons.arrowLeftOnRectangle,
              title: "Logout",
              onTap: controller.logout,
              textColor: Get.theme.errorColor,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

class _Header extends GetView<RootController> {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Get.theme.primaryColor,
        image: const DecorationImage(
          image: AssetImage(
            'assets/openimis-logo.png', // Use your asset image instead of network image
          ),
          fit: BoxFit.contain,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.CUSTOMER_PROFILE),
                  child: Obx(
                    () => HomeController.to.customerAvatar.when(
                      idle: () => const SizedBox(),
                      loading: () => const SizedBox(),
                      success: (data) => CustomAvatar(
                        imageUrl:
                            "https://upload.wikimedia.org/wikipedia/commons/9/92/Logo_of_openIMIS.png", //"${ApiRoutes.BASE_URL}$data",
                        height: 55.h,
                      ),
                      failure: (error) => const SizedBox(),
                    ),
                  ),
                ),
                Row(
                  children: [
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
                      icon: const HeroIcon(
                        HeroIcons.cog6Tooth,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: () => Scaffold.of(context).closeDrawer(),
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
                      icon: const HeroIcon(
                        HeroIcons.xMark,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Text(
              AuthController.to.currentUser!.name!.capitalize!,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Get.theme.colorScheme.onPrimary,
              ),
            ),
            Text(
              AuthController.to.currentUser!.email!,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: Get.theme.colorScheme.onPrimary.withOpacity(.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  const MenuItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color,
    this.textColor,
  }) : super(key: key);
  final HeroIcons icon;
  final String title;
  final String? subtitle;
  final void Function()? onTap;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap ?? () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 16.w),
        backgroundColor: color ?? Colors.transparent,
      ),
      child: Row(
        children: [
          HeroIcon(
            icon,
            color: textColor ?? Get.theme.colorScheme.secondary,
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Get.theme.colorScheme.onBackground,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor ??
                        Get.theme.colorScheme.secondary.withOpacity(.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          )
        ],
      ),
    );
  }
}
