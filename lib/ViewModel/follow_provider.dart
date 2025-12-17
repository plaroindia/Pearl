import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/user_profile.dart';

// Follow State - OPTIMIZED with caching metadata
class FollowState {
  final List<UserProfile> followers;
  final List<UserProfile> following;
  final bool isLoadingFollowers;
  final bool isLoadingFollowing;
  final String? error;
  final bool hasMoreFollowers;
  final bool hasMoreFollowing;
  final int followersPage;
  final int followingPage;
  final Map<String, bool> followingStatus;
  final Set<String> processingFollowRequests;
  final DateTime? lastFollowersUpdate; // NEW: Track last update
  final DateTime? lastFollowingUpdate; // NEW: Track last update
  final Map<String, int> followerCounts; // NEW: Cache follower counts
  final Map<String, int> followingCounts; // NEW: Cache following counts

  const FollowState({
    this.followers = const [],
    this.following = const [],
    this.isLoadingFollowers = false,
    this.isLoadingFollowing = false,
    this.error,
    this.hasMoreFollowers = true,
    this.hasMoreFollowing = true,
    this.followersPage = 0,
    this.followingPage = 0,
    this.followingStatus = const {},
    this.processingFollowRequests = const {},
    this.lastFollowersUpdate,
    this.lastFollowingUpdate,
    this.followerCounts = const {},
    this.followingCounts = const {},
  });

  FollowState copyWith({
    List<UserProfile>? followers,
    List<UserProfile>? following,
    bool? isLoadingFollowers,
    bool? isLoadingFollowing,
    String? error,
    bool? hasMoreFollowers,
    bool? hasMoreFollowing,
    int? followersPage,
    int? followingPage,
    Map<String, bool>? followingStatus,
    Set<String>? processingFollowRequests,
    DateTime? lastFollowersUpdate,
    DateTime? lastFollowingUpdate,
    Map<String, int>? followerCounts,
    Map<String, int>? followingCounts,
  }) {
    return FollowState(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isLoadingFollowers: isLoadingFollowers ?? this.isLoadingFollowers,
      isLoadingFollowing: isLoadingFollowing ?? this.isLoadingFollowing,
      error: error,
      hasMoreFollowers: hasMoreFollowers ?? this.hasMoreFollowers,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
      followersPage: followersPage ?? this.followersPage,
      followingPage: followingPage ?? this.followingPage,
      followingStatus: followingStatus ?? this.followingStatus,
      processingFollowRequests: processingFollowRequests ?? this.processingFollowRequests,
      lastFollowersUpdate: lastFollowersUpdate ?? this.lastFollowersUpdate,
      lastFollowingUpdate: lastFollowingUpdate ?? this.lastFollowingUpdate,
      followerCounts: followerCounts ?? this.followerCounts,
      followingCounts: followingCounts ?? this.followingCounts,
    );
  }
}

