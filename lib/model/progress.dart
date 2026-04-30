class ProgressModel {
  final String userId;
  final List<TopicProgressModel> topicProgress;
  final double averageTestScore;
  final List<AccessHistoryModel> accessHistory;
  final StatsModel stats;

  ProgressModel({
    required this.userId,
    required this.topicProgress,
    required this.averageTestScore,
    required this.accessHistory,
    required this.stats,
  });

  factory ProgressModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProgressModel(
        userId: '',
        topicProgress: [],
        averageTestScore: 0.0,
        accessHistory: [],
        stats: StatsModel.fromJson(null),
      );
    }
    return ProgressModel(
      userId: _parseUserId(json['userId']),
      topicProgress: (json['topicProgress'] as List? ?? [])
          .map((item) => TopicProgressModel.fromJson(item as Map<String, dynamic>?))
          .toList(),
      averageTestScore: (json['averageTestScore'] as num? ?? 0).toDouble(),
      accessHistory: (json['accessHistory'] as List? ?? [])
          .map((item) => AccessHistoryModel.fromJson(item as Map<String, dynamic>?))
          .toList(),
      stats: StatsModel.fromJson(json['stats'] as Map<String, dynamic>?),
    );
  }

  static String _parseUserId(dynamic userId) {
    if (userId == null) return '';
    if (userId is String) return userId;
    if (userId is Map) return userId['_id']?.toString() ?? '';
    return userId.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'topicProgress': topicProgress.map((item) => item.toJson()).toList(),
      'averageTestScore': averageTestScore,
      'accessHistory': accessHistory.map((item) => item.toJson()).toList(),
      'stats': stats.toJson(),
    };
  }
}

class StatsModel {
  final int totalExp;
  final int streakDays;
  final int maxStreak;
  final int totalWordsLearned;
  final double totalLearningMinutes;
  final int dailyGoal;
  final String lastActivity;

  StatsModel({
    required this.totalExp,
    required this.streakDays,
    required this.maxStreak,
    required this.totalWordsLearned,
    required this.totalLearningMinutes,
    required this.dailyGoal,
    required this.lastActivity,
  });

  factory StatsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StatsModel(
        totalExp: 0,
        streakDays: 0,
        maxStreak: 0,
        totalWordsLearned: 0,
        totalLearningMinutes: 0.0,
        dailyGoal: 10,
        lastActivity: '',
      );
    }
    return StatsModel(
      totalExp: _toInt(json['totalExp']),
      streakDays: _toInt(json['streakDays']),
      maxStreak: _toInt(json['maxStreak']),
      totalWordsLearned: _toInt(json['totalWordsLearned']),
      totalLearningMinutes: _toDouble(json['totalLearningMinutes']),
      dailyGoal: _toInt(json['dailyGoal'], defaultValue: 10),
      lastActivity: json['lastActivity']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double _toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalExp': totalExp,
      'streakDays': streakDays,
      'maxStreak': maxStreak,
      'totalWordsLearned': totalWordsLearned,
      'totalLearningMinutes': totalLearningMinutes,
      'dailyGoal': dailyGoal,
      'lastActivity': lastActivity,
    };
  }
}

class TopicProgressModel {
  final String topicId;
  final String topicName;
  final int learnedWordsCount;
  final double percentage;
  final String lastUpdated;

  TopicProgressModel({
    required this.topicId,
    required this.topicName,
    required this.learnedWordsCount,
    required this.percentage,
    required this.lastUpdated,
  });

  factory TopicProgressModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TopicProgressModel(
        topicId: '',
        topicName: '',
        learnedWordsCount: 0,
        percentage: 0.0,
        lastUpdated: '',
      );
    }
    
    String tId = '';
    String tName = '';
    
    final topicIdData = json['topicId'];
    if (topicIdData is String) {
      tId = topicIdData;
      tName = 'Chủ đề ${tId.length > 4 ? tId.substring(tId.length - 4) : tId}';
    } else if (topicIdData is Map) {
      tId = topicIdData['_id']?.toString() ?? '';
      tName = topicIdData['name']?.toString() ?? '';
    }

    return TopicProgressModel(
      topicId: tId,
      topicName: tName,
      learnedWordsCount: (json['learnedWordsCount'] as num? ?? 0).toInt(),
      percentage: (json['percentage'] as num? ?? 0).toDouble(),
      lastUpdated: json['lastUpdated']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'learnedWordsCount': learnedWordsCount,
      'percentage': percentage,
      'lastUpdated': lastUpdated,
    };
  }
}

class AccessHistoryModel {
  final String sessionStart;
  final String? sessionEnd;
  final double duration;

  AccessHistoryModel({
    required this.sessionStart,
    this.sessionEnd,
    required this.duration,
  });

  factory AccessHistoryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AccessHistoryModel(sessionStart: '', duration: 0.0);
    }
    return AccessHistoryModel(
      sessionStart: json['sessionStart']?.toString() ?? '',
      sessionEnd: json['sessionEnd']?.toString(),
      duration: (json['duration'] as num? ?? 0.0).toDouble(),
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
