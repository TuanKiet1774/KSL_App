import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/favorite_word_controller.dart';
import 'package:ksl/model/word.dart';
import 'package:ksl/model/favorite_word.dart';
import 'package:ksl/component/loadingEffect.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:ksl/component/confirmDialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoriteView extends StatefulWidget {
  const FavoriteView({super.key});

  @override
  State<FavoriteView> createState() => _FavoriteViewState();
}

class _FavoriteViewState extends State<FavoriteView> {
  List<FavoriteWordModel> _favorites = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedWordIds = {};
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  int _currentPage = 1;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _isSelectionMode = false;
      _selectedWordIds.clear();
    });
    final result = await FavoriteWordController.getMyFavorites(page: _currentPage, limit: _limit);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _favorites = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _removeSingleFavorite(String wordId, int index) async {
    final result = await FavoriteWordController.removeFromFavorite(wordId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _favorites.removeAt(index);
          _favorites = List.from(_favorites);
        });
        MessDialog.showSuccessDialog(context, 'Thành công', 'Đã xóa khỏi yêu thích');
      } else {
        MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
        _fetchFavorites();
      }
    }
  }

  Future<void> _removeMultipleFavorites() async {
    setState(() => _isLoading = true);
    
    int successCount = 0;
    for (var wordId in _selectedWordIds) {
      final result = await FavoriteWordController.removeFromFavorite(wordId);
      if (result['success']) successCount++;
    }

    if (mounted) {
      MessDialog.showSuccessDialog(context, 'Thành công', 'Đã xóa $successCount mục');
      _fetchFavorites();
    }
  }

  void _showBulkDeleteConfirmation() {
    ConfirmDialog.show(
      context,
      title: 'Xóa nhiều yêu thích',
      message: 'Bạn có chắc chắn muốn xóa ${_selectedWordIds.length} từ vựng đã chọn?',
      icon: Icons.delete_sweep_rounded,
      color: Colors.redAccent,
      confirmText: 'Xóa tất cả',
      onConfirm: _removeMultipleFavorites,
    );
  }

  List<FavoriteWordModel> get _filteredFavorites {
    if (_searchQuery.isEmpty) return _favorites;
    return _favorites.where((f) {
      final name = f.wordId?.name.toLowerCase() ?? "";
      final note = f.note.toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || note.contains(_searchQuery.toLowerCase());
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
                hintText: 'Tìm từ vựng...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            )
          : Text(
              _isSelectionMode ? 'Đã chọn ${_selectedWordIds.length}' : 'Yêu thích',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: _isSearching 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => setState(() {
                _isSearching = false;
                _searchQuery = "";
                _searchController.clear();
              }),
            )
          : (_isSelectionMode 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _selectedWordIds.clear();
                  }),
                )
              : null),
        actions: [
          if (!_isSelectionMode && !_isSearching && _favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (_favorites.isNotEmpty && !_isSearching)
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.select_all_rounded : Icons.edit_note_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (!_isSelectionMode) {
                    _isSelectionMode = true;
                  } else {
                    if (_selectedWordIds.length == _favorites.length) {
                      _selectedWordIds.clear();
                    } else {
                      _selectedWordIds.addAll(_favorites.map((f) => f.wordId?.id ?? ''));
                      _selectedWordIds.remove('');
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
          : Column(
              children: [
                Expanded(
                  child: _filteredFavorites.isEmpty ? _buildEmptyState() : _buildFavoriteList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFavoriteList() {
    final list = _filteredFavorites;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final favorite = list[index];
        final word = favorite.wordId;
        if (word == null) return const SizedBox.shrink();

        return _buildDismissibleCard(favorite, index);
      },
    );
  }

  Widget _buildDismissibleCard(FavoriteWordModel favorite, int index) {
    final word = favorite.wordId!;
    return Dismissible(
      key: Key(word.id),
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
        bool? confirmed = false;
        await showDialog(
          context: context,
          builder: (context) => ConfirmDialog(
            title: 'Xóa yêu thích',
            message: 'Bạn có chắc chắn muốn bỏ lưu "${word.name}"?',
            icon: Icons.delete_outline_rounded,
            color: Colors.redAccent,
            onConfirm: () => confirmed = true,
          ),
        );
        return confirmed;
      },
      onDismissed: (_) => _removeSingleFavorite(word.id, index),
      child: _buildWordCard(favorite),
    );
  }

  Widget _buildWordCard(FavoriteWordModel favorite) {
    final word = favorite.wordId!;
    bool isSelected = _selectedWordIds.contains(word.id);

    return GestureDetector(
      key: ValueKey('${word.id}_${favorite.note}'),
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedWordIds.add(word.id);
          });
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedWordIds.remove(word.id);
              if (_selectedWordIds.isEmpty) _isSelectionMode = false;
            } else {
              _selectedWordIds.add(word.id);
            }
          });
        } else {
          _showWordDetail(favorite);
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
                    word.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (favorite.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ghi chú: ${favorite.note}',
                      style: const TextStyle(
                        fontSize: 12, 
                        color: AppColors.primaryTeal, 
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!_isSelectionMode)
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showWordDetail(FavoriteWordModel favorite) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WordDetailSheet(
        favorite: favorite,
        onUpdate: (updatedFavorite) {
          setState(() {
            int index = _favorites.indexWhere((f) => f.id == updatedFavorite.id);
            if (index != -1) {
              List<FavoriteWordModel> newList = List.from(_favorites);
              newList[index] = updatedFavorite;
              _favorites = newList;
            }
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_searchQuery.isEmpty ? Icons.favorite_border_rounded : Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(_searchQuery.isEmpty ? 'Chưa có từ vựng yêu thích nào' : 'Không tìm thấy từ vựng nào khớp', style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

class _WordDetailSheet extends StatefulWidget {
  final FavoriteWordModel favorite;
  final Function(FavoriteWordModel) onUpdate;
  const _WordDetailSheet({required this.favorite, required this.onUpdate});

  @override
  State<_WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<_WordDetailSheet> {
  late String _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.favorite.note;
  }

  void _editNote() {
    final TextEditingController controller = TextEditingController(text: _currentNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi chú'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú của bạn...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryTeal.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final newNote = controller.text;
              final result = await FavoriteWordController.updateFavoriteNote(widget.favorite.id, newNote);
              if (result['success']) {
                setState(() => _currentNote = newNote);
                widget.onUpdate(result['data']);
                if (mounted) Navigator.pop(context);
              } else {
                if (mounted) MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.favorite.wordId!;
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
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24), 
                        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.1))
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24), 
                        child: hasYoutube
                          ? YoutubeFrame(videoUrl: word.youtubeLink)
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
                      Expanded(
                        child: Text(word.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('MÔ TẢ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text(word.description, style: TextStyle(fontSize: 18, color: Colors.grey.shade800, height: 1.5)),
                  const SizedBox(height: 30),
                  const Text('GHI CHÚ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _editNote,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.1)),
                      ),
                      child: Text(
                        _currentNote.isNotEmpty ? _currentNote : 'Chưa có ghi chú. Nhấn để thêm...',
                        style: TextStyle(
                          fontSize: 16,
                          color: _currentNote.isNotEmpty ? AppColors.textDark : Colors.grey,
                          fontStyle: _currentNote.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
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
