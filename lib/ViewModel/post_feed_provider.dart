import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/post.dart';
import '../Model/comment.dart';

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

  // FIXED: Proper mapping function
  Post_feed _mapToPostFeed(Map<String, dynamic> postData, String userId, Set<int> likedPostIds) {
    final int postId = postData['post_id'] as int;
    final String postIdString = postId.toString();

    return Post_feed(
      post_id: postIdString,
      user_id: postData['user_id']?.toString() ?? '',
      username: postData['user_profiles']?['username'] ?? 'Unknown User',
      profile_pic: postData['user_profiles']?['profile_pic'],
      content: postData['content'],
      title: postData['title'],
      tags: postData['tags'] != null ? List<String>.from(postData['tags']) : [],
      created_at: postData['created_at'] != null
          ? DateTime.parse(postData['created_at'])
          : null,
      like_count: (postData['like_count'] as int?) ?? 0, // FIXED: Direct mapping
      comment_count: (postData['comment_count'] as int?) ?? 0, // FIXED: Direct mapping
      share_count: (postData['share_count'] as int?) ?? 0, // FIXED: Direct mapping
      isliked: likedPostIds.contains(postId), // FIXED: Use integer comparison
      commentsList: [],
      media_urls: postData['media_urls'] != null
          ? List<String>.from(postData['media_urls'])
          : [],
    );
  }

  // FIXED: Load initial posts with proper count mapping
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

      // FIXED: Query with proper field selection
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

      // FIXED: Use integer post IDs for like checking
      final postIds = postsData.map<int>((p) => p['post_id'] as int).toList();

      final userLikes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id)
          .inFilter('post_id', postIds);

      final likedPostIds = (userLikes as List<dynamic>)
          .map<int>((l) => l['post_id'] as int)
          .toSet();

      final List<Post_feed> newPosts = [];

      for (var postData in postsData) {
        final post = _mapToPostFeed(postData, user.id, likedPostIds);
        newPosts.add(post);

        _postCache[post.post_id!] = CachedPost(
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

      print('SUCCESS: Loaded ${newPosts.length} posts with counts: ${newPosts.map((p) => '${p.post_id}: ${p.like_count} likes').toList()}');
    } catch (e) {
      print('ERROR: Error loading posts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load posts: $e',
      );
    }
  }

  // FIXED: Load more posts
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

      final postIds = postsData.map<int>((p) => p['post_id'] as int).toList();

      final userLikes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id)
          .inFilter('post_id', postIds);

      final likedPostIds = (userLikes as List<dynamic>)
          .map<int>((l) => l['post_id'] as int)
          .toSet();

      final List<Post_feed> newPosts = [];

      for (var postData in postsData) {
        final int postId = postData['post_id'] as int;
        final String postIdString = postId.toString();

        if (state.posts.any((p) => p.post_id == postIdString)) continue;

        final post = _mapToPostFeed(postData, user.id, likedPostIds);
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

  // FIXED: Toggle like with proper count handling
  Future<void> toggleLike(String postId) async {
    if (state.likingPosts.contains(postId)) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
    if (postIndex == -1) return;

    final currentPost = state.posts[postIndex];
    final currentlyLiked = currentPost.isliked;
    final int postIdInt = int.parse(postId);

    // Optimistic: toggle isLiked only
    final newPosts = [...state.posts];
    newPosts[postIndex] = currentPost.copyWith(
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

    try {
      if (currentlyLiked) {
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postIdInt)
            .eq('user_id', user.id);
      } else {
        await _supabase.from('post_likes').insert({
          'post_id': postIdInt,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });
      }

      // Reload post to get trigger-updated count
      await _reloadSinglePost(postId, postIndex);

      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(postId),
      );
    } catch (error) {
      // Revert
      final revertedPosts = [...state.posts];
      revertedPosts[postIndex] = currentPost;

      state = state.copyWith(
        posts: revertedPosts,
        likingPosts: {...state.likingPosts}..remove(postId),
        error: 'Failed to update like: ${error.toString()}',
      );

      _postCache[postId] = CachedPost(
        post: currentPost,
        timestamp: DateTime.now(),
      );
    }
  }

// Reload single post
  Future<void> _reloadSinglePost(String postId, int index) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final int postIdInt = int.parse(postId);

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
        .eq('post_id', postIdInt)
        .single();

    final userLikes = await _supabase
        .from('post_likes')
        .select('post_id')
        .eq('user_id', user.id)
        .eq('post_id', postIdInt);

    final isLiked = (userLikes as List).isNotEmpty;

    final updatedPost = _mapToPostFeed(
      response,
      user.id,
      isLiked ? {postIdInt} : {},
    );

    final newPosts = [...state.posts];
    newPosts[index] = updatedPost;

    state = state.copyWith(posts: newPosts);

    _postCache[postId] = CachedPost(
      post: updatedPost,
      timestamp: DateTime.now(),
    );
  }


  // Refresh posts with cache invalidation
  Future<void> refreshPosts() async {
    print('DEBUG: Refreshing posts and clearing cache');
    _postCache.clear();
    _commentCache.clear();
    state = const PostFeedState();
    await loadPosts();
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
        return Comment.fromPostMap({
          ...commentData,
          'username': commentData['user_profiles']['username'],
          'profile_pic': commentData['user_profiles']['profile_pic'],
          'isliked': likedCommentIds.contains(commentData['comment_id']), // Changed from 'uliked' to 'isliked'
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

      // Reload post
      final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
      if (postIndex != -1) {
        await _reloadSinglePost(postId, postIndex);
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

      // Reload post
      final postIndex = state.posts.indexWhere((post) => post.post_id == postId);
      if (postIndex != -1) {
        await _reloadSinglePost(postId, postIndex);
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