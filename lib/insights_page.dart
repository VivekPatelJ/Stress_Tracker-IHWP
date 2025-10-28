import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class InsightsPage extends StatefulWidget {
  @override
  _InsightsPageState createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, int> _moodDistribution = {};
  int _totalJournalEntries = 0;
  int _totalChatSessions = 0;
  int _completedChallenges = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Load mood distribution
      final moodSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moodHistory')
          .get();

      Map<String, int> moodCount = {};
      for (var doc in moodSnapshot.docs) {
        final mood = doc['mood'] as String;
        moodCount[mood] = (moodCount[mood] ?? 0) + 1;
      }
      _moodDistribution = moodCount;

      // Load journal entries count
      final journalSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journals')
          .count()
          .get();
      _totalJournalEntries = journalSnapshot.count ?? 0;

      // Load chat sessions count
      final chatSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .count()
          .get();
      _totalChatSessions = chatSnapshot.count ?? 0;

      // Load completed challenges count
      final challengesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedChallenges')
          .count()
          .get();
      _completedChallenges = challengesSnapshot.count ?? 0;

    } catch (e) {
      print('Error loading insights data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMoodChart() {
    if (_moodDistribution.isEmpty) {
      return Center(
        child: Text(
          'No mood data available',
          style: GoogleFonts.poppins(color: Color(0xFF002D62)),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: _moodDistribution.entries.map((entry) {
          final color = _getMoodColor(entry.key);
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.key}\n${entry.value}',
            color: color,
            radius: 100,
            titleStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.pinkAccent;
      case 'calm':
        return Colors.blueAccent;
      case 'manic':
        return Colors.green;
      case 'angry':
        return Colors.orange;
      case 'sad':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Color(0xFF002D62), size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Color(0xFF002D62),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                color: Color(0xFF002D62),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Insights',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF002D62)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood Distribution',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF002D62),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 300,
                      child: _buildMoodChart(),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Activity Overview',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF002D62),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          'Journal Entries',
                          _totalJournalEntries,
                          Icons.book,
                        ),
                        _buildStatCard(
                          'Chat Sessions',
                          _totalChatSessions,
                          Icons.chat,
                        ),
                        _buildStatCard(
                          'Completed Challenges',
                          _completedChallenges,
                          Icons.emoji_events,
                        ),
                        _buildStatCard(
                          'Total Mood Logs',
                          _moodDistribution.values.fold(0, (a, b) => a + b),
                          Icons.mood,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 