import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Language constants
const Map<String, String> SUPPORTED_LANGUAGES = {
  'en': 'English',
  'ur': 'Urdu',
  'pa': 'Punjabi',
};

class TestAgentsPage extends StatefulWidget {
  @override
  _TestAgentsPageState createState() => _TestAgentsPageState();
}

class _TestAgentsPageState extends State<TestAgentsPage> {
  bool isCounselorMode = false;
  bool isTyping = false;
  bool isRecording = false;
  String _selectedLanguage = 'en';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;
  Map<String, List<Map<String, String>>> _agentMessages = {
    'friend': [],
    'counselor': [],
  };
  String? userId;
  final String baseUrl = 'https://agents-949030063519.us-central1.run.app';

  @override
  void initState() {
    super.initState();
    _getUserId();
    _requestPermissions();
    _testServerConnection();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

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

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _testServerConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      print('Server connection test successful: ${response.statusCode}');
      print('Connected to server at: $baseUrl');
    } catch (e) {
      print('Server connection test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot connect to server at $baseUrl. Please check if the server is running and the IP address is correct.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      print('Starting recording process...');

      final hasPermission = await _audioRecorder.hasPermission();
      print('Microphone permission status: $hasPermission');

      if (!hasPermission) {
        print('Requesting microphone permission...');
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw Exception('Microphone permission not granted');
        }
      }

      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/audio_message.wav';
      print('Recording path: $_recordingPath');

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      );
      print('Recording config: $config');

      await _audioRecorder.start(config, path: _recordingPath!);
      print('Recording started successfully');

