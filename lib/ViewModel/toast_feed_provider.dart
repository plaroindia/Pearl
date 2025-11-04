import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plaro_3/Model/toast.dart';

// State for toast feed
class ToastFeedState {
  final List<Toast_feed> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final Set<String> likingPosts;
  final Set<String> likingComments;
  final DateTime? lastFetchTime;

  const ToastFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.likingPosts = const {},
    this.likingComments = const {},
    this.lastFetchTime,
  });

  ToastFeedState copyWith({
    List<Toast_feed>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    Set<String>? likingPosts,
    Set<String>? likingComments,
    DateTime? lastFetchTime,
  }) {
    return ToastFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      likingPosts: likingPosts ?? this.likingPosts,
      likingComments: likingComments ?? this.likingComments,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }
}

// Helper class for caching
class CachedToast {
  final Toast_feed toast;
  final DateTime timestamp;

  CachedToast({
    required this.toast,
    required this.timestamp,
  });
}

// Toast Feed Provider
final toastFeedProvider = StateNotifierProvider<ToastFeedNotifier, ToastFeedState>((ref) {
  return ToastFeedNotifier();
});

class ToastFeedNotifier extends StateNotifier<ToastFeedState> {
  ToastFeedNotifier() : super(const ToastFeedState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 10;

  // OPTIMIZATION: In-memory cache
  final Map<String, CachedToast> _toastCache = {};
  final Map<String, List<Comment>> _commentCache = {};
  static const _cacheExpiry = Duration(minutes: 5);

  // OPTIMIZED: Load initial posts with single efficient query
  Future<void> loadTosts() async {
    if (state.isLoading) return;

    // Check cache first
    if (_toastCache.isNotEmpty && !_isCacheExpired()) {
      print('📦 Using cached toasts');
      state = state.copyWith(
        posts: _toastCache.values.map((c) => c.toast).toList(),
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

      // OPTIMIZATION 1: Single query instead of N queries per toast
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

      final List<dynamic> toastsData = response as List<dynamic>;

      if (toastsData.isEmpty) {
        state = state.copyWith(
          posts: [],
          isLoading: false,
          hasMore: false,
          currentPage: 1,
          lastFetchTime: DateTime.now(),
        );
        return;
      }

      final toastIds = toastsData.map((t) => t['toast_id'].toString()).toList();

      // OPTIMIZATION 2: Batch check all likes in single query
      final userLikes = await _supabase
          .from('toast_likes')
          .select('toast_id')
          .eq('user_id', user.id)
          .inFilter('toast_id', toastIds);

      final likedToastIds = (userLikes as List<dynamic>)
          .map((l) => l['toast_id'] as String)
          .toSet();

      // OPTIMIZATION 3: Map toasts without loading comments (lazy load)
      final List<Toast_feed> newToasts = [];

      for (var toastData in toastsData) {
        final String toastId = toastData['toast_id'].toString();

        final toast = _mapToToastFeed(
          toastData,
          user.id,
          likedToastIds,
        );

        newToasts.add(toast);

        // Update cache
        _toastCache[toastId] = CachedToast(
          toast: toast,
          timestamp: DateTime.now(),
        );
      }

      state = state.copyWith(
        posts: newToasts,
        isLoading: false,
        hasMore: newToasts.length == _pageSize,
        currentPage: 1,
        lastFetchTime: DateTime.now(),
      );

      print('✅ Loaded ${newToasts.length} toasts efficiently');
    } catch (error) {
      print('❌ Error loading toasts: $error');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load toasts: $error',
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

      final List<dynamic> toastsData = response as List<dynamic>;

      if (toastsData.isEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          hasMore: false,
        );
        return;
      }

      final toastIds = toastsData.map((t) => t['toast_id'].toString()).toList();

      // Batch check likes
      final userLikes = await _supabase
          .from('toast_likes')
          .select('toast_id')
          .eq('user_id', user.id)
          .inFilter('toast_id', toastIds);

      final likedToastIds = (userLikes as List<dynamic>)
          .map((l) => l['toast_id'] as String)
          .toSet();

      final List<Toast_feed> newToasts = [];

      for (var toastData in toastsData) {
        final String toastId = toastData['toast_id'].toString();

        // Avoid duplicates
        if (state.posts.any((t) => t.toast_id == toastId)) continue;

        final toast = _mapToToastFeed(
          toastData,
          user.id,
          likedToastIds,
        );

        newToasts.add(toast);

        // Update cache
        _toastCache[toastId] = CachedToast(
          toast: toast,
          timestamp: DateTime.now(),
        );
      }

      state = state.copyWith(
        posts: [...state.posts, ...newToasts],
        isLoadingMore: false,
        hasMore: newToasts.length == _pageSize,
        currentPage: state.currentPage + 1,
      );

      print('✅ Loaded ${newToasts.length} more toasts');
    } catch (error) {
      print('❌ Error loading more toasts: $error');
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more toasts: $error',
      );
    }
  }

