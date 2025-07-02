import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';

class ArifPayService {
  final Dio _dio = Dio();

  // Mock base URL for ArifPay
  static const String _baseUrl = 'https://api.arifpay.com/v1';

  // Mock payment initiation
  Future<PaymentInitiationResponse> initiatePayment({
    required double amount,
    required String currency,
    required String orderId,
    required String description,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(seconds: 2));

      // Mock response - simulate successful payment initiation
      final mockResponse = {
        'success': true,
        'checkout_url':
            'https://checkout.arifpay.org/checkout/${_generateMockCheckoutId()}',
        'order_id': orderId,
        'amount': amount,
        'currency': currency,
        'session_id': _generateMockSessionId(),
        'expires_at':
            DateTime.now().add(Duration(minutes: 30)).toIso8601String(),
      };

      return PaymentInitiationResponse.fromJson(mockResponse);
    } catch (e) {
      throw PaymentException('Failed to initiate payment: $e');
    }
  }

  // Mock payment status check
  Future<PaymentStatusResponse> checkPaymentStatus(String sessionId) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(seconds: 1));

      // Mock different payment statuses
      final statuses = ['pending', 'success', 'failed'];
      final randomStatus = statuses[Random().nextInt(statuses.length)];

      final mockResponse = {
        'session_id': sessionId,
        'status': randomStatus,
        'amount': 150.0,
        'currency': 'ETB',
        'transaction_id':
            randomStatus == 'success' ? _generateMockTransactionId() : null,
        'receipt_number':
            randomStatus == 'success' ? _generateMockReceiptNumber() : null,
        'payment_date':
            randomStatus == 'success' ? DateTime.now().toIso8601String() : null,
        'message': _getStatusMessage(randomStatus),
      };

      return PaymentStatusResponse.fromJson(mockResponse);
    } catch (e) {
      throw PaymentException('Failed to check payment status: $e');
    }
  }

  // Mock payment verification
  Future<PaymentVerificationResponse> verifyPayment(
      String transactionId) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(seconds: 1));

      final mockResponse = {
        'transaction_id': transactionId,
        'verified': true,
        'amount': 150.0,
        'currency': 'ETB',
        'receipt_number': _generateMockReceiptNumber(),
        'payment_date': DateTime.now().toIso8601String(),
        'payer_details': {
          'name': 'Mock Payer',
          'phone': '+251912345678',
          'email': 'payer@example.com',
        },
      };

      return PaymentVerificationResponse.fromJson(mockResponse);
    } catch (e) {
      throw PaymentException('Failed to verify payment: $e');
    }
  }

  String _generateMockCheckoutId() {
    return 'FEACE93ED6A1${Random().nextInt(1000)}';
  }

  String _generateMockSessionId() {
    return 'sess_${Random().nextInt(1000000)}';
  }

  String _generateMockTransactionId() {
    return 'txn_${Random().nextInt(1000000)}';
  }

  String _generateMockReceiptNumber() {
    return 'RCP${Random().nextInt(100000)}';
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Payment is being processed';
      case 'success':
        return 'Payment completed successfully';
      case 'failed':
        return 'Payment failed. Please try again';
      default:
        return 'Unknown status';
    }
  }
}

// Payment DTOs
class PaymentInitiationResponse {
  final bool success;
  final String checkoutUrl;
  final String orderId;
  final double amount;
  final String currency;
  final String sessionId;
  final String expiresAt;

  PaymentInitiationResponse({
    required this.success,
    required this.checkoutUrl,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.sessionId,
    required this.expiresAt,
  });

  factory PaymentInitiationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiationResponse(
      success: json['success'],
      checkoutUrl: json['checkout_url'],
      orderId: json['order_id'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      sessionId: json['session_id'],
      expiresAt: json['expires_at'],
    );
  }
}

class PaymentStatusResponse {
  final String sessionId;
  final String status;
  final double amount;
  final String currency;
  final String? transactionId;
  final String? receiptNumber;
  final String? paymentDate;
  final String message;

  PaymentStatusResponse({
    required this.sessionId,
    required this.status,
    required this.amount,
    required this.currency,
    this.transactionId,
    this.receiptNumber,
    this.paymentDate,
    required this.message,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      sessionId: json['session_id'],
      status: json['status'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      transactionId: json['transaction_id'],
      receiptNumber: json['receipt_number'],
      paymentDate: json['payment_date'],
      message: json['message'],
    );
  }
}

class PaymentVerificationResponse {
  final String transactionId;
  final bool verified;
  final double amount;
  final String currency;
  final String receiptNumber;
  final String paymentDate;
  final Map<String, dynamic> payerDetails;

  PaymentVerificationResponse({
    required this.transactionId,
    required this.verified,
    required this.amount,
    required this.currency,
    required this.receiptNumber,
    required this.paymentDate,
    required this.payerDetails,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      transactionId: json['transaction_id'],
      verified: json['verified'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      receiptNumber: json['receipt_number'],
      paymentDate: json['payment_date'],
      payerDetails: json['payer_details'],
    );
  }
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}
