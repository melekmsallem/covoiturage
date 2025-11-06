import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> trip;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.booking,
    required this.trip,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _unreadCount = 0;
  String? _errorMessage;
  
  // WebSocket
  StreamSubscription<Map<String, dynamic>>? _websocketSubscription;
  bool _isWebSocketConnected = false;

  @override
  void initState() {
    super.initState();
    
    _loadMessages();
    _loadUnreadCount();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _websocketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await ChatService.getMessages(widget.booking['id']);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Mark messages as read
      await ChatService.markMessagesAsRead(widget.booking['id']);
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ChatService.getUnreadCount(widget.booking['id']);
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      // Ignore unread count errors
    }
  }

  // Setup WebSocket connection for real-time chat
  void _setupWebSocket() {
    try {
      // Connect to WebSocket
      WebSocketService.instance.connect();
      
      // Listen to WebSocket messages
      _websocketSubscription = WebSocketService.instance.messageStream.listen(
        (message) {
          print('WebSocket message received in chat: $message');
          
          // Check if this message is for this booking
          if (message['bookingId'] == widget.booking['id']) {
            _handleWebSocketMessage(message);
          }
        },
        onError: (error) {
          print('WebSocket error in chat: $error');
          setState(() {
            _isWebSocketConnected = false;
          });
        },
      );
      
      setState(() {
        _isWebSocketConnected = WebSocketService.instance.isConnected;
      });
      
      // Subscribe to chat topic for this booking
      WebSocketService.instance.subscribe('/topic/chat/${widget.booking['id']}');
      
    } catch (e) {
      print('Failed to setup WebSocket: $e');
      setState(() {
        _isWebSocketConnected = false;
      });
    }
  }

  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (message['type'] == 'NEW_MESSAGE') {
      // Add new message to the list
      setState(() {
        _messages.add(message['data']);
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      // Update unread count
      _loadUnreadCount();
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Send via HTTP API
      await ChatService.sendMessage(
        bookingId: widget.booking['id'],
        message: message,
      );
      
      // Also send via WebSocket for real-time delivery
      if (_isWebSocketConnected) {
        WebSocketService.instance.sendToDestination(
          '/app/chat/${widget.booking['id']}/send',
          {
            'bookingId': widget.booking['id'],
            'message': message,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      _messageController.clear();
      
      // Reload messages to get the latest from server
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _callUser() async {
    final phoneNumber = widget.otherUser['phoneNumber'] as String?;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create tel: URL
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhoneNumber);
      
      // Check if device can make phone calls
      if (await canLaunchUrl(phoneUri)) {
        // Launch phone app directly
        await launchUrl(phoneUri);
      } else {
        // Fallback: copy to clipboard and show dialog
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Call User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Phone number copied to clipboard: $phoneNumber'),
                const SizedBox(height: 16),
                const Text(
                  'Unable to launch phone app. You can call this number manually.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.otherUser['firstName'] ?? ''} ${widget.otherUser['lastName'] ?? ''}'.trim().isEmpty 
                ? 'Unknown User' 
                : '${widget.otherUser['firstName'] ?? ''} ${widget.otherUser['lastName'] ?? ''}'.trim(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.otherUser['phoneNumber'] ?? 'No phone',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // WebSocket connection indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              _isWebSocketConnected ? Icons.wifi : Icons.wifi_off,
              color: _isWebSocketConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _callUser,
            tooltip: 'Call User',
          ),
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Trip info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.trip['departureCity'] ?? 'Unknown'} → ${widget.trip['arrivalCity'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        _formatDateTime(widget.trip['departureTime']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Messages area
          Expanded(
            child: _buildMessagesArea(),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Start a conversation!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['senderId'] == _getCurrentUserId();
    final timestamp = DateTime.parse(message['timestamp']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                message['senderFirstName']?.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                'Me',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentUserId() {
    // This should be replaced with actual current user ID from auth service
    // For now, we'll use a placeholder
    return 1; // This should come from your auth service
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}


