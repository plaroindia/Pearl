import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../Model/event.dart';
import '../Model/filter_options.dart';

class EventFeedState {
  final List<Event> trendingEvents;
  final List<Event> upcomingHackathons;
  final List<Event> trendingCompetitions;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final FilterOptions filterOptions;

  const EventFeedState({
    this.trendingEvents = const [],
    this.upcomingHackathons = const [],
    this.trendingCompetitions = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterOptions = const FilterOptions(),
  });

  EventFeedState copyWith({
    List<Event>? trendingEvents,
    List<Event>? upcomingHackathons,
    List<Event>? trendingCompetitions,
    bool? isLoading,
    String? error,
    String? searchQuery,
    FilterOptions? filterOptions,
  }) {
    return EventFeedState(
      trendingEvents: trendingEvents ?? this.trendingEvents,
      upcomingHackathons: upcomingHackathons ?? this.upcomingHackathons,
      trendingCompetitions: trendingCompetitions ?? this.trendingCompetitions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filterOptions: filterOptions ?? this.filterOptions,
    );
  }
}

class EventCreateState {
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? error;
  final File? bannerImage;

  const EventCreateState({
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
    this.bannerImage,
  });

  EventCreateState copyWith({
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    File? bannerImage,
  }) {
    return EventCreateState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
      bannerImage: bannerImage ?? this.bannerImage,
    );
  }
}

class EventFeedNotifier extends StateNotifier<EventFeedState> {
  EventFeedNotifier() : super(const EventFeedState());

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      print('🔍 Starting to load events...');

      // Fetch events with organizer information
      final response = await _supabase
          .from('events')
          .select('''
            *,
            user_profiles!events_organizer_id_fkey (
              username,
              profile_pic
            )
          ''')
          .order('created_at', ascending: false);

      print('📦 Received ${(response as List).length} events from database');

      if ((response as List).isEmpty) {
        print('⚠️ No events found in database');
        state = state.copyWith(
          trendingEvents: [],
          upcomingHackathons: [],
          trendingCompetitions: [],
          isLoading: false,
        );
        return;
      }

      // Get current user's registrations separately
      final userId = _supabase.auth.currentUser?.id;
      Set<int> userRegistrations = {};

      if (userId != null) {
        try {
          final registrations = await _supabase
              .from('event_registrations')
              .select('event_id')
              .eq('user_id', userId);

          userRegistrations = (registrations as List)
              .map<int>((reg) => reg['event_id'] as int)
              .toSet();

          print('✅ User registered for ${userRegistrations.length} events');
        } catch (e) {
          print('⚠️ Could not fetch user registrations: $e');
        }
      }

      final List<Event> allEvents = [];

      for (final eventData in (response as List)) {
        try {
          final eventId = eventData['event_id'] as int;
          final isRegistered = userRegistrations.contains(eventId);

          final event = _mapEventFromDatabase(eventData, isRegistered);
          allEvents.add(event);
        } catch (e) {
          print('❌ Error mapping event: $e');
          print('Event data: $eventData');
        }
      }

      print('✅ Mapped ${allEvents.length} events successfully');

      // Categorize events
      final now = DateTime.now();

      final trending = allEvents.where((e) {
        return e.startDate.isAfter(now) &&
            e.startDate.difference(now).inDays <= 30;
      }).toList();

      final hackathons = allEvents.where((e) {
        final categoryLower = e.category?.toLowerCase() ?? '';
        return categoryLower.contains('hackathon') ||
            categoryLower.contains('hack') ||
            e.tags.any((tag) => tag.toLowerCase().contains('hackathon'));
      }).toList();

      final competitions = allEvents.where((e) {
        final categoryLower = e.category?.toLowerCase() ?? '';
        return categoryLower.contains('competition') ||
            categoryLower.contains('compete') ||
            e.tags.any((tag) => tag.toLowerCase().contains('competition'));
      }).toList();

      print('📊 Categorized events:');
      print('   - Trending: ${trending.length}');
      print('   - Hackathons: ${hackathons.length}');
      print('   - Competitions: ${competitions.length}');

      state = state.copyWith(
        trendingEvents: trending,
        upcomingHackathons: hackathons,
        trendingCompetitions: competitions,
        isLoading: false,
        error: null,
      );

