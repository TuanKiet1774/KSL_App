import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/learnedWordController.dart';
import 'package:ksl/component/confirmDialog.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:ksl/model/learnedWord.dart';
import 'package:ksl/view/learnedWordDetail.dart';
import 'package:ksl/controller/authController.dart';

import '../component/loadingEffect.dart';

class LearnedWordListScreen extends StatefulWidget {
  const LearnedWordListScreen({super.key});

  @override
  State<LearnedWordListScreen> createState() => _LearnedWordListScreenState();
}

class _LearnedWordListScreenState extends State<LearnedWordListScreen> {
  List<LearnedWordModel> _learnedWords = [];
  bool _isLoading = true;
  String _errorMessage = "";
  bool _isSelectionMode = false;
  final Set<String> _selectedWordIds = {};
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Phân trang
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchLearnedWords();
    _syncUserExp();
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
      if (_hasMore && !_isFetchingMore && !_isLoading && _searchQuery.isEmpty) {
        _fetchMoreLearnedWords();
      }
    }
  }

  Future<void> _syncUserExp() async {
    final result = await LearnedWordController.syncExp();
    if (mounted && result['success']) {
      await AuthController.getProfile();
    }
  }

  Future<void> _fetchLearnedWords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _currentPage = 1;
      _hasMore = true;
    });

    final result = await LearnedWordController.getMyLearnedWords(page: _currentPage, limit: _limit);

    if (mounted) {
      setState(() {
        if (result['success']) {
          _learnedWords = result['data'];
          if (_learnedWords.length < _limit) {
            _hasMore = false;
          }
        } else {
          _errorMessage = result['message'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMoreLearnedWords() async {
    if (_isFetchingMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    final nextPage = _currentPage + 1;
    final result = await LearnedWordController.getMyLearnedWords(page: nextPage, limit: _limit);

    if (mounted) {
      setState(() {
        if (result['success']) {
          final List<LearnedWordModel> newWords = result['data'];
          if (newWords.isEmpty) {
            _hasMore = false;
          } else {
            _learnedWords.addAll(newWords);
            _currentPage = nextPage;
            if (newWords.length < _limit) {
              _hasMore = false;
            }
          }
        }
        _isFetchingMore = false;
      });
    }
  }

  List<LearnedWordModel> get _filteredWords {
    if (_searchQuery.isEmpty) return _learnedWords;
    return _learnedWords.where((w) {
      final name = w.wordId?.name.toLowerCase() ?? "";
      final topic = w.topicId?.name.toLowerCase() ?? "";
      return name.contains(_searchQuery.toLowerCase()) || topic.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          if (!_isSearching && !_isSelectionMode && _learnedWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (_learnedWords.isNotEmpty && !_isSearching)
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.select_all_rounded : Icons.edit_note_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (!_isSelectionMode) {
                    _isSelectionMode = true;
                  } else {
                    if (_selectedWordIds.length == _learnedWords.length) {
                      _selectedWordIds.clear();
                    } else {
                      _selectedWordIds.addAll(_learnedWords.map((w) => w.id));
                    }
                  }
                });
              },
            ),
          if (_isSelectionMode && _selectedWordIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: _showBulkDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : Column(
                  children: [
                    if (!_isSearching) _buildHeader(),
                    Expanded(
                      child: _filteredWords.isEmpty ? _buildEmptyState() : _buildLearnedWordList(),
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

  Widget _buildLearnedWordList() {
    final list = _filteredWords;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: list.length + (_hasMore && _searchQuery.isEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == list.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
          );
        }
        final learned = list[index];
        return _buildDismissibleCard(learned, index);
      },
    );
  }

  Widget _buildDismissibleCard(LearnedWordModel learned, int index) {
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
        _deleteSingleWord(learned.id, index);
      },
      child: _buildLearnedWordCard(learned, index),
    );
  }

  Widget _buildLearnedWordCard(LearnedWordModel learned, int index) {
    bool isSelected = _selectedWordIds.contains(learned.id);

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
                learnedWords: _filteredWords,
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

  Future<void> _deleteSingleWord(String id, int index) async {
    final result = await LearnedWordController.deleteLearnedWord(id);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _learnedWords.removeAt(index);
        });
        _syncUserExp();
        MessDialog.showSuccessDialog(context, 'Thành công', result['message']);
      } else {
        MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
        _fetchLearnedWords();
      }
    }
  }

  Future<void> _deleteMultipleWords() async {
    setState(() => _isLoading = true);
    
    final result = await LearnedWordController.deleteMultipleLearnedWords(_selectedWordIds.toList());
    
    if (mounted) {
      if (result['success']) {
        setState(() {
          _learnedWords.removeWhere((w) => _selectedWordIds.contains(w.id));
          _selectedWordIds.clear();
          _isSelectionMode = false;
          _isLoading = false;
        });
        _syncUserExp();
        MessDialog.showSuccessDialog(context, 'Thành công', result['message']);
      } else {
        setState(() => _isLoading = false);
        MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
      }
    }
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
          ElevatedButton(onPressed: _fetchLearnedWords, child: const Text('Thử lại')),
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
