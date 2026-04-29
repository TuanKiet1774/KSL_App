import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/topicController.dart';
import 'package:ksl/controller/progressController.dart';
import 'package:ksl/model/topic.dart';
import 'package:ksl/component/lazyLoading.dart';
import 'package:ksl/view/wordList.dart';
import 'package:ksl/component/messDialog.dart';
import '../model/progress.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({super.key});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  List<TopicModel> _allTopics = [];
  ProgressModel? _userProgress;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  
  String _searchQuery = "";
  String _selectedLevel = "All";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool isLoadMore = false, bool showLoading = true}) async {
    if (isLoadMore) {
      if (_isFetchingMore || !_hasMore) return;
      setState(() => _isFetchingMore = true);
    } else if (showLoading) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _allTopics = [];
        _hasMore = true;
      });
    }

    final bool shouldFetchTopics = showLoading || _allTopics.isEmpty || isLoadMore;
    
    dynamic topicResult;
    if (shouldFetchTopics) {
      topicResult = await TopicController.getAllTopics(page: _currentPage, limit: _limit);
    }
    
    final progressResult = await ProgressController.getUserProgress();
    
    if (mounted) {
      setState(() {
        if (shouldFetchTopics && topicResult != null) {
          if (topicResult['success']) {
            final List<TopicModel> newTopics = topicResult['data'];
            if (newTopics.length < _limit) {
              _hasMore = false;
            } else {
              _hasMore = true;
              _currentPage++;
            }
            
            if (showLoading) {
              _allTopics = newTopics;
            } else {
              _allTopics.addAll(newTopics);
            }
          } else {
            _hasMore = false;
          }
        }

        if (progressResult['success']) {
          _userProgress = progressResult['data'];
        }
        
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _onFilterChanged() {
    _fetchData();
  }

  List<TopicModel> get _filteredTopics {
    List<TopicModel> filtered = _allTopics.where((topic) {
      final matchesSearch = topic.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesLevel = _selectedLevel == "All" || topic.level == _selectedLevel;
      return matchesSearch && matchesLevel;
    }).toList();

    // Sắp xếp: Ưu tiên các topic đã mở (đủ EXP), sau đó sắp xếp theo bảng chữ cái
    final int userExp = _userProgress?.stats.totalExp ?? 0;
    filtered.sort((a, b) {
      final bool aLocked = userExp < a.expRequired;
      final bool bLocked = userExp < b.expRequired;
      
      // Nếu trạng thái khóa khác nhau, đưa topic không bị khóa lên trước
      if (aLocked != bLocked) {
        return aLocked ? 1 : -1;
      }
      
      // Nếu cùng trạng thái khóa, sắp xếp theo bảng chữ cái
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Chủ đề học tập',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildLevelFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : _allTopics.isEmpty
                    ? _buildEmptyState()
                    : LazyLoadingList(
                        isLoading: _isFetchingMore,
                        hasMore: _hasMore,
                        onLoadMore: () => _fetchData(isLoadMore: true),
                        controller: _scrollController,
                        child: _buildTopicList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                setState(() {}); 
              },
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm chủ đề...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: AppColors.primaryTeal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    final levels = ["All", "Beginner", "Intermediate", "Advanced"];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = _selectedLevel == level;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLevel = level;
                _onFilterChanged();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentOrange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.accentOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  level == "All" ? "Tất cả" : level,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicList() {
    final topics = _filteredTopics;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: topics.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < topics.length) {
          return _buildTopicCard(topics[index]);
        } else {
          return const LoadingIndicator();
        }
      },
    );
  }

  Widget _buildTopicCard(TopicModel topic) {
    final topicId = topic.id;
    final progressList = _userProgress?.topicProgress ?? [];
    
    // Tìm topicProgress tương ứng
    TopicProgressModel? topicProgress;
    try {
      topicProgress = progressList.firstWhere(
        (p) => p.topicId.toString().trim() == topicId.toString().trim(),
      );
    } catch (_) {
      topicProgress = null;
    }
    
    final double percentage = topicProgress?.percentage ?? 0.0;
    
    // Kiểm tra topic có bị khóa hay không
    final int userExp = _userProgress?.stats.totalExp ?? 0;
    final bool isLocked = userExp < topic.expRequired;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLocked ? 0.01 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLocked 
              ? () {
                  MessDialog.showInfoDialog(
                    context, 
                    'Chủ đề chưa mở', 
                    'Bạn cần ${topic.expRequired} EXP để mở chủ đề này! (Hiện có: $userExp)'
                  );
                }
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WordListScreen(topic: topic),
                    ),
                  );
                  _fetchData(showLoading: false);
                },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: topic.image != ""
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ColorFiltered(
                                  colorFilter: isLocked 
                                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                  child: Image.network(
                                    topic.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.topic_rounded, 
                                size: 40, 
                                color: isLocked ? Colors.grey : AppColors.primaryTeal
                              ),
                      ),
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isLocked ? Colors.grey : _getLevelColor(topic.level)).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                topic.level,
                                style: TextStyle(
                                  color: isLocked ? Colors.grey : _getLevelColor(topic.level),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isLocked)
                              Text(
                                '${topic.expRequired} EXP',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          topic.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.grey : AppColors.primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topic.description,
                          style: TextStyle(fontSize: 12, color: isLocked ? Colors.grey.shade400 : Colors.grey.shade500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLocked ? Colors.grey.shade300 : _getLevelColor(topic.level)
                                ),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${percentage.toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? Colors.grey : _getLevelColor(topic.level),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case "Beginner": return Colors.green;
      case "Intermediate": return Colors.orange;
      case "Advanced": return Colors.red;
      default: return AppColors.primaryTeal;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy chủ đề nào',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
