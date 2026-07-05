import 'category.dart';

class Place {
  final String id;
  final String name;
  final Category category;
  final Region region;
  final double latitude;
  final double longitude;
  final String coverImageUrl;
  final double? averageRating;
  final int reviewsCount;
  final bool isFavorited;

  // Champs présents uniquement dans la fiche détaillée (PlaceDetailSerializer)
  final String? description;
  final String? address;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.coverImageUrl,
    required this.averageRating,
    required this.reviewsCount,
    required this.isFavorited,
    this.description,
    this.address,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      region: Region.fromJson(json['region'] as Map<String, dynamic>),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      coverImageUrl: (json['cover_image_url'] as String?) ?? '',
      averageRating: json['average_rating'] == null
          ? null
          : double.parse(json['average_rating'].toString()),
      reviewsCount: (json['reviews_count'] as int?) ?? 0,
      isFavorited: (json['is_favorited'] as bool?) ?? false,
      description: json['description'] as String?,
      address: json['address'] as String?,
    );
  }

  /// Copie locale utile après un toggle favori pour rafraîchir l'UI
  /// sans refaire un appel réseau complet.
  Place copyWithFavorited(bool value) {
    return Place(
      id: id,
      name: name,
      category: category,
      region: region,
      latitude: latitude,
      longitude: longitude,
      coverImageUrl: coverImageUrl,
      averageRating: averageRating,
      reviewsCount: reviewsCount,
      isFavorited: value,
      description: description,
      address: address,
    );
  }
}
