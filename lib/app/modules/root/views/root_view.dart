import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:openimis_app/app/modules/enrollment/views/enrollment_view.dart';
import 'package:openimis_app/app/widgets/shimmer/insuree_shimmer.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import '../../Insuree/views/claim_view.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/views/home_view.dart';
import '../../policy/views/policy_view.dart';
import '../../search/views/search_view.dart';
import '../controllers/root_controller.dart';
import 'widgets/menu_view.dart';
import '../../settings/views/settings_view.dart';

class RootView extends GetView<RootController> {
  const RootView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(AuthController());
    return Scaffold(
      drawer: Drawer(
        width: 0.85.sw,
        child: const MenuView(),
      ),
      drawerEdgeDragWidth: 0.0,
      body: Obx(
        () {
          return controller.configStatus.when(
            idle: () => Container(),
            success: (data) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Get.theme.backgroundColor,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              child: PersistentTabView(
                context,
                controller: controller.persistentTabController,
                screens: _getNavBarScreens(),
                items: _getNavBarItems(),
                confineInSafeArea: true,
                navBarHeight: 56.h,
                decoration: NavBarDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Get.theme.colorScheme.secondary.withOpacity(.15),
                      spreadRadius: 0,
                      blurRadius: 159,
                      offset: const Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),
                popAllScreensOnTapOfSelectedTab: true,
                popActionScreens: PopActionScreensType.all,
                itemAnimationProperties: const ItemAnimationProperties(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.ease,
                ),
                screenTransitionAnimation: const ScreenTransitionAnimation(
                  animateTabTransition: true,
                  curve: Curves.ease,
                  duration: Duration(milliseconds: 200),
                ),
                navBarStyle: NavBarStyle.style11,
              ),
            ),
            failure: (String? reason) => Center(
              child: Text('Failed: $reason'),
            ),
            loading: () => Center(
              child: InsureeShimmer(),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _getNavBarScreens() {
    if (AuthController.to.isInsuree()) {
      return _getInsureeNavBarScreens();
    } else if (AuthController.to.isOfficer()) {
      return _getOfficerNavBarScreens();
    }
    // Fallback or default in case of undefined roles
    return _getDefaultNavBarScreens();
  }

  List<Widget> _getInsureeNavBarScreens() {
    return [
      HomeView(),
      SearchView(),
      ClaimView()
      //PolicyView(),
      //SearchView(),
    ];
  }

  List<Widget> _getOfficerNavBarScreens() {
    return [
      HomeView(),
      EnrollmentView(),
      PolicyView(),
      SearchView(),
    ];
  }

  List<PersistentBottomNavBarItem> _getNavBarItems() {
    if (AuthController.to.isInsuree()) {
      return _getInsureeNavBarItems();
    } else if (AuthController.to.isOfficer()) {
      return _getOfficerNavBarItems();
    }
    // Fallback or default in case of undefined roles
    return _getDefaultNavBarItems();
  }

  List<PersistentBottomNavBarItem> _getInsureeNavBarItems() {
    return [
      _getNavBarItem(
        "Home",
        HeroIcons.home,
        () => controller.onHomeDoubleClick(),
      ),
      _getNavBarItem(
        "Family",
        HeroIcons.users,
        () => controller.onSearchDoubleClick(),
      ),
      _getNavBarItem(
        "Claims",
        HeroIcons.bars3,
        () => controller.onSearchDoubleClick(),
      )
    ];
  }

  List<PersistentBottomNavBarItem> _getOfficerNavBarItems() {
    return [
      _getNavBarItem(
        "Search",
        HeroIcons.magnifyingGlass,
        () => controller.onSearchDoubleClick(),
      ),
      _getNavBarItem(
        "Enrollment",
        HeroIcons.userGroup,
        () => controller.onSearchDoubleClick(),
      ),
      _getNavBarItem(
        "Policy",
        HeroIcons.identification,
        () => controller.onSearchDoubleClick(),
      ),
      _getNavBarItem(
        "Search Insuree",
        HeroIcons.magnifyingGlass,
        () => controller.onSearchDoubleClick(),
      ),
    ];
  }

  // Optional default nav bar in case of no valid user type
  List<Widget> _getDefaultNavBarScreens() {
    return [
      HomeView(),
      SearchView(),
      PolicyView(),
      SearchView(),
    ];
  }

  List<PersistentBottomNavBarItem> _getDefaultNavBarItems() {
    return [
      _getNavBarItem(
        "Home",
        HeroIcons.home,
        () => controller.onHomeDoubleClick(),
      ),
      _getNavBarItem(
        "Search",
        HeroIcons.magnifyingGlass,
        () => controller.onSearchDoubleClick(),
      ),
      _getNavBarItem(
        "Policy",
        HeroIcons.identification,
        () => controller.onSearchDoubleClick(),
      ),
      _getNavBarItem(
        "Search Insuree",
        HeroIcons.magnifyingGlass,
        () => controller.onSearchDoubleClick(),
      ),
    ];
  }

  PersistentBottomNavBarItem _getNavBarItem(
    String title,
    HeroIcons icon,
    void Function() onDoubleTap,
  ) {
    return PersistentBottomNavBarItem(
      icon: HeroIcon(icon),
      title: title,
      activeColorPrimary: Get.theme.primaryColor,
      inactiveColorPrimary: Get.theme.colorScheme.secondary,
      onSelectedTabPressWhenNoScreensPushed: onDoubleTap,
      textStyle: GoogleFonts.poppins(
        fontSize: 10.sp,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
