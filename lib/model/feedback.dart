class FeedbackModel {
  final String id;
  final String userId;
  final int rating;
  final String comment;
  final String status;
  final String createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
