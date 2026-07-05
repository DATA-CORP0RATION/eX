import 'package:flutter/material.dart';

import '../../models/favorite.dart';
import '../../services/interactions_service.dart';
import '../place/place_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _interactionsService = InteractionsService.instance;

  List<FavoriteItem> _favorites = [];
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
      final favorites = await _interactionsService.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger vos favoris.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
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
    if (_favorites.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun favori pour l\'instant.\nAjoutez des lieux depuis la carte ou la liste !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return ListTile(
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            title: Text(favorite.placeName),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(placeId: favorite.placeId),
                ),
              );
              // Au retour (l'utilisateur a pu retirer le favori depuis la fiche) : on rafraîchit.
              _load();
            },
          );
        },
      ),
    );
  }
}
