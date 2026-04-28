class WordModel {
  final String id;
  final String name;
  final String description;
  final WordMedia media;
  final String youtubeLink;
  final int exp;
  final String topicId;
  bool isFavorite; // Trạng thái yêu thích
  bool isLearned;  // Trạng thái đã học

  WordModel({
    required this.id,
    required this.name,
    required this.description,
    required this.media,
    this.youtubeLink = '',
    required this.exp,
    required this.topicId,
    this.isFavorite = false,
    this.isLearned = false,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      media: WordMedia.fromJson(json['media'] ?? {}),
      youtubeLink: json['youtubeLink'] ?? '',
      exp: json['exp'] ?? 5,
      topicId: json['topicId'] is Map 
          ? (json['topicId']['_id'] ?? json['topicId']['id'] ?? '') 
          : (json['topicId'] ?? ''),
      isFavorite: json['isFavorite'] == true,
      isLearned: json['isLearned'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'media': media.toJson(),
      'youtubeLink': youtubeLink,
      'exp': exp,
      'topicId': topicId,
      'isFavorite': isFavorite,
      'isLearned': isLearned,
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
