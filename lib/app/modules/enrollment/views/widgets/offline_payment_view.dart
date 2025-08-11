import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controller/enhanced_enrollment_controller.dart';

class OfflinePaymentView extends StatelessWidget {
  final EnhancedEnrollmentController controller =
      Get.find<EnhancedEnrollmentController>();

  OfflinePaymentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: AppTheme.primaryColor,
                  size: 28.w,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Offline Payment',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            Text(
              'Complete your payment using a PoS machine and enter the transaction details below.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 24.h),

            // Payment amount display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount to Pay',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(() => Text(
                        '${controller.calculatedContribution.value.toStringAsFixed(2)} ETB',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Transaction ID input method selection
            Text(
              'Transaction ID Entry',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),

            SizedBox(height: 16.h),

            // Option buttons
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    'Manual Entry',
                    Icons.keyboard,
                    () => _showManualEntryDialog(context),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildOptionButton(
                    'Scan Receipt',
                    Icons.camera_alt,
                    () => controller.pickReceiptPhoto(),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Transaction ID display
            Obx(() => controller.transactionId.value.isNotEmpty
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              controller.paymentMethod.value == 'offline_ocr'
                                  ? Icons.camera_alt
                                  : Icons.keyboard,
                              color: Colors.green,
                              size: 20.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Transaction ID',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          controller.transactionId.value,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          controller.paymentMethod.value == 'offline_ocr'
                              ? 'Extracted from receipt'
                              : 'Manually entered',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container()),

            // Receipt image display
            Obx(() => controller.receiptPhoto.value != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      Text(
                        'Receipt Image',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        height: 200.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            File(controller.receiptPhoto.value!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container()),

            // OCR processing indicator
            Obx(() => controller.isProcessingOCR.value
                ? Column(
                    children: [
                      SizedBox(height: 16.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Processing receipt...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Container()),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24.w,
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Transaction ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter the transaction ID from your PoS receipt:',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: controller.transactionIdController,
              decoration: InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'e.g., TXN123456789',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                controller.setManualTransactionId(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = controller.transactionIdController.text.trim();
              if (controller.validateTransactionId(id)) {
                controller.setManualTransactionId(id);
                Get.back();
              } else {
                Get.snackbar(
                  'Invalid ID',
                  'Please enter a valid transaction ID (minimum 8 characters)',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
