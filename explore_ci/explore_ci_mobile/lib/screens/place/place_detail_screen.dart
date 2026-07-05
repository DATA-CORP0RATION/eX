import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../models/review.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/interactions_service.dart';
import '../../services/tourism_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;

  /// Optionnel : données déjà connues depuis la liste/carte, affichées
  /// immédiatement pendant que la fiche complète (description, adresse) charge.
  final Place? initialPlace;

  const PlaceDetailScreen({super.key, required this.placeId, this.initialPlace});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _tourismService = TourismService.instance;
  final _interactionsService = InteractionsService.instance;
  final _authService = AuthService.instance;
  final _gamificationService = GamificationService.instance;

  Place? _place;
  List<Review> _reviews = [];
  Review? _myReview;
  bool _isVisited = false;

  bool _isLoading = true;
  bool _isTogglingFavorite = false;
  bool _isTogglingVisit = false;
  bool _isLoadingReviews = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _place = widget.initialPlace;
    _isLoading = _place == null;
    _loadDetail();
    _loadReviews();
    _loadVisitStatus();
  }

  Future<void> _loadDetail() async {
    try {
      final place = await _tourismService.getPlaceDetail(widget.placeId);
      if (!mounted) return;
      setState(() {
        _place = place;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _place == null ? 'Impossible de charger ce lieu.' : null;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      final results = await Future.wait([
        _interactionsService.getReviews(widget.placeId),
        if (isLoggedIn) _interactionsService.getMyReview(widget.placeId),
      ]);
      if (!mounted) return;
      setState(() {
        _reviews = results[0] as List<Review>;
        _myReview = isLoggedIn ? results[1] as Review? : null;
        _isLoadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final place = _place;
    if (place == null || _isTogglingFavorite) return;

    if (!await _authService.isLoggedIn()) {
      _showLoginRequired();
      return;
    }

    setState(() => _isTogglingFavorite = true);
    try {
      final favorited = await _interactionsService.toggleFavorite(place.id);
      if (!mounted) return;
      setState(() => _place = place.copyWithFavorited(favorited));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible, réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _loadVisitStatus() async {
    try {
      if (!await _authService.isLoggedIn()) return;
      final visits = await _gamificationService.getMyVisits();
      if (!mounted) return;
      setState(() => _isVisited = visits.any((v) => v.placeId == widget.placeId));
    } catch (_) {
      // Pas grave : le bouton restera simplement dans son état par défaut (non visité).
    }
  }

  Future<void> _toggleVisit() async {
    if (_isTogglingVisit) return;

    if (!await _authService.isLoggedIn()) {
      _showLoginRequired();
      return;
    }

    setState(() => _isTogglingVisit = true);
    try {
      final visited = await _gamificationService.toggleVisit(widget.placeId);
      if (!mounted) return;
      setState(() => _isVisited = visited);
      if (visited && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lieu marqué comme visité ! Vérifiez vos défis 🎉')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible, réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _isTogglingVisit = false);
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connectez-vous pour effectuer cette action.')),
    );
  }

  Future<void> _openReviewForm() async {
    if (!await _authService.isLoggedIn()) {
      _showLoginRequired();
      return;
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewFormSheet(placeId: widget.placeId, existingReview: _myReview),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;

    if (_isLoading && place == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (place == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_errorMessage ?? 'Lieu introuvable.')),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReviewForm,
        icon: const Icon(Icons.rate_review_outlined),
        label: Text(_myReview == null ? 'Laisser un avis' : 'Modifier mon avis'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: place.coverImageUrl.isNotEmpty
                  ? Image.network(
                      place.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.teal.shade100),
                    )
                  : Container(
                      color: Colors.teal.shade100,
                      child: const Icon(Icons.landscape, size: 64, color: Colors.white),
                    ),
            ),
            actions: [
              IconButton(
                icon: _isTogglingFavorite
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        place.isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                      ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(place.category.name)),
                      Chip(label: Text(place.region.name)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        place.averageRating != null
                            ? '${place.averageRating} (${place.reviewsCount} avis)'
                            : 'Pas encore d\'avis',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isTogglingVisit ? null : _toggleVisit,
                    icon: _isTogglingVisit
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isVisited ? Icons.check_circle : Icons.check_circle_outline),
                    label: Text(_isVisited ? 'Visité ✓' : 'Marquer comme visité'),
                    style: _isVisited
                        ? OutlinedButton.styleFrom(foregroundColor: Colors.green)
                        : null,
                  ),
                  if (place.address != null && place.address!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(place.address!)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (place.description != null && place.description!.isNotEmpty) ...[
                    Text('Description', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(place.description!),
                  ] else if (_isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Avis (${_reviews.length})', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildReviewsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoadingReviews) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Aucun avis pour le moment. Soyez le premier !', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: _reviews.map((review) {
        final name = review.userFirstName.isNotEmpty ? review.userFirstName : review.userEmail;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
            title: Row(
              children: [
                Text(name),
                const Spacer(),
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            subtitle: review.comment.isNotEmpty ? Text(review.comment) : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Formulaire de dépôt / édition d'un avis (note + commentaire).
class _ReviewFormSheet extends StatefulWidget {
  final String placeId;
  final Review? existingReview;

  const _ReviewFormSheet({required this.placeId, this.existingReview});

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late int _rating = widget.existingReview?.rating ?? 5;
  late final _commentController = TextEditingController(text: widget.existingReview?.comment ?? '');

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final service = InteractionsService.instance;
      if (widget.existingReview == null) {
        await service.postReview(widget.placeId, rating: _rating, comment: _commentController.text.trim());
      } else {
        await service.updateMyReview(widget.placeId, rating: _rating, comment: _commentController.text.trim());
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      setState(() => _errorMessage = 'Impossible d\'enregistrer votre avis. Réessayez.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existingReview == null ? 'Laisser un avis' : 'Modifier mon avis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return IconButton(
                icon: Icon(
                  starIndex <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _rating = starIndex),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Commentaire (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
