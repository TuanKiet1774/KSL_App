class TopicModel {
  final String id;
  final String name;
  final String level;
  final String description;
  final String image;
  final int expRequired;
  final int totalWord;

  TopicModel({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
    required this.image,
    required this.expRequired,
    required this.totalWord,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      level: json['level'] ?? 'Beginner',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      expRequired: json['expRequired'] ?? 0,
      totalWord: json['totalWord'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'level': level,
      'description': description,
      'image': image,
      'expRequired': expRequired,
      'totalWord': totalWord,
    };
  }
}
