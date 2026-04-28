import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/word_controller.dart';
import 'package:ksl/controller/learned_word_controller.dart';
import 'package:ksl/controller/favorite_word_controller.dart';
import 'package:ksl/model/word.dart';
import 'package:ksl/model/topic.dart';
import 'package:ksl/component/loadingEffect.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WordListScreen extends StatefulWidget {
  final TopicModel topic;

  const WordListScreen({super.key, required this.topic});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  List<WordModel> _visibleWords = []; // Các từ đang hiển thị trong PageView
  bool _isLoading = true;
  String _errorMessage = "";
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  // Logic phân đoạn 10 từ (Server-side)
  int _currentPage = 1;
  final int _batchSize = 10;
  final int _threshold = 5; 
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchWords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchWords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _visibleWords = [];
      _currentIndex = 0;
      _currentPage = 1;
      _hasMore = true;
    });

    final result = await WordController.getWordsByTopic(widget.topic.id, page: _currentPage, limit: _batchSize);

    if (mounted) {
      if (result['success']) {
        final List<WordModel> newWords = result['data'];
        _visibleWords = newWords;
        
        if (newWords.length < _batchSize) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }

        // Tải ảnh ngầm, không đợi xong hết mới hiện UI
        _precacheImages(_visibleWords);
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    }
  }

  void _precacheImages(List<WordModel> words) {
    for (var word in words) {
      if (word.media.url.isNotEmpty) {
        precacheImage(NetworkImage(word.media.url), context).catchError((e) => null);
      }
    }
  }

  Future<void> _loadNextBatch() async {
    if (!_hasMore || _isFetchingMore) return;

    _isFetchingMore = true;
    final int nextPage = _currentPage + 1;

    final result = await WordController.getWordsByTopic(widget.topic.id, page: nextPage, limit: _batchSize);
    
    if (mounted) {
      if (result['success']) {
        final List<WordModel> nextWords = result['data'];
        if (nextWords.isNotEmpty) {
          setState(() {
            _visibleWords.addAll(nextWords);
            _currentPage = nextPage;
            if (nextWords.length < _batchSize) {
              _hasMore = false;
            }
          });
          _precacheImages(nextWords);
        } else {
          _hasMore = false;
        }
      }
      _isFetchingMore = false;
    }
  }

  Future<void> _markAsLearned(int index) async {
    if (index >= _visibleWords.length) return;
    final word = _visibleWords[index];
    await LearnedWordController.markAsLearned(
      wordId: word.id,
      topicId: widget.topic.id,
      expGained: word.exp,
    );
  }

  Future<void> _toggleFavorite(WordModel word) async {
    if (word.isFavorite) {
      final result = await FavoriteWordController.removeFromFavorite(word.id);
      if (result['success']) {
        setState(() {
          word.isFavorite = false;
        });
      } else {
        if (mounted) MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
      }
    } else {
      final result = await FavoriteWordController.addToFavorite(
        wordId: word.id,
        topicId: widget.topic.id,
      );
      if (result['success']) {
        setState(() {
          word.isFavorite = true;
        });
      } else {
        if (mounted) MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
      }
    }
  }

  Future<void> _launchYouTube(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) MessDialog.showErrorDialog(context, 'Lỗi', 'Không thể mở link YouTube');
    }
  }

  void _nextPage() {
    if (_currentIndex < _visibleWords.length - 1) {
      _markAsLearned(_currentIndex); 
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                    : _errorMessage.isNotEmpty
                        ? _buildErrorState()
                        : _visibleWords.isEmpty
                            ? _buildEmptyState()
                            : _buildWordPageView(),
              ),
              if (!_isLoading && _visibleWords.isNotEmpty) _buildNavigationControls(),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue, size: 24),
              ),
            ),
          ),

          if (!_isLoading && _visibleWords.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 22,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / ${_visibleWords.length}${_hasMore ? '+' : ''}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWordPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        if (index > _currentIndex) {
          _markAsLearned(_currentIndex);
        }
        
        setState(() {
          _currentIndex = index;
        });
        if (_visibleWords.length - index <= _threshold) {
          _loadNextBatch();
        }
      },
      itemCount: _visibleWords.length,
      itemBuilder: (context, index) {
        return _buildWordContent(_visibleWords[index]);
      },
    );
  }

  Widget _buildWordContent(WordModel word) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 80),
            
            // Media Section (Nhỏ lại và có Border)
            if (word.media.url.isNotEmpty)
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
                    child: word.youtubeLink.isNotEmpty && YoutubePlayer.convertUrlToId(word.youtubeLink) != null
                      ? YoutubeFrame(videoUrl: word.youtubeLink)
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: CachedNetworkImage(
                                imageUrl: word.media.url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryTeal.withOpacity(0.5),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            if (word.media.type == 'video')
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
                              ),
                          ],
                        ),
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // Word Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.name,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        word.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: word.isFavorite ? Colors.red : Colors.grey,
                        size: 32,
                      ),
                      onPressed: () => _toggleFavorite(word),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          Text(
                            '+${word.exp} EXP',
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                fontSize: 19,
                color: Colors.grey.shade800,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentIndex > 0)
            _buildCircleNavButton(
              icon: Icons.chevron_left_rounded,
              onTap: _previousPage,
              isPrimary: false,
            ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildMainNavButton(
              label: (_currentIndex == _visibleWords.length - 1 && !_hasMore) ? 'HOÀN THÀNH' : 'TIẾP THEO',
              onTap: () async {
                if (_currentIndex == _visibleWords.length - 1 && !_hasMore) {
                  await _markAsLearned(_currentIndex);
                  Navigator.pop(context);
                } else {
                  _nextPage();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleNavButton({required IconData icon, required VoidCallback onTap, bool isPrimary = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryTeal : Colors.white,
          shape: BoxShape.circle,
          border: isPrimary ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : AppColors.primaryBlue, size: 28),
      ),
    );
  }

  Widget _buildMainNavButton({required String label, required Future<void> Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchWords, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Chưa có từ vựng nào', style: TextStyle(color: Colors.grey)),
    );
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
