import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../services/events_service.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _eventsService = EventsService.instance;

  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedType;

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
      final events = await _eventsService.getEvents(eventType: _selectedType);
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger le calendrier.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier des événements')),
      body: Column(
        children: [
          _buildTypeFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    final types = Event.typeLabels.entries.toList();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('Tous'),
              selected: _selectedType == null,
              onSelected: (_) {
                setState(() => _selectedType = null);
                _load();
              },
            ),
          ),
          ...types.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: _selectedType == entry.key,
                onSelected: (_) {
                  setState(() => _selectedType = entry.key);
                  _load();
                },
              ),
            ),
          ),
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
    if (_events.isEmpty) {
      return const Center(child: Text('Aucun événement à venir pour le moment.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _events.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final event = _events[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              backgroundImage: event.coverImageUrl.isNotEmpty ? NetworkImage(event.coverImageUrl) : null,
              child: event.coverImageUrl.isEmpty ? const Icon(Icons.event, color: Colors.teal) : null,
            ),
            title: Text(event.title),
            subtitle: Text(
              '${_formatDate(event.startDatetime)} • ${event.locationName.isNotEmpty ? event.locationName : (event.region?.name ?? '')}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(event.typeLabel, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(height: 4),
                Text(
                  event.isFree ? 'Gratuit' : '${event.price?.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id, initialEvent: event)),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${date.day} ${months[date.month - 1]} • ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }
}
