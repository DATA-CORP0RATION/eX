import '../config/api_config.dart';
import '../models/favorite.dart';
import '../models/review.dart';
import 'api_client.dart';

class InteractionsService {
  InteractionsService._();
  static final InteractionsService instance = InteractionsService._();

  final _client = ApiClient.instance;

  /// POST /api/tourism/places/<id>/favorite/ — bascule favori/non-favori.
  /// Retourne le nouvel état (true = ajouté aux favoris).
  Future<bool> toggleFavorite(String placeId) async {
    final res = await _client.post(ApiConfig.toggleFavorite(placeId));
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return data['favorited'] as bool;
  }

  /// GET /api/tourism/favorites/ — favoris de l'utilisateur connecté.
  Future<List<FavoriteItem>> getFavorites() async {
    final res = await _client.get(ApiConfig.favorites);
    final data = _client.decodeOrThrow(res);
    // Pagination DRF possible (results) ou liste simple selon config.
    final list = data is Map<String, dynamic> ? data['results'] as List : data as List;
    return list.map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/tourism/places/<id>/reviews/ — avis publics d'un lieu.
  Future<List<Review>> getReviews(String placeId) async {
    final res = await _client.get(ApiConfig.reviews(placeId), auth: false);
    final data = _client.decodeOrThrow(res) as List;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/tourism/places/<id>/reviews/ — dépose un avis (un seul par lieu).
  Future<Review> postReview(String placeId, {required int rating, String comment = ''}) async {
    final res = await _client.post(
      ApiConfig.reviews(placeId),
      body: {'rating': rating, 'comment': comment},
    );
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return Review.fromJson(data);
  }

  /// GET /api/tourism/places/<id>/reviews/me/ — mon avis existant sur ce lieu (404 si aucun).
  Future<Review?> getMyReview(String placeId) async {
    final res = await _client.get(ApiConfig.myReview(placeId));
    if (res.statusCode == 404) return null;
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return Review.fromJson(data);
  }

  /// PATCH /api/tourism/places/<id>/reviews/me/ — modifie mon avis existant.
  Future<Review> updateMyReview(String placeId, {required int rating, String comment = ''}) async {
    final res = await _client.patch(
      ApiConfig.myReview(placeId),
      body: {'rating': rating, 'comment': comment},
    );
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return Review.fromJson(data);
  }
}
