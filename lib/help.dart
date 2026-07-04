import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ HEADER
          const Text(
            "Help Center",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Get support and learn how to use Rehab Ai",
            style: TextStyle(fontSize: 16, color: Colors.blueGrey[400]),
          ),
          const SizedBox(height: 24),

          // 🎥 VIDEO TUTORIALS
          HelpDropdownCard(
            title: "Video Tutorials",
            icon: Icons.videocam_outlined,
            iconBgColor: const Color(0xFF4353FF).withValues(alpha: 0.15),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How to set up your camera for Form Tracking:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TutorialVideoPlayer(
                      videoUrl: 'https://youtube.com/shorts/stP8LdARJQY',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Make sure your full body is visible in the frame before starting the workout.",
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ❓ FAQ SECTION
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          HelpDropdownCard(
            title: "How does form tracking work?",
            icon: Icons.help_outline,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "We use your device's camera and advanced AI to analyze your joint positions in real-time and compare them against ideal form metrics.",
                  style: TextStyle(color: Colors.blueGrey[300], height: 1.5),
                ),
              ),
            ],
          ),
          HelpDropdownCard(
            title: "Is my video data saved?",
            icon: Icons.help_outline,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "No, all processing happens locally on your device. We do not store or upload your video feeds.",
                  style: TextStyle(color: Colors.blueGrey[300]),
                ),
              ),
            ],
          ),
          HelpDropdownCard(
            title: "Can I use this without camera access?",
            icon: Icons.help_outline,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "You can browse plans and view progress, but live form feedback requires camera permissions.",
                  style: TextStyle(color: Colors.blueGrey[300]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 🤝 STILL NEED HELP SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4353FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Still need help?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Check out our comprehensive documentation or join our community forum for tips and advice from other users.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[300],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4353FF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Documentation",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4353FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Community",
                            style: TextStyle(
                              color: Color(0xFF4353FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// 🧩 REUSABLE DROPDOWN CARD WIDGET
class HelpDropdownCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? iconBgColor;

  const HelpDropdownCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.blueGrey[400],
          collapsedIconColor: Colors.blueGrey[400],
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor ?? const Color(0xFF4353FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4353FF), size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

// 🎬 VIDEO PLAYER WIDGET
class TutorialVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const TutorialVideoPlayer({super.key, required this.videoUrl});

  @override
  State<TutorialVideoPlayer> createState() => _TutorialVideoPlayerState();
}

class _TutorialVideoPlayerState extends State<TutorialVideoPlayer> {
  VideoPlayerController? _localController;
  Future<void>? _initializeLocalVideoFuture;
  bool _isLocalInitialized = false;

  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    final youtubeId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (youtubeId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
        ),
      );
    } else {
      _isYoutube = false;
      _localController = VideoPlayerController.asset(widget.videoUrl);
      _initializeLocalVideoFuture = _localController!.initialize().then((_) {
        setState(() {
          _isLocalInitialized = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFF4353FF),
          bottomActions: [
            CurrentPosition(),
            ProgressBar(
              isExpanded: true,
              colors: const ProgressBarColors(
                playedColor: Color(0xFF4353FF),
                handleColor: Color(0xFF4353FF),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.black26,
              ),
            ),
            RemainingDuration(),
            const PlaybackSpeedButton(),
          ],
        ),
      );
    }

    if (_initializeLocalVideoFuture == null) {
      return Container(
        height: 200,
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Text("Error loading video", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return FutureBuilder(
      future: _initializeLocalVideoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && _isLocalInitialized) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _localController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_localController!),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _localController!.value.isPlaying
                            ? _localController!.pause()
                            : _localController!.play();
                      });
                    },
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: _localController!.value.isPlaying ? 0.0 : 0.3,
                      ),
                      child: Center(
                        child: Icon(
                          _localController!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white.withValues(
                            alpha: _localController!.value.isPlaying ? 0.0 : 0.9,
                          ),
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                  VideoProgressIndicator(
                    _localController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF4353FF),
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4353FF)),
            ),
          );
        }
      },
    );
  }
}
