import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/post.dart';

// State class for post feed
class PostFeedState {
  final List<Post_feed> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final Set<String> likingPosts;
  final Set<String> likingComments;
  final bool hasMore;
  final int currentPage;
  final DateTime? lastFetchTime;

  const PostFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.likingPosts = const {},
    this.likingComments = const {},
    this.hasMore = true,
    this.currentPage = 0,
    this.lastFetchTime,
  });

  PostFeedState copyWith({
    List<Post_feed>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    Set<String>? likingPosts,
    Set<String>? likingComments,
    bool? hasMore,
    int? currentPage,
    DateTime? lastFetchTime,
  }) {
    return PostFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      likingPosts: likingPosts ?? this.likingPosts,
      likingComments: likingComments ?? this.likingComments,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }
}

// Helper class for caching
class CachedPost {
  final Post_feed post;
  final DateTime timestamp;

  CachedPost({
    required this.post,
    required this.timestamp,
  });
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

  // Simple in-memory cache
  final Map<String, CachedPost> _postCache = {};
  final Map<String, List<Comment>> _commentCache = {};
  static const _cacheExpiry = Duration(minutes: 5);

// OPTIMIZED: Load initial posts with single efficient query
  Future<void> loadPosts() async {
    if (state.isLoading) return;

    // Check cache first
    if (_postCache.isNotEmpty && !_isCacheExpired()) {
      print('📦 Using cached posts');
      state = state.copyWith(
        posts: _postCache.values.map((c) => c.post).toList(),
        isLoading: false,
      );
      return;
    }

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

      // OPTIMIZATION 1: Single query instead of N queries per post
      final response = await _supabase
          .from('post')
          .select('''
          post_id,
          user_id,
          content,
          report,
          title,
          tags,
          created_at,
          like_count,
          comment_count,
          share_count,
          is_published,
          media_urls,
          user_profiles!inner(username, profile_pic)
        ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final List<dynamic> postsData = response as List<dynamic>;

      if (postsData.isEmpty) {
        state = state.copyWith(
          posts: [],
          isLoading: false,
          hasMore: false,
          currentPage: 1,
          lastFetchTime: DateTime.now(),
        );
        return;
      }

      // FIXED: Handle post_id as dynamic type (could be int or string)
      final postIds = postsData.map((p) => p['post_id']).toList();

      // OPTIMIZATION 2: Batch check all likes in single query
      final userLikes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id)
          .inFilter('post_id', postIds); // Use raw postIds without conversion

      // FIXED: Handle post_id comparison properly
      final likedPostIds = (userLikes as List<dynamic>)
          .map((l) => l['post_id'].toString()) // Convert to string for consistent comparison
          .toSet();

      // OPTIMIZATION 3: Map posts without loading comments (lazy load)
      final List<Post_feed> newPosts = [];

      for (var postData in postsData) {
        // FIXED: Handle post_id as dynamic and ensure string conversion
        final dynamic rawPostId = postData['post_id'];
        final String postId = rawPostId.toString(); // Safe conversion to string

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postId, // Ensure post_id is string
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'isliked': likedPostIds.contains(postId), // Consistent string comparison
          'post_comments': [], // Lazy load when needed
        });

        newPosts.add(post);

        // Update cache
        _postCache[postId] = CachedPost(
          post: post,
          timestamp: DateTime.now(),
        );
      }

      state = state.copyWith(
        posts: newPosts,
        isLoading: false,
        hasMore: newPosts.length == _pageSize,
        currentPage: 1,
        lastFetchTime: DateTime.now(),
      );

      print(' Loaded ${newPosts.length} posts efficiently');
    } catch (e) {
      print(' Error loading posts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load posts: $e',
      );
    }
  }

// OPTIMIZED: Load more posts (pagination)
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
          post_id,
          user_id,
          content,
          report,
          title,
          tags,
          created_at,
          like_count,
          comment_count,
          share_count,
          is_published,
          media_urls,
          user_profiles!inner(username, profile_pic)
        ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<dynamic> postsData = response as List<dynamic>;

      if (postsData.isEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          hasMore: false,
        );
        return;
      }

      // FIXED: Use raw postIds without conversion for the query
      final postIds = postsData.map((p) => p['post_id']).toList();

      // Batch check likes
      final userLikes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id)
          .inFilter('post_id', postIds); // Use raw postIds

      // FIXED: Convert to string for consistent comparison
      final likedPostIds = (userLikes as List<dynamic>)
          .map((l) => l['post_id'].toString()) // Convert to string
          .toSet();

      final List<Post_feed> newPosts = [];

      for (var postData in postsData) {
        // FIXED: Handle post_id as dynamic and ensure string conversion
        final dynamic rawPostId = postData['post_id'];
        final String postId = rawPostId.toString(); // Safe conversion to string

        // Avoid duplicates
        if (state.posts.any((p) => p.post_id == postId)) continue;

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postId,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'isliked': likedPostIds.contains(postId), // Consistent string comparison
          'post_comments': [],
        });

        newPosts.add(post);

        // Update cache
        _postCache[postId] = CachedPost(
          post: post,
          timestamp: DateTime.now(),
        );
      }

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: newPosts.length == _pageSize,
        currentPage: state.currentPage + 1,
      );

      print(' Loaded ${newPosts.length} more posts');
    } catch (e) {
      print(' Error loading more posts: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more posts: $e',
      );
    }
  }

  // Refresh posts with cache invalidation
  Future<void> refreshPosts() async {
    print('🔄 Refreshing posts and clearing cache');
    _postCache.clear();
    _commentCache.clear();
    state = const PostFeedState();
    await loadPosts();
  }

  // OPTIMIZED: Use database function for atomic like toggle
  Future<void> toggleLike(String postId) async {
    print('🔵 toggleLike called for post: $postId');

    if (state.likingPosts.contains(postId)) {
      print('🟡 Already liking this post, returning');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('🔴 User not authenticated');
      return;
    }

    final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
    if (postIndex == -1) {
      print('🔴 Post not found in current state');
      return;
    }

    final currentPost = state.posts[postIndex];
    final currentlyLiked = currentPost.isliked;
    final currentLikeCount = currentPost.like_count;

    print('🔵 Current like status: $currentlyLiked, count: $currentLikeCount');

    // OPTIMISTIC UPDATE: Update UI immediately
    final newPosts = [...state.posts];
    newPosts[postIndex] = currentPost.copyWith(
      like_count: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
      isliked: !currentlyLiked,
    );

    state = state.copyWith(
      posts: newPosts,
      likingPosts: {...state.likingPosts, postId},
    );

    // Update cache
    _postCache[postId] = CachedPost(
      post: newPosts[postIndex],
      timestamp: DateTime.now(),
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

        // Try to use RPC function, fallback to direct update if not available
        try {
          await _supabase.rpc(
            'decrement_post_likes',
            params: {'post_id_param': postId},
          );
        }catch (rpcError) {
          // Fallback to direct update if RPC doesn't exist
          await _supabase
              .from('post')
              .update({'like_count': currentLikeCount - 1})
              .eq('post_id', postId);
        }

        print('🔵 Unlike successful');
      } else {
        // Like the post
        print('🔵 Attempting to like post...');
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        // Try to use RPC function, fallback to direct update if not available
        try {
          await _supabase.rpc(
            'increment_post_likes',
            params: {'post_id_param': postId},
          );
        } catch (rpcError) {
          // Fallback to direct update if RPC doesn't exist
          await _supabase
              .from('post')
              .update({'like_count': currentLikeCount + 1})
              .eq('post_id', postId);
        }

        print('🔵 Like successful');
      }

      print('🟢 Like operation completed successfully');

      // Remove from likingPosts
      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(postId),
      );

      print('🟢 Loading indicator removed, optimistic update kept');
    } catch (error) {
      print('🔴 Error in toggleLike: $error');

      // REVERT OPTIMISTIC UPDATE
      final revertedPosts = [...state.posts];
      final currentPostIndex = revertedPosts.indexWhere((post) => post.post_id == postId);
      if (currentPostIndex != -1) {
        revertedPosts[currentPostIndex] = currentPost;
      }

      state = state.copyWith(
        posts: revertedPosts,
        likingPosts: {...state.likingPosts}..remove(postId),
        error: 'Failed to update like: ${error.toString()}',
      );

      // Revert cache
      _postCache[postId] = CachedPost(
        post: currentPost,
        timestamp: DateTime.now(),
      );

      print('🔴 Optimistic update reverted due to error');
    }
  }

  // OPTIMIZED: Lazy load comments only when needed
  Future<List<Comment>> loadComments(String postId) async {
    // Check cache first
    if (_commentCache.containsKey(postId)) {
      print('📦 Using cached comments for $postId');
      return _commentCache[postId]!;
    }

    try {
      final response = await _supabase
          .from('post_comments')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('post_id', postId)
          .isFilter('parent_comment_id', null)
          .order('created_at', ascending: false);

      final List<Comment> comments = (response as List<dynamic>).map((commentData) {
        return Comment.fromMap({
          ...commentData,
          'username': commentData['user_profiles']['username'],
          'profile_pic': commentData['user_profiles']['profile_pic'],
        });
      }).toList();

      // Cache comments
      _commentCache[postId] = comments;

      return comments;
    } catch (e) {
      print('❌ Error loading comments: $e');
      state = state.copyWith(error: 'Failed to load comments: $e');
      return [];
    }
  }

  // OPTIMIZED: Add comment with atomic increment
  Future<bool> addComment(String postId, String content) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Try to use RPC function, fallback to manual increment
      final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
      if (postIndex != -1) {
        final currentCount = state.posts[postIndex].comment_count;

        try {
          await _supabase.rpc('increment_post_comments', params: {
            'post_id_param': postId
          });
        } catch (rpcError) {
          // Fallback to direct update
          await _supabase
              .from('post')
              .update({'comment_count': currentCount + 1})
              .eq('post_id', postId);
        }

        // Update local state
        final updatedPosts = [...state.posts];
        updatedPosts[postIndex] = state.posts[postIndex].copyWith(
          comment_count: currentCount + 1,
        );
        state = state.copyWith(posts: updatedPosts);

        // Update cache
        _postCache[postId] = CachedPost(
          post: updatedPosts[postIndex],
          timestamp: DateTime.now(),
        );
      }

      // Invalidate comment cache for this post
      _commentCache.remove(postId);

      return true;
    } catch (e) {
      print('❌ Error adding comment: $e');
      state = state.copyWith(error: 'Failed to add comment: $e');
      return false;
    }
  }

  // Load replies for a given parent comment
  Future<List<Comment>> loadReplies(String postId, int parentCommentId) async {
    try {
      final repliesResponse = await _supabase
          .from('post_comments')
          .select('''
            *,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('post_id', postId)
          .eq('parent_comment_id', parentCommentId)
          .order('created_at', ascending: false);

      final List<Comment> replies = (repliesResponse as List<dynamic>).map((commentData) {
        return Comment.fromMap({
          ...commentData,
          'username': commentData['user_profiles']['username'],
          'profile_pic': commentData['user_profiles']['profile_pic'],
        });
      }).toList();

      return replies;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST204') || msg.contains("'parent_comment_id'") || msg.contains('schema cache')) {
        state = state.copyWith(
            error: 'Replies are not enabled yet. Add parent_comment_id to post_comments and reload API schema.'
        );
      } else {
        state = state.copyWith(error: 'Failed to load replies: $e');
      }
      return [];
    }
  }

  // Get replies count
  Future<int> getRepliesCount(int parentCommentId) async {
    try {
      final countResponse = await _supabase
          .from('post_comments')
          .select('comment_id')
          .eq('parent_comment_id', parentCommentId);
      return (countResponse as List<dynamic>).length;
    } catch (e) {
      return 0;
    }
  }

  // Add a reply to a specific parent comment
  Future<bool> addReply(String postId, int parentCommentId, String content) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'content': content,
        'parent_comment_id': parentCommentId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update comment count
      final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
      if (postIndex != -1) {
        final currentCount = state.posts[postIndex].comment_count;

        try {
          await _supabase.rpc('increment_post_comments', params: {
            'post_id_param': postId
          });
        } catch (rpcError) {
          await _supabase
              .from('post')
              .update({'comment_count': currentCount + 1})
              .eq('post_id', postId);
        }

        final updatedPosts = [...state.posts];
        updatedPosts[postIndex] = state.posts[postIndex].copyWith(
          comment_count: currentCount + 1,
        );
        state = state.copyWith(posts: updatedPosts);

        // Update cache
        _postCache[postId] = CachedPost(
          post: updatedPosts[postIndex],
          timestamp: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST204') || msg.contains("'parent_comment_id'") || msg.contains('schema cache')) {
        state = state.copyWith(
            error: 'Failed to add reply: parent_comment_id missing in post_comments. Run migration and reload API schema.'
        );
      } else {
        state = state.copyWith(error: 'Failed to add reply: $e');
      }
      return false;
    }
  }

  // Toggle comment like
  Future<void> toggleCommentLike(int commentId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final commentIdStr = commentId.toString();

    if (state.likingComments.contains(commentIdStr)) {
      return;
    }

    state = state.copyWith(
      likingComments: {...state.likingComments, commentIdStr},
    );

    try {
      final existingLike = await _supabase
          .from('post_comment_likes')
          .select('post_comment_like_id')
          .eq('comment_id', commentId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('post_comment_likes')
            .delete()
            .eq('post_comment_like_id', existingLike['post_comment_like_id'])
            .eq('user_id', currentUserId);

        final currentComment = await _supabase
            .from('post_comments')
            .select('like_count')
            .eq('comment_id', commentId)
            .single();

        final newCount = (currentComment['like_count'] as int) - 1;
        await _supabase
            .from('post_comments')
            .update({'like_count': newCount >= 0 ? newCount : 0})
            .eq('comment_id', commentId);
      } else {
        // Like
        await _supabase.from('post_comment_likes').insert({
          'comment_id': commentId,
          'user_id': currentUserId,
          'liked_at': DateTime.now().toIso8601String(),
        });

        final currentComment = await _supabase
            .from('post_comments')
            .select('like_count')
            .eq('comment_id', commentId)
            .single();

        final newCount = (currentComment['like_count'] as int) + 1;
        await _supabase
            .from('post_comments')
            .update({'like_count': newCount})
            .eq('comment_id', commentId);
      }

      state = state.copyWith(
        likingComments: {...state.likingComments}..remove(commentIdStr),
      );
    } catch (e) {
      state = state.copyWith(
        likingComments: {...state.likingComments}..remove(commentIdStr),
        error: 'Failed to toggle comment like: $e',
      );
    }
  }

  bool _isCacheExpired() {
    if (_postCache.isEmpty) return true;
    final firstPost = _postCache.values.first;
    return DateTime.now().difference(firstPost.timestamp) > _cacheExpiry;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}