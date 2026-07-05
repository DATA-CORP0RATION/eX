import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/category.dart';
import '../../models/place.dart';
import '../../services/tourism_service.dart';
import '../place/place_detail_screen.dart';

/// Centre par défaut : Abidjan.
const LatLng _kAbidjanCenter = LatLng(5.3599, -4.0083);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _tourismService = TourismService.instance;

  List<Place> _places = [];
  List<Category> _categories = [];
  List<Region> _regions = [];

  String? _selectedCategorySlug;
  String? _selectedRegionSlug;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadPlaces();
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([
        _tourismService.getCategories(),
        _tourismService.getRegions(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Category>;
        _regions = results[1] as List<Region>;
      });
    } catch (_) {
      // Les filtres ne sont pas bloquants pour l'affichage de la carte.
    }
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final places = await _tourismService.getPlaces(
        categorySlug: _selectedCategorySlug,
        regionSlug: _selectedRegionSlug,
      );
      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger les lieux. Vérifiez votre connexion.';
        _isLoading = false;
      });
    }
  }

  /// Centre la carte sur la position actuelle de l'utilisateur.
  Future<void> _centerOnMyLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorisez la localisation pour utiliser cette fonction.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _mapController.move(LatLng(position.latitude, position.longitude), 13);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de récupérer votre position.')),
      );
    }
  }

  void _openPlaceDetail(Place place) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: place.id, initialPlace: place)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des lieux — ExploreCI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaces,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _kAbidjanCenter,
                    initialZoom: 7,
                    minZoom: 5,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.exploreci.mobile',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
                if (_isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black12,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'locate-me',
                    onPressed: _centerOnMyLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _places.map((place) {
      return Marker(
        point: LatLng(place.latitude, place.longitude),
        width: 42,
        height: 42,
        child: GestureDetector(
          onTap: () => _openPlaceDetail(place),
          child: Tooltip(
            message: place.name,
            child: const Icon(Icons.location_on, size: 42, color: Colors.redAccent),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategorySlug,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes')),
                ..._categories.map(
                  (c) => DropdownMenuItem(value: c.slug, child: Text(c.name)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedCategorySlug = value);
                _loadPlaces();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRegionSlug,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Région',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes')),
                ..._regions.map(
                  (r) => DropdownMenuItem(value: r.slug, child: Text(r.name)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedRegionSlug = value);
                _loadPlaces();
              },
            ),
          ),
        ],
      ),
    );
  }
}
