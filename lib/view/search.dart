import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/wordController.dart';
import 'package:ksl/controller/topicController.dart';
import 'package:ksl/provider/authProvider.dart';
import 'package:ksl/provider/learnedWordProvider.dart';
import 'package:ksl/provider/progressProvider.dart';
import 'package:ksl/model/word.dart';
import 'package:ksl/model/topic.dart';
import 'package:ksl/model/user.dart';
import 'package:ksl/model/progress.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:ksl/component/youtubeFrame.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _initialScrollController = ScrollController();
  
  List<WordModel> _searchResults = [];
  List<WordModel> _initialWords = [];
  List<TopicModel> _allTopics = [];
  List<String> _openedTopicIds = [];
  
  UserModel? _currentUser;
  ProgressModel? _userProgress;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isFetchingMoreInitial = false;
  int _currentTopicIndex = 0;
  
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initData();
    _initialScrollController.addListener(_onInitialScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _initialScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onInitialScroll() {
    if (_initialScrollController.position.pixels >= _initialScrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMoreInitial && _query.isEmpty && _currentTopicIndex < _openedTopicIds.length) {
        _loadMoreInitialWords();
      }
    }
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isInitializing = true);

    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();

    // Gọi song song 3 API cùng lúc thay vì tuần tự
    await Future.wait([
      authProvider.getProfile(),
      progressProvider.fetchUserProgress(),
    ]);
    final topicsResult = await TopicController.getAllTopics(limit: 100);

    _currentUser = authProvider.currentUser;
    _userProgress = progressProvider.userProgress;

    if (topicsResult['success']) {
      _allTopics = topicsResult['data'];
    }

    final int userExp = _userProgress?.stats.totalExp ?? _currentUser?.exp ?? 0;

    if (_allTopics.isNotEmpty) {
      _openedTopicIds = _allTopics
          .where((t) => t.expRequired <= userExp)
          .map((t) => t.id)
          .toList();
    }

    // Hiển thị UI ngay, load từ gợi ý ở nền
    if (mounted) setState(() => _isInitializing = false);

    if (_openedTopicIds.isNotEmpty) {
      _currentTopicIndex = 0;
      _loadMoreInitialWords();
    }
  }

  Future<void> _loadMoreInitialWords() async {
    if (_isFetchingMoreInitial || _currentTopicIndex >= _openedTopicIds.length) return;

    if (mounted) setState(() => _isFetchingMoreInitial = true);

    final int countBefore = _initialWords.length;

    // Tiếp tục load topics cho đến khi có đủ từ để list có thể scroll
    while (_currentTopicIndex < _openedTopicIds.length) {
      final topicId = _openedTopicIds[_currentTopicIndex];
      final wordsResult = await WordController.getWordsByTopic(topicId, limit: 20);
      _currentTopicIndex++;

      if (!mounted) return;

      if (wordsResult['success']) {
        final List<WordModel> newWords = wordsResult['data'];
        if (newWords.isNotEmpty) {
          setState(() => _initialWords.addAll(newWords));
        }
      }

      // Dừng khi đã thêm đủ từ để list có thể scroll (~15 từ mới)
      if (_initialWords.length - countBefore >= 15) break;
    }

    if (mounted) setState(() => _isFetchingMoreInitial = false);
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value);
    });
  }

  int _relevanceScore(WordModel word, String query) {
    final name = word.name.toLowerCase();
    final q = query.toLowerCase().trim();
    if (name == q) return 3;
    if (name.startsWith(q)) return 2;
    if (name.contains(q)) return 1;
    return 0;
  }

  Future<void> _performSearch(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _query = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = value;
    });

    final result = await WordController.searchWords(value);

    if (mounted) {
      final List<WordModel> results = result['success'] ? List<WordModel>.from(result['data']) : [];
      results.sort((a, b) => _relevanceScore(b, value).compareTo(_relevanceScore(a, value)));
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleWordTap(WordModel word) async {
    final topic = _allTopics.firstWhere(
      (t) => t.id == word.topicId,
      orElse: () => TopicModel(id: '', name: '', level: '', description: '', image: '', expRequired: 999999, totalWord: 0),
    );

    final int userExp = _userProgress?.stats.totalExp ?? _currentUser?.exp ?? 0;

    if (topic.expRequired <= userExp) {
      // Hiển thị chi tiết
      _showWordDetail(word, topic);
      
      // Đánh dấu đã học nếu chưa học
      if (!word.isLearned) {
        final result = await context.read<LearnedWordProvider>().markAsLearned(
          wordId: word.id,
          topicId: topic.id,
          expGained: word.exp,
        );
        if (mounted && result['success']) {
          setState(() {
            word.isLearned = true;
          });
          // Cập nhật lại progress sau khi học để đồng bộ EXP
          final progressProvider = context.read<ProgressProvider>();
          await progressProvider.fetchUserProgress();
          if (mounted) {
            setState(() {
              _userProgress = progressProvider.userProgress;
            });
          }
        }
      }
    } else {
      if (mounted) {
        MessDialog.showErrorDialog(
          context, 
          'Chưa đủ kinh nghiệm', 
          'Bạn chưa đủ kinh nghiệm để học chủ đề này (Yêu cầu: ${topic.expRequired} EXP)'
        );
      }
    }
  }

  void _showWordDetail(WordModel word, TopicModel topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WordDetailSheet(word: word, topic: topic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryTeal, Color(0xFF236B65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x3A1A4D49),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: const Text(
              'Tìm kiếm ký hiệu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Nhập ký hiệu cần tìm...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.grey), onPressed: () { _searchController.clear(); _performSearch(''); })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                    : _query.isEmpty
                        ? _buildInitialState()
                        : _searchResults.isEmpty
                            ? _buildEmptyState()
                            : _buildResultsList(_searchResults, null),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    if (_initialWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded, size: 100, color: AppColors.primaryTeal.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text('Khám phá kho từ vựng KSL', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Hãy học thêm để mở khóa các chủ đề mới!', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text('Gợi ý ký hiệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        ),
        Expanded(
          child: _buildResultsList(_initialWords, _initialScrollController),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Không tìm thấy kết quả cho "$_query"', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<WordModel> words, ScrollController? controller) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: words.length + (controller != null && _isFetchingMoreInitial ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == words.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
          );
        }
        final word = words[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(word.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue)),
            subtitle: Row(
              children: [
                if (word.isLearned) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 14)),
                Expanded(child: Text(word.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
            onTap: () => _handleWordTap(word),
          ),
        );
      },
    );
  }
}

class _WordDetailSheet extends StatelessWidget {
  final WordModel word;
  final TopicModel topic;
  const _WordDetailSheet({required this.word, required this.topic});

  @override
  Widget build(BuildContext context) {
    final bool hasYoutube = word.youtubeLink.isNotEmpty && YoutubePlayer.convertUrlToId(word.youtubeLink) != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primaryTeal.withOpacity(0.1))),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: hasYoutube
                          ? YoutubeFrame(videoUrl: word.youtubeLink, aspectRatio: 1.0)
                          : (word.media.url.isNotEmpty 
                              ? CachedNetworkImage(
                                  imageUrl: word.media.url, 
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
                                  errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_rounded, size: 50, color: Colors.grey),
                                )
                              : const SizedBox(height: 200, child: Icon(Icons.image_not_supported_rounded, size: 50, color: Colors.grey))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(word.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryBlue))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text('+${word.exp} EXP', style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Chủ đề: ${topic.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 30),
                  const Text('MÔ TẢ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text(word.description, style: TextStyle(fontSize: 18, color: Colors.grey.shade800, height: 1.5)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
