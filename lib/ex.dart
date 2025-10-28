import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool isCounselorMode = false; // Default: Friend mode
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _messages = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _getUserId(); // Fetch user ID when page loads
  }

  // Get current Firebase authenticated user's ID
  Future<void> _getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    } else {
      print("❌ Error: No authenticated user found.");
    }
  }

  // Get API endpoint based on mode
  String get apiUrl =>
      "http://10.0.2.2:8000/chat/${isCounselorMode ? 'counselor' : 'friend'}";

  // Send message to FastAPI server
  void _sendMessage() async {
    if (userId == null) {
      print("❌ Error: User ID is null");
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "Error: User not authenticated.",
        });
      });
      return;
    }

    final String userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": userMessage});
      _messageController.clear();
    });

    // Prepare API request
    Map<String, dynamic> requestBody = {
      "user_id": userId,
      "message": userMessage,
    };

    print("📤 Sending Request: $requestBody to $apiUrl");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📥 Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _messages.add({"role": "bot", "text": responseData["response"]});
        });
      } else if (response.statusCode == 307) {
        print("🔄 Redirect detected! Retrying with new URL...");
        final newUrl = response.headers['location']; // Get the redirected URL

        if (newUrl != null) {
          final retryResponse = await http.post(
            Uri.parse(newUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          );

          if (retryResponse.statusCode == 200) {
            final responseData = jsonDecode(retryResponse.body);
            setState(() {
              _messages.add({"role": "bot", "text": responseData["response"]});
            });
          } else {
            setState(() {
              _messages.add({
                "role": "bot",
                "text": "Error: Could not fetch response after redirect.",
              });
            });
          }
        } else {
          setState(() {
            _messages.add({
              "role": "bot",
              "text": "Error: No redirect location found.",
            });
          });
        }
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "text": "Error: Could not fetch response.",
          });
        });
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() {
        _messages.add({"role": "bot", "text": "Error: $e"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isCounselorMode ? 'Counselor Mode' : 'Friend Mode'),
        actions: [
          Switch(
            value: isCounselorMode,
            onChanged: (value) {
              setState(() {
                isCounselorMode = value;
              });
            },
          ),
        ],
        backgroundColor: Colors.blue[900],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
