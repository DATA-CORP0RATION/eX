/// Configuration de l'API backend ExploreCI.
///
/// IMPORTANT (Semaine 2) : remplacer [baseUrl] par l'URL de déploiement
/// (Render / Railway / Heroku) une fois le backend en ligne.
class ApiConfig {
  ApiConfig._();

  /// URL de base du backend Django.
  ///
  /// - Émulateur Android -> 10.0.2.2 pointe vers le localhost de la machine hôte.
  /// - Simulateur iOS / Flutter Web -> utiliser http://127.0.0.1:8000
  /// - Appareil physique -> utiliser l'IP locale de la machine (ex: http://192.168.1.10:8000)
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Auth
  static const String register = '$baseUrl/auth/register/';
  static const String login = '$baseUrl/auth/login/';
  static const String tokenRefresh = '$baseUrl/auth/token/refresh/';
  static const String me = '$baseUrl/auth/me/';

  // Tourisme
  static const String categories = '$baseUrl/tourism/categories/';
  static const String regions = '$baseUrl/tourism/regions/';
  static const String places = '$baseUrl/tourism/places/';
  static String placeDetail(String id) => '$baseUrl/tourism/places/$id/';

  // Favoris & Avis
  static const String favorites = '$baseUrl/tourism/favorites/';
  static String toggleFavorite(String placeId) =>
      '$baseUrl/tourism/places/$placeId/favorite/';
  static String reviews(String placeId) =>
      '$baseUrl/tourism/places/$placeId/reviews/';
  static String myReview(String placeId) =>
      '$baseUrl/tourism/places/$placeId/reviews/me/';

  // Calendrier des événements
  static const String events = '$baseUrl/events/';
  static const String myEventParticipations = '$baseUrl/events/mine/';
  static String eventDetail(String id) => '$baseUrl/events/$id/';
  static String toggleEventParticipation(String eventId) =>
      '$baseUrl/events/$eventId/participate/';

  // Communauté de voyageurs
  static const String posts = '$baseUrl/community/posts/';
  static String postDetail(String id) => '$baseUrl/community/posts/$id/';
  static String togglePostLike(String postId) =>
      '$baseUrl/community/posts/$postId/like/';
  static String postComments(String postId) =>
      '$baseUrl/community/posts/$postId/comments/';

  // Défis touristiques, badges et profil
  static const String challenges = '$baseUrl/gamification/challenges/';
  static const String allBadges = '$baseUrl/gamification/badges/';
  static const String myBadges = '$baseUrl/gamification/badges/mine/';
  static const String myVisits = '$baseUrl/gamification/visits/mine/';
  static const String profileStats = '$baseUrl/gamification/profile/';
  static String toggleVisit(String placeId) =>
      '$baseUrl/gamification/places/$placeId/visit/';
}
