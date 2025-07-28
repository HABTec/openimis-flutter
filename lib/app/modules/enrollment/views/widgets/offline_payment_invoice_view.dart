import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controller/enrollment_controller.dart';

class OfflinePaymentInvoiceView extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  final EnrollmentController controller = Get.find<EnrollmentController>();

  OfflinePaymentInvoiceView({
    Key? key,
    required this.paymentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'Payment Invoice',
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
            icon: Icon(Icons.cloud_upload, color: Colors.white),
            onPressed: () => _showSyncDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // Success Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 32.w,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Payment Recorded!',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your offline payment has been recorded and will be synced when you\'re online',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Invoice Details Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt,
                          color: AppTheme.primaryColor,
                          size: 24.w,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Payment Invoice',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Member Information
                    _buildInvoiceSection(
                      'Member Information',
                      [
                        _buildInvoiceItem(
                            'CBHI ID', controller.chfidController.text),
                        _buildInvoiceItem('Name',
                            '${controller.givenNameController.text} ${controller.lastNameController.text}'),
                        _buildInvoiceItem(
                            'Phone', controller.phoneController.text),
                        _buildInvoiceItem(
                            'Email', controller.emailController.text),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Payment Information
                    _buildInvoiceSection(
                      'Payment Information',
                      [
                        _buildInvoiceItem('Transaction ID',
                            paymentData['transaction_id'] ?? 'N/A'),
                        _buildInvoiceItem('Amount',
                            '${paymentData['amount']?.toStringAsFixed(2) ?? '0.00'} ETB'),
                        _buildInvoiceItem(
                            'Payment Method',
                            _getPaymentMethodDisplay(
                                paymentData['payment_method'] ?? '')),
                        _buildInvoiceItem('Payment Date',
                            _formatDate(paymentData['payment_date'])),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Status indicator
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sync,
                            color: Colors.orange,
                            size: 24.w,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Pending Sync',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            'This payment will be synced with the server when you\'re online',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.orange.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      onPressed: () => _showSyncDialog(),
                      icon: Icon(Icons.cloud_upload, size: 24.w),
                      label: Text(
                        'Sync Now',
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
                      onPressed: () => _shareInvoice(),
                      icon: Icon(Icons.share, size: 24.w),
                      label: Text(
                        'Share Invoice',
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
                      onPressed: () => _goHome(),
                      child: Text(
                        'Go to Home',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 12.h),
        ...items,
      ],
    );
  }

  Widget _buildInvoiceItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodDisplay(String method) {
    switch (method) {
      case 'offline_manual':
        return 'PoS Machine (Manual Entry)';
      case 'offline_ocr':
        return 'PoS Machine (OCR Scan)';
      case 'online':
        return 'Online Payment';
      default:
        return 'Offline Payment';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showSyncDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Sync Payment',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Text(
          'Do you want to sync this payment with the server now?',
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
              _syncPayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Sync Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _syncPayment() async {
    try {
      // Show loading
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16.w),
              Text('Syncing payment...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Simulate sync operation
      await Future.delayed(Duration(seconds: 2));

      // Call the controller's sync method
      await controller.syncPendingFamilies();

      Get.back(); // Close loading dialog

      Get.snackbar(
        'Success',
        'Payment synced successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to sync payment: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _shareInvoice() {
    // Implement share functionality
    Get.snackbar(
      'Share',
      'Invoice sharing functionality would be implemented here',
      backgroundColor: AppTheme.primaryColor,
      colorText: Colors.white,
    );
  }

  void _goHome() {
    // Navigate to home and clear navigation stack
    Get.offAllNamed('/home');
  }
}
