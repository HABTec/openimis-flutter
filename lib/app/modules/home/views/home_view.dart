import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'OpenIMIS Enrollment',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Community Based Health Insurance',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Quick Actions Section
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),

              SizedBox(height: 16.h),

              // Action Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard(
                      title: 'New Family\nRegistration',
                      icon: HeroIcons.userGroup,
                      color: Color(0xFF036273),
                      onTap: () => Get.toNamed('/enhanced-enrollment'),
                    ),
                    _buildActionCard(
                      title: 'Family\nRecords',
                      icon: HeroIcons.folderOpen,
                      color: Color(0xFF036273),
                      onTap: () => Get.toNamed('/enrollment-list'),
                    ),
                    _buildActionCard(
                      title: 'Membership\nRenewal',
                      icon: HeroIcons.arrowPathRoundedSquare,
                      color: Color(0xFF036273).withOpacity(0.8),
                      onTap: () => _showComingSoonDialog('Membership Renewal'),
                    ),
                    _buildActionCard(
                      title: 'Sync\nStatus',
                      icon: HeroIcons.arrowPath,
                      color: Color(0xFF036273).withOpacity(0.7),
                      onTap: () => Get.toNamed('/sync-status'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required HeroIcons icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: HeroIcon(
                icon,
                color: color,
                size: 32.w,
                style: HeroIconStyle.solid,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.health_and_safety,
                      size: 30.w,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'OpenIMIS',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Community Health Insurance',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: HeroIcons.home,
                  title: 'Dashboard',
                  onTap: () {
                    Get.back();
                    Get.offNamed('/home');
                  },
                ),
                _buildDrawerItem(
                  icon: HeroIcons.userGroup,
                  title: 'New Family Registration',
                  onTap: () {
                    Get.back();
                    Get.toNamed('/enhanced-enrollment');
                  },
                ),
                _buildDrawerItem(
                  icon: HeroIcons.folderOpen,
                  title: 'Family Records',
                  onTap: () {
                    Get.back();
                    Get.toNamed('/enrollment-list');
                  },
                ),
                _buildDrawerItem(
                  icon: HeroIcons.arrowPath,
                  title: 'Sync Status',
                  onTap: () {
                    Get.back();
                    Get.toNamed('/sync-status');
                  },
                ),
                Divider(height: 1.h),
                _buildDrawerItem(
                  icon: HeroIcons.cog6Tooth,
                  title: 'Settings',
                  onTap: () {
                    Get.back();
                    Get.toNamed('/settings');
                  },
                ),
                _buildDrawerItem(
                  icon: HeroIcons.informationCircle,
                  title: 'About',
                  onTap: () {
                    Get.back();
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Divider(height: 1.h),
                SizedBox(height: 8.h),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required HeroIcons icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: HeroIcon(
        icon,
        color: AppTheme.primaryColor,
        size: 24.w,
        style: HeroIconStyle.outline,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'About OpenIMIS',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OpenIMIS Enrollment App',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Community Based Health Insurance enrollment and management system.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'Version: 1.0.0\nBuild: Development',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Text(
          '$feature feature is coming soon!',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
