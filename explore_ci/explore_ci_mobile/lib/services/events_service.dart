import '../config/api_config.dart';
import '../models/event.dart';
import '../models/event_participation.dart';
import 'api_client.dart';

class EventsService {
  EventsService._();
  static final EventsService instance = EventsService._();

  final _client = ApiClient.instance;

  /// GET /api/events/ (paginé, 20/page).
  /// [regionSlug], [eventType], [search] sont optionnels.
  /// [upcoming] = false pour inclure aussi les événements passés (par défaut : à venir uniquement).
  Future<List<Event>> getEvents({
    String? regionSlug,
    String? eventType,
    String? search,
    bool upcoming = true,
  }) async {
    final params = <String, String>{'upcoming': upcoming.toString()};
    if (regionSlug != null) params['region'] = regionSlug;
    if (eventType != null) params['event_type'] = eventType;
    if (search != null && search.isNotEmpty) params['search'] = search;

    var url = Uri.parse(ApiConfig.events).replace(queryParameters: params).toString();
    final events = <Event>[];

    while (url.isNotEmpty) {
      final res = await _client.get(url, auth: false);
      final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
      final results = data['results'] as List;
      events.addAll(results.map((e) => Event.fromJson(e as Map<String, dynamic>)));
      url = (data['next'] as String?) ?? '';
    }

    return events;
  }

  Future<Event> getEventDetail(String id) async {
    final res = await _client.get(ApiConfig.eventDetail(id), auth: false);
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return Event.fromJson(data);
  }

  /// POST /api/events/<id>/participate/ — bascule participation/non-participation.
  /// Retourne le nouvel état (true = participe).
  Future<bool> toggleParticipation(String eventId) async {
    final res = await _client.post(ApiConfig.toggleEventParticipation(eventId));
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return data['participating'] as bool;
  }

  /// GET /api/events/mine/ — événements auxquels l'utilisateur connecté participe.
  Future<List<EventParticipation>> getMyParticipations() async {
    final res = await _client.get(ApiConfig.myEventParticipations);
    final data = _client.decodeOrThrow(res);
    final list = data is Map<String, dynamic> ? data['results'] as List : data as List;
    return list.map((e) => EventParticipation.fromJson(e as Map<String, dynamic>)).toList();
  }
}
