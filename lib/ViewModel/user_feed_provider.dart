import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/post.dart';
import '../Model/toast.dart';

// State class for profile feed
class ProfileFeedState {
  final List<Post_feed> posts;
  final List<Toast_feed> toasts;
  final bool isLoadingPosts;
  final bool isLoadingToasts;
  final bool isLoadingMorePosts;
  final bool isLoadingMoreToasts;
  final String? error;
  final Set<String> likingPosts;
  final Set<String> likingToasts;
  final bool hasMorePosts;
  final bool hasMoreToasts;
  final int currentPostPage;
  final int currentToastPage;

  const ProfileFeedState({
    this.posts = const [],
    this.toasts = const [],
    this.isLoadingPosts = false,
    this.isLoadingToasts = false,
    this.isLoadingMorePosts = false,
    this.isLoadingMoreToasts = false,
    this.error,
    this.likingPosts = const {},
    this.likingToasts = const {},
    this.hasMorePosts = true,
    this.hasMoreToasts = true,
    this.currentPostPage = 0,
    this.currentToastPage = 0,
  });

  ProfileFeedState copyWith({
    List<Post_feed>? posts,
    List<Toast_feed>? toasts,
    bool? isLoadingPosts,
    bool? isLoadingToasts,
    bool? isLoadingMorePosts,
    bool? isLoadingMoreToasts,
    String? error,
    Set<String>? likingPosts,
    Set<String>? likingToasts,
    bool? hasMorePosts,
    bool? hasMoreToasts,
    int? currentPostPage,
    int? currentToastPage,
  }) {
    return ProfileFeedState(
      posts: posts ?? this.posts,
      toasts: toasts ?? this.toasts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingToasts: isLoadingToasts ?? this.isLoadingToasts,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
      isLoadingMoreToasts: isLoadingMoreToasts ?? this.isLoadingMoreToasts,
      error: error,
      likingPosts: likingPosts ?? this.likingPosts,
      likingToasts: likingToasts ?? this.likingToasts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      hasMoreToasts: hasMoreToasts ?? this.hasMoreToasts,
      currentPostPage: currentPostPage ?? this.currentPostPage,
      currentToastPage: currentToastPage ?? this.currentToastPage,
    );
  }
}

// Provider
final profileFeedProvider = StateNotifierProvider<ProfileFeedNotifier, ProfileFeedState>((ref) {
  return ProfileFeedNotifier();
});

// Profile Feed Provider
class ProfileFeedNotifier extends StateNotifier<ProfileFeedState> {
  ProfileFeedNotifier() : super(const ProfileFeedState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 12; // Increased for grid layout

  // Load user's posts
  Future<void> loadUserPosts() async {
    if (state.isLoadingPosts) return;

    state = state.copyWith(isLoadingPosts: true, error: null);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoadingPosts: false,
          error: 'User not authenticated',
        );
        return;
      }

      final response = await _supabase
          .from('post')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('user_id', user.id)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final List<Post_feed> newPosts = [];

