import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hub.dart';
import 'secrets.dart';

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  final List<String> categories = [
    'Recommended',
    'Breathing',
    'Meditation',
    'Self Care',
  ];
  String selectedCategory = 'Recommended';
  List<Map<String, String>> videos = [];

  final Map<String, String> categoryPlaylistIds = {
    'Breathing': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
    'Meditation': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
    'Self Care': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
  };

  final Map<String, String> moodPlaylistIds = {
    'happy': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
    'sad': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
    'angry': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
    'calm': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
    'default': 'PLfre5uyT2g-xKVgei6EGYo_cPzoHJ5ynO',
  };

  String moodKeyword = 'default';

  @override
  void initState() {
    super.initState();
    loadMoodAndRecommended();
  }

  Future<void> loadMoodAndRecommended() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('moodHistory')
              .doc(dateStr)
              .get();

      final keyword =
          doc.exists ? doc['keyword'].toString().toLowerCase() : 'default';
      moodKeyword = moodPlaylistIds.containsKey(keyword) ? keyword : 'default';

      final playlistId = moodPlaylistIds[moodKeyword]!;
      final videosList = await fetchPlaylistVideos(playlistId);

      setState(() {
        selectedCategory = 'Recommended';
        videos = videosList;
      });
    } catch (e) {
      print("Error loading mood: $e");
    }
  }

  Future<List<Map<String, String>>> fetchPlaylistVideos(
    String playlistId,
  ) async {
    final url =
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=10&playlistId=$playlistId&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;

      return items.map<Map<String, String>>((item) {
        final videoId = item['snippet']['resourceId']['videoId'];
        final title = item['snippet']['title'];
        return {'id': videoId, 'title': title};
      }).toList();
    } else {
      throw Exception('Failed to fetch videos');
    }
  }

  Future<void> onCategorySelected(String category) async {
    setState(() {
      selectedCategory = category;
      videos = [];
    });

    if (category == 'Recommended') {
      final playlistId = moodPlaylistIds[moodKeyword]!;
      final videosList = await fetchPlaylistVideos(playlistId);
      setState(() {
        videos = videosList;
      });
    } else {
      final playlistId = categoryPlaylistIds[category];
      if (playlistId == null) return;
      final videosList = await fetchPlaylistVideos(playlistId);
      setState(() {
        videos = videosList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Wellness Hub",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF002D62),
          ),
        ),
        centerTitle: true,
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
                children:
                    categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            category,
                            style: GoogleFonts.poppins(
                              color:
                                  selectedCategory == category
                                      ? Colors.white
                                      : Color(0xFF002D62),
                              fontSize: 14,
                            ),
                          ),
                          selected: selectedCategory == category,
                          onSelected: (_) => onCategorySelected(category),
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
            const SizedBox(height: 20),

            // Video List
            Expanded(
              child:
                  videos.isEmpty
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF002D62),
                        ),
                      )
                      : ListView.builder(
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            color: Color(0xFF002D62).withAlpha(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  YoutubePlayer.getThumbnail(
                                    videoId: video['id']!,
                                  ),
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                video['title'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF002D62),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PLayerScreen(
                                          videoId: video['id']!,
                                          playlist: videos,
                                          currentIndex: index,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
