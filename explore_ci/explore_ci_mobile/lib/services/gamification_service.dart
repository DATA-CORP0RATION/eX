import '../config/api_config.dart';
import '../models/gamification.dart';
import 'api_client.dart';

class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  final _client = ApiClient.instance;

  /// GET /api/gamification/challenges/ — liste des défis actifs avec la
  /// progression de l'utilisateur connecté (0 si non connecté).
  Future<List<Challenge>> getChallenges() async {
    var url = ApiConfig.challenges;
    final challenges = <Challenge>[];

    while (url.isNotEmpty) {
      final res = await _client.get(url, auth: false);
      final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
      final results = data['results'] as List;
      challenges.addAll(results.map((e) => Challenge.fromJson(e as Map<String, dynamic>)));
      url = (data['next'] as String?) ?? '';
    }

    return challenges;
  }

  /// GET /api/gamification/badges/mine/ — badges débloqués par l'utilisateur connecté.
  Future<List<UserBadge>> getMyBadges() async {
    final res = await _client.get(ApiConfig.myBadges);
    final data = _client.decodeOrThrow(res);
    final list = data is Map<String, dynamic> ? data['results'] as List : data as List;
    return list.map((e) => UserBadge.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/gamification/badges/ — catalogue complet (débloqués + à débloquer).
  Future<List<AppBadge>> getAllBadges() async {
    final res = await _client.get(ApiConfig.allBadges, auth: false);
    final data = _client.decodeOrThrow(res);
    final list = data is Map<String, dynamic> ? data['results'] as List : data as List;
    return list.map((e) => AppBadge.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/gamification/profile/ — XP, niveau, visites, badges, progression.
  Future<ProfileStats> getProfileStats() async {
    final res = await _client.get(ApiConfig.profileStats);
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return ProfileStats.fromJson(data);
  }

  /// GET /api/gamification/visits/mine/ — lieux visités par l'utilisateur connecté.
  Future<List<Visit>> getMyVisits() async {
    final res = await _client.get(ApiConfig.myVisits);
    final data = _client.decodeOrThrow(res);
    final list = data is Map<String, dynamic> ? data['results'] as List : data as List;
    return list.map((e) => Visit.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/gamification/places/<id>/visit/ — bascule visité/non visité.
  /// Retourne le nouvel état (true = visité).
  Future<bool> toggleVisit(String placeId) async {
    final res = await _client.post(ApiConfig.toggleVisit(placeId));
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return data['visited'] as bool;
  }
}
