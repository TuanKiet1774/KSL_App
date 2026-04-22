import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/word_controller.dart';
import 'package:ksl/controller/learned_word_controller.dart';
import 'package:ksl/model/word.dart';
import 'package:ksl/model/topic.dart';

class WordListScreen extends StatefulWidget {
  final TopicModel topic;

  const WordListScreen({super.key, required this.topic});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  List<WordModel> _words = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final PageController _pageController = PageController();
  int _currentIndex = 0;

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
    });

    final result = await WordController.getWordsByTopic(widget.topic.id);

    if (mounted) {
      setState(() {
        if (result['success']) {
          _words = result['data'];
          _words.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        } else {
          _errorMessage = result['message'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsLearned(int index) async {
    final word = _words[index];
    await LearnedWordController.markAsLearned(
      wordId: word.id,
      topicId: widget.topic.id,
      expGained: word.exp,
    );
  }

  void _nextPage() {
    if (_currentIndex < _words.length - 1) {
      _markAsLearned(_currentIndex); // Lưu tiến trình từ hiện tại
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
          // Nội dung chính
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                    : _errorMessage.isNotEmpty
                        ? _buildErrorState()
                        : _words.isEmpty
                            ? _buildEmptyState()
                            : _buildWordPageView(),
              ),
              if (!_isLoading && _words.isNotEmpty) _buildNavigationControls(),
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

          if (!_isLoading && _words.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 22,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / ${_words.length}',
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
      },
      itemCount: _words.length,
      itemBuilder: (context, index) {
        return _buildWordContent(_words[index]);
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
                    borderRadius: BorderRadius.circular(21), // Trừ đi độ dày border để bo góc khớp
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 1, // Để ảnh dạng hình vuông cân đối
                          child: Image.network(
                            word.media.url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported_rounded, size: 60, color: Colors.grey),
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
                Column(
                  children: [
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
                    const SizedBox(height: 12),
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
              label: _currentIndex == _words.length - 1 ? 'HOÀN THÀNH' : 'TIẾP THEO',
              onTap: () async {
                if (_currentIndex == _words.length - 1) {
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
