class WordModel {
  final String id;
  final String name;
  final String description;
  final WordMedia media;
  final int exp;
  final String topicId;

  WordModel({
    required this.id,
    required this.name,
    required this.description,
    required this.media,
    required this.exp,
    required this.topicId,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      media: WordMedia.fromJson(json['media'] ?? {}),
      exp: json['exp'] ?? 5,
      topicId: json['topicId'] is Map ? json['topicId']['_id'] : (json['topicId'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'media': media.toJson(),
      'exp': exp,
      'topicId': topicId,
    };
  }
}

class WordMedia {
  final String url;
  final String type;

  WordMedia({
    required this.url,
    required this.type,
  });

  factory WordMedia.fromJson(Map<String, dynamic> json) {
    return WordMedia(
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
    };
  }
}
