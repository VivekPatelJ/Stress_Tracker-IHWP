import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'create_journal_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class JournalsPage extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Journals',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _firebaseService.getJournals(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(color: Color(0xFF002D62)),
            );

          var journals = snapshot.data!.docs;
          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (context, index) {
              var journal = journals[index];
              final date = journal['timestamp'].toDate();
              final formattedDate =
                  DateFormat('d MMM yyyy    h:mm a').format(date).toLowerCase();
              return Dismissible(
                key: Key(journal.id),
                onDismissed:
                    (direction) => _firebaseService.deleteJournal(journal.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  color: Color(0xFFE3ECF7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      journal['title'],
                      style: GoogleFonts.poppins(
                        color: Color(0xFF002D62),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF002D62),
                        fontSize: 13,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  CreateJournalPage(editingJournal: journal),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF002D62),
        child: Icon(Icons.add, color: Colors.white),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateJournalPage()),
            ),
      ),
    );
  }
}
