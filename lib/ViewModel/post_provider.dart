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

  PostFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.likingPosts = const {},
    this.hasMore = true,
  });

  PostFeedState copyWith({
    List<Post_feed>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    Set<String>? likingPosts,
    bool? hasMore,
  }) {
    return PostFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      likingPosts: likingPosts ?? this.likingPosts,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// State class for post creation
class PostCreateState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<XFile> selectedMedia;
  final String content;
  final String title;
  final String caption;
  final List<String> tags;

  PostCreateState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.selectedMedia = const [],
    this.content = '',
    this.title = '',
    this.caption = '',
    this.tags = const [],
  });

  PostCreateState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<XFile>? selectedMedia,
    String? content,
    String? title,
    String? caption,
    List<String>? tags,
  }) {
    return PostCreateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      selectedMedia: selectedMedia ?? this.selectedMedia,
      content: content ?? this.content,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
    );
  }
}

// Post Feed Provider
class PostFeedNotifier extends StateNotifier<PostFeedState> {
  PostFeedNotifier() : super(PostFeedState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 20;
  int _currentPage = 0;

  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final response = await _supabase
          .from('post')
          .select('''
          *,
          user_profiles!inner(username, profile_pic)
        ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(_currentPage * _pageSize, (_currentPage + 1) * _pageSize - 1);

      final List<Post_feed> newPosts = [];

      for (var postData in response) {
        final String postId = postData['post_id'].toString();

        // Avoid duplicate post_id before processing
        final alreadyExists = state.posts.any((p) => p.post_id == postId);
        if (!refresh && alreadyExists) continue;

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
        final currentUserId = _supabase.auth.currentUser?.id;
        bool isLiked = false;
        if (currentUserId != null) {
          final likeResponse = await _supabase
              .from('post_likes')
              .select('like_id')
              .eq('post_id', postId)
              .eq('user_id', currentUserId)
              .maybeSingle();
          isLiked = likeResponse != null;
        }

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

      final hasMore = newPosts.length == _pageSize;

      if (refresh) {
        state = state.copyWith(
          posts: newPosts,
          isLoading: false,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          posts: [...state.posts, ...newPosts],
          isLoadingMore: false,
          hasMore: hasMore,
        );
      }

      _currentPage++;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load posts: $e',
      );
    }
  }


  Future<void> toggleLike(String postId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Add to liking set for UI feedback
    state = state.copyWith(
      likingPosts: {...state.likingPosts, postId},
    );

    try {
      // Check if already liked
      final existingLike = await _supabase
          .from('post_likes')
          .select('post_like_id')
          .eq('post_id', postId) // postId is already a string
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_like_id', existingLike['post_like_id']);

        // Update local state
        final updatedPosts = state.posts.map((post) {
          if (post.post_id == postId) {
            return post.copyWith(
              like_count: post.like_count > 0 ? post.like_count - 1 : 0,
              isliked: false,
            );
          }
          return post;
        }).toList();

        state = state.copyWith(posts: updatedPosts);
      } else {
        // Like
        await _supabase.from('post_likes').insert({
          'post_id': postId, // postId is already a string
          'user_id': currentUserId,
        });

        // Update local state
        final updatedPosts = state.posts.map((post) {
          if (post.post_id == postId) {
            return post.copyWith(
              like_count: post.like_count + 1,
              isliked: true,
            );
          }
          return post;
        }).toList();

        state = state.copyWith(posts: updatedPosts);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle like: $e');
    } finally {
      // Remove from liking set
      final updatedLikingPosts = Set<String>.from(state.likingPosts);
      updatedLikingPosts.remove(postId);
      state = state.copyWith(likingPosts: updatedLikingPosts);
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
      final updatedPosts = state.posts.map((post) {
        if (post.post_id == postId) {
          return post.copyWith(comment_count: post.comment_count + 1);
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
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

// Post Creation Provider
class PostCreateNotifier extends StateNotifier<PostCreateState> {
  PostCreateNotifier() : super(PostCreateState());

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickMedia({bool fromCamera = false}) async {
    try {
      final List<XFile> pickedFiles = [];

      if (fromCamera) {
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (photo != null) pickedFiles.add(photo);
      } else {
        final List<XFile> photos = await _imagePicker.pickMultiImage(
          imageQuality: 80,
        );
        pickedFiles.addAll(photos);
      }

      if (pickedFiles.isNotEmpty) {
        state = state.copyWith(selectedMedia: [...state.selectedMedia, ...pickedFiles]);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick media: $e');
    }
  }

  Future<void> pickVideo({bool fromCamera = false}) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        state = state.copyWith(selectedMedia: [...state.selectedMedia, video]);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick video: $e');
    }
  }

  void removeMedia(int index) {
    final updatedMedia = List<XFile>.from(state.selectedMedia);
    updatedMedia.removeAt(index);
    state = state.copyWith(selectedMedia: updatedMedia);
  }

  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateCaption(String caption) {
    state = state.copyWith(caption: caption);
  }

  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags);
  }

  Future<String?> _uploadFile(XFile file) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final bytes = await file.readAsBytes();
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${currentUserId.substring(0, 8)}.$fileExtension';

      // Create user-specific folder structure
      final filePath = '$currentUserId/$fileName';

      // Upload with proper headers
      await _supabase.storage
          .from('post-media')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      return _supabase.storage
          .from('post-media')
          .getPublicUrl(filePath);
    } catch (e) {
      print('Upload error: $e'); // For debugging
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<bool> createPost() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    if (state.content.isEmpty && state.selectedMedia.isEmpty) {
      state = state.copyWith(error: 'Please add some content or media');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload media files
      List<String> mediaUrls = [];
      for (int i = 0; i < state.selectedMedia.length; i++) {
        try {
          final file = state.selectedMedia[i];
          final url = await _uploadFile(file);
          if (url != null) {
            mediaUrls.add(url);
          }
        } catch (uploadError) {
          print('Failed to upload file ${i + 1}: $uploadError');
          // Continue with other files, but log the error
          state = state.copyWith(
            error: 'Failed to upload some media files. Please try again.',
          );
          return false;
        }
      }

      // Create post in database
      final postData = {
        'user_id': currentUserId,
        'title': state.title.isEmpty ? null : state.title,
        'content': state.content.isEmpty ? null : state.content,
        'tags': state.tags.isEmpty ? null : state.tags,
        'is_published': true,
        'media_urls': mediaUrls.isEmpty ? null : mediaUrls,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('post')
          .insert(postData)
          .select()
          .single();

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Post created successfully!',
        selectedMedia: [],
        content: '',
        title: '',
        caption: '',
        tags: [],
      );

      return true;
    } catch (e) {
      print('Create post error: $e'); // For debugging
      String errorMessage = 'Failed to create post';

      if (e.toString().contains('StorageException')) {
        errorMessage = 'Failed to upload media. Please check your permissions and try again.';
      } else if (e.toString().contains('row-level security')) {
        errorMessage = 'Permission denied. Please contact support.';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}

// Providers
final postFeedProvider = StateNotifierProvider<PostFeedNotifier, PostFeedState>((ref) {
  return PostFeedNotifier();
});

final postCreateProvider = StateNotifierProvider<PostCreateNotifier, PostCreateState>((ref) {
  return PostCreateNotifier();
});