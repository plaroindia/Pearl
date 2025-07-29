import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class EventFeedNotifier extends StateNotifier<EventFeedState> {
  EventFeedNotifier() : super(const EventFeedState());

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Replace with real Supabase query for each category
      // For now, use static sample events for demonstration
      final List<Event> sampleEvents = [
        Event(
          eventId: '1',
          organizerId: 'org1',
          title: 'AI Hackathon 2024',
          description: 'Compete with the best minds in AI and win exciting prizes!',
          organizationName: 'Tech Society',
          organizationLogo: '',
          tags: ['AI', 'Hackathon', 'Tech'],
          startDate: DateTime.now().add(Duration(days: 5)),
          endDate: DateTime.now().add(Duration(days: 7)),
          isTeamEvent: true,
          minTeamSize: 2,
          maxTeamSize: 5,
          isRegistered: true,
          challenges: [],
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        Event(
          eventId: '2',
          organizerId: 'org2',
          title: 'Startup Pitch Fest MADAGADIPET',
          description: 'Pitch your startup idea to top investors and get funded.',
          organizationName: 'Startup Hub',
          organizationLogo: '',
          tags: ['Startup', 'Pitch', 'Business'],
          startDate: DateTime.now().add(Duration(days: 10)),
          endDate: DateTime.now().add(Duration(days: 12)),
          isTeamEvent: false,
          isRegistered: false,
          challenges: [],
          latitude: 11.926013,
          longitude: 79.629678,
        ),
        Event(
          eventId: '3',
          organizerId: 'org3',
          title: 'Design Sprint',
          description: 'A 48-hour sprint to solve real-world design problems.',
          organizationName: 'Designers United',
          organizationLogo: '',
          tags: ['Design', 'Sprint', 'UI/UX'],
          startDate: DateTime.now().add(Duration(days: 15)),
          endDate: DateTime.now().add(Duration(days: 16)),
          isTeamEvent: true,
          minTeamSize: 3,
          maxTeamSize: 4,
          isRegistered: false,
          challenges: [],
          latitude: 37.7749,
          longitude: -122.4194,
        ),
      ];
      state = state.copyWith(
        trendingEvents: sampleEvents,
        upcomingHackathons: sampleEvents.where((e) => e.tags.contains('Hackathon')).toList(),
        trendingCompetitions: sampleEvents.where((e) => e.tags.contains('Pitch')).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
          e.tags.any((tag) => tag.toLowerCase().contains(q))
      ).toList();
    }

    // Apply filters from FilterOptions
    final filters = state.filterOptions;
    if (filters.eventTypes.isNotEmpty) {
      filteredEvents = filteredEvents.where((e) {
        return filters.eventTypes.any((type) => e.tags.contains(type));
      }).toList();
    }

    if (filters.teamSizes.isNotEmpty) {
      filteredEvents = filteredEvents.where((e) {
        if (filters.teamSizes.contains('Individual') && !e.isTeamEvent) {
          return true;
        }
        if (filters.teamSizes.contains('2-4 Members') && e.isTeamEvent && (e.minTeamSize ?? 0) >= 2 && (e.maxTeamSize ?? 0) <= 4) {
          return true;
        }
        if (filters.teamSizes.contains('5+ Members') && e.isTeamEvent && (e.minTeamSize ?? 0) >= 5) {
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
}

final eventFeedProvider = StateNotifierProvider<EventFeedNotifier, EventFeedState>((ref) {
  final notifier = EventFeedNotifier();
  notifier.loadEvents();
  return notifier;
});