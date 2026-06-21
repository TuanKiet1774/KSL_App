import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/provider/wordProvider.dart';
import 'package:ksl/provider/learnedWordProvider.dart';
import 'package:ksl/provider/favoriteWordProvider.dart';
import 'package:ksl/model/word.dart';
import 'package:ksl/model/topic.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ksl/component/youtubeFrame.dart';
import 'package:ksl/provider/authProvider.dart';

class WordListScreen extends StatefulWidget {
  final TopicModel topic;

  const WordListScreen({super.key, required this.topic});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final int _threshold = 5;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final int savedIndex = prefs.getInt('last_index_${widget.topic.id}') ?? 0;
    await _fetchWords(targetIndex: savedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchWords({int targetIndex = 0}) async {
    final provider = context.read<WordProvider>();
    await provider.loadTopicWordsUntilIndex(widget.topic.id, targetIndex);
    if (!mounted) return;

    final words = provider.topicWords;
    if (provider.topicWordsError.isEmpty) {
      if (targetIndex >= words.length) {
        targetIndex = words.isEmpty ? 0 : words.length - 1;
      }
      _currentIndex = targetIndex;
      _precacheImages(words);

      if (targetIndex > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetIndex);
          }
        });
      }
    }
  }

  Future<void> _saveLastIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_index_${widget.topic.id}', index);
  }

  void _precacheImages(List<WordModel> words) {
    for (var word in words) {
      if (word.media.url.isNotEmpty) {
        precacheImage(NetworkImage(word.media.url), context).catchError((e) => null);
      }
    }
  }

  Future<void> _markAsLearned(int index) async {
    final words = context.read<WordProvider>().topicWords;
    if (index >= words.length) return;
    final word = words[index];
    final result = await context.read<LearnedWordProvider>().markAsLearned(
      wordId: word.id,
      topicId: widget.topic.id,
      expGained: word.exp,
    );
    if (mounted && result['success'] == true) {
      context.read<AuthProvider>().getProfile();
    }
  }

  Future<void> _toggleFavorite(WordModel word) async {
    final favoriteProvider = context.read<FavoriteWordProvider>();
    final wordProvider = context.read<WordProvider>();
    if (word.isFavorite) {
      final result = await favoriteProvider.removeFromFavorite(word.id);
      if (result['success']) {
        wordProvider.setTopicWordFavorite(word.id, false);
      } else {
        if (mounted) MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
      }
    } else {
      final result = await favoriteProvider.addToFavorite(
        wordId: word.id,
        topicId: widget.topic.id,
      );
      if (result['success']) {
        wordProvider.setTopicWordFavorite(word.id, true);
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
    final words = context.read<WordProvider>().topicWords;
    if (_currentIndex < words.length - 1) {
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
    final wordProvider = context.watch<WordProvider>();
    final words = wordProvider.topicWords;
    final isLoading = wordProvider.isLoadingTopicWords;
    final errorMessage = wordProvider.topicWordsError;
    final hasMore = wordProvider.hasMoreTopicWords;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                    : errorMessage.isNotEmpty
                        ? _buildErrorState(errorMessage)
                        : words.isEmpty
                            ? _buildEmptyState()
                            : _buildWordPageView(words),
              ),
              if (!isLoading && words.isNotEmpty) _buildNavigationControls(words, hasMore),
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

          if (!isLoading && words.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 22,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / ${words.length}${hasMore ? '+' : ''}',
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

  Widget _buildWordPageView(List<WordModel> words) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        if (index > _currentIndex) {
          _markAsLearned(_currentIndex);
        }

        setState(() {
          _currentIndex = index;
        });
        _saveLastIndex(index);
        if (words.length - index <= _threshold) {
          context.read<WordProvider>().loadNextTopicWordBatch(widget.topic.id);
        }
      },
      itemCount: words.length,
      itemBuilder: (context, index) {
        return _buildWordContent(words[index], isActive: index == _currentIndex);
      },
    );
  }

  Widget _buildWordContent(WordModel word, {required bool isActive}) {
    final String? youtubeVideoId = word.youtubeLink.isNotEmpty ? YoutubePlayer.convertUrlToId(word.youtubeLink) : null;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 80),
            
            // Media Section (Nhỏ lại và có Border)
            if (word.media.url.isNotEmpty || youtubeVideoId != null)
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
                    child: youtubeVideoId != null
                      ? (isActive
                          ? YoutubeFrame(key: ValueKey(word.id), videoUrl: word.youtubeLink, aspectRatio: 1)
                          : AspectRatio(
                              aspectRatio: 1,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: 'https://img.youtube.com/vi/$youtubeVideoId/mqdefault.jpg',
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100),
                                  ),
                                  Container(color: Colors.black26),
                                  const Center(
                                    child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 48),
                                  ),
                                ],
                              ),
                            ))
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

  Widget _buildNavigationControls(List<WordModel> words, bool hasMore) {
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
              label: (_currentIndex == words.length - 1 && !hasMore) ? 'HOÀN THÀNH' : 'TIẾP THEO',
              onTap: () async {
                if (_currentIndex == words.length - 1 && !hasMore) {
                  await _markAsLearned(_currentIndex);
                  await _saveLastIndex(0); // Đã hoàn thành thì không cần lưu vết (về 0)
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

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(errorMessage, style: const TextStyle(color: Colors.grey)),
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

