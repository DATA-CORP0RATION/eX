import '../config/api_config.dart';
import '../models/category.dart';
import '../models/place.dart';
import 'api_client.dart';

class TourismService {
  TourismService._();
  static final TourismService instance = TourismService._();

  final _client = ApiClient.instance;

  Future<List<Category>> getCategories() async {
    final res = await _client.get(ApiConfig.categories, auth: false);
    final data = _client.decodeOrThrow(res) as List;
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Region>> getRegions() async {
    final res = await _client.get(ApiConfig.regions, auth: false);
    final data = _client.decodeOrThrow(res) as List;
    return data.map((e) => Region.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/tourism/places/ (paginé, 20/page).
  /// [categorySlug], [regionSlug], [search] sont optionnels.
  /// Retourne tous les lieux en suivant automatiquement la pagination DRF
  /// (nécessaire pour afficher tous les marqueurs sur la carte).
  Future<List<Place>> getPlaces({
    String? categorySlug,
    String? regionSlug,
    String? search,
  }) async {
    final params = <String, String>{};
    if (categorySlug != null) params['category'] = categorySlug;
    if (regionSlug != null) params['region'] = regionSlug;
    if (search != null && search.isNotEmpty) params['search'] = search;

    var url = Uri.parse(ApiConfig.places).replace(queryParameters: params.isEmpty ? null : params).toString();
    final places = <Place>[];

    while (url.isNotEmpty) {
      final res = await _client.get(url, auth: false);
      final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
      final results = data['results'] as List;
      places.addAll(results.map((e) => Place.fromJson(e as Map<String, dynamic>)));
      url = (data['next'] as String?) ?? '';
    }

    return places;
  }

  Future<Place> getPlaceDetail(String id) async {
    final res = await _client.get(ApiConfig.placeDetail(id), auth: false);
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return Place.fromJson(data);
  }
}
