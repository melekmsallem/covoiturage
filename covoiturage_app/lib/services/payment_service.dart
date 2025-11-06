import 'package:flutter/foundation.dart';
import 'api_service.dart';

// Payment method enum
enum PaymentMethod {
  CREDIT_CARD('CREDIT_CARD'),
  BANK_TRANSFER('BANK_TRANSFER'),
  CASH('CASH'),
  MOBILE_PAYMENT('MOBILE_PAYMENT');

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
class Payment {
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
      id: (json['id'] as num).toInt(),
      reservationId: (json['reservationId'] as num).toInt(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      amount: (json['amount'] as num).toDouble(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['paymentDate'] ?? json['createdAt'] ?? '').toString(),
      transactionId: json['transactionId']?.toString(),
      paymentDetails: json['paymentDetails']?.toString(),
    );
  }

  bool get isPending => status == PaymentStatus.PENDING.value;
  bool get isCompleted => status == PaymentStatus.COMPLETED.value;
  bool get isFailed => status == PaymentStatus.FAILED.value;
  bool get isRefunded => status == PaymentStatus.REFUNDED.value;
}

class PaymentService {
  static const String baseUrl = 'http://localhost:8081/api';

  // Create Stripe Checkout session for a reservation
  static Future<String?> createStripeCheckoutSession({
    required int reservationId,
  }) async {
    try {
      final response = await ApiService.instance.post(
        '/stripe/checkout-session/$reservationId',
        {},
      );
      final url = response['url']?.toString();
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (e) {
      debugPrint('Failed to create Stripe Checkout session: $e');
      return null;
    }
  }

  // Check if payment exists for a reservation
  static Future<Payment?> getPaymentForReservation(int reservationId) async {
    try {
      debugPrint('Checking payment for reservation: $reservationId');
      final response = await ApiService.instance.get('/payments/reservation/$reservationId');
      
      if (response.isNotEmpty) {
        debugPrint('Payment found: ${response.toString()}');
        return Payment.fromJson(response);
      }
      debugPrint('No payment found for reservation: $reservationId');
      return null;
    } catch (e) {
      // 404 means no payment exists, which is normal
      if (e.toString().contains('404')) {
        debugPrint('No payment found for reservation: $reservationId (404)');
        return null;
      }
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
      final paymentData = {
        'reservationId': reservationId,
        'paymentMethod': paymentMethod.value,
        'amount': amount,
      };
      
      debugPrint('Creating payment with data: $paymentData');
      
      final response = await ApiService.instance.post('/payments', paymentData);
      
      debugPrint('Payment created successfully: $response');
      return Payment.fromJson(response);
    } catch (e) {
      // Check if payment already exists
      if (e.toString().contains('Payment already exists')) {
        debugPrint('Payment already exists, fetching existing payment');
        final existingPayment = await getPaymentForReservation(reservationId);
        if (existingPayment != null) {
          return existingPayment;
        }
      }
      debugPrint('Failed to create payment: $e');
      throw Exception('Failed to create payment: $e');
    }
  }

  // Process payment (simulate payment gateway)
  static Future<Payment> processPayment({
    required int paymentId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      print('DEBUG: Processing payment $paymentId with method ${paymentMethod.value}');
      
      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await ApiService.instance.post('/payments/$paymentId/process', {
        'transactionId': transactionId,
        'paymentDetails': 'Payment processed via ${paymentMethod.value}',
      });
      
      print('DEBUG: Payment processed successfully: $response');
      
      return Payment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Get user's payment history
  static Future<List<Payment>> getMyPayments() async {
    try {
      final response = await ApiService.instance.getDynamic('/payments/my-payments');
      
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
      case PaymentMethod.MOBILE_PAYMENT:
        return 'Mobile Payment';
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
      case PaymentMethod.MOBILE_PAYMENT:
        return '📱';
    }
  }

  // Validate payment amount
  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 1000; // Max 1000 TND
  }

  // Get available payment methods for user
  static List<PaymentMethod> getAvailablePaymentMethods() {
    // Hide Mobile Payment as requested; keep others available
    return PaymentMethod.values.where((m) => m != PaymentMethod.MOBILE_PAYMENT).toList();
  }
}
