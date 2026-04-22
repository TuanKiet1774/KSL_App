class LearnedWordModel {
  final String id;
  final String userId;
  final String wordId;
  final String wordName;
  final String topicId;
  final String topicName;
  final int expGained;
  final DateTime learnedAt;
  final DateTime lastReviewed;

  LearnedWordModel({
    required this.id,
    required this.userId,
    required this.wordId,
    required this.wordName,
    required this.topicId,
    required this.topicName,
    required this.expGained,
    required this.learnedAt,
    required this.lastReviewed,
  });

  factory LearnedWordModel.fromJson(Map<String, dynamic> json) {
    return LearnedWordModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      wordId: json['wordId'] is Map ? json['wordId']['_id'] : (json['wordId'] ?? ''),
      wordName: json['wordId'] is Map ? (json['wordId']['name'] ?? '') : '',
      topicId: json['topicId'] is Map ? json['topicId']['_id'] : (json['topicId'] ?? ''),
      topicName: json['topicId'] is Map ? (json['topicId']['name'] ?? '') : '',
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
      'wordId': wordId,
      'wordName': wordName,
      'topicId': topicId,
      'topicName': topicName,
      'expGained': expGained,
      'learnedAt': learnedAt.toIso8601String(),
      'lastReviewed': lastReviewed.toIso8601String(),
    };
  }
}
