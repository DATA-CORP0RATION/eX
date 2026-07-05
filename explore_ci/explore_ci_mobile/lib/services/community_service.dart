import '../config/api_config.dart';
import '../models/post.dart';
import 'api_client.dart';

class CommunityService {
  CommunityService._();
  static final CommunityService instance = CommunityService._();

  final _client = ApiClient.instance;

  /// GET /api/community/posts/ (paginé, 20/page). [placeId] filtre optionnel.
  Future<List<Post>> getPosts({String? placeId}) async {
    final params = <String, String>{};
    if (placeId != null) params['place'] = placeId;

    var url = Uri.parse(ApiConfig.posts)
        .replace(queryParameters: params.isEmpty ? null : params)
        .toString();
    final posts = <Post>[];

    while (url.isNotEmpty) {
      final res = await _client.get(url, auth: false);
      final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
      final results = data['results'] as List;
      posts.addAll(results.map((e) => Post.fromJson(e as Map<String, dynamic>)));
      url = (data['next'] as String?) ?? '';
    }

    return posts;
  }

  /// POST /api/community/posts/ — publier un récit/conseil avec des photos (URLs).
  Future<Post> createPost({required String content, String? placeId, List<String> imageUrls = const []}) async {
    final res = await _client.post(
      ApiConfig.posts,
      body: {
        'content': content,
        if (placeId != null) 'place': placeId,
        'image_urls': imageUrls,
      },
    );
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return Post.fromJson(data);
  }

  /// DELETE /api/community/posts/<id>/ — supprimer sa propre publication.
  Future<void> deletePost(String postId) async {
    final res = await _client.delete(ApiConfig.postDetail(postId));
    _client.decodeOrThrow(res);
  }

  /// POST /api/community/posts/<id>/like/ — bascule j'aime/je n'aime plus.
  /// Retourne le nouvel état (true = aimé).
  Future<bool> toggleLike(String postId) async {
    final res = await _client.post(ApiConfig.togglePostLike(postId));
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return data['liked'] as bool;
  }

  /// GET /api/community/posts/<id>/comments/ — commentaires/conseils d'une publication.
  Future<List<PostComment>> getComments(String postId) async {
    final res = await _client.get(ApiConfig.postComments(postId), auth: false);
    final data = _client.decodeOrThrow(res);
    final list = data is Map<String, dynamic> ? data['results'] as List : data as List;
    return list.map((e) => PostComment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/community/posts/<id>/comments/ — ajouter un commentaire/conseil.
  Future<PostComment> postComment(String postId, String content) async {
    final res = await _client.post(ApiConfig.postComments(postId), body: {'content': content});
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return PostComment.fromJson(data);
  }
}
