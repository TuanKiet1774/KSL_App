import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/model/learned_word.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LearnedWordDetailScreen extends StatefulWidget {
  final List<LearnedWordModel> learnedWords;
  final int initialIndex;

  const LearnedWordDetailScreen({
    super.key,
    required this.learnedWords,
    required this.initialIndex,
  });

  @override
  State<LearnedWordDetailScreen> createState() => _LearnedWordDetailScreenState();
}

class _LearnedWordDetailScreenState extends State<LearnedWordDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchYouTube(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) MessDialog.showErrorDialog(context, 'Lỗi', 'Không thể mở link YouTube');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.learnedWords.length,
            itemBuilder: (context, index) {
              return _buildWordContent(widget.learnedWords[index]);
            },
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryBlue, size: 20),
              ),
            ),
          ),

          // Pagination Indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 22,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.learnedWords.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordContent(LearnedWordModel learnedWord) {
    final word = learnedWord.wordId;
    if (word == null) return const Center(child: Text("Dữ liệu từ vựng không tồn tại"));

    final bool hasYoutube = word.youtubeLink.isNotEmpty && YoutubePlayer.convertUrlToId(word.youtubeLink) != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 100),
            
            // Media Section
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                    child: hasYoutube
                      ? YoutubeFrame(videoUrl: word.youtubeLink)
                      : (word.media.url.isNotEmpty
                          ? AspectRatio(
                              aspectRatio: 1,
                              child: CachedNetworkImage(
                                imageUrl: word.media.url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(color: AppColors.primaryTeal),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const SizedBox(height: 200, child: Icon(Icons.image_not_supported_rounded, size: 60, color: Colors.grey))),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Word Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chủ đề: ${learnedWord.topicId?.name ?? "Không rõ"}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${learnedWord.expGained} EXP',
                    style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              'ĐỊNH NGHĨA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              word.description,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            
            const SizedBox(height: 30),
            const Text(
              'THỜI GIAN HỌC',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(learnedWord.learnedAt),
              style: const TextStyle(fontSize: 16, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      final localDate = date.toLocal();
      return "${localDate.hour}:${localDate.minute.toString().padLeft(2, '0')} - ${localDate.day}/${localDate.month}/${localDate.year}";
    } catch (e) {
      return date.toString();
    }
  }
}

class YoutubeFrame extends StatefulWidget {
  final String videoUrl;
  const YoutubeFrame({super.key, required this.videoUrl});

  @override
  State<YoutubeFrame> createState() => _YoutubeFrameState();
}

class _YoutubeFrameState extends State<YoutubeFrame> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(() {
      if (mounted) {
        if (_controller.value.playerState == PlayerState.ended) {
          _controller.pause();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primaryTeal,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.primaryTeal,
          handleColor: AppColors.primaryTeal,
        ),
        onEnded: (metaData) {
          _controller.seekTo(Duration.zero);
          _controller.pause();
          if (mounted) setState(() {});
        },
      ),
      builder: (context, player) {
        return AspectRatio(
          aspectRatio: 1,
          child: player,
        );
      },
    );
  }
}
