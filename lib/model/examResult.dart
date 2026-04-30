import 'package:ksl/model/question.dart';

class ExamResultModel {
  final String id;
  final String userId;
  final String examId;
  final String examTitle;
  final List<QuestionResultModel> results;
  final int totalScore;
  final int maxScore;
  final int timeSpent; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExamResultModel({
    required this.id,
    required this.userId,
    required this.examId,
    this.examTitle = '',
    required this.results,
    required this.totalScore,
    required this.maxScore,
    required this.timeSpent,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    String eTitle = '';
    if (json['examId'] is Map) {
      eTitle = json['examId']['title'] ?? '';
    }

    return ExamResultModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId'] is Map 
          ? (json['userId']['_id'] ?? json['userId']['id'] ?? '') 
          : (json['userId']?.toString() ?? ''),
      examId: json['examId'] is Map 
          ? (json['examId']['_id'] ?? json['examId']['id'] ?? '') 
          : (json['examId']?.toString() ?? ''),
      examTitle: eTitle,
      results: (json['results'] as List? ?? [])
          .map((item) => QuestionResultModel.fromJson(item))
          .toList(),
      totalScore: json['totalScore'] ?? 0,
      maxScore: json['maxScore'] ?? 0,
      timeSpent: json['timeSpent'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'examId': examId,
      'examTitle': examTitle,
      'results': results.map((e) => e.toJson()).toList(),
      'totalScore': totalScore,
      'maxScore': maxScore,
      'timeSpent': timeSpent,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class QuestionResultModel {
  final String questionId;
  final String userAnswer;
  final String? chosenOptionId;
  final bool isCorrect;
  final int points;

  QuestionResultModel({
    required this.questionId,
    required this.userAnswer,
    this.chosenOptionId,
    required this.isCorrect,
    required this.points,
  });

  factory QuestionResultModel.fromJson(Map<String, dynamic> json) {
    return QuestionResultModel(
      questionId: json['questionId'] is Map 
          ? (json['questionId']['_id'] ?? json['questionId']['id'] ?? '') 
          : (json['questionId']?.toString() ?? ''),
      userAnswer: json['userAnswer'] ?? '',
      chosenOptionId: json['chosenOptionId']?.toString(),
      isCorrect: json['isCorrect'] ?? false,
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'chosenOptionId': chosenOptionId,
      'isCorrect': isCorrect,
      'points': points,
    };
  }
}