  // Refresh posts with cache invalidation
  Future<void> refreshPosts() async {
    print('🔄 Refreshing toasts and clearing cache');
    _toastCache.clear();
    _commentCache.clear();
    state = const ToastFeedState();
    await loadTosts();
  }

  // OPTIMIZED: Use database operations for atomic like toggle
  Future<void> toggleLike(String toastId) async {
    print('🔵 toggleLike called for toast: $toastId');

    if (state.likingPosts.contains(toastId)) {
      print('🟡 Already liking this toast, returning');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('🔴 User not authenticated');
      return;
    }

    final toastIndex = state.posts.indexWhere((toast) => toast.toast_id == toastId);
    if (toastIndex == -1) {
      print('🔴 Toast not found in current state');
      return;
    }

    final currentToast = state.posts[toastIndex];
    final currentlyLiked = currentToast.isliked;
    final currentLikeCount = currentToast.like_count;

    print('🔵 Current like status: $currentlyLiked, count: $currentLikeCount');

    // OPTIMISTIC UPDATE: Update UI immediately
    final newToasts = [...state.posts];
    newToasts[toastIndex] = currentToast.copyWith(
      like_count: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
      isliked: !currentlyLiked,
    );

    state = state.copyWith(
      posts: newToasts,
      likingPosts: {...state.likingPosts, toastId},
    );

    // Update cache
    _toastCache[toastId] = CachedToast(
      toast: newToasts[toastIndex],
      timestamp: DateTime.now(),
    );

    print('🔵 Optimistic update applied - UI updated immediately');

    try {
      if (currentlyLiked) {
        // Unlike the toast
        print('🔵 Attempting to unlike toast...');
        await _supabase
            .from('toast_likes')
            .delete()
            .eq('toast_id', toastId)
            .eq('user_id', user.id);

        // Try to use RPC function, fallback to direct update if not available
        try {
          await _supabase.rpc(
            'decrement_toast_likes',
            params: {'toast_id_param': toastId},
          );
        } catch (rpcError) {
          // Fallback to direct update if RPC doesn't exist
          await _supabase
              .from('toasts')
              .update({'like_count': currentLikeCount - 1})
              .eq('toast_id', toastId);
        }

        print('🔵 Unlike successful');
      } else {
        // Like the toast
        print('🔵 Attempting to like toast...');
        await _supabase.from('toast_likes').insert({
          'toast_id': toastId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        // Try to use RPC function, fallback to direct update if not available
        try {
          await _supabase.rpc(
            'increment_toast_likes',
            params: {'toast_id_param': toastId},
          );
        } catch (rpcError) {
          // Fallback to direct update if RPC doesn't exist
          await _supabase
              .from('toasts')
              .update({'like_count': currentLikeCount + 1})
              .eq('toast_id', toastId);
        }

        print('🔵 Like successful');
      }

      print('🟢 Like operation completed successfully');

      // Remove from likingPosts
      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(toastId),
      );

      print('🟢 Loading indicator removed, optimistic update kept');
    } catch (error) {
      print('🔴 Error in toggleLike: $error');

      // REVERT OPTIMISTIC UPDATE
      final revertedToasts = [...state.posts];
      final currentToastIndex = revertedToasts.indexWhere((toast) => toast.toast_id == toastId);
      if (currentToastIndex != -1) {
        revertedToasts[currentToastIndex] = currentToast;
      }

      state = state.copyWith(
        posts: revertedToasts,
        likingPosts: {...state.likingPosts}..remove(toastId),
        error: 'Failed to update like: ${error.toString()}',
      );

      // Revert cache
      _toastCache[toastId] = CachedToast(
        toast: currentToast,
        timestamp: DateTime.now(),
      );

      print('🔴 Optimistic update reverted due to error');
    }
  }

  // OPTIMIZED: Lazy load comments only when needed
  Future<List<Comment>> loadComments(String toastId) async {
    // Check cache first
    if (_commentCache.containsKey(toastId)) {
      print('📦 Using cached comments for $toastId');
      return _commentCache[toastId]!;
    }

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
          .filter('parent_comment_id', 'is', null)
          .order('created_at', ascending: false);

      // Batch check liked comments
      final commentIds = (response as List<dynamic>).map((c) => c['comment_id'] as int).toList();

      final likedCommentsResponse = await _supabase
          .from('toast_comment_likes')
          .select('comment_id')
          .eq('user_id', user.id)
          .inFilter('comment_id', commentIds);

      final likedCommentIds = (likedCommentsResponse as List<dynamic>)
          .map((e) => e['comment_id'] as int)
          .toSet();

      final comments = (response as List<dynamic>)
          .map((json) => Comment.fromMap({
        ...json,
        'username': json['user_profiles']['username'],
        'profile_pic': json['user_profiles']['profile_pic'],
        'uliked': likedCommentIds.contains(json['comment_id']),
      }))
          .toList();

      // Cache comments
      _commentCache[toastId] = comments;

      return comments;
    } catch (error) {
      print('❌ Error loading comments: $error');
      state = state.copyWith(error: 'Failed to load comments: $error');
      return [];
    }
  }