      for (var postData in response) {
        final String postId = postData['post_id'].toString();

        // Get like count
        final likeCountResponse = await _supabase
            .from('post_likes')
            .select('*')
            .eq('post_id', postId);
        final int likeCount = likeCountResponse.length;

        // Get comment count
        final commentCountResponse = await _supabase
            .from('post_comments')
            .select('*')
            .eq('post_id', postId);
        final int commentCount = commentCountResponse.length;

        // Check if current user liked this post
        bool isLiked = false;
        final likeResponse = await _supabase
            .from('post_likes')
            .select('like_id')
            .eq('post_id', postId)
            .eq('user_id', user.id)
            .maybeSingle();
        isLiked = likeResponse != null;

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postId,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
        });

        newPosts.add(post);
      }

      state = state.copyWith(
        posts: newPosts,
        isLoadingPosts: false,
        hasMorePosts: newPosts.length == _pageSize,
        currentPostPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPosts: false,
        error: 'Failed to load posts: $e',
      );
    }
  }

  // Load user's toasts
  Future<void> loadUserToasts() async {
    if (state.isLoadingToasts) return;

    state = state.copyWith(isLoadingToasts: true, error: null);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoadingToasts: false,
          error: 'User not authenticated',
        );
        return;
      }

      print('Loading toasts for user: ${user.id}'); // Debug log

      final response = await _supabase
          .from('toasts')
          .select('''
          *,
          user_profiles!inner(username, profile_pic)
        ''')
          .eq('user_id', user.id)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      print('Toast response: $response'); // Debug log

      if (response.isEmpty) {
        print('No toasts found for user');
        state = state.copyWith(
          toasts: [],
          isLoadingToasts: false,
          hasMoreToasts: false,
          currentToastPage: 1,
        );
        return;
      }

      final List<Toast_feed> newToasts = [];

      for (var toastData in response) {
        try {
          final String toastId = toastData['toast_id'] as String;

          // Get like count
          final likeCountResponse = await _supabase
              .from('toast_likes')
              .select('*')
              .eq('toast_id', toastId);
          final int likeCount = likeCountResponse.length;

          // Get comment count
          final commentCountResponse = await _supabase
              .from('toast_comments')
              .select('*')
              .eq('toast_id', toastId);
          final int commentCount = commentCountResponse.length;

          // Check if current user liked this toast
          bool isLiked = false;
          final likeResponse = await _supabase
              .from('toast_likes')
              .select('toast_like_id')
              .eq('toast_id', toastId)
              .eq('user_id', user.id)
              .maybeSingle();
          isLiked = likeResponse != null;

          final toast = Toast_feed.fromMap({
            ...toastData,
            'toast_id': toastId,
            'username': toastData['user_profiles']['username'],
            'profile_pic': toastData['user_profiles']['profile_pic'],
            'like_count': likeCount,
            'comment_count': commentCount,
            'isliked': isLiked,
          });

          newToasts.add(toast);
        } catch (e) {
          print('Error processing toast: $e');
          // Continue with other toasts instead of failing completely
          continue;
        }
      }

      state = state.copyWith(
        toasts: newToasts,
        isLoadingToasts: false,
        hasMoreToasts: newToasts.length == _pageSize,
        currentToastPage: 1,
      );

      print('Successfully loaded ${newToasts.length} toasts'); // Debug log

    } catch (e) {
      print('Error loading toasts: $e'); // Debug log
      state = state.copyWith(
        isLoadingToasts: false,
        error: 'Failed to load toasts: $e',
      );
    }
  }

  // Load more posts (pagination)
  Future<void> loadMoreUserPosts() async {
    if (state.isLoadingMorePosts || !state.hasMorePosts) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoadingMorePosts: true, error: null);

    try {
      final startRange = state.currentPostPage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('post')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('user_id', user.id)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<Post_feed> newPosts = [];

      for (var postData in response) {
        final String postId = postData['post_id'].toString();

        // Avoid duplicates
        final alreadyExists = state.posts.any((p) => p.post_id == postId);
        if (alreadyExists) continue;

        // Get like count
        final likeCountResponse = await _supabase
            .from('post_likes')
            .select('*')
            .eq('post_id', postId);
        final int likeCount = likeCountResponse.length;

        // Get comment count
        final commentCountResponse = await _supabase
            .from('post_comments')
            .select('*')
            .eq('post_id', postId);
        final int commentCount = commentCountResponse.length;

        // Check if current user liked this post
        bool isLiked = false;
        final likeResponse = await _supabase
            .from('post_likes')
            .select('like_id')
            .eq('post_id', postId)
            .eq('user_id', user.id)
            .maybeSingle();
        isLiked = likeResponse != null;

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postId,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
        });

        newPosts.add(post);
      }

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMorePosts: false,
        hasMorePosts: newPosts.length == _pageSize,
        currentPostPage: state.currentPostPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMorePosts: false,
        error: 'Failed to load more posts: $e',
      );
    }
  }

  // Load more toasts (pagination)
  Future<void> loadMoreUserToasts() async {
    if (state.isLoadingMoreToasts || !state.hasMoreToasts) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoadingMoreToasts: true, error: null);

    try {
      final startRange = state.currentToastPage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('toasts')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('user_id', user.id)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<Toast_feed> newToasts = [];

      for (var toastData in response) {
        final String toastId = toastData['toast_id'].toString();

        // Avoid duplicates
        final alreadyExists = state.toasts.any((t) => t.toast_id == toastId);
        if (alreadyExists) continue;

        // Get like count
        final likeCountResponse = await _supabase
            .from('toast_likes')
            .select('*')
            .eq('toast_id', toastId);
        final int likeCount = likeCountResponse.length;

        // Get comment count
        final commentCountResponse = await _supabase
            .from('toast_comments')
            .select('*')
            .eq('toast_id', toastId);
        final int commentCount = commentCountResponse.length;

        // Check if current user liked this toast
        bool isLiked = false;
        final likeResponse = await _supabase
            .from('toast_likes')
            .select('toast_like_id')
            .eq('toast_id', toastId)
            .eq('user_id', user.id)
            .maybeSingle();
        isLiked = likeResponse != null;

        final toast = Toast_feed.fromMap({
          ...toastData,
          'toast_id': toastId,
          'username': toastData['user_profiles']['username'],
          'profile_pic': toastData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
        });

        newToasts.add(toast);
      }

      state = state.copyWith(
        toasts: [...state.toasts, ...newToasts],
        isLoadingMoreToasts: false,
        hasMoreToasts: newToasts.length == _pageSize,
        currentToastPage: state.currentToastPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMoreToasts: false,
        error: 'Failed to load more toasts: $e',
      );
    }
  }

  // Refresh user's posts and toasts
  Future<void> refreshUserContent() async {
    state = const ProfileFeedState();
    await Future.wait([
      loadUserPosts(),
      loadUserToasts(),
    ]);
  }

  // Toggle like for user's post
  Future<void> togglePostLike(String postId) async {
    if (state.posts.isEmpty || state.likingPosts.contains(postId)) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
    if (postIndex == -1) return;

    final currentPost = state.posts[postIndex];
    final currentlyLiked = currentPost.isliked;
    final currentLikeCount = currentPost.like_count;

    // Optimistic update
    final newPosts = [...state.posts];
    newPosts[postIndex] = currentPost.copyWith(
      like_count: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
      isliked: !currentlyLiked,
    );

    state = state.copyWith(
      posts: newPosts,
      likingPosts: {...state.likingPosts, postId},
    );

    try {
      if (currentlyLiked) {
        // Unlike the post
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);

        await _supabase
            .from('post')
            .update({'like_count': currentLikeCount - 1})
            .eq('post_id', postId);
      } else {
        // Like the post
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        await _supabase
            .from('post')
            .update({'like_count': currentLikeCount + 1})
            .eq('post_id', postId);
      }

      // Remove from likingPosts
      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(postId),
      );

    } catch (error) {
      // Revert optimistic update
      final revertedPosts = [...state.posts];
      final currentPostIndex = revertedPosts.indexWhere((post) => post.post_id == postId);
      if (currentPostIndex != -1) {
        revertedPosts[currentPostIndex] = currentPost;
      }

      state = state.copyWith(
        posts: revertedPosts,
        likingPosts: {...state.likingPosts}..remove(postId),
        error: 'Failed to update post like: ${error.toString()}',
      );
    }
  }

  // Toggle like for user's toast
  Future<void> toggleToastLike(String toastId) async {
    if (state.toasts.isEmpty || state.likingToasts.contains(toastId)) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final toastIndex = state.toasts.indexWhere((toast) => toast.toast_id == toastId);
    if (toastIndex == -1) return;

    final currentToast = state.toasts[toastIndex];
    final currentlyLiked = currentToast.isliked;
    final currentLikeCount = currentToast.like_count;

    // Optimistic update
    final newToasts = [...state.toasts];
    newToasts[toastIndex] = currentToast.copyWith(
      like_count: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
      isliked: !currentlyLiked,
    );

    state = state.copyWith(
      toasts: newToasts,
      likingToasts: {...state.likingToasts, toastId},
    );

    try {
      if (currentlyLiked) {
        // Unlike the toast
        await _supabase
            .from('toast_likes')
            .delete()
            .eq('toast_id', toastId)
            .eq('user_id', user.id);
      } else {
        // Like the toast
        await _supabase.from('toast_likes').insert({
          'toast_id': toastId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });
      }

      // Remove from likingToasts
      state = state.copyWith(
        likingToasts: {...state.likingToasts}..remove(toastId),
      );

    } catch (error) {
      print('Error toggling toast like: $error'); // Debug log

      // Revert optimistic update
      final revertedToasts = [...state.toasts];
      final currentToastIndex = revertedToasts.indexWhere((toast) => toast.toast_id == toastId);
      if (currentToastIndex != -1) {
        revertedToasts[currentToastIndex] = currentToast;
      }

      state = state.copyWith(
        toasts: revertedToasts,
        likingToasts: {...state.likingToasts}..remove(toastId),
        error: 'Failed to update toast like: ${error.toString()}',
      );
    }
  }

  // Delete user's post
  Future<bool> deletePost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // Delete from database
      await _supabase
          .from('post')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id); // Ensure only owner can delete

      // Remove from local state
      final updatedPosts = state.posts.where((post) => post.post_id != postId).toList();
      state = state.copyWith(posts: updatedPosts);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete post: $e');
      return false;
    }
  }

  // Delete user's toast
  Future<bool> deleteToast(String toastId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // Delete from database
      await _supabase
          .from('toasts')
          .delete()
          .eq('toast_id', toastId)
          .eq('user_id', user.id); // Ensure only owner can delete

      // Remove from local state
      final updatedToasts = state.toasts.where((toast) => toast.toast_id != toastId).toList();
      state = state.copyWith(toasts: updatedToasts);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete toast: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}