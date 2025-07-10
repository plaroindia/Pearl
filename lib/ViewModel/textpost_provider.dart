// providers/text_post_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/text_post.dart';

// State for text post creation
class TextPostState {
  final String title;
  final String content;
  final List<String> tags;
  final bool isLoading;
  final bool isDraft;
  final String? error;
  final bool hasUnsavedChanges;
  final String? successMessage;

  const TextPostState({
    this.title = '',
    this.content = '',
    this.tags = const [],
    this.isLoading = false,
    this.isDraft = false,
    this.error,
    this.hasUnsavedChanges = false,
    this.successMessage,
  });

  TextPostState copyWith({
    String? title,
    String? content,
    List<String>? tags,
    bool? isLoading,
    bool? isDraft,
    String? error,
    bool? hasUnsavedChanges,
    String? successMessage,
  }) {
    return TextPostState(
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      isDraft: isDraft ?? this.isDraft,
      error: error ?? this.error,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// Text Post Provider
final textPostProvider = StateNotifierProvider<TextPostNotifier, TextPostState>((ref) {
  return TextPostNotifier();
});

class TextPostNotifier extends StateNotifier<TextPostState> {
  TextPostNotifier() : super(const TextPostState());

  final SupabaseClient _supabase = Supabase.instance.client;

  // Update title
  void updateTitle(String title) {
    state = state.copyWith(
      title: title,
      hasUnsavedChanges: true,
      error: null,
    );
  }

  // Update content
  void updateContent(String content) {
    state = state.copyWith(
      content: content,
      hasUnsavedChanges: true,
      error: null,
    );
  }

  // Add tag
  void addTag(String tag) {
    if (tag.isNotEmpty && !state.tags.contains(tag)) {
      final newTags = [...state.tags, tag];
      state = state.copyWith(
        tags: newTags,
        hasUnsavedChanges: true,
        error: null,
      );
    }
  }

  // Remove tag
  void removeTag(String tag) {
    final newTags = state.tags.where((t) => t != tag).toList();
    state = state.copyWith(
      tags: newTags,
      hasUnsavedChanges: true,
      error: null,
    );
  }

  // Save as draft
  Future<void> saveDraft() async {
    if (state.title.isEmpty && state.content.isEmpty) {
      state = state.copyWith(error: 'Cannot save empty post');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create data map without toast_id - let Supabase auto-generate it
      final toastData = {
        'user_id': user.id,
        'title': state.title,
        'content': state.content,
        'tags': state.tags,
        'created_at': DateTime.now().toIso8601String(),
        'is_published': false,
        'like_count': 0,
        'comment_count': 0,
      };

      await _supabase.from('toasts').insert(toastData);

      state = state.copyWith(
        isLoading: false,
        isDraft: true,
        hasUnsavedChanges: false,
        successMessage: 'Draft saved successfully!',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Publish post
  Future<void> publishPost() async {
    if (state.title.isEmpty) {
      state = state.copyWith(error: 'Title is required');
      return;
    }

    if (state.content.isEmpty) {
      state = state.copyWith(error: 'Content is required');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create data map without toast_id - let Supabase auto-generate it
      final toastData = {
        'user_id': user.id,
        'title': state.title,
        'content': state.content,
        'tags': state.tags,
        'created_at': DateTime.now().toIso8601String(),
        'is_published': true,
        'like_count': 0,
        'comment_count': 0,
      };

      await _supabase.from('toasts').insert(toastData);

      state = state.copyWith(
        isLoading: false,
        hasUnsavedChanges: false,
        successMessage: 'Post published successfully!',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  void clearSuccessMessage() {
    state = TextPostState(
      title: state.title,
      content: state.content,
      tags: state.tags,
      isLoading: state.isLoading,
      isDraft: state.isDraft,
      error: state.error,
      hasUnsavedChanges: state.hasUnsavedChanges,
      successMessage: null,  // Explicitly set to null
    );
  }

  // Clear form
  void clearForm() {
    state = const TextPostState();
  }

  // Reset error
  void clearError() {
    state = state.copyWith(error: null);
  }
}