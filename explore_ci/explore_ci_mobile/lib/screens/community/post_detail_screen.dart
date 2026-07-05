import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _communityService = CommunityService.instance;
  final _authService = AuthService.instance;
  final _commentController = TextEditingController();

  List<PostComment> _comments = [];
  bool _isLoadingComments = true;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _communityService.getComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (!await _authService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour commenter.')),
      );
      return;
    }

    setState(() => _isSendingComment = true);
    try {
      await _communityService.postComment(widget.postId, content);
      _commentController.clear();
      await _loadComments();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'envoyer le commentaire.')),
      );
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publication')),
      body: Column(
        children: [
          Expanded(child: _buildCommentsList()),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return const Center(
        child: Text('Aucun commentaire. Soyez le premier à donner un conseil !', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final name = comment.userFirstName.isNotEmpty ? comment.userFirstName : 'Voyageur';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 16, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(comment.content),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Ajouter un commentaire ou un conseil...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isSendingComment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(onPressed: _sendComment, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
