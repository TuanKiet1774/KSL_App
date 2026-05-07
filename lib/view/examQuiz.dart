import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/examController.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/exam.dart';
import 'package:ksl/model/question.dart';
import 'package:ksl/model/user.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:ksl/component/confirmDialog.dart';
import 'package:ksl/component/youtubeFrame.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ksl/view/examResult.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExamQuizPage extends StatefulWidget {
  final ExamModel exam;
  const ExamQuizPage({super.key, required this.exam});

  @override
  State<ExamQuizPage> createState() => _ExamQuizPageState();
}

class _ExamQuizPageState extends State<ExamQuizPage> {
  List<QuestionModel> _shuffledQuestions = [];
  int _currentIndex = 0;
  int _timeRemaining = 0;
  Timer? _timer;
  int _totalTimeSpent = 0;
  Map<int, dynamic> _userAnswers = {};
  final TextEditingController _shortAnswerController = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Tạo bản sao và xáo trộn câu hỏi
    _shuffledQuestions = List<QuestionModel>.from(widget.exam.questions);
    _shuffledQuestions.shuffle();
    _startQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _startQuestion() {
    final currentQuestion = _shuffledQuestions[_currentIndex];
    _timeRemaining = currentQuestion.time;
    
    // Cập nhật text controller cho câu hỏi tự luận
    _shortAnswerController.text = _userAnswers[_currentIndex]?.toString() ?? "";
    
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
            _totalTimeSpent++;
          } else {
            _nextQuestion();
          }
        });
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _shuffledQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _startQuestion();
      });
    } else {
      _finishExam();
    }
  }

  Future<void> _finishExam() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    final UserModel? user = await AuthController.getSavedUser();
    if (user == null) return;

    int totalScore = 0;
    int maxScore = 0;
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < _shuffledQuestions.length; i++) {
      final q = _shuffledQuestions[i];
      final answer = _userAnswers[i];
      bool isCorrect = false;
      String userAnswerStr = "";
      String? chosenOptionId;

      if (q.type == 'multiple-choice') {
        if (answer != null && answer is int) {
          final option = q.options[answer];
          isCorrect = option.isCorrect;
          userAnswerStr = option.content;
          // Ở đây có thể bổ sung ID option nếu model có
        }
      } else if (q.type == 'short-answer') {
        userAnswerStr = answer?.toString() ?? "";
        if (q.options.isNotEmpty) {
          // Chuẩn hóa chuỗi: Trim và viết thường
          String normalizedUser = userAnswerStr.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          String normalizedSystem = q.options[0].content.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          isCorrect = normalizedUser == normalizedSystem;
        }
      }

      int points = isCorrect ? q.score : 0;
      totalScore += points;
      maxScore += q.score;

      results.add({
        'questionId': q.id,
        'userAnswer': userAnswerStr,
        'chosenOptionId': chosenOptionId,
        'isCorrect': isCorrect,
        'points': points,
      });
    }

    final submitResult = await ExamController.submitExamResult(
      userId: user.id,
      examId: widget.exam.id,
      results: results,
      totalScore: totalScore,
      maxScore: maxScore,
      timeSpent: _totalTimeSpent,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (submitResult['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultPage(
              exam: widget.exam,
              totalScore: totalScore,
              maxScore: maxScore,
              timeSpent: _totalTimeSpent,
              results: results,
            ),
          ),
        );
      } else {
        MessDialog.showErrorDialog(context, 'Lỗi', submitResult['message']);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_shuffledQuestions.isEmpty) return const SizedBox.shrink();
    final currentQuestion = _shuffledQuestions[_currentIndex];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          'Câu ${_currentIndex + 1} / ${_shuffledQuestions.length}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
             ConfirmDialog.show(
              context, 
              title: 'Thoát bài thi', 
              message: 'Bạn có chắc muốn thoát? Kết quả bài làm của bạn sẽ không được lưu lại.',
              icon: Icons.exit_to_app_rounded,
              onConfirm: () => Navigator.pop(context)
            );
          },
        ),
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
        : Column(
            children: [
              _buildProgressBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimerDisplay(),
                      const SizedBox(height: 20),
                      _buildQuestionCard(currentQuestion),
                      const SizedBox(height: 30),
                      _buildAnswerSection(currentQuestion),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
    );
  }

  Widget _buildProgressBar() {
    double progress = (_currentIndex + 1) / _shuffledQuestions.length;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey.shade200,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
      minHeight: 6,
    );
  }

  Widget _buildTimerDisplay() {
    final currentQuestion = widget.exam.questions[_currentIndex];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, color: _timeRemaining < 10 ? Colors.red : AppColors.primaryTeal),
        const SizedBox(width: 8),
        Text(
          '$_timeRemaining giây',
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: _timeRemaining < 10 ? Colors.red : AppColors.primaryTeal
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    final bool hasYoutube = question.youtubeLink.isNotEmpty && YoutubePlayer.convertUrlToId(question.youtubeLink) != null;
    final bool urlIsYoutube = question.media.url.isNotEmpty && YoutubePlayer.convertUrlToId(question.media.url) != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasYoutube || urlIsYoutube) ...[
            ClipRRect(
              key: ValueKey('yt_${question.id}'),
              borderRadius: BorderRadius.circular(16),
              child: YoutubeFrame(
                videoUrl: hasYoutube ? question.youtubeLink : question.media.url,
                aspectRatio: 1,
              ),
            ),
            const SizedBox(height: 20),
          ] else if (question.media.url.isNotEmpty) ...[
             ClipRRect(
              key: ValueKey('img_${question.id}'),
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  question.media.url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(QuestionModel question) {
    if (question.type == 'multiple-choice') {
      return Column(
        children: List.generate(question.options.length, (index) {
          final option = question.options[index];
          final isSelected = _userAnswers[_currentIndex] == index;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _userAnswers[_currentIndex] = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primaryTeal : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryTeal : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  if (option.media.url.isNotEmpty) ...[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white.withOpacity(0.5) : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: option.media.url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                  ],
                  if (option.content.isNotEmpty)
                    Expanded(
                      child: Text(
                        option.content,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      );
    } else if (question.type == 'short-answer') {
      return Container(
        key: ValueKey('short_${question.id}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _shortAnswerController,
          onChanged: (value) {
            _userAnswers[_currentIndex] = value;
          },
          decoration: const InputDecoration(
            hintText: 'Nhập câu trả lời của bạn...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Loại câu hỏi nhận diện ký hiệu đang được phát triển',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Widget _buildBottomAction() {
    bool isLast = _currentIndex == _shuffledQuestions.length - 1;
    bool hasAnswer = _userAnswers.containsKey(_currentIndex);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasAnswer ? AppColors.primaryTeal : Colors.grey.shade400,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            isLast ? 'Hoàn thành bài thi' : (hasAnswer ? 'Câu tiếp theo' : 'Bỏ qua câu này'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
