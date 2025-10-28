import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MiniHabitsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get userId => _auth.currentUser?.uid;

  // Predefined Mini Habits List
  final List<String> miniHabits = [
    "Drink more water",
    "Stretch for 5 minutes",
    "Meditate for 5 minutes",
    "Take 10 deep breaths",
    "Go for a short walk",
    "Write down 3 things you're grateful for",
    "Read for 10 minutes",
    "Do a quick workout",
    "Listen to calming music",
    "Avoid screens for 30 minutes",
    "Compliment yourself",
    "Eat one healthy meal",
    "Smile at yourself in the mirror",
    "Practice good posture",
    "Declutter your workspace",
    "Say something positive about yourself",
    "Stand up and move around every hour",
    "Limit social media scrolling",
    "Write a small journal entry",
    "Try a new relaxation technique",
  ];

  /// **Store Mini Habits in Firestore**
  Future<void> storeMiniHabits() async {
    if (userId == null) return;

    final habitCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('habitList');

    // Check if habits already exist to avoid duplication
    final existingDocs = await habitCollection.get();
    if (existingDocs.docs.isNotEmpty) {
      print("Mini habits already stored.");
      return;
    }

    // Add habits to Firestore
    for (String habit in miniHabits) {
      await habitCollection.add({
        'text': habit,
        'completed': false, // Track if user completed the habit
      });
    }

    print("Mini habits stored successfully.");
  }

  /// **Fetch 5 Random Mini Habits**
  Future<List<Map<String, dynamic>>> getMiniHabits() async {
    if (userId == null) return [];

    final habitCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('habitList');

    final snapshot = await habitCollection.get();
    final allHabits =
        snapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'text': doc['text'],
                'completed': doc['completed'] ?? false,
              },
            )
            .toList();

    allHabits.shuffle(); // Randomize the order
    return allHabits.take(5).toList(); // Return 5 random habits
  }

  /// **Mark a Habit as Completed**
  Future<void> completeHabit(String habitId) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habitList')
        .doc(habitId)
        .update({'completed': true});

    print("Habit marked as completed.");
  }
}
