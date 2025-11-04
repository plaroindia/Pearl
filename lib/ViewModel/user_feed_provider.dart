import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/post.dart' as post_model;
import '../Model/toast.dart' as toast_model;
import '../Model/byte.dart';

// State class for profile feed
class ProfileFeedState {
  final List<post_model.Post_feed> posts;
  final List<toast_model.Toast_feed> toasts;
  final List<Byte> bytes;
  final bool isLoadingPosts;
  final bool isLoadingToasts;
  final bool isLoadingBytes;
  final bool isLoadingMorePosts;
  final bool isLoadingMoreToasts;
  final bool isLoadingMoreBytes;
  final String? error;
  final Set<String> likingPosts;
  final Set<String> likingToasts;
  final Set<String> likingBytes;
  final bool hasMorePosts;
  final bool hasMoreToasts;
  final bool hasMoreBytes;
  final int currentPostPage;
  final int currentToastPage;
  final int currentBytePage;

  const ProfileFeedState({
    this.posts = const [],
    this.toasts = const [],
    this.bytes = const [],
    this.isLoadingPosts = false,
    this.isLoadingToasts = false,
    this.isLoadingBytes = false,
    this.isLoadingMorePosts = false,
    this.isLoadingMoreToasts = false,
    this.isLoadingMoreBytes = false,
    this.error,
    this.likingPosts = const {},
    this.likingToasts = const {},
    this.likingBytes = const {},
    this.hasMorePosts = true,
    this.hasMoreToasts = true,
    this.hasMoreBytes = true,
    this.currentPostPage = 0,
    this.currentToastPage = 0,
    this.currentBytePage = 0,
  });

