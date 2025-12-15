import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../Model/byte.dart';
import '../Model/comment.dart';

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
  final Set<String> likingComments;
  final bool hasMore;
  final int currentPage;
  final Map<String, List<Comment>> commentsByByteId;
  final Set<String> loadingComments;

  const BytesFeedState({
    this.bytes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.likingBytes = const {},
    this.likingComments = const {},
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
    Set<String>? likingComments,
    bool? hasMore,
    int? currentPage,
    Map<String, List<Comment>>? commentsByByteId,
    Set<String>? loadingComments,
  }) {
    return BytesFeedState(
      bytes: bytes ?? this.bytes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      likingBytes: likingBytes ?? this.likingBytes,
      likingComments: likingComments ?? this.likingComments,
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
        maxDuration: const Duration(minutes: 1),
        preferredCameraDevice: CameraDevice.rear,
      );

      if (video != null) {
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

      await _supabase.storage.from('bytes').uploadBinary(
        fileName,
        await videoFile.readAsBytes(),
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

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
      debugPrint('Starting byte creation...');

      final String? videoUrl = await _uploadVideo(state.selectedVideo!);
      if (videoUrl == null) {
        debugPrint('Video upload failed');
        return false;
      }

      debugPrint('Video uploaded: $videoUrl');
      debugPrint('Inserting into database...');

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

      debugPrint('Database response: $response');

      if (response.isEmpty) {
        state = state.copyWith(error: 'Failed to create byte - no response from database');
        return false;
      }

      debugPrint('Byte created successfully with ID: ${response[0]['byte_id']}');
      state = ByteCreateState();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error creating byte: $e');
      debugPrint('Stack trace: $stackTrace');
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

      final byteResponse = await _supabase
          .from('bytes')
          .select('user_id, byte')
          .eq('byte_id', byteId)
          .single();

      if (byteResponse['user_id'] != user.id) {
        throw Exception('You can only delete your own bytes');
      }

      final String videoUrl = byteResponse['byte'];
      final String fileName = videoUrl.split('/').last;
      await _supabase.storage.from('bytes').remove([fileName]);

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

  Future<void> loadBytes() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user');
        state = state.copyWith(
          isLoading: false,
          bytes: [],
          hasMore: false,
          currentPage: 1,
        );
        return;
      }

      debugPrint('Loading bytes for user: ${user.id}');

      // Test table access
      try {
        final testQuery = await _supabase
            .from('bytes')
            .select('byte_id')
            .limit(1);
        debugPrint('Table exists, found ${testQuery.length} records');
      } catch (tableError) {
        debugPrint('Table access error: $tableError');
        state = state.copyWith(
          isLoading: false,
          bytes: [],
          error: 'Database table not accessible: $tableError',
        );
        return;
      }

      // Fetch bytes with user profiles
      final response = await _supabase
          .from('bytes')
          .select('''
            *,
            user_profiles!bytes_user_id_fkey(username, profile_pic)
          ''')
          .order('created_at', ascending: false)
          .limit(_pageSize);

      debugPrint('Query executed successfully, fetched ${response.length} bytes');

      if (response.isEmpty) {
        debugPrint('No bytes found in database');
        state = state.copyWith(
          bytes: [],
          isLoading: false,
          hasMore: false,
          currentPage: 1,
        );
        return;
      }

      // Process bytes
      final List<Byte> newBytes = [];

      for (var byteData in response) {
        try {
          final byteId = byteData['byte_id'];
          final userProfile = byteData['user_profiles'];

          debugPrint('Processing byte: $byteId');

          // Check if user liked this byte
          bool isliked = false;
          try {
            final likeResponse = await _supabase
                .from('byte_likes')
                .select('byte_like_id')
                .eq('byte_id', byteId)
                .eq('user_id', user.id)
                .maybeSingle();

            isliked = likeResponse != null;
          } catch (e) {
            debugPrint('Error checking like status for byte $byteId: $e');
          }

          final byte = Byte.fromJson({
            'byte_id': byteId,
            'user_id': byteData['user_id'],
            'byte': byteData['byte'],
            'caption': byteData['caption'],
            'like_count': byteData['like_count'],
            'comment_count': byteData['comment_count'],
            'share_count': byteData['share_count'],
            'created_at': byteData['created_at'],
            'updated_at': byteData['updated_at'],
            'username': userProfile?['username'],
            'profile_pic': userProfile?['profile_pic'],
            'isliked': isliked,
          });

          newBytes.add(byte);
          debugPrint('Added byte: ${byte.byteId}');
        } catch (byteError, stack) {
          debugPrint('Error processing byte: $byteError');
          debugPrint('Stack: $stack');
          continue;
        }
      }

      state = state.copyWith(
        bytes: newBytes,
        isLoading: false,
        hasMore: newBytes.length == _pageSize,
        currentPage: 1,
        error: null,
      );

      debugPrint('Successfully loaded ${newBytes.length} bytes');
    } catch (e, stack) {
      debugPrint('Error loading bytes: $e');
      debugPrint('Stack trace: $stack');

      String errorMessage = 'Failed to load bytes';
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        errorMessage = 'Database table "bytes" does not exist. Please create it first.';
      } else if (e.toString().contains('permission denied')) {
        errorMessage = 'Permission denied. Check RLS policies.';
      } else if (e.toString().contains('violates foreign key constraint')) {
        errorMessage = 'User profile not found. Please complete your profile first.';
      } else {
        errorMessage = 'Failed to load bytes: ${e.toString()}';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        bytes: [],
      );
    }
  }

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
            user_profiles!bytes_user_id_fkey(username, profile_pic)
          ''')
          .order('created_at', ascending: false)
          .range(startRange, endRange);

      final List<Byte> newBytes = [];

      for (var byteData in response) {
        final byteId = byteData['byte_id'];
        final String byteIdStr = byteId.toString();
        final userProfile = byteData['user_profiles'];

        final alreadyExists = state.bytes.any((b) => b.byteId == byteIdStr);
        if (alreadyExists) continue;

        bool isliked = false;
        try {
          final likeResponse = await _supabase
              .from('byte_likes')
              .select('byte_like_id')
              .eq('byte_id', byteId)
              .eq('user_id', user.id)
              .maybeSingle();
          isliked = likeResponse != null;
        } catch (e) {
          debugPrint('Error checking like status: $e');
        }

        final byte = Byte.fromJson({
          'byte_id': byteId,
          'user_id': byteData['user_id'],
          'byte': byteData['byte'],
          'caption': byteData['caption'],
          'like_count': byteData['like_count'],
          'comment_count': byteData['comment_count'],
          'share_count': byteData['share_count'],
          'created_at': byteData['created_at'],
          'updated_at': byteData['updated_at'],
          'username': userProfile?['username'],
          'profile_pic': userProfile?['profile_pic'],
          'isliked': isliked,
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

  Future<void> refreshBytes() async {
    state = const BytesFeedState();
    await loadBytes();
  }

  Future<void> toggleLike(String byteId) async {
    if (state.likingBytes.contains(byteId)) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    final byteIndex = state.bytes.indexWhere((byte) => byte.byteId == byteId);
    if (byteIndex == -1) {
      return;
    }

    final currentByte = state.bytes[byteIndex];
    final currentlyliked = currentByte.isliked ?? false;
    final currentLikeCount = currentByte.likeCount;

    // Optimistic update
    final newBytes = [...state.bytes];
    newBytes[byteIndex] = currentByte.copyWith(
      likeCount: currentlyliked ? currentLikeCount - 1 : currentLikeCount + 1,
      isliked: !currentlyliked,
    );

    state = state.copyWith(
      bytes: newBytes,
      likingBytes: {...state.likingBytes, byteId},
    );

    try {
      if (currentlyliked) {
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
      debugPrint('Error toggling like: $error');

      // Revert optimistic update
      final revertedBytes = [...state.bytes];
      final currentByteIndex = revertedBytes.indexWhere((byte) => byte.byteId == byteId);
      if (currentByteIndex != -1) {
        revertedBytes[currentByteIndex] = currentByte;
      }

      state = state.copyWith(
        bytes: revertedBytes,
        likingBytes: {...state.likingBytes}..remove(byteId),
      );
    }
  }

  // Load comments for a byte
  Future<List<Comment>> loadComments(String byteId) async {
    if (state.loadingComments.contains(byteId)) {
      return state.commentsByByteId[byteId] ?? [];
    }

    state = state.copyWith(
      loadingComments: {...state.loadingComments, byteId},
    );

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          loadingComments: {...state.loadingComments}..remove(byteId),
        );
        return [];
      }

      final response = await _supabase
          .from('byte_comments')
          .select('''
            *,
            user_profiles!byte_comments_user_id_fkey(username, profile_pic)
          ''')
          .eq('byte_id', byteId)
          .isFilter('parent_comment_id', null)
          .order('created_at', ascending: false);

      final List<Comment> comments = [];

      for (var commentData in response) {
        final int commentId = commentData['comment_id'] is int 
            ? commentData['comment_id'] 
            : int.tryParse(commentData['comment_id'].toString()) ?? 0;
        final userProfile = commentData['user_profiles'];

        bool isliked = false;
        try {
          final likeResponse = await _supabase
              .from('byte_comment_likes')
              .select('byte_comment_like_id')
              .eq('comment_id', commentId)
              .eq('user_id', user.id)
              .maybeSingle();

          isliked = likeResponse != null;
        } catch (e) {
          debugPrint('Error checking comment like status: $e');
        }

        final comment = Comment.fromByteMap({
          ...commentData,
          'username': userProfile?['username'] ?? 'Unknown',
          'profile_pic': userProfile?['profile_pic'],
          'isliked': isliked,
        });

        comments.add(comment);
      }

      final updatedComments = Map<String, List<Comment>>.from(state.commentsByByteId);
      updatedComments[byteId] = comments;

      state = state.copyWith(
        commentsByByteId: updatedComments,
        loadingComments: {...state.loadingComments}..remove(byteId),
      );

      debugPrint('Fetched ${comments.length} comments for byte $byteId');
      return comments;
    } catch (e, stack) {
      debugPrint('Error loading comments: $e\n$stack');
      state = state.copyWith(
        loadingComments: {...state.loadingComments}..remove(byteId),
      );
      return state.commentsByByteId[byteId] ?? [];
    }
  }

  // Load replies for a parent comment
  Future<List<Comment>> loadReplies(String byteId, String parentCommentIdStr) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Convert IDs to int for database query
      final byteIdInt = int.tryParse(byteId);
      final parentCommentId = int.tryParse(parentCommentIdStr);
      if (byteIdInt == null || parentCommentId == null) {
        debugPrint('Error: Invalid ID format - byteId: $byteId, parentCommentId: $parentCommentIdStr');
        return [];
      }

      final response = await _supabase
          .from('byte_comments')
          .select('''
            *,
            user_profiles!byte_comments_user_id_fkey(username, profile_pic)
          ''')
          .eq('byte_id', byteIdInt)
          .eq('parent_comment_id', parentCommentId)
          .order('created_at', ascending: true);

      final List<Comment> replies = [];

      for (var replyData in response) {
        final int commentId = replyData['comment_id'] is int 
            ? replyData['comment_id'] 
            : int.tryParse(replyData['comment_id'].toString()) ?? 0;
        final userProfile = replyData['user_profiles'];

        bool isliked = false;
        try {
          final likeResponse = await _supabase
              .from('byte_comment_likes')
              .select('byte_comment_like_id')
              .eq('comment_id', commentId)
              .eq('user_id', user.id)
              .maybeSingle();

          isliked = likeResponse != null;
        } catch (e) {
          debugPrint('Error checking reply like status: $e');
        }

        final reply = Comment.fromByteMap({
          ...replyData,
          'username': userProfile?['username'] ?? 'Unknown',
          'profile_pic': userProfile?['profile_pic'],
          'isliked': isliked,
        });

        replies.add(reply);
      }

      return replies;
    } catch (e) {
      debugPrint('Error loading replies: $e');
      return [];
    }
  }

  Future<int> getRepliesCount(String parentCommentIdStr) async {
    try {
      final parentCommentId = int.tryParse(parentCommentIdStr);
      if (parentCommentId == null) return 0;

      final countResponse = await _supabase
          .from('byte_comments')
          .select('comment_id')
          .eq('parent_comment_id', parentCommentId);

      return (countResponse as List).length;
    } catch (e) {
      debugPrint('Error getting replies count: $e');
      return 0;
    }
  }

  // Add a reply to a comment
  Future<bool> addReply(String byteId, String parentCommentId, String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Convert IDs to int (database expects integers)
      final byteIdInt = int.tryParse(byteId);
      final parentCommentIdInt = int.tryParse(parentCommentId);
      if (byteIdInt == null || parentCommentIdInt == null) {
        debugPrint('Error: Invalid ID format - byteId: $byteId, parentCommentId: $parentCommentId');
        return false;
      }

      await _supabase.from('byte_comments').insert({
        'byte_id': byteIdInt,
        'user_id': user.id,
        'content': content.trim(),
        'parent_comment_id': parentCommentIdInt,
        'like_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Added reply to comment $parentCommentId');
      return true;
    } catch (e) {
      debugPrint('Error adding reply: $e');
      return false;
    }
  }

  // Add a new comment
  Future<bool> addComment(String byteId, String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Convert byteId to int (database expects integer)
      final byteIdInt = int.tryParse(byteId);
      if (byteIdInt == null) {
        debugPrint('Error: Invalid byteId format: $byteId');
        return false;
      }

      final insertResp = await _supabase.from('byte_comments').insert({
        'byte_id': byteIdInt,
        'user_id': user.id,
        'content': content.trim(),
        'like_count': 0,
        'parent_comment_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      final userProfile = await _supabase
          .from('user_profiles')
          .select('username, profile_pic')
          .eq('user_id', user.id)
          .single();

      final newComment = Comment.fromByteMap({
        ...insertResp,
        'username': userProfile['username'] ?? 'Unknown',
        'profile_pic': userProfile['profile_pic'],
        'isliked': false,
      });

      final currentComments = state.commentsByByteId[byteId] ?? [];
      final updatedComments = [newComment, ...currentComments];

      state = state.copyWith(
        commentsByByteId: {
          ...state.commentsByByteId,
          byteId: updatedComments,
        },
      );

      // Update comment count
      final byteIndex = state.bytes.indexWhere((b) => b.byteId == byteId);
      if (byteIndex != -1) {
        final updatedBytes = [...state.bytes];
        updatedBytes[byteIndex] = updatedBytes[byteIndex].copyWith(
          commentCount: updatedBytes[byteIndex].commentCount + 1,
        );
        state = state.copyWith(bytes: updatedBytes);
      }

      debugPrint('Added comment to byte $byteId');
      return true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  Future<void> toggleCommentLike(String commentIdStr) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      if (state.likingComments.contains(commentIdStr)) {
        return;
      }

      state = state.copyWith(
        likingComments: {...state.likingComments, commentIdStr},
      );
      
      final int commentId = int.tryParse(commentIdStr) ?? 0;

      Comment? targetComment;
      String? targetByteId;

      for (var entry in state.commentsByByteId.entries) {
        try {
          final comment = entry.value.firstWhere(
                (c) => c.commentId.toString() == commentId,
          );
          targetComment = comment;
          targetByteId = entry.key;
          break;
        } catch (_) {
          continue;
        }
      }

      if (targetComment == null || targetByteId == null) {
        state = state.copyWith(
          likingComments: {...state.likingComments}..remove(commentIdStr),
        );
        return;
      }

      // Optimistic update
      final updatedComments = state.commentsByByteId[targetByteId]!.map((comment) {
        if (comment.commentId.toString() == commentId) {
          return comment.copyWith(
            isliked: !comment.isliked,
            likes: comment.isliked
                ? comment.likes - 1
                : comment.likes + 1,
          );
        }
        return comment;
      }).toList();

      state = state.copyWith(
        commentsByByteId: {
          ...state.commentsByByteId,
          targetByteId: updatedComments,
        },
      );

      if (targetComment.isliked) {
        await _supabase
            .from('byte_comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', user.id);
      } else {
        await _supabase.from('byte_comment_likes').insert({
          'comment_id': commentId,
          'user_id': user.id,
        });
      }

      state = state.copyWith(
        likingComments: {...state.likingComments}..remove(commentIdStr),
      );
    } catch (e) {
      debugPrint('Error toggling comment like: $e');

      // Revert on error
      state = state.copyWith(
        likingComments: {...state.likingComments}..remove(commentIdStr),
      );
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