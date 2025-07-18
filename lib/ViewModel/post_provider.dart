import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../Model/post.dart';



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

final postCreateProvider = StateNotifierProvider<PostCreateNotifier, PostCreateState>((ref) {
  return PostCreateNotifier();
});