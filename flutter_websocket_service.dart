import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static WebSocketChannel? _channel;
  static StreamController<Map<String, dynamic>>? _messageController;
  static StreamController<String>? _connectionController;
  
  // Connection status
  static bool get isConnected => _channel != null;
  
  // Message stream
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageController?.stream ?? Stream.empty();
  
  // Connection status stream
  static Stream<String> get connectionStream =>
      _connectionController?.stream ?? Stream.empty();

  // Connect to WebSocket
  static Future<void> connect() async {
    try {
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      _connectionController = StreamController<String>.broadcast();
      
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8081/ws'));
      
      _connectionController!.add('connecting');
      
      // Listen to messages
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            _messageController!.add(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _connectionController!.add('error');
        },
        onDone: () {
          print('WebSocket connection closed');
          _connectionController!.add('disconnected');
        },
      );
      
      _connectionController!.add('connected');
      
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _connectionController!.add('error');
    }
  }

  // Disconnect from WebSocket
  static Future<void> disconnect() async {
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    await _messageController?.close();
    await _connectionController?.close();
    _messageController = null;
    _connectionController = null;
  }

  // Send message
  static void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    } else {
      print('WebSocket not connected');
    }
  }

  // Subscribe to public messages
  static void subscribeToPublicMessages() {
    sendMessage({
      'type': 'SUBSCRIBE',
      'destination': '/topic/public',
    });
  }

  // Subscribe to user-specific notifications
  static void subscribeToNotifications(String userId) {
    sendMessage({
      'type': 'SUBSCRIBE',
      'destination': '/user/$userId/queue/notifications',
    });
  }

  // Subscribe to trip updates
  static void subscribeToTripUpdates() {
    sendMessage({
      'type': 'SUBSCRIBE',
      'destination': '/topic/trip-updates',
    });
  }

  // Subscribe to booking updates
  static void subscribeToBookingUpdates() {
    sendMessage({
      'type': 'SUBSCRIBE',
      'destination': '/topic/booking-updates',
    });
  }

  // Send chat message
  static void sendChatMessage({
    required String sender,
    required String content,
    String type = 'CHAT',
  }) {
    sendMessage({
      'type': 'CHAT',
      'sender': sender,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send trip update
  static void sendTripUpdate({
    required int tripId,
    required String updateType,
    required String message,
    Map<String, dynamic>? data,
  }) {
    sendMessage({
      'type': 'TRIP_UPDATE',
      'tripId': tripId,
      'updateType': updateType,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send booking update
  static void sendBookingUpdate({
    required int bookingId,
    required int tripId,
    required String updateType,
    required String message,
    Map<String, dynamic>? data,
  }) {
    sendMessage({
      'type': 'BOOKING_UPDATE',
      'bookingId': bookingId,
      'tripId': tripId,
      'updateType': updateType,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Listen to specific message types
  static Stream<Map<String, dynamic>> listenToMessageType(String messageType) {
    return messageStream.where((message) => message['type'] == messageType);
  }

  // Listen to trip notifications
  static Stream<Map<String, dynamic>> listenToTripNotifications() {
    return messageStream.where((message) => 
        message['type'] == 'TRIP_UPDATE' || 
        message['type'] == 'TRIP_CREATED' ||
        message['type'] == 'TRIP_CANCELLED');
  }

  // Listen to booking notifications
  static Stream<Map<String, dynamic>> listenToBookingNotifications() {
    return messageStream.where((message) => 
        message['type'] == 'BOOKING_UPDATE' || 
        message['type'] == 'BOOKING_CREATED' ||
        message['type'] == 'BOOKING_CONFIRMED' ||
        message['type'] == 'BOOKING_CANCELLED');
  }

  // Listen to payment notifications
  static Stream<Map<String, dynamic>> listenToPaymentNotifications() {
    return messageStream.where((message) => 
        message['type'] == 'PAYMENT_UPDATE' || 
        message['type'] == 'PAYMENT_COMPLETED' ||
        message['type'] == 'PAYMENT_FAILED');
  }

  // Listen to rating notifications
  static Stream<Map<String, dynamic>> listenToRatingNotifications() {
    return messageStream.where((message) => 
        message['type'] == 'RATING_RECEIVED');
  }

  // Cleanup
  static void dispose() {
    disconnect();
  }
}


