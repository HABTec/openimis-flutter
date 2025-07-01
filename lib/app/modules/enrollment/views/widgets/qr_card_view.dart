import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/remote/services/payment/arifpay_service.dart';

class QRCardView extends StatefulWidget {
  final String chfid;
  final String memberName;
  final PaymentVerificationResponse? receiptData;

  const QRCardView({
    Key? key,
    required this.chfid,
    required this.memberName,
    this.receiptData,
  }) : super(key: key);

  @override
  State<QRCardView> createState() => _QRCardViewState();
}

class _QRCardViewState extends State<QRCardView> {
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'CBHI Membership Card',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: _shareCard,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // Header
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
                  children: [
                    Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 48.w,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'CBHI Membership Card',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Community Based Health Insurance',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Membership Card Preview
              Screenshot(
                controller: screenshotController,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Card Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25.r,
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 30.w,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ethiopian Health Insurance Agency',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'CBHI Membership Certificate',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Member Details
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCardDetail('Member Name', widget.memberName),
                            _buildCardDetail('CHFID', widget.chfid),
                            _buildCardDetail(
                                'Member Type', 'Head of Household'),
                            _buildCardDetail(
                              'Enrollment Date',
                              widget.receiptData?.paymentDate != null
                                  ? DateTime.parse(
                                          widget.receiptData!.paymentDate)
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0]
                                  : DateTime.now().toString().split(' ')[0],
                            ),
                            _buildCardDetail('Status', 'Active'),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // QR Code
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppTheme.secondaryColor,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: _generateQRData(),
                              version: QrVersions.auto,
                              size: 150.w,
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'CBHI ID: ${widget.chfid}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Validity Info
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: Colors.green,
                              size: 20.w,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Valid for healthcare services at registered facilities',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: _downloadCard,
                      icon: Icon(Icons.download, size: 24.w),
                      label: Text(
                        'Download Membership Card',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: OutlinedButton.icon(
                      onPressed: _shareCard,
                      icon: Icon(Icons.share, size: 24.w),
                      label: Text(
                        'Share Card',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Footer
              Text(
                'Keep this card safe and present it when accessing healthcare services',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateQRData() {
    return '''
{
  "chfid": "${widget.chfid}",
  "name": "${widget.memberName}",
  "type": "CBHI_MEMBER",
  "status": "ACTIVE",
  "enrollmentDate": "${DateTime.now().toIso8601String()}",
  "receiptNumber": "${widget.receiptData?.receiptNumber ?? 'N/A'}"
}
''';
  }

  void _downloadCard() async {
    try {
      // Enhanced permission handling for different Android versions
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return;
      }

      // Show loading dialog
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              SizedBox(width: 16),
              Text('Generating card...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Capture the screenshot
      final imageBytes = await screenshotController.capture(pixelRatio: 3.0);

      if (imageBytes != null) {
        // Get the downloads directory
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
          // Create CBHI folder in downloads
          final cbhiDir = Directory('${directory!.path}/CBHI_Cards');
          if (!await cbhiDir.exists()) {
            await cbhiDir.create(recursive: true);
          }
          directory = cbhiDir;
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        // Generate filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'CBHI_Card_${widget.chfid}_$timestamp.png';
        final filePath = '${directory.path}/$fileName';

        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Close loading dialog
        Get.back();

        // Show success message
        Get.snackbar(
          'Success',
          'Membership card saved to: $filePath',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () => _openFileLocation(filePath),
            child: Text('Open', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        Get.back();
        Get.snackbar(
          'Error',
          'Failed to generate card image',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to save card: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _shareCard() async {
    try {
      // Show loading dialog
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              SizedBox(width: 16),
              Text('Preparing to share...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Capture the screenshot
      final imageBytes = await screenshotController.capture(pixelRatio: 3.0);

      if (imageBytes != null) {
        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final fileName = 'CBHI_Card_${widget.chfid}.png';
        final filePath = '${directory.path}/$fileName';

        // Save temporary file
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Close loading dialog
        Get.back();

        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          text:
              'CBHI Membership Card for ${widget.memberName}\nCHFID: ${widget.chfid}\n\nCommunity Based Health Insurance',
          subject: 'CBHI Membership Card - ${widget.memberName}',
        );
      } else {
        Get.back();
        Get.snackbar(
          'Error',
          'Failed to generate card image for sharing',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to share card: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _openFileLocation(String filePath) async {
    try {
      // This would typically open the file manager to show the file
      // For now, we'll just copy the path to clipboard
      await Clipboard.setData(ClipboardData(text: filePath));
      Get.snackbar(
        'Path Copied',
        'File path copied to clipboard',
        backgroundColor: AppTheme.primaryColor,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error opening file location: $e');
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      // For Android 13+ (API 33+), we need different permissions
      if (Platform.isAndroid) {
        var androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ doesn't need storage permission for app-specific folders
          // But if we want to save to Downloads, we need MANAGE_EXTERNAL_STORAGE
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            // Show explanation dialog first
            bool shouldRequest = await _showPermissionDialog(
                'Storage Access Required',
                'This app needs access to save your membership card to Downloads folder. This helps you easily find and share your card.',
                'Grant Access',
                'Cancel');

            if (!shouldRequest) return false;

            status = await Permission.manageExternalStorage.request();

            if (!status.isGranted) {
              if (status.isPermanentlyDenied) {
                _showSettingsDialog();
              } else {
                Get.snackbar(
                  'Permission Required',
                  'Storage permission is needed to save your membership card',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  duration: Duration(seconds: 4),
                );
              }
              return false;
            }
          }
        } else {
          // Android 12 and below
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            bool shouldRequest = await _showPermissionDialog(
                'Storage Permission',
                'Allow this app to save your membership card to your device storage?',
                'Allow',
                'Deny');

            if (!shouldRequest) return false;

            status = await Permission.storage.request();

            if (!status.isGranted) {
              if (status.isPermanentlyDenied) {
                _showSettingsDialog();
              } else {
                Get.snackbar(
                  'Permission Denied',
                  'Storage permission is required to save the card',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
              return false;
            }
          }
        }
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'Permission Error',
        'Error requesting permission: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> _showPermissionDialog(String title, String message,
      String confirmText, String cancelText) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.security, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(cancelText),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  void _showSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: Text(
          'Storage permission has been permanently denied. Please grant permission in Settings to save your membership card.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
