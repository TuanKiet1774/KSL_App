import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/provider/examProvider.dart';
import 'package:ksl/provider/progressProvider.dart';
import 'package:ksl/model/exam.dart';
import 'package:ksl/model/progress.dart';
import 'package:ksl/view/examQuiz.dart';
import 'package:ksl/component/messDialog.dart';

class ExamListPage extends StatefulWidget {
  const ExamListPage({super.key});

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().fetchExams();
    });
  }

  List<ExamModel> _filteredExams(List<ExamModel> exams) {
    if (_searchQuery.isEmpty) return exams;
    return exams.where((exam) =>
      exam.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      exam.description.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final filteredExams = _filteredExams(examProvider.exams);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Danh sách bài thi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: examProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : filteredExams.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => context.read<ExamProvider>().fetchExams(),
                        color: AppColors.primaryTeal,
                        child: _buildExamList(filteredExams),
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
      child: Container(
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
            setState(() => _searchQuery = value);
          },
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm bài thi...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            icon: Icon(Icons.search_rounded, color: AppColors.primaryTeal),
          ),
        ),
      ),
    );
  }

  Widget _buildExamList(List<ExamModel> exams) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        return _buildExamCard(exams[index]);
      },
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
              );

              final examProvider = context.read<ExamProvider>();
              final progressProvider = context.read<ProgressProvider>();

              await examProvider.fetchExamById(exam.id);
              final fullExam = examProvider.currentExam;

              if (mounted) {
                if (fullExam != null) {
                  if (fullExam.questions.isEmpty) {
                    Navigator.pop(context); // Đóng loading
                    MessDialog.showInfoDialog(context, 'Thông báo', 'Bài thi này hiện chưa có câu hỏi nào.');
                    return;
                  }

                  await progressProvider.fetchUserProgress();
                  final progress = progressProvider.userProgress;

                  if (mounted) {
                    Navigator.pop(context);

                    if (progress != null) {
                      
                      final examTopicIds = fullExam.questions
                          .map((q) => q.topicId)
                          .where((id) => id.isNotEmpty)
                          .toSet();
                      
                      bool allTopicsCompleted = true;
                      List<String> uncompletedTopics = [];

                      for (var topicId in examTopicIds) {
                        final topicProg = progress.topicProgress.firstWhere(
                          (tp) => tp.topicId.toString().trim() == topicId.toString().trim(),
                          orElse: () => TopicProgressModel(
                            topicId: topicId, 
                            topicName: 'Chủ đề chưa học', 
                            percentage: 0,
                            learnedWordsCount: 0,
                            lastUpdated: '',
                          ),
                        );

                        if (topicProg.percentage < 99.9) {
                          allTopicsCompleted = false;
                          uncompletedTopics.add(topicProg.topicName);
                        }
                      }

                      if (!allTopicsCompleted && examTopicIds.isNotEmpty) {
                        // Liệt kê các chủ đề chưa xong xuống dòng với dấu gạch đầu dòng
                        String topicsStr = uncompletedTopics.take(5).map((e) => '- $e').join('\n');
                        if (uncompletedTopics.length > 5) topicsStr += '\n- ...';
                        
                        MessDialog.showInfoDialog(
                          context, 
                          'Chú ý',
                          'Bạn cần hoàn thiện 100% các chủ đề liên quan trước khi làm bài kiểm tra này.\n\nCác chủ đề chưa xong:\n$topicsStr',
                          textAlign: TextAlign.left,
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamQuizPage(exam: fullExam),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamQuizPage(exam: fullExam),
                        ),
                      );
                    }
                  }
                } else {
                  Navigator.pop(context); // Đóng loading
                  MessDialog.showErrorDialog(context, 'Lỗi', 'Không thể lấy chi tiết bài thi');
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam.description.isNotEmpty ? exam.description : 'Không có mô tả',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.help_outline_rounded, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${exam.questions.length} câu hỏi',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Không tìm thấy bài thi nào',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
