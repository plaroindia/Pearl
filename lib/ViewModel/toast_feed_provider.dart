import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plaro_3/Model/toast.dart';


// State for toast feed
class ToastFeedState {
  final List<Toast_feed> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const ToastFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  ToastFeedState copyWith({
    List<Toast_feed>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return ToastFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Toast Feed Provider
final toastFeedProvider = StateNotifierProvider<ToastFeedNotifier, ToastFeedState>((ref) {
  return ToastFeedNotifier();
});

class ToastFeedNotifier extends StateNotifier<ToastFeedState> {
  ToastFeedNotifier() : super(const ToastFeedState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 10;

  // Load initial posts
  Future<void> loadPosts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _supabase
          .from('toasts')
          .select('''
            toast_id,
            user_id,
            title,
            content,
            tags,
            created_at,
            is_published,
            like_count,
            comment_count,
            share_count,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final posts = (response as List)
          .map((json) => _mapToToastFeed(json))
          .toList();

      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == _pageSize,
        currentPage: 1,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final startRange = state.currentPage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('toasts')
          .select('''
            toast_id,
            user_id,
            title,
            content,
            tags,
            created_at,
            is_published,
            like_count,
            comment_count,
            share_count,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final newPosts = (response as List)
          .map((json) => _mapToToastFeed(json))
          .toList();

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: newPosts.length == _pageSize,
        currentPage: state.currentPage + 1,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Refresh posts
  Future<void> refreshPosts() async {
    state = const ToastFeedState();
    await loadPosts();
  }

  // Toggle like for a post
  Future<void> toggleLike(String toastId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Find the post in current state
      final postIndex = state.posts.indexWhere((post) => post.toast_id == toastId);
      if (postIndex == -1) return;

      final post = state.posts[postIndex];
      final newPosts = [...state.posts];

      // Optimistically update UI
      newPosts[postIndex].incrementLikes();
      state = state.copyWith(posts: newPosts);

      // Check if user already liked this post
      final existingLike = await _supabase
          .from('toast_likes')
          .select('toast_like_id')
          .eq('toast_id', toastId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike the post
        await _supabase
            .from('toast_likes')
            .delete()
            .eq('toast_id', toastId)
            .eq('user_id', user.id);

        // Update likes count in toasts table
        await _supabase
            .from('toasts')
            .update({'like_count': post.like_count - 1})
            .eq('toast_id', toastId);
      } else {
        // Like the post
        await _supabase
            .from('toast_likes')
            .insert({
          'toast_id': toastId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        // Update likes count in toasts table
        await _supabase
            .from('toasts')
            .update({'like_count': post.like_count + 1})
            .eq('toast_id', toastId);
      }
    } catch (error) {
      // Revert optimistic update on error
      await refreshPosts();
    }
  }

  // Helper method to map JSON to Toast_feed
  Toast_feed _mapToToastFeed(Map<String, dynamic> json) {
    final userProfile = json['user_profiles'] as Map<String, dynamic>?;

    return Toast_feed(
      toast_id: json['toast_id'],
      user_id: json['user_id'],
      username: userProfile?['username'] ?? 'Unknown User',
      profile_pic: userProfile?['profile_pic'],
      title: json['title'],
      content: json['content'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      created_at: json['created_at'],
      like_count: json['like_count'] ?? 0,
      comment_count: json['comment_count'] ?? 0,
      share_count: json['share_count'] ?? 0,
      isliked: false, // You'll need to check this based on current user
      commentsList: [], // Load comments separately when needed
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}