class FavoriteItem {
  final String id;
  final String placeId;
  final String placeName;
  final DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'].toString(),
      placeId: json['place'].toString(),
      placeName: (json['place_name'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
