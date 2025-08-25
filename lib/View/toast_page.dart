// Updated toast_page.dart - Clean, minimalist UI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ViewModel/textpost_provider.dart';

class ToastPage extends ConsumerStatefulWidget {
  const ToastPage({super.key});

  @override
  ConsumerState<ToastPage> createState() => _TextPostPageState();
}

class _TextPostPageState extends ConsumerState<ToastPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Listen to controller changes to update state
    _titleController.addListener(() {
      ref.read(textPostProvider.notifier).updateTitle(_titleController.text);
    });

    _contentController.addListener(() {
      ref.read(textPostProvider.notifier).updateContent(_contentController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _tagController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(textPostProvider.notifier).addTag(value);
              _tagController.clear();
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (_tagController.text.isNotEmpty) {
                ref.read(textPostProvider.notifier).addTag(_tagController.text);
                _tagController.clear();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Discard Changes?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(textPostProvider.notifier).clearForm();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPostState = ref.watch(textPostProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    ref.listen<TextPostState>(textPostProvider, (previous, next) {
      if (next.successMessage != null) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ref.read(textPostProvider.notifier).clearSuccessMessage();
            Navigator.pop(context);
          }
        });
      }
    });

    return PopScope(
      canPop: !textPostState.hasUnsavedChanges,
      onPopInvoked: (didPop) {
        if (!didPop && textPostState.hasUnsavedChanges) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () {
              if (textPostState.hasUnsavedChanges) {
                _showDiscardDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Create Text Post',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            // Draft button (only show if there are unsaved changes)
            if (textPostState.hasUnsavedChanges)
              TextButton(
                onPressed: textPostState.isLoading
                    ? null
                    : () => ref.read(textPostProvider.notifier).saveDraft(),
                child: Text(
                  'Draft',
                  style: TextStyle(
                    color: textPostState.isLoading ? Colors.grey : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // Post button (always visible in app bar)
            TextButton(
              onPressed: textPostState.isLoading
                  ? null
                  : () => ref.read(textPostProvider.notifier).publishPost(),
              child: Text(
                'Post',
                style: TextStyle(
                  color: textPostState.isLoading ? Colors.grey : Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Error message
            if (textPostState.error != null)
              Container(
                width: double.infinity,
                color: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        textPostState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => ref.read(textPostProvider.notifier).clearError(),
                    ),
                  ],
                ),
              ),

            // Success message
            if (textPostState.successMessage != null)
              Container(
                width: double.infinity,
                color: Colors.green.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        textPostState.successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.green, size: 20),
                      onPressed: () => ref.read(textPostProvider.notifier).clearSuccessMessage(),
                    ),
                  ],
                ),
              ),

            // Loading indicator
            if (textPostState.isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field - clean, no borders
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your title here...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                    ),

                    // Subtle divider
                    Container(
                      height: 1,
                      color: Colors.grey[800],
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),

                    // Content field - clean, spacious
                    TextField(
                      controller: _contentController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 16,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your post content here...\n\nYou can write multiple paragraphs, share your thoughts, ask questions, or start a discussion.',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isTablet ? 18 : 16,
                          height: 1.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      maxLines: null,
                      minLines: 10,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 32),

                    // Tags section
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tags',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showTagDialog,
                          icon: const Icon(Icons.add, color: Colors.blue, size: 20),
                          label: const Text(
                            'Add Tag',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Tags display
                    if (textPostState.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: textPostState.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => ref.read(textPostProvider.notifier).removeTag(tag),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Text(
                          'No tags added yet. Tags help others discover your post.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Writing tips section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.yellow[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Writing Tips',
                                style: TextStyle(
                                  color: Colors.yellow[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Write a clear, descriptive title\n'
                                '• Use proper grammar and spelling\n'
                                '• Break up long text into paragraphs\n'
                                '• Add relevant tags to reach your audience\n'
                                '• Be respectful and constructive',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom padding for scroll
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Optional: Post preview widget for future use
class PostPreviewWidget extends ConsumerWidget {
  const PostPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPostState = ref.watch(textPostProvider);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title preview
          if (textPostState.title.isNotEmpty)
            Text(
              textPostState.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 12),

          // Content preview
          if (textPostState.content.isNotEmpty)
            Text(
              textPostState.content,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: isTablet ? 16 : 14,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),

          // Tags preview
          if (textPostState.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: textPostState.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Empty state
          if (textPostState.title.isEmpty && textPostState.content.isEmpty)
            Text(
              'Start writing to see preview...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}