import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../services/auth_service.dart';
import '../../services/events_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  /// Optionnel : données déjà connues depuis la liste, affichées
  /// immédiatement pendant que la fiche complète (description) charge.
  final Event? initialEvent;

  const EventDetailScreen({super.key, required this.eventId, this.initialEvent});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventsService = EventsService.instance;
  final _authService = AuthService.instance;

  Event? _event;
  bool _isLoading = true;
  bool _isToggling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
    _isLoading = _event == null;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final event = await _eventsService.getEventDetail(widget.eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _event == null ? 'Impossible de charger cet événement.' : null;
      });
    }
  }

  Future<void> _toggleParticipation() async {
    final event = _event;
    if (event == null || _isToggling) return;

    if (!await _authService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour indiquer votre participation.')),
      );
      return;
    }

    setState(() => _isToggling = true);
    try {
      final participating = await _eventsService.toggleParticipation(event.id);
      if (!mounted) return;
      setState(() {
        _event = event.copyWithParticipating(
          participating,
          newParticipantsCount: event.participantsCount + (participating ? 1 : -1),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible, réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    if (_isLoading && event == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_errorMessage ?? 'Événement introuvable.')),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isToggling ? null : _toggleParticipation,
        icon: Icon(event.isParticipating ? Icons.event_available : Icons.event_outlined),
        label: Text(event.isParticipating ? 'Je participe ✓' : 'Je participe'),
        backgroundColor: event.isParticipating ? Colors.green : null,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: event.coverImageUrl.isNotEmpty
                  ? Image.network(
                      event.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.teal.shade100),
                    )
                  : Container(
                      color: Colors.teal.shade100,
                      child: const Icon(Icons.event, size: 64, color: Colors.white),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(event.typeLabel)),
                      if (event.region != null) Chip(label: Text(event.region!.name)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.calendar_today_outlined, _formatDateRange(event)),
                  if (event.locationName.isNotEmpty)
                    _infoRow(Icons.place_outlined, event.locationName),
                  _infoRow(
                    Icons.payments_outlined,
                    event.isFree ? 'Gratuit' : '${event.price?.toStringAsFixed(0)} FCFA',
                  ),
                  _infoRow(Icons.groups_outlined, '${event.participantsCount} participant(s)'),
                  if (event.bookingUrl != null && event.bookingUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () {}, // Ouvrir avec url_launcher si le package est ajouté au projet
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('Réserver / billetterie'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    Text('Description', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(event.description!),
                  ] else if (_isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatDateRange(Event event) {
    final start = event.startDatetime;
    final startStr =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} à ${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')}';
    if (event.endDatetime == null) return startStr;
    final end = event.endDatetime!;
    return '$startStr → ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
  }
}
