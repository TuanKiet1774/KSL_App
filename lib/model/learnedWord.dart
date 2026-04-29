import 'package:ksl/model/word.dart';
import 'package:ksl/model/topic.dart';

class LearnedWordModel {
  final String id;
  final String userId;
  final WordModel? wordId; // Populated word data
  final TopicModel? topicId; // Populated topic data
  final int expGained;
  final DateTime learnedAt;
  final DateTime lastReviewed;

  LearnedWordModel({
    required this.id,
    required this.userId,
    this.wordId,
    this.topicId,
    required this.expGained,
    required this.learnedAt,
    required this.lastReviewed,
  });

  factory LearnedWordModel.fromJson(Map<String, dynamic> json) {
    return LearnedWordModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      wordId: json['wordId'] != null ? WordModel.fromJson(json['wordId']) : null,
      topicId: json['topicId'] != null ? TopicModel.fromJson(json['topicId']) : null,
      expGained: json['expGained'] ?? 0,
      learnedAt: json['learnedAt'] != null 
          ? DateTime.parse(json['learnedAt']) 
          : DateTime.now(),
      lastReviewed: json['lastReviewed'] != null 
          ? DateTime.parse(json['lastReviewed']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'wordId': wordId?.toJson(),
      'topicId': topicId?.toJson(),
      'expGained': expGained,
      'learnedAt': learnedAt.toIso8601String(),
      'lastReviewed': lastReviewed.toIso8601String(),
    };
  }
}
