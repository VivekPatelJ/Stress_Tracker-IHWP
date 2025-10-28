import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secrets.dart'; // Import API key
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool isCounselorMode = false; // Default: Friend mode
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _messages = [];

  void _sendMessage() async {
    final String userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": userMessage});
      _messageController.clear();
    });

    // **Set System Instruction Based on Mode**
    String systemInstruction =
        isCounselorMode
            ? "You are a professional mental health counselor. Provide direct and informative responses."
            : "You are a friendly, compassionate AI companion.";

    // Prepare OpenAI API request
    final Uri apiUrl = Uri.parse("https://api.openai.com/v1/chat/completions");

    Map<String, dynamic> requestBody = {
      "model": "gpt-4o",
      "messages": [
        {"role": "system", "content": systemInstruction},
        {"role": "user", "content": userMessage},
      ],
    };

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _messages.add({
            "role": "bot",
            "text": responseData["choices"][0]["message"]["content"],
          });
        });
      } else {
        setState(() {
          _messages.add({"role": "bot", "text": "Error: ${response.body}"});
        });
      }
    } catch (e) {
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
        title: Text(
          isCounselorMode ? 'Counselor Mode' : 'Friend Mode',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Row(
            children: [
              Text("", style: GoogleFonts.poppins(color: Color(0xFF002D62))),
              Switch(
                value: isCounselorMode,
                onChanged: (value) {
                  setState(() {
                    isCounselorMode = value;
                  });
                },
                activeColor: Color(0xFF002D62),
                activeTrackColor: Color(0xFF002D62).withAlpha(100),
              ),
              Text("", style: GoogleFonts.poppins(color: Color(0xFF002D62))),
            ],
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
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
                      color:
                          isUser
                              ? Color(0xFF002D62).withAlpha(50)
                              : Colors.white,
                      border:
                          isUser
                              ? null
                              : Border.all(
                                color: Color(0xFF002D62).withAlpha(50),
                              ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["text"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Color(0xFF002D62),
                      ),
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
                    style: GoogleFonts.poppins(color: Color(0xFF002D62)),
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: GoogleFonts.poppins(
                        color: Color(0xFF002D62).withAlpha(120),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Color(0xFF002D62).withAlpha(50),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Color(0xFF002D62).withAlpha(50),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Color(0xFF002D62)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF002D62)),
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
