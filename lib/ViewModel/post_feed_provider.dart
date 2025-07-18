import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../Model/post.dart';

// State class for post feed
class PostFeedState {
  final List<Post_feed> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final Set<String> likingPosts;
  final bool hasMore;
  final int currentPage;

  const PostFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.likingPosts = const {},
    this.hasMore = true,
    this.currentPage = 0,
  });

  PostFeedState copyWith({
    List<Post_feed>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    Set<String>? likingPosts,
    bool? hasMore,
    int? currentPage,
  }) {
    return PostFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      likingPosts: likingPosts ?? this.likingPosts,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Providers
final postFeedProvider = StateNotifierProvider<PostFeedNotifier, PostFeedState>((ref) {
  return PostFeedNotifier();
});

// Post Feed Provider
class PostFeedNotifier extends StateNotifier<PostFeedState> {
  PostFeedNotifier() : super(const PostFeedState());

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
          .from('post')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
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

        // Load comments for this post
        final commentsResponse = await _supabase
            .from('post_comments')
            .select('''
              *,
              user_profiles!inner(username, profile_pic)
            ''')
            .eq('post_id', postId)
            .order('created_at', ascending: false)
            .limit(5);

        final List<Comment> comments = commentsResponse.map((commentData) {
          return Comment.fromMap({
            ...commentData,
            'username': commentData['user_profiles']['username'],
            'profile_pic': commentData['user_profiles']['profile_pic'],
          });
        }).toList();

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postId,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
          'post_comments': comments.map((c) => c.toMap()).toList(),
        });

        newPosts.add(post);
      }

      state = state.copyWith(
        posts: newPosts,
        isLoading: false,
        hasMore: newPosts.length == _pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load posts: $e',
      );
    }
  }

  // Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final startRange = state.currentPage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('post')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
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

        // Load comments for this post
        final commentsResponse = await _supabase
            .from('post_comments')
            .select('''
              *,
              user_profiles!inner(username, profile_pic)
            ''')
            .eq('post_id', postId)
            .order('created_at', ascending: false)
            .limit(5);

        final List<Comment> comments = commentsResponse.map((commentData) {
          return Comment.fromMap({
            ...commentData,
            'username': commentData['user_profiles']['username'],
            'profile_pic': commentData['user_profiles']['profile_pic'],
          });
        }).toList();

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postId,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
          'post_comments': comments.map((c) => c.toMap()).toList(),
        });

        newPosts.add(post);
      }

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: newPosts.length == _pageSize,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more posts: $e',
      );
    }
  }

  // Refresh posts
  Future<void> refreshPosts() async {
    state = const PostFeedState();
    await loadPosts();
  }

  // Updated toggleLike method with optimistic updates
  Future<void> toggleLike(String postId) async {
    print('🔵 toggleLike called for post: $postId');

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
    if (state.likingPosts.contains(postId)) {
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
    final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
    if (postIndex == -1) {
      print('🔴 Post not found in current state');
      print('🔍 Available post IDs: ${state.posts.map((p) => p.post_id).toList()}');
      return;
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
      likingPosts: {...state.likingPosts, postId},
    );

    print('🔵 Optimistic update applied - UI updated immediately');

    try {
      if (currentlyLiked) {
        // Unlike the post
        print('🔵 Attempting to unlike post...');
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
        print('🔵 Unlike successful');
      } else {
        // Like the post
        print('🔵 Attempting to like post...');
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
        print('🔵 Like successful');
      }

      print('🟢 Like operation completed successfully');

      // Remove from likingPosts - keep the optimistic update since it succeeded
      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(postId),
      );

      print('🟢 Loading indicator removed, optimistic update kept');

    } catch (error) {
      print('🔴 Error in toggleLike: $error');

      // REVERT OPTIMISTIC UPDATE: Restore original state on error
      final revertedPosts = [...state.posts];
      final currentPostIndex = revertedPosts.indexWhere((post) => post.post_id == postId);
      if (currentPostIndex != -1) {
        revertedPosts[currentPostIndex] = currentPost; // Restore original state
      }

      state = state.copyWith(
        posts: revertedPosts,
        likingPosts: {...state.likingPosts}..remove(postId),
        error: 'Failed to update like: ${error.toString()}',
      );

      print('🔴 Optimistic update reverted due to error');
    }
  }

  Future<List<Comment>> loadComments(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return response.map((commentData) {
        return Comment.fromMap({
          ...commentData,
          'username': commentData['user_profiles']['username'],
          'profile_pic': commentData['user_profiles']['profile_pic'],
        });
      }).toList();
    } catch (e) {
      state = state.copyWith(error: 'Failed to load comments: $e');
      return [];
    }
  }

  Future<bool> addComment(String postId, String content) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'content': content,
      });

      // Update comment count in local state
      final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
      if (postIndex != -1) {
        final updatedPosts = [...state.posts];
        updatedPosts[postIndex] = state.posts[postIndex].copyWith(
          comment_count: state.posts[postIndex].comment_count + 1,
        );
        state = state.copyWith(posts: updatedPosts);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add comment: $e');
      return false;
    }
  }

  Future<void> toggleCommentLike(int commentId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final existingLike = await _supabase
          .from('post_comment_likes')
          .select('post_comment_like_id')
          .eq('comment_id', commentId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike != null) {
        await _supabase
            .from('post_comment_likes')
            .delete()
            .eq('post_comment_like_id', existingLike['post_comment_like_id']);
      } else {
        await _supabase.from('post_comment_likes').insert({
          'comment_id': commentId,
          'user_id': currentUserId,
        });
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle comment like: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}