      print('✅ Events loaded successfully!');
    } catch (e, stackTrace) {
      print('❌ Error loading events: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load events: ${e.toString()}',
      );
    }
  }

  double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Event _mapEventFromDatabase(Map<String, dynamic> data, [bool isRegistered = false]) {
    // Create tags from category
    final List<String> tags = [];
    if (data['category'] != null) {
      tags.add(data['category']);
    }

    // Add additional tags based on category type
    final category = data['category']?.toLowerCase() ?? '';
    if (category.contains('hackathon') || category.contains('hack')) tags.add('Hackathon');
    if (category.contains('competition') || category.contains('compete')) tags.add('Competition');
    if (category.contains('workshop')) tags.add('Workshop');
    if (category.contains('tech')) tags.add('Technology');
    if (category.contains('business')) tags.add('Business');
    if (category.contains('gaming') || category.contains('game')) tags.add('Gaming');

    // Safely extract organizer information
    String organizerName = 'Unknown Organizer';
    String organizerPic = '';

    try {
      if (data['user_profiles'] != null) {
        final profiles = data['user_profiles'];
        organizerName = profiles['username'] ?? 'Unknown Organizer';
        organizerPic = profiles['profile_pic'] ?? '';
      }
    } catch (e) {
      print('⚠️ Error extracting organizer info: $e');
    }

    return Event(
      eventId: data['event_id'].toString(),
      organizerId: data['organizer_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      organizationName: organizerName,
      organizationLogo: organizerPic,
      tags: tags,
      startDate: DateTime.parse(data['start_time']),
      endDate: DateTime.parse(data['end_time']),
      isTeamEvent: category.contains('team') || category.contains('hackathon'),
      minTeamSize: category.contains('hackathon') ? 2 : 1,
      maxTeamSize: category.contains('hackathon') ? 5 : 1,
      isRegistered: isRegistered,
      challenges: [],
      latitude: _parseCoordinate(data['latitude']),
      longitude: _parseCoordinate(data['longitude']),
      category: data['category'],
      location: data['location'],
      registrationDeadline: data['registration_deadline'] != null
          ? DateTime.parse(data['registration_deadline'])
          : null,
      bannerUrl: data['banner_url'],
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void applyFilters(FilterOptions filters) {
    state = state.copyWith(filterOptions: filters);
  }

  List<Event> _applyAllFilters(List<Event> events) {
    List<Event> filteredEvents = events;

    // Apply search query
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      filteredEvents = filteredEvents.where((e) =>
      e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.organizationName.toLowerCase().contains(q) ||
          (e.category?.toLowerCase().contains(q) ?? false) ||
          (e.location?.toLowerCase().contains(q) ?? false) ||
          e.tags.any((tag) => tag.toLowerCase().contains(q))
      ).toList();
    }

    // Apply filters from FilterOptions
    final filters = state.filterOptions;
    if (filters.eventTypes.isNotEmpty) {
      filteredEvents = filteredEvents.where((e) {
        return filters.eventTypes.any((type) =>
        e.tags.any((tag) => tag.toLowerCase().contains(type.toLowerCase())) ||
            (e.category?.toLowerCase().contains(type.toLowerCase()) ?? false)
        );
      }).toList();
    }

    if (filters.teamSizes.isNotEmpty) {
      filteredEvents = filteredEvents.where((e) {
        if (filters.teamSizes.contains('Individual') && !e.isTeamEvent) {
          return true;
        }
        if (filters.teamSizes.contains('2-4 Members') && e.isTeamEvent &&
            (e.minTeamSize ?? 0) >= 2 && (e.maxTeamSize ?? 0) <= 4) {
          return true;
        }
        if (filters.teamSizes.contains('5+ Members') && e.isTeamEvent &&
            (e.minTeamSize ?? 0) >= 5) {
          return true;
        }
        return false;
      }).toList();
    }

    return filteredEvents;
  }

  List<Event> get filteredTrendingEvents => _applyAllFilters(state.trendingEvents);
  List<Event> get filteredUpcomingHackathons => _applyAllFilters(state.upcomingHackathons);
  List<Event> get filteredTrendingCompetitions => _applyAllFilters(state.trendingCompetitions);

  Future<List<Event>> getEventsByCategory(String category) async {
    try {
      print('🔍 Fetching events for category: $category');

      final response = await _supabase
          .from('events')
          .select('''
            *,
            user_profiles!events_organizer_id_fkey (
              username,
              profile_pic
            )
          ''')
          .eq('category', category)
          .order('start_time', ascending: true);

      // Get user registrations
      final userId = _supabase.auth.currentUser?.id;
      Set<int> userRegistrations = {};

      if (userId != null) {
        try {
          final registrations = await _supabase
              .from('event_registrations')
              .select('event_id')
              .eq('user_id', userId);

          userRegistrations = (registrations as List)
              .map<int>((reg) => reg['event_id'] as int)
              .toSet();
        } catch (e) {
          print('⚠️ Could not fetch user registrations: $e');
        }
      }

      final List<Event> events = [];
      for (final eventData in (response as List)) {
        final eventId = eventData['event_id'] as int;
        final isRegistered = userRegistrations.contains(eventId);
        final event = _mapEventFromDatabase(eventData, isRegistered);
        events.add(event);
      }

      return events;
    } catch (e) {
      print('❌ Error fetching events by category: $e');
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<List<Event>> getUserCreatedEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      print('🔍 Fetching events created by user: $userId');

      final response = await _supabase
          .from('events')
          .select('''
            *,
            user_profiles!events_organizer_id_fkey (
              username,
              profile_pic
            )
          ''')
          .eq('organizer_id', userId)
          .order('created_at', ascending: false);

      final List<Event> events = [];
      for (final eventData in (response as List)) {
        // User is the organizer, so always registered
        final event = _mapEventFromDatabase(eventData, true);
        events.add(event);
      }

      return events;
    } catch (e) {
      print('❌ Error fetching user created events: $e');
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<List<Event>> getUserRegisteredEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      print('🔍 Fetching events user is registered for: $userId');

      // Get event IDs user is registered for
      final registrations = await _supabase
          .from('event_registrations')
          .select('event_id')
          .eq('user_id', userId);

      if ((registrations as List).isEmpty) {
        print('ℹ️ User has no registrations');
        return [];
      }

      final eventIds = (registrations as List).map<int>((reg) => reg['event_id'] as int).toList();
      print('📋 User registered for ${eventIds.length} events');

      final List<Event> events = [];

      // Fetch each event individually (most compatible approach)
      for (final eventId in eventIds) {
        try {
          final response = await _supabase
              .from('events')
              .select('''
                *,
                user_profiles!events_organizer_id_fkey (
                  username,
                  profile_pic
                )
              ''')
              .eq('event_id', eventId)
              .single();

          final event = _mapEventFromDatabase(response, true);
          events.add(event);
        } catch (e) {
          print('⚠️ Error fetching event $eventId: $e');
          // Continue with other events
        }
      }

      // Sort by start time
      events.sort((a, b) => a.startDate.compareTo(b.startDate));

      print('✅ Fetched ${events.length} registered events');
      return events;
    } catch (e) {
      print('❌ Error fetching user registered events: $e');
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<bool> registerForEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(error: 'User not authenticated');
        return false;
      }

      await _supabase
          .from('event_registrations')
          .insert({
        'event_id': int.parse(eventId),
        'user_id': userId,
        'registered_at': DateTime.now().toIso8601String(),
      });

      // Refresh events to update registration status
      await loadEvents();
      return true;
    } catch (e) {
      print('❌ Error registering for event: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(error: 'User not authenticated');
        return false;
      }

      await _supabase
          .from('event_registrations')
          .delete()
          .eq('event_id', int.parse(eventId))
          .eq('user_id', userId);

      // Refresh events to update registration status
      await loadEvents();
      return true;
    } catch (e) {
      print('❌ Error unregistering from event: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

class EventCreateNotifier extends StateNotifier<EventCreateState> {
  EventCreateNotifier() : super(const EventCreateState());

  final SupabaseClient _supabase = Supabase.instance.client;

  void setBannerImage(File? image) {
    state = state.copyWith(bannerImage: image);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Event _mapEventFromDatabase(Map<String, dynamic> data) {
    final userId = _supabase.auth.currentUser?.id;

    // Check if user is registered for this event
    bool isRegistered = false;
    if (userId != null && data['event_registrations'] != null) {
      isRegistered = (data['event_registrations'] as List)
          .any((reg) => reg['user_id'] == userId);
    }

    // Create tags from category
    final List<String> tags = [];
    if (data['category'] != null) {
      tags.add(data['category']);
    }

    // Add additional tags based on category type
    final category = data['category']?.toLowerCase() ?? '';
    if (category.contains('hackathon')) tags.add('Hackathon');
    if (category.contains('competition')) tags.add('Competition');
    if (category.contains('workshop')) tags.add('Workshop');
    if (category.contains('tech')) tags.add('Technology');

    return Event(
      eventId: data['event_id'].toString(),
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
      isRegistered: isRegistered,
      challenges: [],
      latitude: _parseCoordinate(data['latitude']),
      longitude: _parseCoordinate(data['longitude']),
      category: data['category'],
      location: data['location'],
      registrationDeadline: data['registration_deadline'] != null
          ? DateTime.parse(data['registration_deadline'])
          : null,
      bannerUrl: data['banner_url'],
    );
  }

  Future<String?> _uploadBannerImage(File imageFile, String eventId) async {
    try {
      state = state.copyWith(isUploading: true, uploadProgress: 0.0);

      final fileName = 'event_banners/${eventId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('event-banners')
          .upload(fileName, imageFile);

      // Simulate progress updates
      for (double progress = 0.2; progress <= 1.0; progress += 0.2) {
        state = state.copyWith(uploadProgress: progress);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Get public URL and ensure HTTPS
      String publicUrl = _supabase.storage
          .from('event-banners')
          .getPublicUrl(fileName);
      
      // Ensure URL has HTTPS scheme
      if (!publicUrl.startsWith('https://')) {
        if (publicUrl.startsWith('http://')) {
          publicUrl = publicUrl.replaceFirst('http://', 'https://');
        } else {
          publicUrl = 'https://$publicUrl';
        }
      }

      state = state.copyWith(isUploading: false, uploadProgress: 1.0);
      return publicUrl;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: 'Failed to upload banner: ${e.toString()}');
      return null;
    }
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    DateTime? registrationDeadline,
    double? latitude,
    double? longitude,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      print('🎯 Creating event: $title');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('👤 User ID: $userId');

      // Insert event with proper field mapping
      final eventResponse = await _supabase
          .from('events')
          .insert({
        'organizer_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'registration_deadline': registrationDeadline?.toIso8601String(),
        'banner_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select('event_id')
          .single();

      final eventId = eventResponse['event_id'].toString();
      print('✅ Event created with ID: $eventId');

      // Upload banner image if provided
      String? bannerUrl;
      if (state.bannerImage != null) {
        print('📸 Banner image found, starting upload...');
        bannerUrl = await _uploadBannerImage(state.bannerImage!, eventId);

        if (bannerUrl != null) {
          print('🖼️ Updating event with banner URL...');
          await _supabase
              .from('events')
              .update({
            'banner_url': bannerUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
              .eq('event_id', eventId);
          print('✅ Banner URL updated in database');
        } else {
          print('⚠️ Banner upload failed, continuing without banner');
        }
      } else {
        print('ℹ️ No banner image provided');
      }

      // Insert contact information if provided
      if (contactName?.isNotEmpty == true ||
          contactEmail?.isNotEmpty == true ||
          contactPhone?.isNotEmpty == true) {
        print('📞 Adding contact information...');
        await _supabase
            .from('event_contacts')
            .insert({
          'event_id': int.parse(eventId),
          'name': contactName ?? '',
          'email': contactEmail ?? '',
          'phone': contactPhone ?? '',
          'role': 'Organizer',
        });
        print('✅ Contact information added');
      }

      state = state.copyWith(isLoading: false, bannerImage: null);
      print('🎉 Event creation completed successfully!');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error creating event: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String content,
    DateTime? createdAt,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user owns this event
      final eventCheck = await _supabase
          .from('events')
          .select('organizer_id')
          .eq('event_id', int.parse(eventId))
          .single();

      if (eventCheck['organizer_id'] != userId) {
        throw Exception('Unauthorized: You can only update your own events');
      }

      // Update event in event_updates table (if that's the intended behavior)
      await _supabase
          .from('event_updates')
          .insert({
        'event_id': int.parse(eventId),
        'title': title,
        'content': content,
        'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user owns this event
      final eventCheck = await _supabase
          .from('events')
          .select('organizer_id, banner_url')
          .eq('event_id', int.parse(eventId))
          .single();

      if (eventCheck['organizer_id'] != userId) {
        throw Exception('Unauthorized: You can only delete your own events');
      }

      // Delete banner image from storage if exists
      if (eventCheck['banner_url'] != null) {
        try {
          final fileName = eventCheck['banner_url'].split('/').last;
          await _supabase.storage
              .from('event-banners')
              .remove(['event_banners/$fileName']);
        } catch (e) {
          // Continue even if image deletion fails
          print('Failed to delete banner image: $e');
        }
      }

      // Delete related records first (due to foreign key constraints)
      await _supabase
          .from('event_registrations')
          .delete()
          .eq('event_id', int.parse(eventId));

      await _supabase
          .from('event_contacts')
          .delete()
          .eq('event_id', int.parse(eventId));

      await _supabase
          .from('event_updates')
          .delete()
          .eq('event_id', int.parse(eventId));

      // Finally delete the event
      await _supabase
          .from('events')
          .delete()
          .eq('event_id', int.parse(eventId));

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('''
            *,
            user_profiles!organizer_id (
              username,
              profile_pic
            ),
            event_registrations (
              user_id
            )
          ''')
          .eq('event_id', int.parse(eventId))
          .single();

      return _mapEventFromDatabase(response);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getEventUpdates(String eventId) async {
    try {
      final response = await _supabase
          .from('event_updates')
          .select('*')
          .eq('event_id', int.parse(eventId))
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEventContacts(String eventId) async {
    try {
      final response = await _supabase
          .from('event_contacts')
          .select('*')
          .eq('event_id', int.parse(eventId));

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<int> getEventRegistrationCount(String eventId) async {
    try {
      final response = await _supabase
          .from('event_registrations')
          .select('registration_id')
          .eq('event_id', int.parse(eventId));

      return response.length;
    } catch (e) {
      return 0;
    }
  }
}

// Providers
final eventFeedProvider = StateNotifierProvider<EventFeedNotifier, EventFeedState>((ref) {
  final notifier = EventFeedNotifier();
  notifier.loadEvents();
  return notifier;
});

final eventCreateProvider = StateNotifierProvider<EventCreateNotifier, EventCreateState>((ref) {
  return EventCreateNotifier();
});

// Additional utility providers
final eventCategoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('event_categories')
        .select('name')
        .order('name', ascending: true);

    return (response as List).map((cat) => cat['name'] as String).toList();
  } catch (e) {
    // Return default categories if database fetch fails
    return [
      'Technology',
      'Business',
      'Arts & Culture',
      'Sports',
      'Education',
      'Health & Wellness',
      'Social',
      'Music',
      'Gaming',
      'Hackathon',
      'Competition',
      'Workshop',
      'Other'
    ];
  }
});

final userEventsProvider = FutureProvider<Map<String, List<Event>>>((ref) async {
  final notifier = ref.read(eventFeedProvider.notifier);

  final createdEvents = await notifier.getUserCreatedEvents();
  final registeredEvents = await notifier.getUserRegisteredEvents();

  return {
    'created': createdEvents,
    'registered': registeredEvents,
  };
});

// Provider for getting a specific event by ID
final eventByIdProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final notifier = ref.read(eventCreateProvider.notifier);
  return await notifier.getEventById(eventId);
});

// Provider for getting event updates
final eventUpdatesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final notifier = ref.read(eventCreateProvider.notifier);
  return await notifier.getEventUpdates(eventId);
});

// Provider for getting event contacts
final eventContactsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  final notifier = ref.read(eventCreateProvider.notifier);
  return await notifier.getEventContacts(eventId);
});

// Provider for getting event registration count
final eventRegistrationCountProvider = FutureProvider.family<int, String>((ref, eventId) async {
  final notifier = ref.read(eventCreateProvider.notifier);
  return await notifier.getEventRegistrationCount(eventId);
});