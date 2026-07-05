import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../services/tourism_service.dart';
import '../place/place_detail_screen.dart';

class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({super.key});

  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  final _tourismService = TourismService.instance;
  final _searchController = TextEditingController();

  List<Place> _places = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final places = await _tourismService.getPlaces(search: search);
      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger les lieux.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lieux touristiques')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un lieu...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      ),
              ),
              onSubmitted: (value) => _load(search: value),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_places.isEmpty) {
      return const Center(child: Text('Aucun lieu trouvé.'));
    }
    return RefreshIndicator(
      onRefresh: () => _load(search: _searchController.text),
      child: ListView.separated(
        itemCount: _places.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = _places[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              backgroundImage: place.coverImageUrl.isNotEmpty ? NetworkImage(place.coverImageUrl) : null,
              child: place.coverImageUrl.isEmpty ? const Icon(Icons.landscape, color: Colors.teal) : null,
            ),
            title: Text(place.name),
            subtitle: Text('${place.category.name} • ${place.region.name}'),
            trailing: place.averageRating != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(' ${place.averageRating}'),
                    ],
                  )
                : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaceDetailScreen(placeId: place.id, initialPlace: place),
              ),
            ),
          );
        },
      ),
    );
  }
}
