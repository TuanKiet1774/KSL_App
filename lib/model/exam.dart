import 'package:ksl/model/question.dart';

class ExamModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExamModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questions: (json['questions'] as List? ?? []).map((item) {
        if (item is Map<String, dynamic>) {
          return QuestionModel.fromJson(item);
        } else {
          // Trường hợp chỉ có ID (chưa populate)
          return QuestionModel(
            id: item.toString(),
            question: '',
            type: 'multiple-choice',
            difficulty: 'easy',
            media: MediaModel(url: '', type: 'none'),
            options: [],
            topicId: '',
            score: 1,
            time: 30,
          );
        }
      }).toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'questions': questions.map((e) => e.id).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
