import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileInformationPage extends StatefulWidget {
  @override
  _ProfileInformationPageState createState() => _ProfileInformationPageState();
}

class _ProfileInformationPageState extends State<ProfileInformationPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalJournals': 0,
    'lastJournalDate': null,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get journal count
      final journalsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journals')
          .get();

      // Get last journal date
      DateTime? lastJournalDate;
      if (journalsSnapshot.docs.isNotEmpty) {
        final lastJournal = journalsSnapshot.docs
            .reduce((a, b) => (a.data()['timestamp'] as Timestamp)
                .toDate()
                .isAfter((b.data()['timestamp'] as Timestamp).toDate())
                ? a
                : b);
        lastJournalDate = (lastJournal.data()['timestamp'] as Timestamp).toDate();
      }

      setState(() {
        _stats = {
          'totalJournals': journalsSnapshot.docs.length,
          'lastJournalDate': lastJournalDate,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF002D62)),
        title: Text(
          'Profile Information',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF002D62)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF002D62).withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF002D62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Account Email',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF002D62),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _auth.currentUser?.email ?? 'Not signed in',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF002D62),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Activity Statistics',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF002D62),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildStatCard(
                    icon: Icons.book,
                    title: 'Total Journal Entries',
                    value: _stats['totalJournals'].toString(),
                    subtitle: _stats['lastJournalDate'] != null
                        ? 'Last entry: ${_formatDate(_stats['lastJournalDate'])}'
                        : 'No entries yet',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF002D62).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF002D62).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF002D62),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF002D62),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF002D62),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF002D62).withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 