  ProfileFeedState copyWith({
    List<post_model.Post_feed>? posts,
    List<toast_model.Toast_feed>? toasts,
    List<Byte>? bytes,
    bool? isLoadingPosts,
    bool? isLoadingToasts,
    bool? isLoadingBytes,
    bool? isLoadingMorePosts,
    bool? isLoadingMoreToasts,
    bool? isLoadingMoreBytes,
    String? error,
    Set<String>? likingPosts,
    Set<String>? likingToasts,
    Set<String>? likingBytes,
    bool? hasMorePosts,
    bool? hasMoreToasts,
    bool? hasMoreBytes,
    int? currentPostPage,
    int? currentToastPage,
    int? currentBytePage,
  }) {
    return ProfileFeedState(
      posts: posts ?? this.posts,
      toasts: toasts ?? this.toasts,
      bytes: bytes ?? this.bytes,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingToasts: isLoadingToasts ?? this.isLoadingToasts,
      isLoadingBytes: isLoadingBytes ?? this.isLoadingBytes,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
      isLoadingMoreToasts: isLoadingMoreToasts ?? this.isLoadingMoreToasts,
      isLoadingMoreBytes: isLoadingMoreBytes ?? this.isLoadingMoreBytes,
      error: error,
      likingPosts: likingPosts ?? this.likingPosts,
      likingToasts: likingToasts ?? this.likingToasts,
      likingBytes: likingBytes ?? this.likingBytes,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      hasMoreToasts: hasMoreToasts ?? this.hasMoreToasts,
      hasMoreBytes: hasMoreBytes ?? this.hasMoreBytes,
      currentPostPage: currentPostPage ?? this.currentPostPage,
      currentToastPage: currentToastPage ?? this.currentToastPage,
      currentBytePage: currentBytePage ?? this.currentBytePage,
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
  static const int _pageSize = 12;

  // Load user's posts
  Future<void> loadUserPosts(final UserId) async {
    if (state.isLoadingPosts) return;

    state = state.copyWith(isLoadingPosts: true, error: null);

    try {
      final user = UserId;
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
    post_id,
    user_id,
    content,
    media_urls,
    like_count,
    comment_count,
    share_count,
    created_at,
    is_published,
    user_profiles(username, profile_pic),
    post_comments(comment_id, user_id, content, like_count, created_at)
  ''')
          .eq('user_id', user)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final List<post_model.Post_feed> newPosts = [];

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
            .eq('user_id', user)
            .maybeSingle();
        isLiked = likeResponse != null;

        // Process comments - convert to proper format for Post_feed

        List<Map<String, dynamic>> commentMaps = [];
        if (postData['post_comments'] != null) {
          for (var commentData in postData['post_comments']) {
            // Fetch user profile for each comment
            final commentUserId = commentData['user_id'];
            final userProfileResponse = await _supabase
                .from('user_profiles')
                .select('username, profile_pic')
                .eq('user_id', commentUserId)
                .maybeSingle();

            commentMaps.add({
              'comment_id': commentData['comment_id'],
              'user_id': commentData['user_id'],
              'content': commentData['content'],
              'like_count': commentData['like_count'] ?? 0,
              'created_at': commentData['created_at'],
              'username': userProfileResponse?['username'] ?? 'Unknown',
              'profile_pic': userProfileResponse?['profile_pic'] ?? '',
              'isliked': false,
            });
          }
        }

        final post = post_model.Post_feed.fromMap({
          ...postData,
          'post_id': postId,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
          'post_comments': commentMaps,
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
  Future<void> loadUserToasts(final UserId) async {
    if (state.isLoadingToasts) return;

    state = state.copyWith(isLoadingToasts: true, error: null);

    try {
      final user = UserId;
      if (user == null) {
        state = state.copyWith(
          isLoadingToasts: false,
          error: 'User not authenticated',
        );
        return;
      }

      print('Loading toasts for user: ${user}');

      final response = await _supabase
          .from('toasts')
          .select('''
      *,
      user_profiles!inner(username, profile_pic),
      toast_comments(
        comment_id,
        user_id,
        content,
        like_count,
        created_at
      )
    ''')
          .eq('user_id', user)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      print('Toast response: $response');

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

      final List<toast_model.Toast_feed> newToasts = [];

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
              .eq('user_id', user)
              .maybeSingle();
          isLiked = likeResponse != null;

          // Process comments
          // Process comments
          List<Map<String, dynamic>> commentMaps = [];
          if (toastData['toast_comments'] != null) {
            for (var commentData in toastData['toast_comments']) {
              // Fetch user profile for each comment
              final commentUserId = commentData['user_id'];
              final userProfileResponse = await _supabase
                  .from('user_profiles')
                  .select('username, profile_pic')
                  .eq('user_id', commentUserId)
                  .maybeSingle();

              commentMaps.add({
                'comment_id': commentData['comment_id'],
                'toast_id': toastId,
                'user_id': commentData['user_id'],
                'content': commentData['content'],
                'like_count': commentData['like_count'] ?? 0,
                'created_at': commentData['created_at'],
                'username': userProfileResponse?['username'] ?? 'Unknown',
                'profile_pic': userProfileResponse?['profile_pic'] ?? '',
                'uliked': false,
              });
            }
          }
          final toast = toast_model.Toast_feed.fromMap({
            ...toastData,
            'toast_id': toastId,
            'username': toastData['user_profiles']['username'],
            'profile_pic': toastData['user_profiles']['profile_pic'],
            'like_count': likeCount,
            'comment_count': commentCount,
            'isliked': isLiked,
            'toast_comments': commentMaps,
          });

          newToasts.add(toast);
        } catch (e) {
          print('Error processing toast: $e');
          continue;
        }
      }

      state = state.copyWith(
        toasts: newToasts,
        isLoadingToasts: false,
        hasMoreToasts: newToasts.length == _pageSize,
        currentToastPage: 1,
      );

      print('Successfully loaded ${newToasts.length} toasts');

    } catch (e) {
      print('Error loading toasts: $e');
      state = state.copyWith(
        isLoadingToasts: false,
        error: 'Failed to load toasts: $e',
      );
    }
  }

  // Load more posts (pagination)
  Future<void> loadMoreUserPosts(final UserId) async {
    if (state.isLoadingMorePosts || !state.hasMorePosts) return;

    final user = UserId;
    if (user == null) return;

    state = state.copyWith(isLoadingMorePosts: true, error: null);

    try {
      final startRange = state.currentPostPage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('post')
          .select('''
            *,
            user_profiles!inner(username, profile_pic),
            post_comments(
              comment_id,
              user_id,
              content,
              like_count,
              created_at,
              user_profiles!post_comments_user_id_fkey(username, profile_pic)
            )
          ''')
          .eq('user_id', user)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<post_model.Post_feed> newPosts = [];

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
            .eq('user_id', user)
            .maybeSingle();
        isLiked = likeResponse != null;

        // Process comments
        List<Map<String, dynamic>> commentMaps = [];
        if (postData['post_comments'] != null) {
          for (var commentData in postData['post_comments']) {
            commentMaps.add({
              'comment_id': commentData['comment_id'],
              'user_id': commentData['user_id'],
              'content': commentData['content'],
              'like_count': commentData['like_count'] ?? 0,
              'created_at': commentData['created_at'],
              'username': commentData['user_profiles']['username'],
              'profile_pic': commentData['user_profiles']['profile_pic'],
              'isliked': false,
            });
          }
        }

        final post = post_model.Post_feed.fromMap({
          ...postData,
          'post_id': postId,
          'username': postData['user_profiles']['username'],
          'profile_pic': postData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
          'post_comments': commentMaps,
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
  Future<void> loadMoreUserToasts(final UserId) async {
    if (state.isLoadingMoreToasts || !state.hasMoreToasts) return;

    final user = UserId;
    if (user == null) return;

    state = state.copyWith(isLoadingMoreToasts: true, error: null);

    try {
      final startRange = state.currentToastPage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('toasts')
          .select('''
            *,
            user_profiles!inner(username, profile_pic),
            toast_comments(
              comment_id,
              user_id,
              content,
              like_count,
              created_at,
              user_profiles!toast_comments_user_id_fkey(username, profile_pic)
            )
          ''')
          .eq('user_id', user)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<toast_model.Toast_feed> newToasts = [];

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
            .eq('user_id', user)
            .maybeSingle();
        isLiked = likeResponse != null;

        // Process comments
        List<Map<String, dynamic>> commentMaps = [];
        if (toastData['toast_comments'] != null) {
          for (var commentData in toastData['toast_comments']) {
            commentMaps.add({
              'comment_id': commentData['comment_id'],
              'toast_id': toastId,
              'user_id': commentData['user_id'],
              'content': commentData['content'],
              'like_count': commentData['like_count'] ?? 0,
              'created_at': commentData['created_at'],
              'username': commentData['user_profiles']['username'],
              'profile_pic': commentData['user_profiles']['profile_pic'],
              'uliked': false,
            });
          }
        }

        final toast = toast_model.Toast_feed.fromMap({
          ...toastData,
          'toast_id': toastId,
          'username': toastData['user_profiles']['username'],
          'profile_pic': toastData['user_profiles']['profile_pic'],
          'like_count': likeCount,
          'comment_count': commentCount,
          'isliked': isLiked,
          'toast_comments': commentMaps,
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

  // Load user's bytes
  Future<void> loadUserBytes(final UserId) async {
    if (state.isLoadingBytes) return;

    state = state.copyWith(isLoadingBytes: true, error: null);

    try {
      final user = UserId;
      if (user == null) {
        state = state.copyWith(
          isLoadingBytes: false,
          error: 'User not authenticated',
        );
        return;
      }

      final response = await _supabase
          .from('bytes')
          .select('''
            *,
            user_profiles!bytes_user_id_fkey (username, profile_pic)
          ''')
          .eq('user_id', user)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final List<Byte> newBytes = [];

      for (var byteData in response) {
        final String byteId = byteData['byte_id'].toString();
        final userProfile = byteData['user_profiles'];

        bool isLiked = false;
        final likeResponse = await _supabase
            .from('byte_likes')
            .select('byte_like_id')
            .eq('byte_id', byteId)
            .eq('user_id', user)
            .maybeSingle();
        isLiked = likeResponse != null;

        final byte = Byte.fromJson({
          ...byteData,
          'byte_id': byteId,
          'username': userProfile?['username'],
          'profile_pic': userProfile?['profile_pic'],
          'isliked': isLiked,
        });

        newBytes.add(byte);
      }

      state = state.copyWith(
        bytes: newBytes,
        isLoadingBytes: false,
        hasMoreBytes: newBytes.length == _pageSize,
        currentBytePage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingBytes: false,
        error: 'Failed to load bytes: $e',
      );
    }
  }

  // Load more user's bytes (pagination)
  Future<void> loadMoreUserBytes(final UserId) async {
    if (state.isLoadingMoreBytes || !state.hasMoreBytes) return;

    final user = UserId;
    if (user == null) return;

    state = state.copyWith(isLoadingMoreBytes: true, error: null);

    try {
      final startRange = state.currentBytePage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('bytes')
          .select('''
            *,
            user_profiles!bytes_user_id_fkey (username, profile_pic)
          ''')
          .eq('user_id', user)
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<Byte> newBytes = [];

      for (var byteData in response) {
        final String byteId = byteData['byte_id'].toString();
        final userProfile = byteData['user_profiles'];

        final alreadyExists = state.bytes.any((b) => b.byteId == byteId);
        if (alreadyExists) continue;

        bool isLiked = false;
        final likeResponse = await _supabase
            .from('byte_likes')
            .select('byte_like_id')
            .eq('byte_id', byteId)
            .eq('user_id', user)
            .maybeSingle();
        isLiked = likeResponse != null;

        final byte = Byte.fromJson({
          ...byteData,
          'byte_id': byteId,
          'username': userProfile?['username'],
          'profile_pic': userProfile?['profile_pic'],
          'isliked': isLiked,
        });

        newBytes.add(byte);
      }

      state = state.copyWith(
        bytes: [...state.bytes, ...newBytes],
        isLoadingMoreBytes: false,
        hasMoreBytes: newBytes.length == _pageSize,
        currentBytePage: state.currentBytePage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMoreBytes: false,
        error: 'Failed to load more bytes: $e',
      );
    }
  }// Toggle like for user's byte
  Future<void> toggleByteLike(String byteId) async {
    if (state.bytes.isEmpty || state.likingBytes.contains(byteId)) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final byteIndex = state.bytes.indexWhere((byte) => byte.byteId == byteId);
    if (byteIndex == -1) return;

    final currentByte = state.bytes[byteIndex];
    final currentlyLiked = currentByte.isliked ?? false;
    final currentLikeCount = currentByte.likeCount;

    final newBytes = [...state.bytes];
    newBytes[byteIndex] = currentByte.copyWith(
      likeCount: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
      isliked: !currentlyLiked,
    );

    state = state.copyWith(
      bytes: newBytes,
      likingBytes: {...state.likingBytes, byteId},
    );

    try {
      if (currentlyLiked) {
        await _supabase
            .from('byte_likes')
            .delete()
            .eq('byte_id', byteId)
            .eq('user_id', user.id);

        await _supabase
            .from('bytes')
            .update({'like_count': currentLikeCount - 1})
            .eq('byte_id', byteId);
      } else {
        await _supabase.from('byte_likes').insert({
          'byte_id': byteId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        await _supabase
            .from('bytes')
            .update({'like_count': currentLikeCount + 1})
            .eq('byte_id', byteId);
      }

      state = state.copyWith(
        likingBytes: {...state.likingBytes}..remove(byteId),
      );

    } catch (error) {
      final revertedBytes = [...state.bytes];
      final currentByteIndex = revertedBytes.indexWhere((byte) => byte.byteId == byteId);
      if (currentByteIndex != -1) {
        revertedBytes[currentByteIndex] = currentByte;
      }

      state = state.copyWith(
        bytes: revertedBytes,
        likingBytes: {...state.likingBytes}..remove(byteId),
        error: 'Failed to update byte like: ${error.toString()}',
      );
    }
  }

  // Refresh user's posts and toasts
  Future<void> refreshUserContent(final UserId) async {
    state = const ProfileFeedState();
    await Future.wait([
      loadUserPosts(UserId),
      loadUserToasts(UserId),
      loadUserBytes(UserId),
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

      state = state.copyWith(
        likingPosts: {...state.likingPosts}..remove(postId),
      );

    } catch (error) {
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
        await _supabase
            .from('toast_likes')
            .delete()
            .eq('toast_id', toastId)
            .eq('user_id', user.id);
      } else {
        await _supabase.from('toast_likes').insert({
          'toast_id': toastId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });
      }

      state = state.copyWith(
        likingToasts: {...state.likingToasts}..remove(toastId),
      );

    } catch (error) {
      print('Error toggling toast like: $error');

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
      await _supabase
          .from('post')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);

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
      await _supabase
          .from('toasts')
          .delete()
          .eq('toast_id', toastId)
          .eq('user_id', user.id);

      final updatedToasts = state.toasts.where((toast) => toast.toast_id != toastId).toList();
      state = state.copyWith(toasts: updatedToasts);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete toast: $e');
      return false;
    }
  }

  void clearFeed() {
    state = const ProfileFeedState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}