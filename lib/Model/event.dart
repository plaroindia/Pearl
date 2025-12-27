import 'challenge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final String? category;
  final String? location;
  final DateTime? registrationDeadline;
  final String? bannerUrl;

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
    this.bannerUrl,
    this.category,
    this.location,
    this.registrationDeadline,
  });

  // Updated factory constructor to match database schema
  factory Event.fromMap(Map<String, dynamic> map) {
    // Handle tags - if category exists, add it to tags
    List<String> tags = [];
    if (map['category'] != null) {
      tags.add(map['category']);
    }

    // Add additional tags based on category type
    final category = map['category']?.toLowerCase() ?? '';
    if (category.contains('hackathon')) tags.add('Hackathon');
    if (category.contains('competition')) tags.add('Competition');
    if (category.contains('workshop')) tags.add('Workshop');
    if (category.contains('tech')) tags.add('Technology');

    return Event(
      eventId: map['event_id']?.toString() ?? '',
      organizerId: map['organizer_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Map from joined user_profiles table
      organizationName: map['user_profiles']?['username'] ?? map['organization_name'] ?? 'Unknown Organizer',
      organizationLogo: map['user_profiles']?['profile_pic'] ?? map['organization_logo'] ?? '',
      tags: tags,
      // Map database time fields to model date fields
      startDate: map['start_time'] != null ? DateTime.parse(map['start_time']) : DateTime.now(),
      endDate: map['end_time'] != null ? DateTime.parse(map['end_time']) : DateTime.now(),
      isTeamEvent: map['is_team_event'] ?? (category.contains('team') || category.contains('hackathon')),
      minTeamSize: map['min_team_size'] ?? (category.contains('hackathon') ? 2 : 1),
      maxTeamSize: map['max_team_size'] ?? (category.contains('hackathon') ? 5 : 1),
      isRegistered: map['is_registered'] ?? false,
      challenges: map['challenges'] != null
          ? (map['challenges'] as List)
          .map((e) => Challenge.fromMap(e))
          .toList()
          : [],
      latitude: _parseCoordinate(map['latitude']),
      longitude: _parseCoordinate(map['longitude']),
      category: map['category'],
      location: map['location'],
      registrationDeadline: map['registration_deadline'] != null
          ? DateTime.parse(map['registration_deadline'])
          : null,
      bannerUrl: map['banner_url'],
    );
  }

  // Updated toMap to match database schema
  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'organizer_id': organizerId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'start_time': startDate.toIso8601String(),
      'end_time': endDate.toIso8601String(),
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'banner_url': bannerUrl,
      // Note: organization_name and organization_logo come from user_profiles join
      // These fields below are for compatibility with your existing code
      'organization_name': organizationName,
      'organization_logo': organizationLogo,
      'tags': tags,
      'is_team_event': isTeamEvent,
      'min_team_size': minTeamSize,
      'max_team_size': maxTeamSize,
      'is_registered': isRegistered,
      'challenges': challenges.map((e) => e.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Factory constructor specifically for database results with joins
  factory Event.fromDatabaseJoin(Map<String, dynamic> data, {bool? isRegistered}) {
    // Handle user registration status
    bool registered = isRegistered ?? false;
    if (!registered && data['event_registrations'] != null) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        registered = (data['event_registrations'] as List)
            .any((reg) => reg['user_id'] == userId);
      }
    }

    // Create tags from category
    List<String> tags = [];
    if (data['category'] != null) {
      tags.add(data['category']);
    }

    final category = data['category']?.toLowerCase() ?? '';
    if (category.contains('hackathon')) tags.add('Hackathon');
    if (category.contains('competition')) tags.add('Competition');
    if (category.contains('workshop')) tags.add('Workshop');
    if (category.contains('tech')) tags.add('Technology');

    return Event(
      eventId: data['event_id']?.toString() ?? '',
      organizerId: data['organizer_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      organizationName: data['user_profiles']?['username'] ?? 'Unknown Organizer',
      organizationLogo: data['user_profiles']?['profile_pic'] ?? '',
      tags: tags,
      startDate: DateTime.parse(data['start_time']),
      endDate: DateTime.parse(data['end_time']),
      isTeamEvent: category.contains('team') || category.contains('hackathon'),
      minTeamSize: category.contains('hackathon') ? 2 : 1,
      maxTeamSize: category.contains('hackathon') ? 5 : 1,
      isRegistered: registered,
      challenges: [], // Add challenges table if needed
      latitude: 0.0, // Add to schema if location features needed
      longitude: 0.0,
      category: data['category'],
      location: data['location'],
      registrationDeadline: data['registration_deadline'] != null
          ? DateTime.parse(data['registration_deadline'])
          : null,
      bannerUrl: data['banner_url'],
    );
  }

  String get duration {
    return "${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}";
  }

  // Helper method to safely parse coordinates
  static double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }
}