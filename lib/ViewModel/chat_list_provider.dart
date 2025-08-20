// IMPROVED chat_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../Model/user_profile.dart';

// Enhanced state class for chat users
class ChatListState {
  final List<UserProfile> users;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final bool hasMore;
  final DateTime? lastFetched;

  const ChatListState({
    this.users = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.hasMore = true,
    this.lastFetched,
  });

  ChatListState copyWith({
    List<UserProfile>? users,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool? hasMore,
    DateTime? lastFetched,
  }) {
    return ChatListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  bool get isEmpty => users.isEmpty && !isLoading;
  bool get hasError => error != null;
  bool get shouldShowLoading => isLoading && users.isEmpty;
}

// Enhanced ChatListNotifier with better error handling and caching
class ChatListNotifier extends StateNotifier<ChatListState> {
  final String userId;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 20;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  ChatListNotifier(this.userId) : super(const ChatListState());

  Future<void> fetchChatUsers({bool refresh = false}) async {
    try {
      // Prevent multiple simultaneous requests
      if (state.isLoading && !refresh) return;
      if (!state.hasMore && !refresh) return;

      // Check cache validity for refresh
      if (refresh && _isCacheValid() && state.users.isNotEmpty) {
        return;
      }

      state = state.copyWith(
        isLoading: true,
        isRefreshing: refresh,
        error: null,
      );

      final offset = refresh ? 0 : state.users.length;

      // Fetch data with timeout
      final combinedUsers = await _fetchCombinedUsers().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out. Please try again.'),
      );

      // Apply pagination
      final paginatedUsers = _applyPagination(combinedUsers, offset, refresh);
      final hasMore = combinedUsers.length > paginatedUsers.length;

      state = state.copyWith(
        users: paginatedUsers,
        isLoading: false,
        isRefreshing: false,
        hasMore: hasMore,
        lastFetched: DateTime.now(),
        error: null,
      );

    } catch (error) {
      final errorMessage = _getErrorMessage(error);
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: errorMessage,
      );
    }
  }

  Future<List<UserProfile>> _fetchCombinedUsers() async {
    // Create futures for parallel execution
    final followersQuery = _supabase
        .from('user_follows')
        .select('''
          follower_id,
          followed_at,
          follower:user_profiles!fk_follower(
            user_id,
            username,
            email,
            role,
            profile_pic,
            bio,
            study,
            location,
            is_verified,
            followers_count,
            following_count,
            streak_count,
            created_at,
            updated_at
          )
        ''')
        .eq('followee_id', userId)
        .order('followed_at', ascending: false)
        .limit(100); // Reasonable limit

    final followingQuery = _supabase
        .from('user_follows')
        .select('''
          followee_id,
          followed_at,
          following:user_profiles!fk_followee(
            user_id,
            username,
            email,
            role,
            profile_pic,
            bio,
            study,
            location,
            is_verified,
            followers_count,
            following_count,
            streak_count,
            created_at,
            updated_at
          )
        ''')
        .eq('follower_id', userId)
        .order('followed_at', ascending: false)
        .limit(100); // Reasonable limit

    // Execute queries in parallel
    final results = await Future.wait([followersQuery, followingQuery]);
    final followersData = results[0] as List;
    final followingData = results[1] as List;

    // Process and combine data
    return _processCombinedData(followersData, followingData);
  }

  List<UserProfile> _processCombinedData(List followersData, List followingData) {
    final Map<String, UserProfile> uniqueUsers = {};
    final Map<String, DateTime> userActivityMap = {};

    // Process followers
    for (final item in followersData) {
      final followerData = item['follower'];
      final followedAt = DateTime.parse(item['followed_at'] ?? DateTime.now().toIso8601String());

      if (followerData != null) {
        final user = UserProfile.fromJson(followerData);
        uniqueUsers[user.user_id] = user;

        // Keep track of most recent activity
        if (!userActivityMap.containsKey(user.user_id) ||
            followedAt.isAfter(userActivityMap[user.user_id]!)) {
          userActivityMap[user.user_id] = followedAt;
        }
      }
    }

    // Process following
    for (final item in followingData) {
      final followingUserData = item['following'];
      final followedAt = DateTime.parse(item['followed_at'] ?? DateTime.now().toIso8601String());

      if (followingUserData != null) {
        final user = UserProfile.fromJson(followingUserData);
        uniqueUsers[user.user_id] = user;

        // Keep track of most recent activity
        if (!userActivityMap.containsKey(user.user_id) ||
            followedAt.isAfter(userActivityMap[user.user_id]!)) {
          userActivityMap[user.user_id] = followedAt;
        }
      }
    }

    // Convert to list and sort by recent activity, then by username
    final List<UserProfile> combinedUsers = uniqueUsers.values.toList();
    combinedUsers.sort((a, b) {
      final aActivity = userActivityMap[a.user_id] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bActivity = userActivityMap[b.user_id] ?? DateTime.fromMillisecondsSinceEpoch(0);

      // Sort by most recent activity first
      final activityComparison = bActivity.compareTo(aActivity);
      if (activityComparison != 0) return activityComparison;

      // Then by username alphabetically
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });

    return combinedUsers;
  }

  List<UserProfile> _applyPagination(List<UserProfile> allUsers, int offset, bool refresh) {
    if (refresh) {
      return allUsers.take(_pageSize).toList();
    } else {
      final existingUsers = state.users;
      final newUsers = allUsers.skip(offset).take(_pageSize).toList();

      // Merge and remove duplicates
      final Map<String, UserProfile> uniqueUserMap = {};

      for (final user in existingUsers) {
        uniqueUserMap[user.user_id] = user;
      }

      for (final user in newUsers) {
        uniqueUserMap[user.user_id] = user;
      }

      return uniqueUserMap.values.toList();
    }
  }

  bool _isCacheValid() {
    if (state.lastFetched == null) return false;
    return DateTime.now().difference(state.lastFetched!) < _cacheTimeout;
  }

  String _getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '42P01':
          return 'Database table not found. Please contact support.';
        case '42703':
          return 'Invalid data structure. Please update the app.';
        default:
          return 'Database error: ${error.message}';
      }
    } else if (error.toString().contains('timeout')) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else {
      return 'Failed to load chats. Please try again.';
    }
  }

  Future<void> refresh() async {
    await fetchChatUsers(refresh: true);
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }

  // Method to manually add/remove users (for real-time updates)
  void updateUserInList(UserProfile updatedUser) {
    final updatedUsers = state.users.map((user) {
      return user.user_id == updatedUser.user_id ? updatedUser : user;
    }).toList();

    state = state.copyWith(users: updatedUsers);
  }

  void removeUserFromList(String userId) {
    final updatedUsers = state.users.where((user) => user.user_id != userId).toList();
    state = state.copyWith(users: updatedUsers);
  }
}

