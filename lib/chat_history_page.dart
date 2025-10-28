import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatHistoryPage extends StatefulWidget {
  @override
  _ChatHistoryPageState createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _chatSessions = [];
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .orderBy('start_time', descending: true)
          .get();

      _chatSessions = sessionsSnapshot.docs.map((doc) {
        final data = doc.data();
        final startTime = data['start_time'];
        final endTime = data['end_time'];
        final messages = data['messages'] as List<dynamic>? ?? [];
        
        // Convert messages to the correct format
        final formattedMessages = messages.map((msg) {
          if (msg is Map) {
            return {
              'role': msg['role']?.toString() ?? 'unknown',
              'text': msg['text']?.toString() ?? '',
            };
          }
          return {'role': 'unknown', 'text': ''};
        }).toList();

        return {
          'id': doc.id,
          'agent': data['agent'] ?? 'Unknown',
          'start_time': startTime is Timestamp ? startTime.toDate() : DateTime.now(),
          'end_time': endTime is Timestamp ? endTime.toDate() : null,
          'message_count': formattedMessages.length,
          'messages': formattedMessages,
        };
      }).toList();

    } catch (e) {
      print('Error loading chat sessions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredSessions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(Duration(days: 7));
    final monthAgo = today.subtract(Duration(days: 30));

    switch (_selectedCategory) {
      case 'Today':
        return _chatSessions.where((session) {
          final startTime = session['start_time'] as DateTime;
          return startTime.isAfter(today);
        }).toList();
      case 'This Week':
        return _chatSessions.where((session) {
          final startTime = session['start_time'] as DateTime;
          return startTime.isAfter(weekAgo);
        }).toList();
      case 'This Month':
        return _chatSessions.where((session) {
          final startTime = session['start_time'] as DateTime;
          return startTime.isAfter(monthAgo);
        }).toList();
      default:
        return _chatSessions;
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chat session deleted',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Color(0xFF002D62),
        ),
      );

      _loadChatSessions(); // Reload the list
    } catch (e) {
      print('Error deleting chat session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete chat session',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewChatSession(Map<String, dynamic> session) {
    final messages = (session['messages'] as List).map((msg) {
      return {
        'role': msg['role'] as String,
        'text': msg['text'] as String,
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatViewPage(
          sessionId: session['id'],
          agent: session['agent'],
          startTime: session['start_time'],
          messages: messages,
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final startTime = session['start_time'] as DateTime;
    final endTime = session['end_time'] as DateTime?;
    final duration = endTime != null 
        ? endTime.difference(startTime)
        : DateTime.now().difference(startTime);

    return Card(
      elevation: 0,
      color: Color(0xFF002D62).withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewChatSession(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['agent'],
                          style: GoogleFonts.poppins(
                            color: Color(0xFF002D62),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, y • h:mm a').format(startTime),
                          style: GoogleFonts.poppins(
                            color: Color(0xFF002D62).withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(session['id']),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Color(0xFF002D62).withOpacity(0.7),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${session['message_count']} messages',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF002D62).withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Color(0xFF002D62).withOpacity(0.7),
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDuration(duration),
                    style: GoogleFonts.poppins(
                      color: Color(0xFF002D62).withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _showDeleteConfirmation(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Chat Session',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this chat session? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Color(0xFF002D62).withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(sessionId);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSessions = _getFilteredSessions();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Chat History',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: _selectedCategory == category
                              ? Colors.white
                              : Color(0xFF002D62),
                          fontSize: 14,
                        ),
                      ),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: Color(0xFF002D62),
                      backgroundColor: Color(0xFF002D62).withAlpha(50),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            // Chat Sessions List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF002D62),
                      ),
                    )
                  : filteredSessions.isEmpty
                      ? Center(
                          child: Text(
                            'No chat sessions found',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF002D62).withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredSessions.length,
                          itemBuilder: (context, index) {
                            return _buildSessionCard(filteredSessions[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatViewPage extends StatelessWidget {
  final String sessionId;
  final String agent;
  final DateTime startTime;
  final List<Map<String, String>> messages;

  const ChatViewPage({
    Key? key,
    required this.sessionId,
    required this.agent,
    required this.startTime,
    required this.messages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF002D62)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agent,
              style: GoogleFonts.poppins(
                color: Color(0xFF002D62),
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              DateFormat('MMM d, y • h:mm a').format(startTime),
              style: GoogleFonts.poppins(
                color: Color(0xFF002D62).withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isUser = message['role'] == 'user';

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: isUser
                    ? Color(0xFF002D62).withAlpha(50)
                    : Colors.white,
                border: isUser
                    ? null
                    : Border.all(
                        color: Color(0xFF002D62).withAlpha(50),
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message['text']!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(0xFF002D62),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 