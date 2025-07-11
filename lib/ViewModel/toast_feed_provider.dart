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
  final Set<String> likingPosts; // Track posts being liked/unliked

  const ToastFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.likingPosts = const {},
  });

  ToastFeedState copyWith({
    List<Toast_feed>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
    Set<String>? likingPosts,
  }) {
    return ToastFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      likingPosts: likingPosts ?? this.likingPosts,
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
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

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

      // Get liked posts for current user
      final likedToastsResponse = await _supabase
          .from('toast_likes')
          .select('toast_id')
          .eq('user_id', user.id);

      final likedToastIds = (likedToastsResponse as List)
          .map((e) => e['toast_id'] as String)
          .toSet();

      final posts = (response as List)
          .map((json) => _mapToToastFeed(json, user.id, likedToastIds))
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

    final user = _supabase.auth.currentUser;
    if (user == null) return;

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

      final likedToastsResponse = await _supabase
          .from('toast_likes')
          .select('toast_id')
          .eq('user_id', user.id);

      final likedToastIds = (likedToastsResponse as List)
          .map((e) => e['toast_id'] as String)
          .toSet();

      final newPosts = (response as List)
          .map((json) => _mapToToastFeed(json, user.id, likedToastIds))
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



  // Updated toggleLike method with Instagram-like optimistic updates
  Future<void> toggleLike(String toastId) async {
    print('🔵 toggleLike called for toast: $toastId');

    // Check if posts are loaded
    if (state.posts.isEmpty) {
      print('🟡 No posts loaded yet, loading posts first...');
      await loadPosts();

      // Check again after loading
      if (state.posts.isEmpty) {
        print('🔴 Still no posts after loading, cannot toggle like');
        return;
      }
    }

    // Prevent multiple simultaneous like operations on the same post
    if (state.likingPosts.contains(toastId)) {
      print('🟡 Already liking this post, returning');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('🔴 User not authenticated');
      return;
    }

    print('🔵 User ID: ${user.id}');
    print('🔍 Current posts in state: ${state.posts.length}');

    // Find the post in current state
    final postIndex = state.posts.indexWhere((post) => post.toast_id == toastId);
    if (postIndex == -1) {
      print('🔴 Post not found in current state');
      print('🔍 Available post IDs: ${state.posts.map((p) => p.toast_id).toList()}');

      // Try to refresh the specific post
      await refreshPost(toastId);

      // Try one more time
      final newPostIndex = state.posts.indexWhere((post) => post.toast_id == toastId);
      if (newPostIndex == -1) {
        print('🔴 Post still not found after refresh');
        return;
      }
    }

    final currentPost = state.posts[postIndex];
    final currentlyLiked = currentPost.isliked;
    final currentLikeCount = currentPost.like_count;

    print('🔵 Current like status: $currentlyLiked, count: $currentLikeCount');

    // OPTIMISTIC UPDATE: Update UI immediately for instant feedback
    final newPosts = [...state.posts];
    newPosts[postIndex] = currentPost.copyWith(
      like_count: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
      isliked: !currentlyLiked,
    );

    state = state.copyWith(
      posts: newPosts,
      likingPosts: {...state.likingPosts, toastId},
    );

    print('🔵 Optimistic update applied - UI updated immediately');

    try {
      if (currentlyLiked) {
        // Unlike the post
        print('🔵 Attempting to unlike post...');

        final deleteResponse = await _supabase
            .from('toast_likes')
            .delete()
            .eq('toast_id', toastId)
            .eq('user_id', user.id);

        print('🔵 Delete response: $deleteResponse');

        // Update likes count in toasts table
        final updateResponse = await _supabase
            .from('toasts')
            .update({'like_count': currentLikeCount - 1})
            .eq('toast_id', toastId);

        print('🔵 Update response: $updateResponse');
        //await refreshSinglePost(toastId);

      } else {
        // Like the post
        print('🔵 Attempting to like post...');

        final insertResponse = await _supabase.from('toast_likes').insert({
          'toast_id': toastId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        print('🔵 Insert response: $insertResponse');

        // Update likes count in toasts table
        final updateResponse = await _supabase
            .from('toasts')
            .update({'like_count': currentLikeCount + 1})
            .eq('toast_id', toastId);

        print('🔵 Update response: $updateResponse');

      }
     // await refreshSinglePost(toastId);

      print('🟢 Like operation completed successfully');

      // Remove from likingPosts - keep the optimistic update since it succeeded
      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(toastId),
      );

      print('🟢 Loading indicator removed, optimistic update kept');

    } catch (error) {
      print('🔴 Error in toggleLike: $error');

      // REVERT OPTIMISTIC UPDATE: Restore original state on error
      final revertedPosts = [...state.posts];
      final currentPostIndex = revertedPosts.indexWhere((post) => post.toast_id == toastId);
      if (currentPostIndex != -1) {
        revertedPosts[currentPostIndex] = currentPost; // Restore original state
      }

      state = state.copyWith(
        posts: revertedPosts,
        likingPosts: {...state.likingPosts}..remove(toastId),
        error: 'Failed to update like: ${error.toString()}',
      );

      print('🔴 Optimistic update reverted due to error');
    }
  }

  // Updated refreshPost method to handle the specific post update
  Future<void> refreshPost(String toastId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      print('🔵 Refreshing post: $toastId');

      // Get the updated post from database
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
          .eq('toast_id', toastId)
          .eq('is_published', true)
          .single();

      // Get liked status
      final likedResponse = await _supabase
          .from('toast_likes')
          .select('toast_id')
          .eq('toast_id', toastId)
          .eq('user_id', user.id)
          .maybeSingle();

      final isLiked = likedResponse != null;
      final updatedPost = _mapToToastFeed(
        response,
        user.id,
        isLiked ? {toastId} : <String>{},
      );

      // Update the post in the current state
      final postIndex = state.posts.indexWhere((post) => post.toast_id == toastId);
      if (postIndex != -1) {
        final newPosts = [...state.posts];
        newPosts[postIndex] = updatedPost;
        state = state.copyWith(posts: newPosts);
        print('🟢 Post updated in state with fresh data');
      } else {
        // Add to beginning of the list if not found
        state = state.copyWith(
          posts: [updatedPost, ...state.posts],
        );
        print('🟢 Post added to state');
      }
    } catch (error) {
      print('🔴 Error refreshing post: $error');
    }
  }

  // Helper method to map JSON to Toast_feed
  Toast_feed _mapToToastFeed(
      Map<String, dynamic> json,
      String userId,
      Set<String> likedToastIds,
      ) {
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
      isliked: likedToastIds.contains(json['toast_id']),
      commentsList: [],
    );
  }

  Future<List<Comment>> loadComments(String toastId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('toast_comments')
          .select('''
            comment_id,
            toast_id,
            user_id,
            content,
            like_count,
            created_at,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('toast_id', toastId)
          .order('created_at', ascending: false);

      // Get liked comments for current user
      final likedCommentsResponse = await _supabase
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', user.id);

      final likedCommentIds = (likedCommentsResponse as List)
          .map((e) => e['comment_id'] as int)
          .toSet();

      return (response as List)
          .map((json) => Comment.fromMap({
        ...json,
        'username': json['user_profiles']['username'],
        'profile_pic': json['user_profiles']['profile_pic'],
        'uliked': likedCommentIds.contains(json['comment_id']),
      }))
          .toList();
    } catch (error) {
      print('Error loading comments: $error');
      return [];
    }
  }

  // Add method to create a comment
  Future<bool> addComment(String toastId, String content) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // Insert comment
      await _supabase.from('toast_comments').insert({
        'toast_id': toastId,
        'user_id': user.id,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update comment count in toasts table
      final currentPost = state.posts.firstWhere(
            (post) => post.toast_id == toastId,
        orElse: () => Toast_feed(toast_id: toastId, user_id: '', username: '', commentsList: []),
      );

      await _supabase
          .from('toasts')
          .update({'comment_count': currentPost.comment_count + 1})
          .eq('toast_id', toastId);

      // Update local state
      final postIndex = state.posts.indexWhere((post) => post.toast_id == toastId);
      if (postIndex != -1) {
        final newPosts = [...state.posts];
        newPosts[postIndex] = currentPost.copyWith(
          comment_count: currentPost.comment_count + 1,
        );
        state = state.copyWith(posts: newPosts);
      }

      return true;
    } catch (error) {
      print('Error adding comment: $error');
      return false;
    }
  }
  Future<void> toggleCommentLike(int commentId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Check if already liked
      final existingLike = await _supabase
          .from('toast_comment_likes')
          .select('comment_id')
          .eq('comment_id', commentId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('toast_comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', user.id);

        // Decrement like count - get current count first
        final currentComment = await _supabase
            .from('toast_comments')
            .select('like_count')
            .eq('comment_id', commentId)
            .single();

        final newCount = (currentComment['like_count'] as int) - 1;
        await _supabase
            .from('toast_comments')
            .update({'like_count': newCount >= 0 ? newCount : 0})
            .eq('comment_id', commentId);
      } else {
        // Like
        await _supabase.from('toast_comment_likes').insert({
          'comment_id': commentId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        // Increment like count - get current count first
        final currentComment = await _supabase
            .from('toast_comments')
            .select('like_count')
            .eq('comment_id', commentId)
            .single();

        final newCount = (currentComment['like_count'] as int) + 1;
        await _supabase
            .from('toast_comments')
            .update({'like_count': newCount})
            .eq('comment_id', commentId);
      }
    } catch (error) {
      print('Error toggling comment like: $error');
    }
  }
  void clearError() {
    state = state.copyWith(error: null);
  }
}