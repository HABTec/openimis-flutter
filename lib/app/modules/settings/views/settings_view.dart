import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Configuration Section
                _buildCurrentConfigSection(),

                SizedBox(height: 24.h),

                // Base URL Configuration Section
                _buildBaseUrlSection(),

                SizedBox(height: 24.h),

                // Predefined URLs Section
                _buildPredefinedUrlsSection(),

                SizedBox(height: 24.h),

                // Action Buttons Section
                _buildActionButtonsSection(),

                SizedBox(height: 24.h),

                // App Information Section
                _buildAppInfoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentConfigSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: AppTheme.primaryColor,
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Current Configuration',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Obx(() => Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base URL:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        controller.currentBaseUrl,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseUrlSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link,
                  color: AppTheme.primaryColor,
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Base URL Configuration',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            TextFormField(
              controller: controller.baseUrlController,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'e.g., http://127.0.0.1:8000',
                prefixIcon: Icon(Icons.language, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide:
                      BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                helperText:
                    'Enter the complete URL including protocol (http/https)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a base URL';
                }
                if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Test and Save buttons
            Row(
              children: [
                Expanded(
                  child: Obx(() => OutlinedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.testConnection,
                        icon: controller.isLoading.value
                            ? SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.wifi_protected_setup),
                        label: Text('Test Connection'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      )),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                if (controller.formKey.currentState!
                                    .validate()) {
                                  controller.saveBaseUrl(
                                    controller.baseUrlController.text.trim(),
                                  );
                                }
                              },
                        icon: controller.isLoading.value
                            ? SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(Icons.save),
                        label: Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedUrlsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark_border,
                  color: AppTheme.primaryColor,
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Quick Select',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Choose from predefined server configurations:',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            ...controller.predefinedUrls
                .map(
                  (urlConfig) => _buildPredefinedUrlTile(
                    urlConfig['name']!,
                    urlConfig['url']!,
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedUrlTile(String name, String url) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        subtitle: Text(
          url,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 16.w,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => controller.selectPredefinedUrl(url),
        ),
        onTap: () => controller.selectPredefinedUrl(url),
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build,
                  color: AppTheme.primaryColor,
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Advanced Options',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Reset to defaults button
            SizedBox(
              width: double.infinity,
              child: Obx(() => OutlinedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => _showResetDialog(),
                    icon: Icon(Icons.restore),
                    label: Text('Reset to Defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  )),
            ),

            SizedBox(height: 12.h),

            // Database dump button
            SizedBox(
              width: double.infinity,
              child: Obx(() => OutlinedButton.icon(
                    onPressed: controller.isLoading.value ||
                            controller.isDumpingDb.value
                        ? null
                        : () => _showDatabaseDumpDialog(),
                    icon: controller.isDumpingDb.value
                        ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.backup),
                    label: Text(controller.isDumpingDb.value
                        ? 'Generating Dump...'
                        : 'Export Database Dump'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: BorderSide(color: Colors.purple),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  )),
            ),

            SizedBox(height: 12.h),

            // Clear app data button
            SizedBox(
              width: double.infinity,
              child: Obx(() => OutlinedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => _showClearDataDialog(),
                    icon: Icon(Icons.delete_sweep),
                    label: Text('Clear All App Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.app_settings_alt, color: Colors.grey[600]),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      controller.appInfo,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.developer_mode, color: Colors.grey[600]),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environment',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Development Build',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Reset Settings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Text(
          'This will reset all settings to their default values. Are you sure?',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Clear App Data',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'This will delete all app data including settings, cache, and stored information. This action cannot be undone. Are you sure?',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearAppData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Clear Data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatabaseDumpDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.backup,
              color: Colors.purple,
              size: 24.w,
            ),
            SizedBox(width: 8.w),
            Text(
              'Export Database Dump',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will export all database content including:',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12.h),
            _buildDumpFeatureItem('Family and member data'),
            _buildDumpFeatureItem('Configuration settings'),
            _buildDumpFeatureItem('Application preferences'),
            _buildDumpFeatureItem('Database schemas and metadata'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber[700], size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'The dump will be saved as a JSON file that you can share for analysis.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              controller.exportDatabaseDump();
            },
            icon: Icon(Icons.file_download),
            label: Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDumpFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 16.w,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDbStatItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.blue[600],
        ),
      ),
    );
  }
}
