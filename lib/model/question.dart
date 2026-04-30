class QuestionModel {
  final String id;
  final String question;
  final String type; // multiple-choice, short-answer, recognition
  final String difficulty; // easy, medium, hard
  final MediaModel media;
  final List<OptionModel> options;
  final String topicId;
  final String youtubeLink;
  final int score;
  final int time;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuestionModel({
    required this.id,
    required this.question,
    required this.type,
    required this.difficulty,
    required this.media,
    required this.options,
    required this.topicId,
    this.youtubeLink = '',
    required this.score,
    required this.time,
    this.createdAt,
    this.updatedAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      type: json['type'] ?? 'multiple-choice',
      difficulty: json['difficulty'] ?? 'easy',
      media: MediaModel.fromJson(json['media'] ?? {}),
      options: (json['options'] as List? ?? [])
          .map((item) => OptionModel.fromJson(item))
          .toList(),
      topicId: json['topicId'] is Map 
          ? (json['topicId']['_id'] ?? json['topicId']['id'] ?? '') 
          : (json['topicId']?.toString() ?? ''),
      youtubeLink: json['youtubeLink'] ?? '',
      score: json['score'] ?? 1,
      time: json['time'] ?? 30,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': question,
      'type': type,
      'difficulty': difficulty,
      'media': media.toJson(),
      'options': options.map((e) => e.toJson()).toList(),
      'topicId': topicId,
      'youtubeLink': youtubeLink,
      'score': score,
      'time': time,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class MediaModel {
  final String url;
  final String type; // image, gif, video, none

  MediaModel({
    required this.url,
    required this.type,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      url: json['url'] ?? '',
      type: json['type'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
    };
  }
}

class OptionModel {
  final String content;
  final MediaModel media;
  final bool isCorrect;

  OptionModel({
    required this.content,
    required this.media,
    required this.isCorrect,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      content: json['content'] ?? '',
      media: MediaModel.fromJson(json['media'] ?? {}),
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'media': media.toJson(),
      'isCorrect': isCorrect,
    };
  }
}
