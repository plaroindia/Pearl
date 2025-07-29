import 'challenge.dart';

class Event {
  final String eventId;
  final String organizerId;
  final String title;
  final String description;
  final String organizationName;
  final String organizationLogo;
  final List<String> tags;
  final DateTime startDate;
  final DateTime endDate;
  final bool isTeamEvent;
  final int? minTeamSize;
  final int? maxTeamSize;
  final bool isRegistered;
  final List<Challenge> challenges;
  final double latitude;
  final double longitude;

  Event({
    required this.eventId,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.organizationName,
    required this.organizationLogo,
    required this.tags,
    required this.startDate,
    required this.endDate,
    this.isTeamEvent = false,
    this.minTeamSize,
    this.maxTeamSize,
    this.isRegistered = false,
    this.challenges = const [],
    required this.latitude,
    required this.longitude,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      eventId: map['event_id'] as String,
      organizerId: map['organizer_id'] as String,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      organizationName: map['organization_name'] ?? '',
      organizationLogo: map['organization_logo'] ?? '',
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isTeamEvent: map['is_team_event'] ?? false,
      minTeamSize: map['min_team_size'],
      maxTeamSize: map['max_team_size'],
      isRegistered: map['is_registered'] ?? false,
      challenges: map['challenges'] != null
          ? (map['challenges'] as List)
          .map((e) => Challenge.fromMap(e))
          .toList()
          : [],
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'organizer_id': organizerId,
      'title': title,
      'description': description,
      'organization_name': organizationName,
      'organization_logo': organizationLogo,
      'tags': tags,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_team_event': isTeamEvent,
      'min_team_size': minTeamSize,
      'max_team_size': maxTeamSize,
      'is_registered': isRegistered,
      'challenges': challenges.map((e) => e.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get duration {
    return "${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}";
  }
}