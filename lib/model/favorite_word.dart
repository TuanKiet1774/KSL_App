import 'package:ksl/model/word.dart';
import 'package:ksl/model/topic.dart';

class FavoriteWordModel {
  final String id;
  final String userId;
  final WordModel? wordId;
  final TopicModel? topicId;
  final String note;
  final DateTime createdAt;

  FavoriteWordModel({
    required this.id,
    required this.userId,
    this.wordId,
    this.topicId,
    this.note = '',
    required this.createdAt,
  });

  factory FavoriteWordModel.fromJson(Map<String, dynamic> json) {
    return FavoriteWordModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      wordId: json['wordId'] is Map ? WordModel.fromJson(json['wordId']) : null,
      topicId: json['topicId'] is Map ? TopicModel.fromJson(json['topicId']) : null,
      note: json['note'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'wordId': wordId?.toJson(),
      'topicId': topicId?.toJson(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
