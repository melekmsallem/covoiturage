import 'api_service.dart';

class ChatService {
  /// Send a message to a booking chat
  static Future<Map<String, dynamic>> sendMessage({
    required int bookingId,
    required String message,
    String messageType = 'TEXT',
  }) async {
    try {
      final response = await ApiService.instance.post('/chat/send', {
        'bookingId': bookingId,
        'message': message,
        'messageType': messageType,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get all messages for a booking
  static Future<List<dynamic>> getMessages(int bookingId) async {
    try {
      final response = await ApiService.instance.getDynamic('/chat/booking/$bookingId/messages');
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Get messages since a specific timestamp
  static Future<List<dynamic>> getMessagesSince(int bookingId, String since) async {
    try {
      final response = await ApiService.instance.getDynamic('/chat/booking/$bookingId/messages/since/$since');
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get messages since: $e');
    }
  }

  /// Get unread message count for a booking
  static Future<int> getUnreadCount(int bookingId) async {
    try {
      final response = await ApiService.instance.getDynamic('/chat/booking/$bookingId/unread-count');
      if (response is Map<String, dynamic> && response.containsKey('unreadCount')) {
        return response['unreadCount'] as int;
      }
      return response as int;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Mark messages as read for a booking
  static Future<void> markMessagesAsRead(int bookingId) async {
    try {
      await ApiService.instance.post('/chat/booking/$bookingId/mark-read', {});
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }
}

