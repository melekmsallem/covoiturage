import 'api_service.dart';

class GroupChatService {
  static final ApiService _apiService = ApiService.instance;

  /// Send a group message
  static Future<Map<String, dynamic>> sendGroupMessage({
    required int tripId,
    required String message,
    String messageType = 'TEXT',
  }) async {
    try {
      final response = await _apiService.post('/chat/group/send', {
        'tripId': tripId,
        'message': message,
        'messageType': messageType,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to send group message: $e');
    }
  }

  /// Get group messages for a trip
  static Future<List<dynamic>> getGroupMessages(int tripId) async {
    try {
      final response = await _apiService.getDynamic('/chat/trip/$tripId/messages');
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get group messages: $e');
    }
  }

  /// Get group messages since a specific time
  static Future<List<dynamic>> getGroupMessagesSince(int tripId, String since) async {
    try {
      final response = await _apiService.getDynamic('/chat/trip/$tripId/messages/since/$since');
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get group messages since: $e');
    }
  }

  /// Get unread count for group chat
  static Future<int> getGroupUnreadCount(int tripId) async {
    try {
      final response = await _apiService.getDynamic('/chat/trip/$tripId/unread-count');
      if (response is Map<String, dynamic> && response.containsKey('unreadCount')) {
        return response['unreadCount'] as int;
      }
      return response as int;
    } catch (e) {
      throw Exception('Failed to get group unread count: $e');
    }
  }

  /// Mark group messages as read
  static Future<void> markGroupMessagesAsRead(int tripId) async {
    try {
      await _apiService.post('/chat/trip/$tripId/mark-read', {});
    } catch (e) {
      throw Exception('Failed to mark group messages as read: $e');
    }
  }

  /// Get trip chat info
  static Future<Map<String, dynamic>> getTripChatInfo(int tripId) async {
    try {
      final response = await _apiService.getDynamic('/chat/trip/$tripId/info');
      return response;
    } catch (e) {
      throw Exception('Failed to get trip chat info: $e');
    }
  }

  /// Create or get trip chat
  static Future<Map<String, dynamic>> createOrGetTripChat(int tripId) async {
    try {
      final response = await _apiService.post('/chat/trip/$tripId/create', {});
      return response;
    } catch (e) {
      throw Exception('Failed to create or get trip chat: $e');
    }
  }
}
