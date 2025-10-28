import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class PLayerScreen extends StatefulWidget {
  final String videoId;
  final List<Map<String, String>> playlist;
  final int currentIndex;

  const PLayerScreen({
    super.key,
    required this.videoId,
    required this.playlist,
    required this.currentIndex,
  });

  @override
  State<PLayerScreen> createState() => _PLayerScreenState();
}

class _PLayerScreenState extends State<PLayerScreen> {
  late final YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: widget.videoId,
    flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get upcoming videos (all except the current one)
    final upcoming = List<Map<String, String>>.from(widget.playlist)
      ..removeAt(widget.currentIndex);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF002D62)),
        title: Text(
          "Player",
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(controller: _controller),
        builder: (context, player) {
          return Column(
            children: [
              player,
              if (upcoming.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Upcoming Videos',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF002D62),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: upcoming.length,
                    itemBuilder: (context, idx) {
                      final video = upcoming[idx];
                      return Card(
                        color: Color(0xFF002D62).withAlpha(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              YoutubePlayer.getThumbnail(videoId: video['id']!),
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            video['title'] ?? '',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF002D62),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PLayerScreen(
                                      videoId: video['id']!,
                                      playlist: widget.playlist,
                                      currentIndex: widget.playlist.indexOf(
                                        video,
                                      ),
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
            ],
          );
        },
      ),
    );
  }
}
