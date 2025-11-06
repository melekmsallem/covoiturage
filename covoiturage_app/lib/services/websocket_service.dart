import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/status.dart' as status;
import 'api_service.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;

  WebSocketService._internal();

  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  // Get the message stream
  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  // Check if connected
  bool get isConnected => _isConnected;

  // Connect to WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // Get the resolved base URL (works for emulator and real device)
      final baseUrl = kIsWeb ? 'http://localhost:8081' : await ApiService.getResolvedBaseUrl();
      // Convert http to ws
      final wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('/api', '');
      
      print('Connecting to WebSocket: $wsUrl/ws');
      
      // Connect to the WebSocket endpoint
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws'),
      );

      // Listen to messages
      _channel!.stream.listen(
        (message) {
          try {
            print('WebSocket message received: $message');
            // Try to parse as JSON first
            try {
              final data = jsonDecode(message);
              _messageController?.add(data);
            } catch (e) {
              // If not JSON, create a simple map
              final data = {
                'type': 'text',
                'message': message,
                'timestamp': DateTime.now().toIso8601String(),
              };
              _messageController?.add(data);
            }
          } catch (e) {
            print('Error processing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          if (_shouldReconnect) {
            _scheduleReconnect();
          }
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          if (_shouldReconnect) {
            _scheduleReconnect();
          }
        },
      );

      _isConnected = true;
      print('WebSocket connected successfully');
      
      // Send a test message to verify connection
      Future.delayed(const Duration(seconds: 1), () {
        _sendTestMessage();
      });
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    
    _isConnected = false;
    print('WebSocket disconnected');
  }

  // Send a message
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    } else {
      print('WebSocket not connected, cannot send message');
    }
  }

  // Subscribe to a topic
  void subscribe(String topic) {
    sendMessage({
      'type': 'SUBSCRIBE',
      'destination': topic,
    });
  }

  // Unsubscribe from a topic
  void unsubscribe(String topic) {
    sendMessage({
      'type': 'UNSUBSCRIBE',
      'destination': topic,
    });
  }

  // Send a message to a specific destination
  void sendToDestination(String destination, Map<String, dynamic> data) {
    sendMessage({
      'type': 'MESSAGE',
      'destination': destination,
      'body': jsonEncode(data),
    });
  }

  // Send a test message to verify connection
  void _sendTestMessage() {
    if (_isConnected && _channel != null) {
      try {
        final testMessage = 'Hello from Flutter WebSocket Test!';
        _channel!.sink.add(testMessage);
        print('Test message sent to WebSocket: $testMessage');
      } catch (e) {
        print('Error sending test message: $e');
      }
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldReconnect && !_isConnected) {
        print('Attempting to reconnect WebSocket...');
        connect();
      }
    });
  }

  // Dispose resources
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _messageController?.close();
    disconnect();
  }
}

