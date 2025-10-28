import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> selectMood(String mood, String keyword) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Ensure user is logged in

  String today = DateTime.now().toIso8601String().split("T")[0]; // YYYY-MM-DD
  DocumentReference moodDocRef = FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .collection("moodHistory")
      .doc(today);

  // Check if mood is already selected for today
  var moodDoc = await moodDocRef.get();
  if (moodDoc.exists) {
    print("Mood already selected today.");
    return;
  }

  // Save mood selection
  await moodDocRef.set({
    "mood": mood,
    "keyword": keyword,
    "timestamp": DateTime.now().toIso8601String(),
  });

  print("Mood saved successfully.");
}
