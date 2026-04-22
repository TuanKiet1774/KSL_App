import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:ksl/controller/auth_controller.dart';
import 'package:ksl/controller/feedback_controller.dart';
import 'package:intl/intl.dart';
import 'package:ksl/model/feedback.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      MessDialog.showInfoDialog(
        context,
        'Thông báo',
        'Vui lòng chọn số sao đánh giá',
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      MessDialog.showInfoDialog(
        context,
        'Thông báo',
        'Vui lòng nhập ý kiến đóng góp của bạn',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthController.getSavedUser();
      if (user == null) {
        if (mounted) {
          MessDialog.showErrorDialog(
            context,
            'Lỗi',
            'Bạn cần đăng nhập để thực hiện chức năng này',
          );
        }
        return;
      }

      final result = await FeedbackController.sendFeedback(
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          MessDialog.showSuccessDialog(
            context,
            'Thành công',
            'Cảm ơn ý kiến đóng góp của bạn!',
          );
          _commentController.clear();
          setState(() {
            _rating = 0;
          });
        } else {
          MessDialog.showErrorDialog(
            context,
            'Lỗi',
            result['message'] ?? 'Gửi phản hồi thất bại',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text(
          'Đánh giá & Phản hồi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Lịch sử đánh giá',
            onPressed: () => _showHistoryModal(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRatingCard(),
                  const SizedBox(height: 20),
                  _buildCommentCard(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
            'assets/danhgia.png',
            height: 150,
            width: 150,
          ),
          const Text(
            'Ý kiến của bạn rất quan trọng!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy cho chúng tôi biết cảm nhận của bạn để ứng dụng ngày càng hoàn thiện hơn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Điểm đánh giá',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: index < _rating ? AppColors.accentOrange : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getRatingText(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _rating > 0 ? AppColors.accentOrange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1: return 'Tệ';
      case 2: return 'Không hài lòng';
      case 3: return 'Bình thường';
      case 4: return 'Tốt';
      case 5: return 'Rất tuyệt vời!';
      default: return 'Chọn số sao';
    }
  }

  Widget _buildCommentCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 5,
        maxLength: 1000,
        decoration: InputDecoration(
          hintText: 'Nhập ý kiến đóng góp của bạn tại đây...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          counterStyle: TextStyle(color: Colors.grey.shade400),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.primaryBlue,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitFeedback,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: AppColors.primaryTeal.withOpacity(0.4),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Gửi đánh giá',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lịch sử đánh giá',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: FeedbackController.getFeedbackHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryTeal),
                    );
                  }

                  if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data!['success'] == false) {
                    return Center(
                      child: Text(
                        'Không thể tải lịch sử đánh giá',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    );
                  }

                  final List<FeedbackModel> history = snapshot.data!['data'] ?? [];

                  if (history.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Bạn chưa có đánh giá nào',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final rating = item.rating;
                      final comment = item.comment;
                      final dateStr = item.createdAt;
                      String formattedDate = 'N/A';
                      if (dateStr.isNotEmpty) {
                        try {
                          final date = DateTime.parse(dateStr);
                          formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                        } catch (_) {}
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 18,
                                      color: i < rating ? AppColors.accentOrange : Colors.grey.shade300,
                                    );
                                  }),
                                ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              comment,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryBlue,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
