import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/remote/services/payment/arifpay_service.dart';

class ReceiptView extends StatelessWidget {
  final PaymentVerificationResponse receiptData;
  final VoidCallback onDownloadQR;

  const ReceiptView({
    Key? key,
    required this.receiptData,
    required this.onDownloadQR,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'Payment Receipt',
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
            onPressed: _shareReceipt,
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32.w,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your CBHI membership payment has been processed successfully',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Receipt Details Card
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
                          Icons.receipt_long,
                          color: AppTheme.primaryColor,
                          size: 24.w,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Payment Receipt',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _buildReceiptItem(
                      'Receipt Number',
                      receiptData.receiptNumber,
                      Icons.confirmation_number,
                    ),
                    _buildReceiptItem(
                      'Transaction ID',
                      receiptData.transactionId,
                      Icons.tag,
                    ),
                    _buildReceiptItem(
                      'Amount Paid',
                      '${receiptData.amount.toStringAsFixed(2)} ${receiptData.currency}',
                      Icons.monetization_on,
                      valueColor: Colors.green,
                    ),
                    _buildReceiptItem(
                      'Payment Date',
                      DateFormat('MMM dd, yyyy HH:mm').format(
                        DateTime.parse(receiptData.paymentDate),
                      ),
                      Icons.calendar_today,
                    ),
                    _buildReceiptItem(
                      'Payer Name',
                      receiptData.payerDetails['name'] ?? 'N/A',
                      Icons.person,
                    ),
                    _buildReceiptItem(
                      'Phone Number',
                      receiptData.payerDetails['phone'] ?? 'N/A',
                      Icons.phone,
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.secondaryColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 24.w,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Payment Verified',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            'This payment has been verified and processed',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.green.shade600,
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
                      onPressed: onDownloadQR,
                      icon: Icon(Icons.qr_code, size: 24.w),
                      label: Text(
                        'Download QR Membership Card',
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
                      onPressed: _downloadReceipt,
                      icon: Icon(Icons.download, size: 24.w),
                      label: Text(
                        'Download Receipt',
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
                        'Continue',
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

  Widget _buildReceiptItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.w,
            color: Colors.grey[600],
          ),
          SizedBox(width: 12.w),
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
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _shareReceipt() {
    // Implement share functionality
    Get.snackbar(
      'Share',
      'Receipt sharing functionality would be implemented here',
      backgroundColor: AppTheme.primaryColor,
      colorText: Colors.white,
    );
  }

  void _downloadReceipt() {
    // Implement download functionality
    Get.snackbar(
      'Download',
      'Receipt download functionality would be implemented here',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
