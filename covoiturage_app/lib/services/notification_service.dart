import 'api_service.dart';
import 'websocket_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;

  // Get all notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final List<dynamic> notifications = await _apiService.getNotifications();
      return notifications.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      return await _apiService.markNotificationAsRead(notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      return await _apiService.markAllNotificationsAsRead();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Connect to real-time notifications
  void connectToRealTimeNotifications() {
    _webSocketService.connect();
    _webSocketService.subscribe('/topic/notifications');
  }

  // Disconnect from real-time notifications
  void disconnectFromRealTimeNotifications() {
    _webSocketService.unsubscribe('/topic/notifications');
    _webSocketService.disconnect();
  }

  // Get real-time notification stream
  Stream<Map<String, dynamic>> get realTimeNotificationStream {
    return _webSocketService.messageStream.where((message) {
      return message['type'] == 'NOTIFICATION' || 
             message['destination']?.contains('/notifications') == true;
    });
  }

  // Send a test notification (for development)
  void sendTestNotification() {
    _webSocketService.sendToDestination('/app/notifications', {
      'type': 'TEST_NOTIFICATION',
      'message': 'This is a test notification from Flutter app',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

