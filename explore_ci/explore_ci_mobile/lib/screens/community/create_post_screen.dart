import 'package:flutter/material.dart';

import '../../services/community_service.dart';

/// Formulaire de publication : texte (récit/conseil) + photos.
///
/// NOTE : les photos sont ajoutées via des URLs (cohérent avec cover_image_url
/// utilisé ailleurs dans l'app). Pour un vrai upload depuis la galerie du
/// téléphone, il faudra ajouter `image_picker` + un stockage de fichiers
/// (S3, Cloudinary...) côté backend — hors du scope MVP actuel.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final List<String> _imageUrls = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _imageUrls.add(url);
      _imageUrlController.clear();
    });
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _errorMessage = 'Écrivez quelque chose avant de publier.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await CommunityService.instance.createPost(content: content, imageUrls: _imageUrls);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Impossible de publier. Réessayez.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle publication')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Racontez votre expérience ou un conseil pratique',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL d\'une photo (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addImageUrl, icon: const Icon(Icons.add)),
              ],
            ),
            if (_imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _imageUrls
                    .map(
                      (url) => Chip(
                        label: Text(url.length > 24 ? '${url.substring(0, 24)}…' : url),
                        onDeleted: () => setState(() => _imageUrls.remove(url)),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}
