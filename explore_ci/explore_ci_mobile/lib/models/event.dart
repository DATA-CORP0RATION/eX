import 'category.dart';

class Event {
  final String id;
  final String title;
  final String eventType;
  final Region? region;
  final String locationName;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final double? price;
  final bool isFree;
  final String coverImageUrl;
  final int participantsCount;
  final bool isParticipating;

  // Présents uniquement dans la fiche détaillée (EventDetailSerializer)
  final String? description;
  final String? placeId;
  final String? bookingUrl;

  Event({
    required this.id,
    required this.title,
    required this.eventType,
    required this.region,
    required this.locationName,
    required this.startDatetime,
    required this.endDatetime,
    required this.price,
    required this.isFree,
    required this.coverImageUrl,
    required this.participantsCount,
    required this.isParticipating,
    this.description,
    this.placeId,
    this.bookingUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      eventType: json['event_type'] as String,
      region: json['region'] == null
          ? null
          : Region.fromJson(json['region'] as Map<String, dynamic>),
      locationName: (json['location_name'] as String?) ?? '',
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: json['end_datetime'] == null
          ? null
          : DateTime.parse(json['end_datetime'] as String),
      price: json['price'] == null ? null : double.parse(json['price'].toString()),
      isFree: (json['is_free'] as bool?) ?? true,
      coverImageUrl: (json['cover_image_url'] as String?) ?? '',
      participantsCount: (json['participants_count'] as int?) ?? 0,
      isParticipating: (json['is_participating'] as bool?) ?? false,
      description: json['description'] as String?,
      placeId: json['place'] as String?,
      bookingUrl: json['booking_url'] as String?,
    );
  }

  /// Copie locale utile après un toggle participation pour rafraîchir l'UI
  /// sans refaire un appel réseau complet.
  Event copyWithParticipating(bool value, {required int newParticipantsCount}) {
    return Event(
      id: id,
      title: title,
      eventType: eventType,
      region: region,
      locationName: locationName,
      startDatetime: startDatetime,
      endDatetime: endDatetime,
      price: price,
      isFree: isFree,
      coverImageUrl: coverImageUrl,
      participantsCount: newParticipantsCount,
      isParticipating: value,
      description: description,
      placeId: placeId,
      bookingUrl: bookingUrl,
    );
  }

  static const Map<String, String> typeLabels = {
    'festival': 'Festival',
    'concert': 'Concert',
    'culturel': 'Fête culturelle',
    'sport': 'Sport',
    'foire': 'Foire',
    'autre': 'Autre',
  };

  String get typeLabel => typeLabels[eventType] ?? eventType;
}
