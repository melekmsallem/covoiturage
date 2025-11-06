import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/group_chat_service.dart';
import '../../services/websocket_service.dart';
import 'dart:async';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Map<String, dynamic>? currentUser;

  const GroupChatScreen({
    super.key,
    required this.trip,
    this.currentUser,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  StreamSubscription? _websocketSubscription;
  bool _isWebSocketConnected = false;
  Map<String, dynamic>? _tripChatInfo;
  List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _setupWebSocket();
    _loadTripChatInfo();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _websocketSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocket() {
    try {
      // Connect to WebSocket
      WebSocketService.instance.connect();
      
      // Listen to WebSocket messages
      _websocketSubscription = WebSocketService.instance.messageStream.listen(
        (message) {
          print('WebSocket message received in group chat: $message');
          
          // Check if this message is for this trip
          if (message['tripId'] == widget.trip['id']) {
            _handleWebSocketMessage(message);
          }
        },
        onError: (error) {
          print('WebSocket error in group chat: $error');
          setState(() {
            _isWebSocketConnected = false;
          });
        },
      );
      
      setState(() {
        _isWebSocketConnected = WebSocketService.instance.isConnected;
      });
      
      // Subscribe to group chat topic for this trip
      WebSocketService.instance.subscribe('/topic/group-chat/${widget.trip['id']}');
      
    } catch (e) {
      print('Failed to setup WebSocket: $e');
      setState(() {
        _isWebSocketConnected = false;
      });
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (message['type'] == 'NEW_GROUP_MESSAGE') {
      setState(() {
        _messages.add(Map<String, dynamic>.from(message['data']));
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadTripChatInfo() async {
    try {
      final info = await GroupChatService.getTripChatInfo(widget.trip['id']);
      setState(() {
        _tripChatInfo = info;
        _participants = List<Map<String, dynamic>>.from(info['participants'] ?? []);
      });
    } catch (e) {
      print('Failed to load trip chat info: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await GroupChatService.getGroupMessages(widget.trip['id']);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(messages);
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      await GroupChatService.sendGroupMessage(
        tripId: widget.trip['id'],
        message: message,
      );
      
      // Also send via WebSocket for real-time delivery
      if (_isWebSocketConnected) {
        WebSocketService.instance.sendToDestination(
          '/app/group-chat/${widget.trip['id']}/send',
          {
            'tripId': widget.trip['id'],
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _callUser(Map<String, dynamic> user) async {
    final phoneNumber = user['phoneNumber'] as String?;
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
              _tripChatInfo?['tripRoute'] ?? 'Group Chat',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_participants.length} participants',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
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
          // Participants button
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _showParticipantsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Participants info bar
          if (_participants.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver + ${_participants.where((p) => p['userType'] == 'PASSENGER').length} passengers',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.\nStart the conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['senderId'] == widget.currentUser?['id'];
                          final senderType = message['senderType'] as String?;
                          
                          return _buildMessageBubble(message, isMe, senderType);
                        },
                      ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isSending ? Colors.grey : Colors.blue,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe, String? senderType) {
    final senderName = message['senderName'] as String? ?? 'Unknown';
    final messageText = message['message'] as String? ?? '';
    final timestamp = message['timestamp'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: senderType == 'DRIVER' ? Colors.blue : Colors.green,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: senderType == 'DRIVER' ? Colors.blue : Colors.green,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    messageText,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                widget.currentUser?['firstName']?[0]?.toUpperCase() ?? 'M',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trip Participants'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _participants.length,
            itemBuilder: (context, index) {
              final participant = _participants[index];
              final isDriver = participant['userType'] == 'DRIVER';
              final name = '${participant['firstName']} ${participant['lastName']}';
              final phoneNumber = participant['phoneNumber'] as String?;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDriver ? Colors.blue : Colors.green,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(name),
                subtitle: Text(isDriver ? 'Driver' : 'Passenger'),
                trailing: phoneNumber != null && phoneNumber.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _callUser(participant);
                        },
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}









