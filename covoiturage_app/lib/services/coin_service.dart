import 'package:flutter/foundation.dart';
import 'api_service.dart';

class CoinService {
  static const String _baseUrl = '/coins';

  // Get user's coin balance
  static Future<Map<String, dynamic>> getBalance() async {
    try {
      debugPrint('DEBUG: CoinService.getBalance called');
      final response = await ApiService.instance.getDynamic('$_baseUrl/balance');
      debugPrint('DEBUG: CoinService.getBalance response: $response');
      return response;
    } catch (e) {
      debugPrint('Failed to get coin balance: $e');
      throw Exception('Failed to get coin balance: $e');
    }
  }

  // Get user's transaction history
  static Future<List<dynamic>> getTransactionHistory() async {
    try {
      final response = await ApiService.instance.getDynamic('$_baseUrl/transactions');
      return response;
    } catch (e) {
      debugPrint('Failed to get transaction history: $e');
      throw Exception('Failed to get transaction history: $e');
    }
  }

  // Purchase coins via Stripe
  static Future<Map<String, dynamic>> purchaseCoins(double coinAmount) async {
    try {
      // First get the user ID from the balance endpoint
      final balanceResponse = await getBalance();
      final userId = balanceResponse['userId'];
      
      // Send as query parameters instead of POST body
      final response = await ApiService.instance.post(
        '/stripe/checkout-session/coins?userId=$userId&coinAmount=$coinAmount',
        <String, dynamic>{},
      );
      
      return response;
    } catch (e) {
      debugPrint('Failed to create coin purchase session: $e');
      throw Exception('Failed to create coin purchase session: $e');
    }
  }

  // Spend coins (for bookings)
  static Future<Map<String, dynamic>> spendCoins({
    required double amount,
    required String description,
    required String referenceId,
  }) async {
    try {
      final response = await ApiService.instance.post('$_baseUrl/spend', {
        'amount': amount,
        'description': description,
        'referenceId': referenceId,
      });
      
      return response;
    } catch (e) {
      debugPrint('Failed to spend coins: $e');
      throw Exception('Failed to spend coins: $e');
    }
  }

  // Refund coins
  static Future<Map<String, dynamic>> refundCoins({
    required double amount,
    required String description,
    required String referenceId,
  }) async {
    try {
      final response = await ApiService.instance.post('$_baseUrl/refund', {
        'amount': amount,
        'description': description,
        'referenceId': referenceId,
      });
      
      return response;
    } catch (e) {
      debugPrint('Failed to refund coins: $e');
      throw Exception('Failed to refund coins: $e');
    }
  }

  // Check if user has sufficient balance
  static Future<bool> hasSufficientBalance(double amount) async {
    try {
      final balanceResponse = await getBalance();
      final balance = balanceResponse['balance'] ?? 0.0;
      return balance >= amount;
    } catch (e) {
      debugPrint('Failed to check balance: $e');
      return false;
    }
  }
}
