class EventParticipation {
  final String id;
  final String eventId;
  final String eventTitle;
  final DateTime createdAt;

  EventParticipation({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.createdAt,
  });

  factory EventParticipation.fromJson(Map<String, dynamic> json) {
    return EventParticipation(
      id: json['id'].toString(),
      eventId: json['event'].toString(),
      eventTitle: (json['event_title'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
