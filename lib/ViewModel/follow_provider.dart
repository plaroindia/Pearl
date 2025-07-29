import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/user_profile.dart';

// Follow State class to hold follow-related data
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
  final Map<String, bool> followingStatus; // userId -> isFollowing
  final Set<String> processingFollowRequests; // Track which users are being processed

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
    );
  }
}

// Follow Notifier class that handles all follow-related operations
class FollowNotifier extends StateNotifier<FollowState> {
  FollowNotifier() : super(const FollowState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 20;

  // Get current user ID - Fixed getter
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // Load followers for a specific user
  Future<void> loadFollowers(String userId, {bool refresh = false}) async {
    if (state.isLoadingFollowers && !refresh) return;

    state = state.copyWith(
      isLoadingFollowers: true,
      error: null,
    );

    try {
      final page = refresh ? 0 : state.followersPage;
      final offset = page * _pageSize;

      // First, let's try a simpler query to avoid foreign key issues
      final response = await _supabase
          .from('user_follows')
          .select('follower_id')
          .eq('followee_id', userId)
          .order('followed_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      // Get user profiles separately
      final followerIds = (response as List).map((item) => item['follower_id'] as String).toList();

      List<UserProfile> newFollowers = [];
      if (followerIds.isNotEmpty) {
        // Use individual queries or batch them differently
        for (String followerId in followerIds) {
          try {
            final profileResponse = await _supabase
                .from('user_profiles')
                .select('*')
                .eq('user_id', followerId)
                .maybeSingle();

            if (profileResponse != null) {
              newFollowers.add(UserProfile.fromJson(profileResponse));
            }
          } catch (e) {
            print('Error fetching profile for $followerId: $e');
          }
        }
      }

      // Update following status for current user
      Map<String, bool> updatedFollowingStatus = Map.from(state.followingStatus);
      if (_currentUserId != null) {
        for (var follower in newFollowers) {
          updatedFollowingStatus[follower.user_id] = await _checkIfFollowing(follower.user_id);
        }
      }

      state = state.copyWith(
        followers: refresh ? newFollowers : [...state.followers, ...newFollowers],
        isLoadingFollowers: false,
        hasMoreFollowers: newFollowers.length == _pageSize,
        followersPage: refresh ? 1 : state.followersPage + 1,
        followingStatus: updatedFollowingStatus,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFollowers: false,
        error: 'Failed to load followers: ${e.toString()}',
      );
    }
  }

  // Load following for a specific user
  Future<void> loadFollowing(String userId, {bool refresh = false}) async {
    if (state.isLoadingFollowing && !refresh) return;

    state = state.copyWith(
      isLoadingFollowing: true,
      error: null,
    );

    try {
      final page = refresh ? 0 : state.followingPage;
      final offset = page * _pageSize;

      // First, let's try a simpler query to avoid foreign key issues
      final response = await _supabase
          .from('user_follows')
          .select('followee_id')
          .eq('follower_id', userId)
          .order('followed_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      // Get user profiles separately
      final followeeIds = (response as List).map((item) => item['followee_id'] as String).toList();

      List<UserProfile> newFollowing = [];
      if (followeeIds.isNotEmpty) {
        // Use individual queries or batch them differently
        for (String followeeId in followeeIds) {
          try {
            final profileResponse = await _supabase
                .from('user_profiles')
                .select('*')
                .eq('user_id', followeeId)
                .maybeSingle();

            if (profileResponse != null) {
              newFollowing.add(UserProfile.fromJson(profileResponse));
            }
          } catch (e) {
            print('Error fetching profile for $followeeId: $e');
          }
        }
      }

      // Update following status for current user
      Map<String, bool> updatedFollowingStatus = Map.from(state.followingStatus);
      if (_currentUserId != null) {
        for (var followedUser in newFollowing) {
          updatedFollowingStatus[followedUser.user_id] = true; // We know we're following them
        }
      }

      state = state.copyWith(
        following: refresh ? newFollowing : [...state.following, ...newFollowing],
        isLoadingFollowing: false,
        hasMoreFollowing: newFollowing.length == _pageSize,
        followingPage: refresh ? 1 : state.followingPage + 1,
        followingStatus: updatedFollowingStatus,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFollowing: false,
        error: 'Failed to load following: ${e.toString()}',
      );
    }
  }

  // Toggle follow/unfollow for a user with improved error handling
  Future<void> toggleFollow(String targetUserId) async {
    if (_currentUserId == null || _currentUserId == targetUserId) return;

    // Prevent multiple simultaneous requests for the same user
    if (state.processingFollowRequests.contains(targetUserId)) return;

    // Add to processing set
    state = state.copyWith(
      processingFollowRequests: {...state.processingFollowRequests, targetUserId},
    );

    try {
      final isCurrentlyFollowing = state.followingStatus[targetUserId] ?? false;

      if (isCurrentlyFollowing) {
        // Unfollow
        await _supabase
            .from('user_follows')
            .delete()
            .eq('follower_id', _currentUserId!)
            .eq('followee_id', targetUserId);

        // Update follower count
        await _updateFollowerCount(targetUserId, -1);
        await _updateFollowingCount(_currentUserId!, -1);
      } else {
        // Follow
        await _supabase
            .from('user_follows')
            .insert({
          'follower_id': _currentUserId!,
          'followee_id': targetUserId,
          'followed_at': DateTime.now().toIso8601String(),
        });

        // Update follower count
        await _updateFollowerCount(targetUserId, 1);
        await _updateFollowingCount(_currentUserId!, 1);
      }

      // Update following status after successful operation
      Map<String, bool> updatedFollowingStatus = Map.from(state.followingStatus);
      updatedFollowingStatus[targetUserId] = !isCurrentlyFollowing;

      state = state.copyWith(
        followingStatus: updatedFollowingStatus,
        error: null, // Clear any previous errors
      );

      // Update followers/following lists with new counts
      _updateUserProfilesInLists(targetUserId, isCurrentlyFollowing ? -1 : 1);

    } catch (e) {
      // Don't do optimistic updates, just show error
      state = state.copyWith(
        error: 'Failed to ${state.followingStatus[targetUserId] == true ? 'unfollow' : 'follow'} user: ${e.toString()}',
      );
    } finally {
      // Remove from processing set
      final updatedProcessingSet = Set<String>.from(state.processingFollowRequests);
      updatedProcessingSet.remove(targetUserId);

      state = state.copyWith(
        processingFollowRequests: updatedProcessingSet,
      );
    }
  }

  // Helper method to update user profiles in lists
  void _updateUserProfilesInLists(String targetUserId, int increment) {
    // Update followers list if target user is in current followers
    List<UserProfile> updatedFollowers = state.followers.map((follower) {
      if (follower.user_id == targetUserId) {
        return follower.copyWith(
          followersCount: (follower.followersCount ?? 0) + increment,
        );
      }
      return follower;
    }).toList();

    // Update following list if target user is in current following
    List<UserProfile> updatedFollowing = state.following.map((following) {
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

  // Check if current user is following a specific user
  Future<bool> _checkIfFollowing(String targetUserId) async {
    if (_currentUserId == null || _currentUserId == targetUserId) return false;

    try {
      final response = await _supabase
          .from('user_follows')
          .select('follower_id')
          .eq('follower_id', _currentUserId!)
          .eq('followee_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Update follower count in user profile
  Future<void> _updateFollowerCount(String userId, int increment) async {
    try {
      // Try using RPC first
      await _supabase.rpc('increment_followers_count', params: {
        'user_id': userId,
        'increment_by': increment,
      });
    } catch (e) {
      // // If RPC doesn't exist, fall back to manual update
      // try {
      //   final currentProfile = await _supabase
      //       .from('user_profiles')
      //       .select('followers_count')
      //       .eq('user_id', userId)
      //       .single();
      //
      //   final currentCount = currentProfile['followers_count'] ?? 0;
      //   final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
      //
      //   await _supabase
      //       .from('user_profiles')
      //       .update({'followers_count': newCount})
      //       .eq('user_id', userId);
      // } catch (fallbackError) {
      //   // Log error but don't throw - count updates are not critical
      //   print('Failed to update follower count: $fallbackError');
      // }
    }
  }

  // Update following count in user profile
  Future<void> _updateFollowingCount(String userId, int increment) async {
    try {
      // Try using RPC first
      await _supabase.rpc('increment_following_count', params: {
        'user_id': userId,
        'increment_by': increment,
      });
    } catch (e) {
      // // If RPC doesn't exist, fall back to manual update
      // try {
      //   final currentProfile = await _supabase
      //       .from('user_profiles')
      //       .select('following_count')
      //       .eq('user_id', userId)
      //       .single();
      //
      //   final currentCount = currentProfile['following_count'] ?? 0;
      //   final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
      //
      //   await _supabase
      //       .from('user_profiles')
      //       .update({'following_count': newCount})
      //       .eq('user_id', userId);
      // } catch (fallbackError) {
      //   // Log error but don't throw - count updates are not critical
      //   print('Failed to update following count: $fallbackError');
      // }
    }
  }

  // Load more followers
  Future<void> loadMoreFollowers(String userId) async {
    if (!state.hasMoreFollowers || state.isLoadingFollowers) return;
    await loadFollowers(userId);
  }

  // Load more following
  Future<void> loadMoreFollowing(String userId) async {
    if (!state.hasMoreFollowing || state.isLoadingFollowing) return;
    await loadFollowing(userId);
  }

  // Refresh both lists and following status
  Future<void> refresh(String userId) async {
    await Future.wait([
      loadFollowers(userId, refresh: true),
      loadFollowing(userId, refresh: true),
    ]);

    // Refresh following status for all loaded users
    if (_currentUserId != null) {
      Map<String, bool> updatedFollowingStatus = Map.from(state.followingStatus);
      final allUsers = [...state.followers, ...state.following];

      for (var user in allUsers) {
        updatedFollowingStatus[user.user_id] = await _checkIfFollowing(user.user_id);
      }

      state = state.copyWith(followingStatus: updatedFollowingStatus);
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get following status for a specific user
  bool isFollowing(String userId) {
    return state.followingStatus[userId] ?? false;
  }

  // Check if a follow request is being processed
  bool isProcessingFollow(String userId) {
    return state.processingFollowRequests.contains(userId);
  }

  // Clear all data (useful when switching between users)
  void clear() {
    state = const FollowState();
  }

  // Method to refresh following status for a specific user
  Future<void> refreshFollowingStatus(String userId) async {
    if (_currentUserId == null) return;

    final isFollowingUser = await _checkIfFollowing(userId);
    Map<String, bool> updatedFollowingStatus = Map.from(state.followingStatus);
    updatedFollowingStatus[userId] = isFollowingUser;

    state = state.copyWith(followingStatus: updatedFollowingStatus);
  }
}

// Provider for the follow functionality
final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  return FollowNotifier();
});

// Provider for checking if current user follows a specific user
final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  final followState = ref.watch(followProvider);
  return followState.followingStatus[userId] ?? false;
});

// Provider for checking if a follow request is being processed
final isProcessingFollowProvider = Provider.family<bool, String>((ref, userId) {
  final followState = ref.watch(followProvider);
  return followState.processingFollowRequests.contains(userId);
});