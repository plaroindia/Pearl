import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../Model/byte.dart';

// Comment model for bytes
class ByteComment {
  final String commentId;
  final String byteId;
  final String userId;
  final String content;
  final String username;
  final String? profilePic;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;

  ByteComment({
    required this.commentId,
    required this.byteId,
    required this.userId,
    required this.content,
    required this.username,
    this.profilePic,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory ByteComment.fromJson(Map<String, dynamic> json) {
    return ByteComment(
      commentId: json['comment_id'].toString(),
      byteId: json['byte_id'].toString(),
      userId: json['user_id'].toString(),
      content: json['content'] ?? '',
      username: json['username'] ?? 'Unknown',
      profilePic: json['profile_pic'],
      likeCount: json['like_count'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  ByteComment copyWith({
    int? likeCount,
    bool? isLiked,
  }) {
    return ByteComment(
      commentId: commentId,
      byteId: byteId,
      userId: userId,
      content: content,
      username: username,
      profilePic: profilePic,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}

// Byte create state
class ByteCreateState {
  final XFile? selectedVideo;
  final String caption;
  final bool isLoading;
  final String? error;
  final bool isUploading;
  final double uploadProgress;

  ByteCreateState({
    this.selectedVideo,
    this.caption = '',
    this.isLoading = false,
    this.error,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  ByteCreateState copyWith({
    XFile? selectedVideo,
    String? caption,
    bool? isLoading,
    String? error,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return ByteCreateState(
      selectedVideo: selectedVideo ?? this.selectedVideo,
      caption: caption ?? this.caption,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

// Bytes feed state
class BytesFeedState {
  final List<Byte> bytes;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final Set<String> likingBytes;
  final bool hasMore;
  final int currentPage;
  final Map<String, List<ByteComment>> commentsByByteId;
  final Set<String> loadingComments;

  const BytesFeedState({
    this.bytes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.likingBytes = const {},
    this.hasMore = true,
    this.currentPage = 0,
    this.commentsByByteId = const {},
    this.loadingComments = const {},
  });

  BytesFeedState copyWith({
    List<Byte>? bytes,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    Set<String>? likingBytes,
    bool? hasMore,
    int? currentPage,
    Map<String, List<ByteComment>>? commentsByByteId,
    Set<String>? loadingComments,
  }) {
    return BytesFeedState(
      bytes: bytes ?? this.bytes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      likingBytes: likingBytes ?? this.likingBytes,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      commentsByByteId: commentsByByteId ?? this.commentsByByteId,
      loadingComments: loadingComments ?? this.loadingComments,
    );
  }
}

// Byte create provider
class ByteCreateNotifier extends StateNotifier<ByteCreateState> {
  ByteCreateNotifier() : super(ByteCreateState());

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  void updateCaption(String caption) {
    state = state.copyWith(caption: caption);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearVideo() {
    state = state.copyWith(selectedVideo: null);
  }

  Future<void> pickVideo({bool fromCamera = false}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 1), // 1 minute max for bytes
        preferredCameraDevice: CameraDevice.rear,
      );

      if (video != null) {
        // Check video file size (max 50MB for bytes)
        final File videoFile = File(video.path);
        final int fileSizeInBytes = await videoFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 50) {
          state = state.copyWith(error: 'Video file size must be less than 50MB');
          return;
        }

        state = state.copyWith(selectedVideo: video, error: null);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick video: ${e.toString()}');
    }
  }

  Future<String?> _uploadVideo(XFile video) async {
    try {
      final String fileName = 'byte_${DateTime.now().millisecondsSinceEpoch}_${_supabase.auth.currentUser?.id}.mp4';
      final File videoFile = File(video.path);

      state = state.copyWith(isUploading: true, uploadProgress: 0.0);

      // Upload to Supabase Storage
      await _supabase.storage.from('bytes').uploadBinary(
        fileName,
        await videoFile.readAsBytes(),
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Get public URL
      final String publicUrl = _supabase.storage.from('bytes').getPublicUrl(fileName);

      state = state.copyWith(uploadProgress: 1.0);
      return publicUrl;
    } catch (e) {
      state = state.copyWith(error: 'Failed to upload video: ${e.toString()}');
      return null;
    } finally {
      state = state.copyWith(isUploading: false);
    }
  }

  Future<bool> createByte() async {
    if (state.selectedVideo == null) {
      state = state.copyWith(error: 'Please select a video');
      return false;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = state.copyWith(error: 'Please log in to create a byte');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload video
      final String? videoUrl = await _uploadVideo(state.selectedVideo!);
      if (videoUrl == null) {
        return false;
      }

      // Create byte record
      final response = await _supabase.from('bytes').insert({
        'user_id': user.id,
        'byte': videoUrl,
        'caption': state.caption.trim().isEmpty ? null : state.caption.trim(),
        'like_count': 0,
        'comment_count': 0,
        'share_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isEmpty) {
        state = state.copyWith(error: 'Failed to create byte');
        return false;
      }

      // Reset state after successful creation
      state = ByteCreateState();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create byte: ${e.toString()}');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> deleteByte(String byteId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get byte to check ownership and get video URL for deletion
      final byteResponse = await _supabase
          .from('bytes')
          .select('user_id, byte')
          .eq('byte_id', byteId)
          .single();

      if (byteResponse['user_id'] != user.id) {
        throw Exception('You can only delete your own bytes');
      }

      // Delete video from storage
      final String videoUrl = byteResponse['byte'];
      final String fileName = videoUrl.split('/').last;
      await _supabase.storage.from('bytes').remove([fileName]);

      // Delete byte record
      await _supabase.from('bytes').delete().eq('byte_id', byteId);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete byte: ${e.toString()}');
      return false;
    }
  }
}

// Bytes feed provider
class BytesFeedNotifier extends StateNotifier<BytesFeedState> {
  BytesFeedNotifier() : super(const BytesFeedState());

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _pageSize = 20;

  // Load initial bytes
  Future<void> loadBytes() async {
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
          .from('bytes')
          .select('''
            *,
            user_profiles!bytes_user_id_fkey (
              username,
              profile_pic
            )
          ''')
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final List<Byte> newBytes = [];

      for (var byteData in response) {
        final String byteId = byteData['byte_id'].toString(); // Convert to string
        final userProfile = byteData['user_profiles'];

        // Check if current user liked this byte
        bool isLiked = false;
        final likeResponse = await _supabase
            .from('byte_likes')
            .select('byte_like_id')
            .eq('byte_id', byteId)
            .eq('user_id', user.id)
            .maybeSingle();
        isLiked = likeResponse != null;

        final byte = Byte.fromJson({
          ...byteData,
          'byte_id': byteId, // Ensure it's a string in the JSON
          'username': userProfile?['username'],
          'profile_pic': userProfile?['profile_pic'],
          'isLiked': isLiked,
        });

        newBytes.add(byte);
      }

      state = state.copyWith(
        bytes: newBytes,
        isLoading: false,
        hasMore: newBytes.length == _pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load bytes: $e',
      );
    }
  }

  // Load more bytes (pagination)
  Future<void> loadMoreBytes() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final startRange = state.currentPage * _pageSize;
      final endRange = startRange + _pageSize - 1;

      final response = await _supabase
          .from('bytes')
          .select('''
            *,
            user_profiles!bytes_user_id_fkey (
              username,
              profile_pic
            )
          ''')
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<Byte> newBytes = [];

      for (var byteData in response) {
        final String byteId = byteData['byte_id'].toString(); // Convert to string
        final userProfile = byteData['user_profiles'];

        // Avoid duplicates
        final alreadyExists = state.bytes.any((b) => b.byteId == byteId);
        if (alreadyExists) continue;

        // Check if current user liked this byte
        bool isLiked = false;
        final likeResponse = await _supabase
            .from('byte_likes')
            .select('byte_like_id')
            .eq('byte_id', byteId)
            .eq('user_id', user.id)
            .maybeSingle();
        isLiked = likeResponse != null;

        final byte = Byte.fromJson({
          ...byteData,
          'byte_id': byteId, // Ensure it's a string in the JSON
          'username': userProfile?['username'],
          'profile_pic': userProfile?['profile_pic'],
          'isLiked': isLiked,
        });

        newBytes.add(byte);
      }

      state = state.copyWith(
        bytes: [...state.bytes, ...newBytes],
        isLoadingMore: false,
        hasMore: newBytes.length == _pageSize,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more bytes: $e',
      );
    }
  }

  // Refresh bytes
  Future<void> refreshBytes() async {
    state = const BytesFeedState();
    await loadBytes();
  }

  // Toggle like with optimistic updates
  Future<void> toggleLike(String byteId) async {
    // Check if bytes are loaded
    if (state.bytes.isEmpty) {
      await loadBytes();
      if (state.bytes.isEmpty) {
        return;
      }
    }

    // Prevent multiple simultaneous like operations on the same byte
    if (state.likingBytes.contains(byteId)) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    // Find the byte in current state
    final byteIndex = state.bytes.indexWhere((byte) => byte.byteId == byteId);
    if (byteIndex == -1) {
      return;
    }

    final currentByte = state.bytes[byteIndex];
    final currentlyLiked = currentByte.isLiked ?? false;
    final currentLikeCount = currentByte.likeCount;

    // OPTIMISTIC UPDATE: Update UI immediately for instant feedback
    final newBytes = [...state.bytes];
    newBytes[byteIndex] = currentByte.copyWith(
      likeCount: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
      isLiked: !currentlyLiked,
    );

    state = state.copyWith(
      bytes: newBytes,
      likingBytes: {...state.likingBytes, byteId},
    );

    try {
      if (currentlyLiked) {
        // Unlike the byte
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
        // Like the byte
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

      // Remove from likingBytes - keep the optimistic update since it succeeded
      state = state.copyWith(
        likingBytes: {...state.likingBytes}..remove(byteId),
      );

    } catch (error) {
      // REVERT OPTIMISTIC UPDATE: Restore original state on error
      final revertedBytes = [...state.bytes];
      final currentByteIndex = revertedBytes.indexWhere((byte) => byte.byteId == byteId);
      if (currentByteIndex != -1) {
        revertedBytes[currentByteIndex] = currentByte; // Restore original state
      }

      state = state.copyWith(
        bytes: revertedBytes,
        likingBytes: {...state.likingBytes}..remove(byteId),
        error: 'Failed to update like: ${error.toString()}',
      );
    }
  }

  // Load comments for a specific byte
  Future<List<ByteComment>> loadComments(String byteId) async {
    if (state.loadingComments.contains(byteId)) {
      return state.commentsByByteId[byteId] ?? [];
    }

    state = state.copyWith(
      loadingComments: {...state.loadingComments, byteId},
    );

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('byte_comments')
          .select('''
            *,
            user_profiles!byte_comments_user_id_fkey (
              username,
              profile_pic
            )
          ''')
          .eq('byte_id', byteId)
          .order('created_at', ascending: false);

      final List<ByteComment> comments = [];

      for (var commentData in response) {
        final String commentId = commentData['comment_id'].toString();
        final userProfile = commentData['user_profiles'];

        // Check if current user liked this comment
        bool isLiked = false;
        final likeResponse = await _supabase
            .from('byte_comment_likes')
            .select('byte_comment_like_id')
            .eq('comment_id', commentId)
            .eq('user_id', user.id)
            .maybeSingle();
        isLiked = likeResponse != null;

        final comment = ByteComment.fromJson({
          ...commentData,
          'comment_id': commentId,
          'username': userProfile?['username'] ?? 'Unknown',
          'profile_pic': userProfile?['profile_pic'],
          'isLiked': isLiked,
        });

        comments.add(comment);
      }

      final updatedComments = Map<String, List<ByteComment>>.from(state.commentsByByteId);
      updatedComments[byteId] = comments;

      state = state.copyWith(
        commentsByByteId: updatedComments,
        loadingComments: {...state.loadingComments}..remove(byteId),
      );

      return comments;
    } catch (e) {
      state = state.copyWith(
        loadingComments: {...state.loadingComments}..remove(byteId),
        error: 'Failed to load comments: $e',
      );
      return [];
    }
  }

  // Add a comment
  Future<bool> addComment(String byteId, String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Insert the comment
      await _supabase.from('byte_comments').insert({
        'byte_id': byteId,
        'user_id': user.id,
        'content': content,
        'like_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update the byte's comment count
      final currentByte = state.bytes.firstWhere((b) => b.byteId == byteId);
      await _supabase
          .from('bytes')
          .update({'comment_count': currentByte.commentCount + 1})
          .eq('byte_id', byteId);

      // Update local state
      final updatedBytes = state.bytes.map((byte) {
        if (byte.byteId == byteId) {
          return byte.copyWith(commentCount: byte.commentCount + 1);
        }
        return byte;
      }).toList();

      state = state.copyWith(bytes: updatedBytes);

      // Refresh comments for this byte
      await loadComments(byteId);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add comment: $e');
      return false;
    }
  }

  // Toggle comment like
  Future<void> toggleCommentLike(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Find the comment across all byte comments
      ByteComment? targetComment;
      String? targetByteId;

      for (var entry in state.commentsByByteId.entries) {
        final comment = entry.value.firstWhere(
              (c) => c.commentId == commentId,
          orElse: () => throw Exception('Comment not found'),
        );
        if (comment.commentId == commentId) {
          targetComment = comment;
          targetByteId = entry.key;
          break;
        }
      }

      if (targetComment == null || targetByteId == null) return;

      final currentlyLiked = targetComment.isLiked;
      final currentLikeCount = targetComment.likeCount;

      if (currentlyLiked) {
        // Unlike
        await _supabase
            .from('byte_comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', user.id);

        await _supabase
            .from('byte_comments')
            .update({'like_count': currentLikeCount - 1})
            .eq('comment_id', commentId);
      } else {
        // Like
        await _supabase.from('byte_comment_likes').insert({
          'comment_id': commentId,
          'user_id': user.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        await _supabase
            .from('byte_comments')
            .update({'like_count': currentLikeCount + 1})
            .eq('comment_id', commentId);
      }

      // Update local state
      final updatedComments = Map<String, List<ByteComment>>.from(state.commentsByByteId);
      final byteComments = List<ByteComment>.from(updatedComments[targetByteId] ?? []);
      final commentIndex = byteComments.indexWhere((c) => c.commentId == commentId);

      if (commentIndex != -1) {
        byteComments[commentIndex] = targetComment.copyWith(
          likeCount: currentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
          isLiked: !currentlyLiked,
        );
        updatedComments[targetByteId] = byteComments;

        state = state.copyWith(commentsByByteId: updatedComments);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle comment like: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final byteCreateProvider = StateNotifierProvider<ByteCreateNotifier, ByteCreateState>(
      (ref) => ByteCreateNotifier(),
);

final bytesFeedProvider = StateNotifierProvider<BytesFeedNotifier, BytesFeedState>(
      (ref) => BytesFeedNotifier(),
);