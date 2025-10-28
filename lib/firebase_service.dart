import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get userId => _auth.currentUser?.uid;

  /// **Add a New Journal Entry**
  Future<void> addJournal(
    String title,
    String content,
    String? imageUrl,
  ) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('journals')
        .add({
          'title': title,
          'content': content,
          'imageUrl': imageUrl ?? '',
          'timestamp': Timestamp.now(),
        });
  }

  /// **Fetch All Journal Entries (Fixed Typing)**
  Stream<QuerySnapshot<Map<String, dynamic>>> getJournals() {
    if (userId == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('journals')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// **Update a Journal Entry**
  Future<void> updateJournal(
    String journalId,
    String title,
    String content,
    String? imageUrl,
  ) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('journals')
        .doc(journalId)
        .update({
          'title': title,
          'content': content,
          'imageUrl': imageUrl ?? '',
          'timestamp': Timestamp.now(),
        });
  }

  /// **Delete a Journal Entry**
  Future<void> deleteJournal(String journalId) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('journals')
        .doc(journalId)
        .delete();
  }
}
