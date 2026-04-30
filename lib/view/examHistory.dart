import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/examController.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/examResult.dart';
import 'package:intl/intl.dart';

import 'package:ksl/model/exam.dart';
import 'package:ksl/view/examResult.dart';
import 'package:ksl/component/messDialog.dart';

import '../component/confirmDialog.dart';

class ExamHistoryPage extends StatefulWidget {
  const ExamHistoryPage({super.key});

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  List<ExamResultModel> _history = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final user = await AuthController.getSavedUser();
    if (user == null) return;

    final result = await ExamController.getUserResults(user.id);
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _history = result['data'];
          _history.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        } else {
          _errorMessage = result['message'];
        }
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "N/A";
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes}p ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Lịch sử bài thi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              onPressed: _showClearHistoryConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _history.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchHistory,
                              color: AppColors.primaryTeal,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  return _buildDismissibleCard(_history[index], index);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDismissibleCard(ExamResultModel result, int index) {
    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
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
        return await _showDeleteConfirmation(result);
      },
      onDismissed: (direction) {
        _deleteSingleResult(result.id, index);
      },
      child: _buildHistoryCard(result),
    );
  }

  Future<bool?> _showDeleteConfirmation(ExamResultModel result) async {
    bool? confirmed;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmDialog(
        title: 'Xóa lịch sử',
        message: 'Bạn có chắc chắn muốn xóa kết quả bài thi này không?',
        icon: Icons.delete_outline_rounded,
        color: Colors.redAccent,
        onConfirm: () {
          confirmed = true;
        },
      ),
    );
    return confirmed;
  }

  void _showClearHistoryConfirmation() {
    ConfirmDialog.show(
      context,
      title: 'Xóa tất cả',
      message: 'Bạn có chắc chắn muốn xóa toàn bộ lịch sử bài thi không?',
      icon: Icons.delete_sweep_rounded,
      color: Colors.redAccent,
      confirmText: 'Xóa hết',
      onConfirm: _clearAllHistory,
    );
  }

  Future<void> _deleteSingleResult(String id, int index) async {
    final result = await ExamController.deleteResult(id);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _history.removeAt(index);
        });
        MessDialog.showSuccessDialog(context, 'Thành công', 'Đã xóa kết quả bài thi');
      } else {
        MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
        _fetchHistory();
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final user = await AuthController.getSavedUser();
    if (user == null) return;

    setState(() => _isLoading = true);
    final result = await ExamController.clearHistory(user.id);
    
    if (mounted) {
      if (result['success']) {
        setState(() {
          _history.clear();
          _isLoading = false;
        });
        MessDialog.showSuccessDialog(context, 'Thành công', 'Đã xóa toàn bộ lịch sử');
      } else {
        setState(() => _isLoading = false);
        MessDialog.showErrorDialog(context, 'Lỗi', result['message']);
      }
    }
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
            'assets/lichsubaithi.png',
            height: 150,
            width: 150,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.history_rounded, size: 100, color: Colors.white24),
          ),
          const SizedBox(height: 15),
          const Text(
            'Kết quả rèn luyện của bạn',
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

  Widget _buildHistoryCard(ExamResultModel result) {
    double accuracy = result.maxScore > 0 ? (result.totalScore / result.maxScore) * 100 : 0;
    Color statusColor = accuracy >= 80 ? Colors.green : (accuracy >= 50 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Hiển thị loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
              );

              final examResult = await ExamController.getExamById(result.examId);
              
              if (mounted) {
                Navigator.pop(context);

                if (examResult['success']) {
                  final exam = examResult['data'] as ExamModel;
                  
                  // Chuyển đổi format kết quả
                  final List<Map<String, dynamic>> formattedResults = result.results.map((r) => {
                    'questionId': r.questionId,
                    'userAnswer': r.userAnswer,
                    'chosenOptionId': r.chosenOptionId,
                    'isCorrect': r.isCorrect,
                    'points': r.points,
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamResultPage(
                        exam: exam,
                        totalScore: result.totalScore,
                        maxScore: result.maxScore,
                        timeSpent: result.timeSpent,
                        results: formattedResults,
                      ),
                    ),
                  );
                } else {
                  MessDialog.showErrorDialog(context, 'Lỗi', 'Không thể tải thông tin bài thi: ${examResult['message']}');
                }
              }
            },
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    color: statusColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  result.examTitle.isNotEmpty ? result.examTitle : 'Bài thi không xác định',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primaryBlue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDate(result.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoItem(Icons.star_rounded, '${result.totalScore}/${result.maxScore}', Colors.orange),
                              const SizedBox(width: 20),
                              _buildInfoItem(Icons.timer_rounded, _formatTime(result.timeSpent), Colors.blue),
                              const SizedBox(width: 20),
                              _buildInfoItem(Icons.percent_rounded, '${accuracy.toStringAsFixed(0)}%', statusColor),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildInfoItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchHistory,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
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
          Text(
            'Bạn chưa tham gia bài thi nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
