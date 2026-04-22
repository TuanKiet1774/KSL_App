class ProgressModel {
  final String userId;
  final List<TopicProgressModel> topicProgress;
  final double averageTestScore;
  final List<AccessHistoryModel> accessHistory;

  ProgressModel({
    required this.userId,
    required this.topicProgress,
    required this.averageTestScore,
    required this.accessHistory,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      userId: json['userId'] ?? '',
      topicProgress: (json['topicProgress'] as List? ?? [])
          .map((item) => TopicProgressModel.fromJson(item))
          .toList(),
      averageTestScore: (json['averageTestScore'] as num? ?? 0).toDouble(),
      accessHistory: (json['accessHistory'] as List? ?? [])
          .map((item) => AccessHistoryModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'topicProgress': topicProgress.map((item) => item.toJson()).toList(),
      'averageTestScore': averageTestScore,
      'accessHistory': accessHistory.map((item) => item.toJson()).toList(),
    };
  }
}

class TopicProgressModel {
  final String topicId;
  final int learnedWordsCount;
  final double percentage;
  final String lastUpdated;

  TopicProgressModel({
    required this.topicId,
    required this.learnedWordsCount,
    required this.percentage,
    required this.lastUpdated,
  });

  factory TopicProgressModel.fromJson(Map<String, dynamic> json) {
    // topicId có thể là String hoặc Object (nếu được populate)
    String tId = '';
    if (json['topicId'] is String) {
      tId = json['topicId'];
    } else if (json['topicId'] is Map) {
      tId = json['topicId']['_id'] ?? '';
    }

    return TopicProgressModel(
      topicId: tId,
      learnedWordsCount: json['learnedWordsCount'] ?? 0,
      percentage: (json['percentage'] as num? ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'learnedWordsCount': learnedWordsCount,
      'percentage': percentage,
      'lastUpdated': lastUpdated,
    };
  }
}

class AccessHistoryModel {
  final String sessionStart;
  final String? sessionEnd;
  final int duration;

  AccessHistoryModel({
    required this.sessionStart,
    this.sessionEnd,
    required this.duration,
  });

  factory AccessHistoryModel.fromJson(Map<String, dynamic> json) {
    return AccessHistoryModel(
      sessionStart: json['sessionStart'] ?? '',
      sessionEnd: json['sessionEnd'],
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionStart': sessionStart,
      'sessionEnd': sessionEnd,
      'duration': duration,
    };
  }
}
