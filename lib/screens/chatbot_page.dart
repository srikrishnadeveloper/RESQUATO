import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // Required for HapticFeedback

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // Add timestamp to messages
  // TODO: Load API key from environment variables or secure storage
  final String _apiKey = const String.fromEnvironment('GOOGLE_API_KEY', defaultValue: '');
  final String _model =
      'gemini-1.5-flash'; // You can change to gemini-2.0-pro if you enable that
  Future<void> _sendMessage(String message) async {
    // Check if API key is available
    if (_apiKey.isEmpty) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': '❌ API key not configured. Please contact the app administrator.',
          'timestamp': DateTime.now(),
        });
      });
      return;
    }

    final timestamp = DateTime.now();
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': message,
        'timestamp': timestamp,
      });
    });

    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    // System instruction to guide Gemini's response toward vehicle-related help
    final systemPrompt =
        'You are ResQAuto AI Support, a helpful assistant that only provides solutions for vehicle-related issues. '
        'Always prioritize understanding the user\'s vehicle problem, and provide mechanical or service guidance. '
        'Keep answers practical and friendly. Never answer non-vehicle questions.';

    final requestPayload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemPrompt\n\nUser query: $message'},
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestPayload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final botText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            '🤖 No response from ResQAuto.';
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': botText,
            'timestamp': DateTime.now(),
          });
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text':
                '❌ Error: ${response.statusCode} - ${response.reasonPhrase}',
            'timestamp': DateTime.now(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': '⚠️ Exception occurred: $e',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Initial greeting
    _messages.add({
      'sender': 'bot',
      'text':
          '🔧 Hello! I\'m **ResQAuto AI Support**. How can I assist you with your vehicle problems today?',
      'timestamp': DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ResQAuto Support'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                final timestamp =
                    message['timestamp'] is DateTime
                        ? message['timestamp'] as DateTime
                        : DateTime.now(); // Fallback to current time if null
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft:
                            isUser
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                        bottomRight:
                            isUser
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question about your car...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final msg = _messageController.text.trim();
                    if (msg.isNotEmpty) {
                      HapticFeedback.heavyImpact(); // Use heavy haptic feedback
                      _sendMessage(msg);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