// OPTIMIZED Follow Notifier
class FollowNotifier extends StateNotifier<FollowState> {
  FollowNotifier() : super(const FollowState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 20;
  static const _cacheExpiry = Duration(minutes: 5);
  final Map<String, DateTime> _lastToggleTime = {};
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // OPTIMIZED: Load followers with caching
  Future<void> loadFollowers(String userId, {bool refresh = false}) async {
    // Check if we need to refresh based on cache expiry
    if (!refresh &&
        state.lastFollowersUpdate != null &&
        DateTime.now().difference(state.lastFollowersUpdate!) < _cacheExpiry &&
        state.followers.isNotEmpty) {
      debugPrint(' Using cached followers');
      return;
    }

    if (state.isLoadingFollowers && !refresh) return;

    state = state.copyWith(
      isLoadingFollowers: true,
      error: null,
    );

    try {
      final page = refresh ? 0 : state.followersPage;
      final offset = page * _pageSize;

      // OPTIMIZATION: Get follower IDs in batch
      final followsResponse = await _supabase
          .from('user_follows')
          .select('follower_id')
          .eq('followee_id', userId)
          .order('followed_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final followerIds = (followsResponse as List<dynamic>)
          .map((item) => item['follower_id'] as String)
          .toList();

      if (followerIds.isEmpty) {
        state = state.copyWith(
          followers: refresh ? [] : state.followers,
          isLoadingFollowers: false,
          hasMoreFollowers: false,
          followersPage: refresh ? 1 : state.followersPage + 1,
          lastFollowersUpdate: DateTime.now(),
        );
        return;
      }

      // OPTIMIZATION: Batch fetch user profiles
      final profilesResponse = await _supabase
          .from('user_profiles')
          .select('*')
          .inFilter('user_id', followerIds);

      final newFollowers = (profilesResponse as List<dynamic>)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      // OPTIMIZATION: Batch check following status
      Map<String, bool> updatedFollowingStatus = Map.from(state.followingStatus);
      if (_currentUserId != null && newFollowers.isNotEmpty) {
        final followingCheckResponse = await _supabase
            .from('user_follows')
            .select('followee_id')
            .eq('follower_id', _currentUserId!)
            .inFilter('followee_id', followerIds);

        final followingSet = (followingCheckResponse as List<dynamic>)
            .map((item) => item['followee_id'] as String)
            .toSet();

        for (var follower in newFollowers) {
          updatedFollowingStatus[follower.user_id] = followingSet.contains(follower.user_id);
        }
      }

      state = state.copyWith(
        followers: refresh ? newFollowers : [...state.followers, ...newFollowers],
        isLoadingFollowers: false,
        hasMoreFollowers: newFollowers.length == _pageSize,
        followersPage: refresh ? 1 : state.followersPage + 1,
        followingStatus: updatedFollowingStatus,
        lastFollowersUpdate: DateTime.now(),
      );

      debugPrint(' Loaded ${newFollowers.length} followers');
    } catch (e) {
      debugPrint(' Error loading followers: $e');
      state = state.copyWith(
        isLoadingFollowers: false,
        error: 'Failed to load followers: ${e.toString()}',
      );
    }
  }

  // OPTIMIZED: Load following with caching
  Future<void> loadFollowing(String userId, {bool refresh = false}) async {
    // Check cache
    if (!refresh &&
        state.lastFollowingUpdate != null &&
        DateTime.now().difference(state.lastFollowingUpdate!) < _cacheExpiry &&
        state.following.isNotEmpty) {
      debugPrint(' Using cached following');
      return;
    }

    if (state.isLoadingFollowing && !refresh) return;

    state = state.copyWith(
      isLoadingFollowing: true,
      error: null,
    );

    try {
      final page = refresh ? 0 : state.followingPage;
      final offset = page * _pageSize;

      // OPTIMIZATION: Get following IDs in batch
      final followsResponse = await _supabase
          .from('user_follows')
          .select('followee_id')
          .eq('follower_id', userId)
          .order('followed_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final followeeIds = (followsResponse as List<dynamic>)
          .map((item) => item['followee_id'] as String)
          .toList();

      if (followeeIds.isEmpty) {
        state = state.copyWith(
          following: refresh ? [] : state.following,
          isLoadingFollowing: false,
          hasMoreFollowing: false,
          followingPage: refresh ? 1 : state.followingPage + 1,
          lastFollowingUpdate: DateTime.now(),
        );
        return;
      }

      // OPTIMIZATION: Batch fetch user profiles
      final profilesResponse = await _supabase
          .from('user_profiles')
          .select('*')
          .inFilter('user_id', followeeIds);

      final newFollowing = (profilesResponse as List<dynamic>)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      // Update following status - we know we follow all these users
      Map<String, bool> updatedFollowingStatus = Map.from(state.followingStatus);
      for (var followedUser in newFollowing) {
        updatedFollowingStatus[followedUser.user_id] = true;
      }

      state = state.copyWith(
        following: refresh ? newFollowing : [...state.following, ...newFollowing],
        isLoadingFollowing: false,
        hasMoreFollowing: newFollowing.length == _pageSize,
        followingPage: refresh ? 1 : state.followingPage + 1,
        followingStatus: updatedFollowingStatus,
        lastFollowingUpdate: DateTime.now(),
      );

      debugPrint('Loaded ${newFollowing.length} following');
    } catch (e) {
      debugPrint(' Error loading following: $e');
      state = state.copyWith(
        isLoadingFollowing: false,
        error: 'Failed to load following: ${e.toString()}',
      );
    }
  }

  // OPTIMIZED: Toggle follow with optimistic updates + cache invalidation
  Future<void> toggleFollow(String targetUserId) async {
    if (_currentUserId == null || _currentUserId == targetUserId) return;

    // Prevent multiple simultaneous requests
    if (state.processingFollowRequests.contains(targetUserId)) {
      debugPrint('⏳ Already processing follow request for $targetUserId');
      return;
    }

    final isCurrentlyFollowing = state.followingStatus[targetUserId] ?? false;

    // OPTIMISTIC UPDATE
    state = state.copyWith(
      processingFollowRequests: {...state.processingFollowRequests, targetUserId},
      followingStatus: {
        ...state.followingStatus,
        targetUserId: !isCurrentlyFollowing,
      },
    );

    // Update counts optimistically
    _updateUserProfilesInLists(targetUserId, isCurrentlyFollowing ? -1 : 1);

    debugPrint('✅ Optimistic update: ${isCurrentlyFollowing ? 'Unfollowed' : 'Followed'} $targetUserId');

    try {
      if (isCurrentlyFollowing) {
        // Unfollow
        await _supabase
            .from('user_follows')
            .delete()
            .eq('follower_id', _currentUserId!)
            .eq('followee_id', targetUserId);

        debugPrint('✅ Unfollowed $targetUserId');

        await _updateFollowerCount(targetUserId, -1);
        await _updateFollowingCount(_currentUserId!, -1);
      } else {
        // Follow
        await _supabase.from('user_follows').insert({
          'follower_id': _currentUserId!,
          'followee_id': targetUserId,
          'followed_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ Followed $targetUserId');

        await _updateFollowerCount(targetUserId, 1);
        await _updateFollowingCount(_currentUserId!, 1);
      }

      // Invalidate cache after follow action
      state = state.copyWith(
        lastFollowersUpdate: null,
        lastFollowingUpdate: null,
      );
      debugPrint('✅ Follow toggle successful, cache invalidated');

      // Remove from processing
      final updatedProcessingSet = Set<String>.from(state.processingFollowRequests);
      updatedProcessingSet.remove(targetUserId);

      state = state.copyWith(
        processingFollowRequests: updatedProcessingSet,
        error: null,
      );

      return;
    } catch (e) {
      debugPrint('❌ Error toggling follow: $e');

      // REVERT optimistic update
      state = state.copyWith(
        followingStatus: {
          ...state.followingStatus,
          targetUserId: isCurrentlyFollowing,
        },
        error: 'Failed to ${isCurrentlyFollowing ? 'unfollow' : 'follow'} user',
      );

      // Revert counts
      _updateUserProfilesInLists(targetUserId, isCurrentlyFollowing ? 1 : -1);

      // Remove from processing
      final updatedProcessingSet = Set<String>.from(state.processingFollowRequests);
      updatedProcessingSet.remove(targetUserId);

      state = state.copyWith(
        processingFollowRequests: updatedProcessingSet,
      );

      // Rethrow for caller to handle
      rethrow;
    }
  }

  // Debounced toggle to prevent rapid-fire clicks
  Future<void> toggleFollowWithDebounce(String targetUserId) async {
    final now = DateTime.now();
    final lastTime = _lastToggleTime[targetUserId];

    if (lastTime != null && now.difference(lastTime) < _debounceDelay) {
      debugPrint('⏳ Debouncing follow toggle for $targetUserId');
      return;
    }

    _lastToggleTime[targetUserId] = now;
    await toggleFollow(targetUserId);
  }

  /// Global refresh to sync follow status across app
  Future<void> refreshFollowStatusGlobally(String targetUserId) async {
    if (_currentUserId == null) return;
    try {
      final response = await _supabase
          .from('user_follows')
          .select('follower_id')
          .eq('follower_id', _currentUserId!)
          .eq('followee_id', targetUserId)
          .maybeSingle();

      final isFollowing = response != null;
      state = state.copyWith(
        followingStatus: {
          ...state.followingStatus,
          targetUserId: isFollowing,
        },
      );
      debugPrint('✅ Refreshed follow status for $targetUserId: $isFollowing');
    } catch (e) {
      debugPrint('❌ Error refreshing follow status: $e');
    }
  }

  // Helper: Update user profiles in lists
  void _updateUserProfilesInLists(String targetUserId, int increment) {
    final updatedFollowers = state.followers.map((follower) {
      if (follower.user_id == targetUserId) {
        return follower.copyWith(
          followersCount: (follower.followersCount ?? 0) + increment,
        );
      }
      return follower;
    }).toList();

    final updatedFollowing = state.following.map((following) {
      if (following.user_id == targetUserId) {
        return following.copyWith(
          followersCount: (following.followersCount ?? 0) + increment,
        );
      }
      return following;
    }).toList();

    state = state.copyWith(
      followers: updatedFollowers,
      following: updatedFollowing,
    );
  }

  // OPTIMIZED: Update follower count with RPC
  Future<void> _updateFollowerCount(String userId, int increment) async {
    try {
      await _supabase.rpc('increment_followers_count', params: {
        'user_id': userId,
        'increment_by': increment,
      });
      debugPrint('✅ Updated follower count via RPC');
    } catch (e) {
      debugPrint('⚠️ RPC not available, using direct update: $e');
      try {
        await _supabase
            .from('user_profiles')
            .update({
              'followers_count': _supabase.rpc('GREATEST', params: {
                'a': 0,
                'b': '(followers_count + $increment)',
              }),
            })
            .eq('user_id', userId);
        debugPrint('✅ Updated follower count via direct update');
      } catch (directError) {
        debugPrint('❌ Failed to update follower count: $directError');
        state = state.copyWith(
          error: 'Failed to update follower count. Please refresh.',
        );
      }
    }
  }

  // OPTIMIZED: Update following count with RPC
  Future<void> _updateFollowingCount(String userId, int increment) async {
    try {
      await _supabase.rpc('increment_following_count', params: {
        'user_id': userId,
        'increment_by': increment,
      });
      debugPrint('✅ Updated following count via RPC');
    } catch (e) {
      debugPrint('⚠️ RPC not available, using direct update: $e');
      try {
        await _supabase
            .from('user_profiles')
            .update({
              'following_count': _supabase.rpc('GREATEST', params: {
                'a': 0,
                'b': '(following_count + $increment)',
              }),
            })
            .eq('user_id', userId);
        debugPrint('✅ Updated following count via direct update');
      } catch (directError) {
        debugPrint('❌ Failed to update following count: $directError');
        state = state.copyWith(
          error: 'Failed to update following count. Please refresh.',
        );
      }
    }
  }

  // Batch check following status
  Future<Map<String, bool>> batchCheckFollowing(List<String> userIds) async {
    if (_currentUserId == null || userIds.isEmpty) return {};

    try {
      final response = await _supabase
          .from('user_follows')
          .select('followee_id')
          .eq('follower_id', _currentUserId!)
          .inFilter('followee_id', userIds);

      final followingSet = (response as List<dynamic>)
          .map((item) => item['followee_id'] as String)
          .toSet();

      return Map.fromEntries(
        userIds.map((id) => MapEntry(id, followingSet.contains(id))),
      );
    } catch (e) {
      debugPrint('Error batch checking following: $e');
      return {};
    }
  }

  // Load more methods
  Future<void> loadMoreFollowers(String userId) async {
    if (!state.hasMoreFollowers || state.isLoadingFollowers) return;
    await loadFollowers(userId);
  }

  Future<void> loadMoreFollowing(String userId) async {
    if (!state.hasMoreFollowing || state.isLoadingFollowing) return;
    await loadFollowing(userId);
  }

  // Refresh both lists
  Future<void> refresh(String userId) async {
    await Future.wait([
      loadFollowers(userId, refresh: true),
      loadFollowing(userId, refresh: true),
    ]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  bool isFollowing(String userId) {
    return state.followingStatus[userId] ?? false;
  }

  bool isProcessingFollow(String userId) {
    return state.processingFollowRequests.contains(userId);
  }

  void clear() {
    state = const FollowState();
  }

  Future<void> refreshFollowingStatus(String userId) async {
    if (_currentUserId == null) return;

    final statusMap = await batchCheckFollowing([userId]);

    state = state.copyWith(
      followingStatus: {
        ...state.followingStatus,
        ...statusMap,
      },
    );
  }
}

final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  return FollowNotifier();
});

final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(followProvider).followingStatus[userId] ?? false;
});

final isProcessingFollowProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(followProvider).processingFollowRequests.contains(userId);
});
