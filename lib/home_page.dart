import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/login_page.dart';
import 'test_agents.dart';
import 'journals_page.dart';
import 'feed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/settings_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String userName = "Jim"; // User name
  bool _isMoodSelected = false; // Flag for mood selection
  double _chatMargin = 20.0; // Margin for chat section
  double _opacity = 1.0; // Opacity for fade effect

  // List of moods
  final List<Map<String, dynamic>> moods = [
    {
      'icon': Icons.sentiment_satisfied,
      'label': 'Happy',
      'color': Colors.pinkAccent,
    },
    {'icon': Icons.nights_stay, 'label': 'Calm', 'color': Colors.blueAccent},
    {'icon': Icons.emoji_nature, 'label': 'Manic', 'color': Colors.green},
    {'icon': Icons.mood_bad, 'label': 'Angry', 'color': Colors.orange},
    {
      'icon': Icons.sentiment_very_dissatisfied,
      'label': 'Sad',
      'color': Colors.yellow,
    },
  ];

  int _selectedMoodIndex = -1; // To track the selected mood index
  List<String> _challenges = [];
  Set<String> _completedChallenges = Set();
  bool _loadingChallenges = true;

  Future<void> _fetchChallenges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingChallenges = false;
        _challenges = [];
      });
      return;
    }

    try {
      // First try to get challenges from Firestore
      var snapshot =
          await FirebaseFirestore.instance
              .collection('challenges')
              .doc('FqJ4cb1I1mukBHaD0ZyN')
              .get();

      List<String> allChallenges = [];

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        allChallenges =
            data.values
                .where((value) => value != null && value.toString().isNotEmpty)
                .map((e) => e.toString())
                .toList();
      }

      // If no challenges found, use default challenges
      if (allChallenges.isEmpty) {
        allChallenges = [
          "Take a 10-minute walk outside",
          "Practice deep breathing for 5 minutes",
          "Write down three things you're grateful for",
          "Call a friend or family member",
          "Do something creative for 15 minutes",
        ];
      }

      // Shuffle and take first 5 challenges
      allChallenges.shuffle();
      allChallenges = allChallenges.take(5).toList();

      // Get completed challenges
      var completedSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('completedChallenges')
              .get();

      setState(() {
        _challenges = allChallenges;
        _completedChallenges =
            completedSnapshot.docs.map((doc) => doc.id).toSet();
        _loadingChallenges = false;
      });
    } catch (e) {
      print('Error fetching challenges: $e');
      // Set default challenges in case of error
      setState(() {
        _challenges = [
          "Take a 10-minute walk outside",
          "Practice deep breathing for 5 minutes",
          "Write down three things you're grateful for",
          "Call a friend or family member",
          "Do something creative for 15 minutes",
        ];
        _loadingChallenges = false;
      });
    }
  }

  Future<void> _toggleChallengeComplete(String challenge) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    var ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('completedChallenges')
        .doc(challenge);
    if (_completedChallenges.contains(challenge)) {
      await ref.delete();
      setState(() {
        _completedChallenges.remove(challenge);
      });
    } else {
      await ref.set({'completedAt': DateTime.now().toIso8601String()});
      setState(() {
        _completedChallenges.add(challenge);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkMoodForToday();
    _fetchChallenges();
    // Add listener for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchChallenges(); // Refresh challenges when user logs in
      }
    });
  }

  Future<void> _checkMoodForToday() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String today = DateTime.now().toIso8601String().split("T")[0];
    DocumentReference moodDocRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moodHistory")
        .doc(today);
    var moodDoc = await moodDocRef.get();
    if (moodDoc.exists) {
      String mood = moodDoc["mood"];
      int index = moods.indexWhere((m) => m['label'] == mood);
      if (index != -1) {
        setState(() {
          _selectedMoodIndex = index;
          _isMoodSelected = true;
        });
      }
    }
  }

  // Hide mood selection after a tap
  void _onMoodSelected(int index) async {
    if (_isMoodSelected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Mood already selected today.")));
      return;
    }

    // Optimistically update UI
    setState(() {
      _selectedMoodIndex = index;
      _isMoodSelected = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String today = DateTime.now().toIso8601String().split("T")[0]; // YYYY-MM-DD
    String mood = moods[index]['label'];
    String keyword = mood.toLowerCase(); // Use mood as a keyword for now

    DocumentReference moodDocRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moodHistory")
        .doc(today);

    // Check if mood is already selected for today
    var moodDoc = await moodDocRef.get();
    if (moodDoc.exists) {
      // Revert UI
      setState(() {
        _isMoodSelected = true;
        _selectedMoodIndex = moods.indexWhere(
          (m) => m['label'] == moodDoc["mood"],
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Mood already selected today.")));
      return;
    }

    // Save mood selection
    try {
      await moodDocRef.set({
        "mood": mood,
        "keyword": keyword,
        "timestamp": DateTime.now().toIso8601String(),
      });
      print("Mood saved successfully.");
    } catch (e) {
      // Revert UI on error
      setState(() {
        _selectedMoodIndex = -1;
        _isMoodSelected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save mood. Please try again.")),
      );
    }
  }

  // Logout method
  void _logOut() async {
    await FirebaseAuth.instance.signOut();
    // Redirect to login page after log out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Navigate to pages
  void _navigateToChatPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestAgentsPage(),
      ), // Navigate to ChatPage
    );
  }

  void _navigateToJournalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalsPage(),
      ), // Navigate to JournalPage
    );
  }

  void _navigateToLibraryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Feed(),
      ), // Navigate to LibraryPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Text(
                      'Welcome Back !',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 0,
                          right: 0,
                          top: 32,
                          bottom: 18,
                        ), // Customizable padding
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage(),
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 0,
                          right: 0,
                          top: 37.7,
                          bottom: 22,
                        ), // Customizable padding
                        child: IconButton(
                          icon: Icon(
                            Icons.exit_to_app,
                            color: Colors.black,
                            size: 26,
                          ),
                          onPressed: _logOut,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              // "How are you feeling today?" mini heading
              Padding(
                padding: EdgeInsets.only(
                  top: 0,
                ), // Margin between greeting and mini heading
                child:
                    !_isMoodSelected
                        ? Text(
                          'How are you feeling today?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        )
                        : SizedBox(),
              ),
              SizedBox(height: 10),

              // Mood Tracker Section with hover effect
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    moods.map((mood) {
                      int index = moods.indexOf(mood);
                      return GestureDetector(
                        onTap:
                            () =>
                                _onMoodSelected(index), // Call updated function
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: mood['color'].withOpacity(0.2),
                              child: Icon(
                                mood['icon'],
                                color:
                                    _selectedMoodIndex == index
                                        ? mood['color']
                                        : Colors.black,
                                size: 30,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              mood['label'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
              SizedBox(height: 20),

              // Chat Now Section
              GestureDetector(
                onTap: _navigateToChatPage, // Navigate to Chat Now page
                child: Container(
                  margin: EdgeInsets.only(top: _chatMargin),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    color: Color(0xFF002D62).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage('assets/images/back.png'),
                      fit: BoxFit.cover,
                      opacity: 0.9,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Let's open up to the things that matter",
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF002D62),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "the most",
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF002D62),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Chat Now ',
                              style: GoogleFonts.poppins(
                                color: Color(0xFF002D62),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Journal & Library Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF002D62),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _navigateToJournalPage, // Navigate to JournalPage
                      icon: Icon(Icons.book, color: Colors.white),
                      label: Text(
                        'Journal',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF002D62),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _navigateToLibraryPage, // Navigate to LibraryPage
                      icon: Icon(Icons.library_books, color: Colors.white),
                      label: Text(
                        'Library',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Quotes Section
              _loadingChallenges
                  ? Center(child: CircularProgressIndicator())
                  : _challenges.isEmpty
                  ? Center(child: Text('No challenges available.'))
                  : Column(
                    children:
                        _challenges
                            .map(
                              (challenge) => ChallengeCard(
                                challenge: challenge,
                                completed: _completedChallenges.contains(
                                  challenge,
                                ),
                                onToggle:
                                    () => _toggleChallengeComplete(challenge),
                              ),
                            )
                            .toList(),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final String challenge;
  final bool completed;
  final VoidCallback onToggle;

  ChallengeCard({
    required this.challenge,
    required this.completed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF002D62).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              challenge,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002D62),
              ),
            ),
          ),
          GestureDetector(
            onTap: completed ? null : onToggle,
            child: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? Color(0xFF002D62) : Colors.grey,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
