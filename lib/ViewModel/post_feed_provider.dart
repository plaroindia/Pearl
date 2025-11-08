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

    if (_postCache.isNotEmpty && !_isCacheExpired()) {
      print('DEBUG: Using cached posts');
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

      final postIds = postsData.map((p) => p['post_id'] as int).toList();

      final userLikes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id)
          .inFilter('post_id', postIds);

      final likedPostIds = (userLikes as List<dynamic>)
          .map((l) => l['post_id'] as int)
          .toSet();

      final List<Post_feed> newPosts = [];

      for (var postData in postsData) {
        final int postId = postData['post_id'] as int;
        final String postIdString = postId.toString();

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postIdString,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'isliked': likedPostIds.contains(postId),
          'post_comments': [],
        });

        newPosts.add(post);

        _postCache[postIdString] = CachedPost(
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

      print('SUCCESS: Loaded ${newPosts.length} posts efficiently');
    } catch (e) {
      print('ERROR: Error loading posts: $e');
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

      final postIds = postsData.map((p) => p['post_id'] as int).toList();

      final userLikes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id)
          .inFilter('post_id', postIds);

      final likedPostIds = (userLikes as List<dynamic>)
          .map((l) => l['post_id'] as int)
          .toSet();

      final List<Post_feed> newPosts = [];

      for (var postData in postsData) {
        final int postId = postData['post_id'] as int;
        final String postIdString = postId.toString();

        if (state.posts.any((p) => p.post_id == postIdString)) continue;

        final post = Post_feed.fromMap({
          ...postData,
          'post_id': postIdString,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'isliked': likedPostIds.contains(postId),
          'post_comments': [],
        });

        newPosts.add(post);

        _postCache[postIdString] = CachedPost(
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

      print('SUCCESS: Loaded ${newPosts.length} more posts');
    } catch (error) {
      print('ERROR: Error loading more posts: $error');
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more posts: $error',
      );
    }
  }

  // Refresh posts with cache invalidation
  Future<void> refreshPosts() async {
    print('DEBUG: Refreshing posts and clearing cache');
    _postCache.clear();
    _commentCache.clear();
    state = const PostFeedState();
    await loadPosts();
  }

  // OPTIMIZED: Toggles are handled by database triggers
  Future<void> toggleLike(String postId) async {
    print('DEBUG: toggleLike called for post: $postId');

    if (state.likingPosts.contains(postId)) {
      print('DEBUG: Already liking this post, returning');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('ERROR: User not authenticated');
      return;
    }

    final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
    if (postIndex == -1) {
      print('ERROR: Post not found in current state');
      return;
    }

    final currentPost = state.posts[postIndex];
    final currentlyLiked = currentPost.isliked;
    final currentLikeCount = currentPost.like_count;

    final int postIdInt = int.parse(postId);

    print('DEBUG: Current like status: $currentlyLiked, count: $currentLikeCount');

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

    _postCache[postId] = CachedPost(
      post: newPosts[postIndex],
      timestamp: DateTime.now(),
    );

    print('DEBUG: Optimistic update applied - UI updated immediately');

    try {
      if (currentlyLiked) {
        // Unlike - trigger will handle count update
        print('DEBUG: Attempting to unlike post...');
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postIdInt)
            .eq('user_id', user.id);

        print('DEBUG: Unlike successful');
      } else {
        // Like - trigger will handle count update
        print('DEBUG: Attempting to like post...');
        await _supabase.from('post_likes').insert({
          'post_id': postIdInt,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        print('DEBUG: Like successful');
      }

      print('SUCCESS: Like operation completed successfully');

      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(postId),
      );

      print('DEBUG: Loading indicator removed, optimistic update kept');
    } catch (error) {
      print('ERROR: Error in toggleLike: $error');

      // REVERT OPTIMISTIC UPDATE on error
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

      _postCache[postId] = CachedPost(
        post: currentPost,
        timestamp: DateTime.now(),
      );

      print('ERROR: Optimistic update reverted due to error');
    }
  }

  // OPTIMIZED: Lazy load comments only when needed
  Future<List<Comment>> loadComments(String postId) async {
    if (_commentCache.containsKey(postId)) {
      print('DEBUG: Using cached comments for $postId');
      return _commentCache[postId]!;
    }

    final int postIdInt = int.parse(postId);
    final user = _supabase.auth.currentUser;

    try {
      final response = await _supabase
          .from('post_comments')
          .select('''
          *,
          user_profiles!inner(username, profile_pic)
        ''')
          .eq('post_id', postIdInt)
          .isFilter('parent_comment_id', null)
          .order('created_at', ascending: false);

      final commentIds = (response as List<dynamic>).map((c) => c['comment_id'] as int).toList();

      Set<int> likedCommentIds = {};
      if (user != null && commentIds.isNotEmpty) {
        final likedCommentsResponse = await _supabase
            .from('post_comment_likes')
            .select('comment_id')
            .eq('user_id', user.id)
            .inFilter('comment_id', commentIds);

        likedCommentIds = (likedCommentsResponse as List<dynamic>)
            .map((e) => e['comment_id'] as int)
            .toSet();
      }

      final List<Comment> comments = (response as List<dynamic>).map((commentData) {
        return Comment.fromMap({
          ...commentData,
          'username': commentData['user_profiles']['username'],
          'profile_pic': commentData['user_profiles']['profile_pic'],
          'uliked': likedCommentIds.contains(commentData['comment_id']),
        });
      }).toList();

      _commentCache[postId] = comments;

      return comments;
    } catch (e) {
      print('ERROR: Error loading comments: $e');
      state = state.copyWith(error: 'Failed to load comments: $e');
      return [];
    }
  }

  // OPTIMIZED: Add comment - trigger handles count
  Future<bool> addComment(String postId, String content) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final int postIdInt = int.parse(postId);

    try {
      await _supabase.from('post_comments').insert({
        'post_id': postIdInt,
        'user_id': currentUserId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Optimistic update for UI
      final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
      if (postIndex != -1) {
        final currentCount = state.posts[postIndex].comment_count;

        final updatedPosts = [...state.posts];
        updatedPosts[postIndex] = state.posts[postIndex].copyWith(
          comment_count: currentCount + 1,
        );
        state = state.copyWith(posts: updatedPosts);

        _postCache[postId] = CachedPost(
          post: updatedPosts[postIndex],
          timestamp: DateTime.now(),
        );
      }

      _commentCache.remove(postId);

      return true;
    } catch (e) {
      print('ERROR: Error adding comment: $e');
      state = state.copyWith(error: 'Failed to add comment: $e');
      return false;
    }
  }

  // Load replies for a given parent comment
  Future<List<Comment>> loadReplies(String postId, int parentCommentId) async {
    final int postIdInt = int.parse(postId);
    final user = _supabase.auth.currentUser;

    try {
      final repliesResponse = await _supabase
          .from('post_comments')
          .select('''
          *,
          user_profiles!inner(username, profile_pic)
        ''')
          .eq('post_id', postIdInt)
          .eq('parent_comment_id', parentCommentId)
          .order('created_at', ascending: false);

      final replyIds = (repliesResponse as List<dynamic>).map((c) => c['comment_id'] as int).toList();

      Set<int> likedReplyIds = {};
      if (user != null && replyIds.isNotEmpty) {
        final likedRepliesResponse = await _supabase
            .from('post_comment_likes')
            .select('comment_id')
            .eq('user_id', user.id)
            .inFilter('comment_id', replyIds);

        likedReplyIds = (likedRepliesResponse as List<dynamic>)
            .map((e) => e['comment_id'] as int)
            .toSet();
      }

      final List<Comment> replies = (repliesResponse as List<dynamic>).map((commentData) {
        return Comment.fromMap({
          ...commentData,
          'username': commentData['user_profiles']['username'],
          'profile_pic': commentData['user_profiles']['profile_pic'],
          'uliked': likedReplyIds.contains(commentData['comment_id']),
        });
      }).toList();

      return replies;
    } catch (e) {
      print('ERROR: Failed to load replies: $e');
      state = state.copyWith(error: 'Failed to load replies: $e');
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

  // Add a reply - trigger handles count
  Future<bool> addReply(String postId, int parentCommentId, String content) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final int postIdInt = int.parse(postId);

    try {
      await _supabase.from('post_comments').insert({
        'post_id': postIdInt,
        'user_id': currentUserId,
        'content': content,
        'parent_comment_id': parentCommentId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Optimistic update for UI
      final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
      if (postIndex != -1) {
        final currentCount = state.posts[postIndex].comment_count;

        final updatedPosts = [...state.posts];
        updatedPosts[postIndex] = state.posts[postIndex].copyWith(
          comment_count: currentCount + 1,
        );
        state = state.copyWith(posts: updatedPosts);

        _postCache[postId] = CachedPost(
          post: updatedPosts[postIndex],
          timestamp: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      print('ERROR: Failed to add reply: $e');
      state = state.copyWith(error: 'Failed to add reply: $e');
      return false;
    }
  }

  // Toggle comment like - trigger handles count
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
        // Unlike - trigger will handle count
        await _supabase
            .from('post_comment_likes')
            .delete()
            .eq('post_comment_like_id', existingLike['post_comment_like_id'])
            .eq('user_id', currentUserId);
      } else {
        // Like - trigger will handle count
        await _supabase.from('post_comment_likes').insert({
          'comment_id': commentId,
          'user_id': currentUserId,
          'liked_at': DateTime.now().toIso8601String(),
        });
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