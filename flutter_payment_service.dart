import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_api_service.dart';

class PaymentService {
  static const String baseUrl = 'http://localhost:8081/api';

  // Payment method enum
  enum PaymentMethod {
    CREDIT_CARD('CREDIT_CARD'),
    BANK_TRANSFER('BANK_TRANSFER'),
    CASH('CASH'),
    MOBILE_MONEY('MOBILE_MONEY');

    const PaymentMethod(this.value);
    final String value;
  }

  // Payment status enum
  enum PaymentStatus {
    PENDING('PENDING'),
    COMPLETED('COMPLETED'),
    FAILED('FAILED'),
    REFUNDED('REFUNDED');

    const PaymentStatus(this.value);
    final String value;
  }

  // Payment model
  static class Payment {
    final int id;
    final int reservationId;
    final String paymentMethod;
    final double amount;
    final String status;
    final String createdAt;
    final String? transactionId;
    final String? paymentDetails;

    Payment({
      required this.id,
      required this.reservationId,
      required this.paymentMethod,
      required this.amount,
      required this.status,
      required this.createdAt,
      this.transactionId,
      this.paymentDetails,
    });

    factory Payment.fromJson(Map<String, dynamic> json) {
      return Payment(
        id: json['id'],
        reservationId: json['reservationId'],
        paymentMethod: json['paymentMethod'],
        amount: json['amount'].toDouble(),
        status: json['status'],
        createdAt: json['createdAt'],
        transactionId: json['transactionId'],
        paymentDetails: json['paymentDetails'],
      );
    }

    bool get isPending => status == PaymentStatus.PENDING.value;
    bool get isCompleted => status == PaymentStatus.COMPLETED.value;
    bool get isFailed => status == PaymentStatus.FAILED.value;
    bool get isRefunded => status == PaymentStatus.REFUNDED.value;
  }

  // Check if payment exists for a reservation
  static Future<Payment?> getPaymentForReservation(int reservationId) async {
    try {
      final response = await ApiService.getPaymentByReservation(
        reservationId: reservationId,
      );
      
      if (response.isNotEmpty) {
        return Payment.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting payment for reservation: $e');
      return null;
    }
  }

  // Create payment for a confirmed reservation
  static Future<Payment> createPayment({
    required int reservationId,
    required PaymentMethod paymentMethod,
    required double amount,
  }) async {
    try {
      final response = await ApiService.createPayment(
        reservationId: reservationId,
        paymentMethod: paymentMethod.value,
        amount: amount,
      );
      
      return Payment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  // Process payment (simulate payment gateway)
  static Future<Payment> processPayment({
    required int paymentId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate mock transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await ApiService.processPayment(
        paymentId: paymentId,
        transactionId: transactionId,
        paymentDetails: 'Payment processed via ${paymentMethod.value}',
      );
      
      return Payment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Get user's payment history
  static Future<List<Payment>> getMyPayments() async {
    try {
      final response = await ApiService.getMyPayments();
      
      return response.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get payments: $e');
    }
  }

  // Check if payment is required for a reservation
  static Future<bool> isPaymentRequired(int reservationId) async {
    try {
      final payment = await getPaymentForReservation(reservationId);
      
      // Payment is required if:
      // 1. No payment exists yet, OR
      // 2. Payment exists but is pending or failed
      return payment == null || 
             payment.isPending || 
             payment.isFailed;
    } catch (e) {
      debugPrint('Error checking payment requirement: $e');
      return false;
    }
  }

  // Get payment status for a reservation
  static Future<PaymentStatus?> getPaymentStatus(int reservationId) async {
    try {
      final payment = await getPaymentForReservation(reservationId);
      
      if (payment == null) return null;
      
      return PaymentStatus.values.firstWhere(
        (status) => status.value == payment.status,
        orElse: () => PaymentStatus.PENDING,
      );
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return null;
    }
  }

  // Format payment amount
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} TND';
  }

  // Get payment method display name
  static String getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.CREDIT_CARD:
        return 'Credit Card';
      case PaymentMethod.BANK_TRANSFER:
        return 'Bank Transfer';
      case PaymentMethod.CASH:
        return 'Cash';
      case PaymentMethod.MOBILE_MONEY:
        return 'Mobile Money';
    }
  }

  // Get payment method icon
  static String getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.CREDIT_CARD:
        return '💳';
      case PaymentMethod.BANK_TRANSFER:
        return '🏦';
      case PaymentMethod.CASH:
        return '💵';
      case PaymentMethod.MOBILE_MONEY:
        return '📱';
    }
  }

  // Validate payment amount
  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 1000; // Max 1000 TND
  }

  // Get available payment methods for user
  static List<PaymentMethod> getAvailablePaymentMethods() {
    // In a real app, this would be based on user preferences or country
    return PaymentMethod.values;
  }
}








