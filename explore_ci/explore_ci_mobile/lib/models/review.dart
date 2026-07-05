class Review {
  final String id;
  final String placeId;
  final String userEmail;
  final String userFirstName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.placeId,
    required this.userEmail,
    required this.userFirstName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      placeId: json['place'].toString(),
      userEmail: (json['user_email'] as String?) ?? '',
      userFirstName: (json['user_first_name'] as String?) ?? '',
      rating: json['rating'] as int,
      comment: (json['comment'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