// Keep existing state classes for backwards compatibility
class FollowersState {
  final List<UserProfile> followers;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const FollowersState({
    this.followers = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  FollowersState copyWith({
    List<UserProfile>? followers,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return FollowersState(
      followers: followers ?? this.followers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FollowingState {
  final List<UserProfile> following;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const FollowingState({
    this.following = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  FollowingState copyWith({
    List<UserProfile>? following,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return FollowingState(
      following: following ?? this.following,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Keep existing notifiers for backwards compatibility
class FollowersNotifier extends StateNotifier<FollowersState> {
  final String userId;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 20;

  FollowersNotifier(this.userId) : super(const FollowersState());

  Future<void> fetchFollowers({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    if (!state.hasMore && !refresh) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      final offset = refresh ? 0 : state.followers.length;

      final response = await _supabase
          .from('user_follows')
          .select('''
            follower_id,
            follower:user_profiles!fk_follower(
              user_id, username, email, role, profile_pic, bio, study,
              location, is_verified, followers_count, following_count,
              streak_count, created_at, updated_at
            )
          ''')
          .eq('followee_id', userId)
          .order('followed_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final List<UserProfile> newFollowers = [];
      for (final item in response as List) {
        final followerData = item['follower'];
        if (followerData != null) {
          newFollowers.add(UserProfile.fromJson(followerData));
        }
      }

      final updatedFollowers = refresh ? newFollowers : [...state.followers, ...newFollowers];

      state = state.copyWith(
        followers: updatedFollowers,
        isLoading: false,
        hasMore: newFollowers.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void refresh() => fetchFollowers(refresh: true);
}

class FollowingNotifier extends StateNotifier<FollowingState> {
  final String userId;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 20;

  FollowingNotifier(this.userId) : super(const FollowingState());

  Future<void> fetchFollowing({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    if (!state.hasMore && !refresh) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      final offset = refresh ? 0 : state.following.length;

      final response = await _supabase
          .from('user_follows')
          .select('''
            followee_id,
            following:user_profiles!fk_followee(
              user_id, username, email, role, profile_pic, bio, study,
              location, is_verified, followers_count, following_count,
              streak_count, created_at, updated_at
            )
          ''')
          .eq('follower_id', userId)
          .order('followed_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final List<UserProfile> newFollowing = [];
      for (final item in response as List) {
        final followingData = item['following'];
        if (followingData != null) {
          newFollowing.add(UserProfile.fromJson(followingData));
        }
      }

      final updatedFollowing = refresh ? newFollowing : [...state.following, ...newFollowing];

      state = state.copyWith(
        following: updatedFollowing,
        isLoading: false,
        hasMore: newFollowing.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void refresh() => fetchFollowing(refresh: true);
}

// Enhanced providers
final chatListProvider = StateNotifierProvider.family<ChatListNotifier, ChatListState, String>(
      (ref, userId) => ChatListNotifier(userId),
);

final followersProvider = StateNotifierProvider.family<FollowersNotifier, FollowersState, String>(
      (ref, userId) => FollowersNotifier(userId),
);

final followingProvider = StateNotifierProvider.family<FollowingNotifier, FollowingState, String>(
      (ref, userId) => FollowingNotifier(userId),
);