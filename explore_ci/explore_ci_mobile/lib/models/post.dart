class PostImage {
  final String id;
  final String imageUrl;
  final int position;

  PostImage({required this.id, required this.imageUrl, required this.position});

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'].toString(),
      imageUrl: json['image_url'] as String,
      position: (json['position'] as int?) ?? 0,
    );
  }
}

class Post {
  final String id;
  final String userId;
  final String userFirstName;
  final String? placeId;
  final String? placeName;
  final String content;
  final List<PostImage> images;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.userFirstName,
    required this.placeId,
    required this.placeName,
    required this.content,
    required this.images,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user'].toString(),
      userFirstName: (json['user_first_name'] as String?) ?? '',
      placeId: json['place'] as String?,
      placeName: json['place_name'] as String?,
      content: json['content'] as String,
      images: (json['images'] as List? ?? [])
          .map((e) => PostImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      likesCount: (json['likes_count'] as int?) ?? 0,
      commentsCount: (json['comments_count'] as int?) ?? 0,
      isLiked: (json['is_liked'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Copie locale utile après un toggle j'aime pour rafraîchir l'UI
  /// sans refaire un appel réseau complet.
  Post copyWithLiked(bool value, {required int newLikesCount}) {
    return Post(
      id: id,
      userId: userId,
      userFirstName: userFirstName,
      placeId: placeId,
      placeName: placeName,
      content: content,
      images: images,
      likesCount: newLikesCount,
      commentsCount: commentsCount,
      isLiked: value,
      createdAt: createdAt,
    );
  }
}

class PostComment {
  final String id;
  final String postId;
  final String userFirstName;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userFirstName,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'].toString(),
      postId: json['post'].toString(),
      userFirstName: (json['user_first_name'] as String?) ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