  // OPTIMIZED: Add comment with atomic increment
  Future<bool> addComment(String toastId, String content) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      await _supabase.from('toast_comments').insert({
        'toast_id': toastId,
        'user_id': currentUserId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Try to use RPC function, fallback to manual increment
      final toastIndex = state.posts.indexWhere((toast) => toast.toast_id == toastId);
      if (toastIndex != -1) {
        final currentCount = state.posts[toastIndex].comment_count;

        try {
          await _supabase.rpc('increment_toast_comments', params: {
            'toast_id_param': toastId
          });
        } catch (rpcError) {
          // Fallback to direct update
          await _supabase
              .from('toasts')
              .update({'comment_count': currentCount + 1})
              .eq('toast_id', toastId);
        }

        // Update local state
        final updatedToasts = [...state.posts];
        updatedToasts[toastIndex] = state.posts[toastIndex].copyWith(
          comment_count: currentCount + 1,
        );
        state = state.copyWith(posts: updatedToasts);

        // Update cache
        _toastCache[toastId] = CachedToast(
          toast: updatedToasts[toastIndex],
          timestamp: DateTime.now(),
        );
      }

      // Invalidate comment cache for this toast
      _commentCache.remove(toastId);

      return true;
    } catch (e) {
      print('❌ Error adding comment: $e');
      state = state.copyWith(error: 'Failed to add comment: $e');
      return false;
    }
  }

  // Load replies for a given parent comment
  Future<List<Comment>> loadReplies(String toastId, int parentCommentId) async {
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
            parent_comment_id,
            user_profiles!inner(username, profile_pic)
          ''')
          .eq('toast_id', toastId)
          .eq('parent_comment_id', parentCommentId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Comment.fromMap({
        ...json,
        'username': json['user_profiles']['username'],
        'profile_pic': json['user_profiles']['profile_pic'],
      }))
          .toList();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST204') || msg.contains("'parent_comment_id'") || msg.contains('schema cache')) {
        state = state.copyWith(
            error: 'Replies are not enabled yet. Add parent_comment_id to toast_comments and reload API schema.'
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
          .from('toast_comments')
          .select('comment_id')
          .eq('parent_comment_id', parentCommentId);
      return (countResponse as List<dynamic>).length;
    } catch (e) {
      return 0;
    }
  }

  // Add a reply to a specific parent comment
  Future<bool> addReply(String toastId, int parentCommentId, String content) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      await _supabase.from('toast_comments').insert({
        'toast_id': toastId,
        'user_id': currentUserId,
        'content': content,
        'parent_comment_id': parentCommentId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update comment count
      final toastIndex = state.posts.indexWhere((toast) => toast.toast_id == toastId);
      if (toastIndex != -1) {
        final currentCount = state.posts[toastIndex].comment_count;

        try {
          await _supabase.rpc('increment_toast_comments', params: {
            'toast_id_param': toastId
          });
        } catch (rpcError) {
          await _supabase
              .from('toasts')
              .update({'comment_count': currentCount + 1})
              .eq('toast_id', toastId);
        }

        final updatedToasts = [...state.posts];
        updatedToasts[toastIndex] = state.posts[toastIndex].copyWith(
          comment_count: currentCount + 1,
        );
        state = state.copyWith(posts: updatedToasts);

        // Update cache
        _toastCache[toastId] = CachedToast(
          toast: updatedToasts[toastIndex],
          timestamp: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST204') || msg.contains("'parent_comment_id'") || msg.contains('schema cache')) {
        state = state.copyWith(
            error: 'Failed to add reply: parent_comment_id missing in toast_comments. Run migration and reload API schema.'
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
          .from('toast_comment_likes')
          .select('toast_comment_like_id')
          .eq('comment_id', commentId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('toast_comment_likes')
            .delete()
            .eq('toast_comment_like_id', existingLike['toast_comment_like_id']);

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
          'user_id': currentUserId,
          'liked_at': DateTime.now().toIso8601String(),
        });

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
      commentsList: [], // Lazy load when needed
    );
  }

  bool _isCacheExpired() {
    if (_toastCache.isEmpty) return true;
    final firstToast = _toastCache.values.first;
    return DateTime.now().difference(firstToast.timestamp) > _cacheExpiry;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}