import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateJournalPage extends StatefulWidget {
  final QueryDocumentSnapshot? editingJournal;

  CreateJournalPage({this.editingJournal});

  @override
  _CreateJournalPageState createState() => _CreateJournalPageState();
}

class _CreateJournalPageState extends State<CreateJournalPage> {
  final FirebaseService _firebaseService = FirebaseService();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingJournal != null) {
      _titleController.text = widget.editingJournal!['title'];
      _contentController.text = widget.editingJournal!['content'];
    }
  }

  Future<void> _saveJournal() async {
    setState(() => _isUploading = true);

    if (widget.editingJournal == null) {
      await _firebaseService.addJournal(
        _titleController.text,
        _contentController.text,
        null,
      );
    } else {
      await _firebaseService.updateJournal(
        widget.editingJournal!.id,
        _titleController.text,
        _contentController.text,
        null,
      );
    }

    setState(() => _isUploading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.editingJournal == null ? 'New Journal' : 'Edit Journal',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF002D62)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.poppins(color: Color(0xFF002D62)),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.poppins(color: Color(0xFF002D62)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Color(0xFF002D62).withAlpha(50),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Color(0xFF002D62).withAlpha(50),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFF002D62)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              style: GoogleFonts.poppins(color: Color(0xFF002D62)),
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: GoogleFonts.poppins(color: Color(0xFF002D62)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Color(0xFF002D62).withAlpha(50),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Color(0xFF002D62).withAlpha(50),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFF002D62)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 24),
            _isUploading
                ? CircularProgressIndicator(color: Color(0xFF002D62))
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveJournal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF002D62),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