      setState(() {
        isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      print('Stopping recording...');
      final path = await _audioRecorder.stop();
      print('Recording stopped. Path: $path');

      setState(() {
        isRecording = false;
      });

      if (path != null) {
        _recordingPath = path;
        print('Recording saved to: $_recordingPath');

        final file = File(_recordingPath!);
        final exists = await file.exists();
        final size = await file.length();
        print('Recording file exists: $exists');
        print('Recording file size: $size bytes');

        if (exists && size > 0) {
          await _sendVoiceMessage();
        } else {
          throw Exception('Recording file is empty or does not exist');
        }
      } else {
        throw Exception('Failed to save recording');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordingPath == null) {
      print('No recording path available');
      return;
    }

    setState(() {
      isTyping = true;
    });

    try {
      final file = File(_recordingPath!);
      print('Preparing to send voice message...');
      print('Recording file exists: ${await file.exists()}');
      print('Recording file size: ${await file.length()} bytes');
      print('Recording file path: $_recordingPath');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/voice/chat/${isCounselorMode ? 'counselor' : 'friend'}',
        ),
      );

      request.fields['user_id'] = userId ?? '';
      request.fields['language_code'] = _selectedLanguage;

      print('Request URL: ${request.url}');
      print('Request fields: ${request.fields}');

      final audioFile = await http.MultipartFile.fromPath(
        'audio_file',
        file.path,
        contentType: MediaType('audio', 'wav'),
      );
      request.files.add(audioFile);
      print('Added audio file to request: ${audioFile.filename}');

      print('Sending request...');
      final streamedResponse = await request.send();
      print('Response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('Error response body: $errorBody');
        throw Exception(
          'Failed to send voice message: ${streamedResponse.statusCode} - $errorBody',
        );
      }

      final responseData = await streamedResponse.stream.toBytes();
      print('Received response data: ${responseData.length} bytes');

      final directory = await getTemporaryDirectory();
      final responsePath = '${directory.path}/response.mp3';
      await File(responsePath).writeAsBytes(responseData);
      print('Saved response to: $responsePath');

      await _audioPlayer.setFilePath(responsePath);
      await _audioPlayer.play();
      print('Started playing response');

      await file.delete();
      await File(responsePath).delete();
      print('Cleaned up temporary files');
    } catch (e) {
      print('Error sending voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        isTyping = false;
      });
    }
  }

  String get _currentAgent => isCounselorMode ? 'counselor' : 'friend';
  String get apiUrl =>
      "$baseUrl/chat/${isCounselorMode ? 'counselor' : 'friend'}";

  Future<void> _sendMessage() async {
    if (userId == null) {
      setState(() {
        _agentMessages[_currentAgent]!.add({
          "role": "bot",
          "text": "Error: User not authenticated.",
        });
      });
      _scrollToBottom();
      return;
    }

    final String userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _agentMessages[_currentAgent]!.add({"role": "user", "text": userMessage});
      _messageController.clear();
      isTyping = true;
    });
    _scrollToBottom();

    Map<String, dynamic> requestBody = {
      "user_id": userId,
      "message": userMessage,
      "language_code": _selectedLanguage,
    };

    print("📤 Sending Request: $requestBody to $apiUrl");

    try {
      try {
        final testResponse = await http.get(Uri.parse('$baseUrl/'));
        print('Server connection test: ${testResponse.statusCode}');
        if (testResponse.statusCode != 200) {
          throw Exception('Server is not responding correctly');
        }
      } catch (e) {
        print('Server connection test failed: $e');
        throw Exception(
          'Cannot connect to server. Please check if the server is running and the IP address is correct.',
        );
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📥 Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _agentMessages[_currentAgent]!.add({
            "role": "bot",
            "text": responseData["response"],
          });
          isTyping = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _agentMessages[_currentAgent]!.add({
            "role": "bot",
            "text": "Error: Server returned status code ${response.statusCode}",
          });
          isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() {
        _agentMessages[_currentAgent]!.add({
          "role": "bot",
          "text": "Error: $e",
        });
        isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? Color(0xFF002D62) : Colors.white,
        border: Border.all(color: Color(0xFF002D62).withAlpha(50), width: 2),
      ),
      child: Icon(
        isUser
            ? Icons.person
            : (isCounselorMode ? Icons.psychology : Icons.favorite),
        color: isUser ? Colors.white : Color(0xFF002D62),
        size: 24,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(false),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFF002D62).withAlpha(50)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 700),
      curve: Interval(
        index * 0.2,
        (index * 0.2) + 0.5,
        curve: Curves.easeInOut,
      ),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF002D62).withOpacity(0.5 + (0.5 * value)),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${link.url}'),
            backgroundColor: Color(0xFF002D62),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _agentMessages[_currentAgent]!;
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
          // Language Selector
          Container(
            margin: EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              items:
                  SUPPORTED_LANGUAGES.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: GoogleFonts.poppins(
                          color: Color(0xFF002D62),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
              style: GoogleFonts.poppins(
                color: Color(0xFF002D62),
                fontSize: 14,
              ),
              underline: Container(),
              icon: Icon(Icons.language, color: Color(0xFF002D62)),
            ),
          ),
          // Mode Toggle Switch
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Switch(
              value: isCounselorMode,
              onChanged: (value) {
                setState(() {
                  isCounselorMode = value;
                });
                _scrollToBottom();
              },
              activeColor: Color(0xFF002D62),
              activeTrackColor: Color(0xFF002D62).withAlpha(100),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == messages.length) {
                  return _buildTypingIndicator();
                }
                final message = messages[index];
                final isUser = message["role"] == "user";

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment:
                        isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) _buildAvatar(false),
                      SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(12),
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SelectableLinkify(
                            text: message["text"]!,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Color(0xFF002D62),
                            ),
                            linkStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Color(0xFF002D62),
                              decoration: TextDecoration.underline,
                            ),
                            onOpen: _onOpen,
                            options: LinkifyOptions(humanize: false),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (isUser) _buildAvatar(true),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording ? Colors.red : Color(0xFF002D62),
                    boxShadow: [
                      BoxShadow(
                        color: (isRecording ? Colors.red : Color(0xFF002D62))
                            .withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: isRecording ? _stopRecording : _startRecording,
                    iconSize: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.poppins(
                      color: Color(0xFF002D62),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: GoogleFonts.poppins(
                        color: Color(0xFF002D62).withAlpha(120),
                        fontSize: 16,
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF002D62),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF002D62).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 28),
                    onPressed: _sendMessage,
                    iconSize: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
