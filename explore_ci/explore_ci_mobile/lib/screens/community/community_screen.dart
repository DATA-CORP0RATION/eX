import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _communityService = CommunityService.instance;
  final _authService = AuthService.instance;

  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = await _communityService.getPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger la communauté.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreatePost() async {
    if (!await _authService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour publier.')),
      );
      return;
    }
    if (!mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _toggleLike(Post post) async {
    if (!await _authService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour aimer une publication.')),
      );
      return;
    }
    try {
      final liked = await _communityService.toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post.copyWithLiked(liked, newLikesCount: post.likesCount + (liked ? 1 : -1));
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible, réessayez.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communauté de voyageurs')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucune publication pour l\'instant.\nPartagez votre première expérience de voyage !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) => _PostCard(
          post: _posts[index],
          onLike: () => _toggleLike(_posts[index]),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(postId: _posts[index].id)),
            );
            _load();
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onLike, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = post.userFirstName.isNotEmpty ? post.userFirstName : 'Voyageur';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (post.placeName != null && post.placeName!.isNotEmpty)
                          Text(
                            '📍 ${post.placeName}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(post.content),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.images[i].imageUrl,
                        width: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 140,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.redAccent : null,
                      size: 20,
                    ),
                    onPressed: onLike,
                  ),
                  Text('${post.likesCount}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.mode_comment_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
