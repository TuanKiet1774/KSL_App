import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/provider/learnedWordProvider.dart';
import 'package:ksl/provider/authProvider.dart';
import 'package:ksl/component/confirmDialog.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:ksl/model/learnedWord.dart';
import 'package:ksl/view/learnedWordDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearnedWordListScreen extends StatefulWidget {
  const LearnedWordListScreen({super.key});

  @override
  State<LearnedWordListScreen> createState() => _LearnedWordListScreenState();
}

class _LearnedWordListScreenState extends State<LearnedWordListScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedWordIds = {};

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearnedWordProvider>().fetchLearnedWords();
      _syncUserExp();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<LearnedWordProvider>();
      if (provider.hasMore && !provider.isFetchingMore && !provider.isLoading && _searchQuery.isEmpty) {
        provider.fetchLearnedWords(isLoadMore: true);
      }
    }
  }

  Future<void> _syncUserExp() async {
    final result = await context.read<LearnedWordProvider>().syncExp();
    if (mounted && result['success'] == true) {
      await context.read<AuthProvider>().getProfile();
    }
  }

  List<LearnedWordModel> _filteredWords(List<LearnedWordModel> learnedWords) {
    if (_searchQuery.isEmpty) return learnedWords;
    return learnedWords.where((w) {
      final name = w.wordId?.name.toLowerCase() ?? "";
      final topic = w.topicId?.name.toLowerCase() ?? "";
      return name.contains(_searchQuery.toLowerCase()) || topic.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final learnedProvider = context.watch<LearnedWordProvider>();
    final learnedWords = learnedProvider.learnedWords;
    final filteredWords = _filteredWords(learnedWords);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tìm từ vựng đã học...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            )
          : Text(
              _isSelectionMode ? 'Đã chọn ${_selectedWordIds.length}' : 'Từ vựng đã học',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(_isSearching ? Icons.arrow_back_ios_new_rounded : (_isSelectionMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded), color: Colors.white),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = "";
                _searchController.clear();
              });
            } else if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedWordIds.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isSearching && !_isSelectionMode && learnedWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (learnedWords.isNotEmpty && !_isSearching)
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.select_all_rounded : Icons.edit_note_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (!_isSelectionMode) {
                    _isSelectionMode = true;
                  } else {
                    if (_selectedWordIds.length == learnedWords.length) {
                      _selectedWordIds.clear();
                    } else {
                      _selectedWordIds.addAll(learnedWords.map((w) => w.id));
                    }
                  }
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!_isSearching) _buildHeader(),
              Expanded(
                child: learnedProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                    : (learnedProvider.errorMessage ?? '').isNotEmpty
                        ? _buildErrorState(learnedProvider.errorMessage ?? '')
                        : filteredWords.isEmpty
                            ? _buildEmptyState()
                            : _buildLearnedWordList(filteredWords, learnedProvider),
              ),
            ],
          ),
          if (_isSelectionMode && _selectedWordIds.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: _buildBottomDeleteAction(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomDeleteAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Đã chọn ${_selectedWordIds.length} mục',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showBulkDeleteConfirmation,
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            label: const Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryTeal, Color(0xFF2D6A65)],
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/tuvungdahoc.png',
            height: 100,
            width: 100,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.book_rounded, size: 100, color: Colors.white24),
          ),
          const SizedBox(height: 15),
          const Text(
            'Kho tàng từ vựng của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnedWordList(List<LearnedWordModel> list, LearnedWordProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: list.length + (provider.hasMore && _searchQuery.isEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == list.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
          );
        }
        final learned = list[index];
        return _buildDismissibleCard(learned, list);
      },
    );
  }

  Widget _buildDismissibleCard(LearnedWordModel learned, List<LearnedWordModel> list) {
    return Dismissible(
      key: Key(learned.id),
      direction: _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(learned);
      },
      onDismissed: (direction) {
        _deleteSingleWord(learned.id);
      },
      child: _buildLearnedWordCard(learned, list),
    );
  }

  Widget _buildLearnedWordCard(LearnedWordModel learned, List<LearnedWordModel> list) {
    bool isSelected = _selectedWordIds.contains(learned.id);
    final index = list.indexWhere((w) => w.id == learned.id);

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedWordIds.add(learned.id);
          });
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedWordIds.remove(learned.id);
              if (_selectedWordIds.isEmpty) {
                _isSelectionMode = false;
              }
            } else {
              _selectedWordIds.add(learned.id);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearnedWordDetailScreen(
                learnedWords: list,
                initialIndex: index,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.primaryTeal : Colors.grey,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    learned.wordId?.name ?? 'Không rõ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chủ đề: ${learned.topicId?.name ?? 'Không rõ'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày học: ${DateFormat('dd/MM/yyyy HH:mm').format(learned.learnedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${learned.expGained} EXP',
                style: const TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(LearnedWordModel learned) async {
    bool? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmDialog(
        title: 'Xóa từ vựng',
        message: 'Bạn có chắc chắn muốn xóa "${learned.wordId?.name ?? 'từ vựng này'}" khỏi danh sách đã học?',
        icon: Icons.delete_outline_rounded,
        color: Colors.redAccent,
        onConfirm: () {
          result = true;
        },
      ),
    );
    return result;
  }

  Future<void> _showBulkDeleteConfirmation() async {
    ConfirmDialog.show(
      context,
      title: 'Xóa nhiều từ vựng',
      message: 'Bạn có chắc chắn muốn xóa ${_selectedWordIds.length} từ vựng đã chọn?',
      icon: Icons.delete_sweep_rounded,
      color: Colors.redAccent,
      confirmText: 'Xóa tất cả',
      onConfirm: _deleteMultipleWords,
    );
  }

  Future<void> _deleteSingleWord(String id) async {
    final provider = context.read<LearnedWordProvider>();
    final learned = provider.learnedWords.firstWhere((w) => w.id == id);
    final result = await provider.deleteLearnedWord(id);
    if (mounted) {
      if (result['success']) {
        // Xóa luôn vết (reset index về 0) cho topic của từ này
        if (learned.topicId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('last_index_${learned.topicId!.id}');
        }

        _syncUserExp();
        MessDialog.showSuccessDialog(context, 'Thành công', result['message']);
      } else {
        MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
        context.read<LearnedWordProvider>().fetchLearnedWords();
      }
    }
  }

  Future<void> _deleteMultipleWords() async {
    final provider = context.read<LearnedWordProvider>();
    final deletedTopics = provider.learnedWords
        .where((w) => _selectedWordIds.contains(w.id))
        .map((w) => w.topicId?.id)
        .whereType<String>()
        .toSet();

    final result = await provider.deleteMultipleLearnedWords(_selectedWordIds.toList());

    if (mounted) {
      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        for (var topicId in deletedTopics) {
          await prefs.remove('last_index_$topicId');
        }

        setState(() {
          _selectedWordIds.clear();
          _isSelectionMode = false;
        });
        _syncUserExp();
        MessDialog.showSuccessDialog(context, 'Thành công', result['message']);
      } else {
        MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
      }
    }
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
          ElevatedButton(
            onPressed: () => context.read<LearnedWordProvider>().fetchLearnedWords(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Bạn chưa học từ vựng nào' : 'Không tìm thấy từ vựng nào khớp',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
