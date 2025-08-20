// widgets/toast_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Model/toast.dart';
import '../../ViewModel/toast_feed_provider.dart';
import '../../ViewModel/theme_provider.dart'; // Add this import
import 'comment_card.dart';

class ToastCard extends ConsumerWidget {
  final Toast_feed toast;
  final VoidCallback? onTap;
  final VoidCallback? onUserInfo;

  const ToastCard({
    Key? key,
    required this.toast,
    this.onTap,
    this.onUserInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    final toastFeedState = ref.watch(toastFeedProvider);
    final toast = toastFeedState.posts.firstWhere((p) => p.toast_id == this.toast.toast_id, orElse: () => this.toast);

    final isLiking = toastFeedState.likingPosts.contains(toast.toast_id);

    // Show error if there's one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (toastFeedState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toastFeedState.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(toastFeedProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    void _showCommentsSheet(BuildContext context, String toastId) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CommentsBottomSheet(toastId: toastId);
        },
      );
    }

    Widget buildContent(BuildContext context, String content) {
      final textStyle = TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.8),
        fontSize: 14,
        height: 1.4,
      );

      final textSpan = TextSpan(text: content, style: textStyle);

      final tp = TextPainter(
        text: textSpan,
        maxLines: 10,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: MediaQuery.of(context).size.width);

      final isOverflowing = tp.didExceedMaxLines;

      if (!isOverflowing) {
        return Text(content, style: textStyle);
      }

      return SizedBox(
        height: 10 * 14 * 1.4, // limit height to 10 lines
        child: Stack(
          children: [
            Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(content, style: textStyle),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 2 * 14 * 1.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.scaffoldBackgroundColor.withOpacity(0.8)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header
              GestureDetector(
                onTap:onUserInfo,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: toast.profile_pic != null
                          ? NetworkImage(toast.profile_pic!)
                          : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toast.username ?? 'Unknown User',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatTimeAgo(toast.created_at),
                            style: TextStyle(
                              color: theme.dividerColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: theme.dividerColor),
                      onPressed: () {
                        _showMoreOptions(context);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Title
              if (toast.title != null && toast.title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    toast.title!,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Content
              if (toast.content != null && toast.content!.isNotEmpty)
                buildContent(context, toast.content!),

              const SizedBox(height: 12),

              // Tags
              if (toast.tags != null && toast.tags!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: toast.tags!.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like Button
                  _ActionButton(
                    icon: toast.isliked ? Icons.favorite : Icons.favorite_border,
                    label: '${toast.like_count}',
                    color: toast.isliked ? Colors.red : theme.dividerColor!,
                    isLoading: isLiking,
                    onPressed: isLiking ? null : () {
                      print('🔵 Like button pressed for toast: ${toast.toast_id}');
                      if (toast.toast_id != null) {
                        ref.read(toastFeedProvider.notifier).toggleLike(toast.toast_id!);
                      } else {
                        print('🔴 Toast ID is null!');
                      }
                    },
                  ),

                  // Comment Button
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    label: '${toast.comment_count}',
                    color: theme.dividerColor!,
                    onPressed: () {
                      _showCommentsSheet(context, toast.toast_id!);
                    },
                  ),

                  // Share Button
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: '${toast.share_count}',
                    color: theme.dividerColor!,
                    onPressed: () {
                      _sharePost(context);
                    },
                  ),

                  // Bookmark Button
                  _ActionButton(
                    icon: Icons.bookmark_border,
                    label: '',
                    color: theme.dividerColor!,
                    onPressed: () {
                      _bookmarkPost(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Unknown time';

    try {
      final DateTime postTime = DateTime.parse(createdAt);
      final Duration difference = DateTime.now().difference(postTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  void _showMoreOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.red),
              title: Text('Report', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                // Handle report
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: Colors.orange),
              title: Text('Block User', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                // Handle block user
              },
            ),
            ListTile(
              leading: Icon(Icons.link_outlined, color: theme.colorScheme.primary),
              title: Text('Copy Link', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                // Handle copy link
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(BuildContext context) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _bookmarkPost(BuildContext context) {
    // Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark functionality coming soon')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String toastId;

  const CommentsBottomSheet({Key? key, required this.toastId}) : super(key: key);

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final comments = await ref.read(toastFeedProvider.notifier).loadComments(widget.toastId);
    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(toastFeedProvider.notifier).addComment(
      widget.toastId,
      _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      await _loadComments(); // Reload comments
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Comments',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),

              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(top: BorderSide(color: theme.dividerColor!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: _isSubmitting
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        )
                            : Icon(Icons.send, color: theme.colorScheme.primary),
                        onPressed: _isSubmitting ? null : _submitComment,
                      ),
                    ),
                  ],
                ),
              ),

              // Comments list
              Expanded(
                child: _isLoading
                    ? Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary)
                )
                    : _comments.isEmpty
                    ? Center(
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return CommentCard(
                      comment: comment,
                      onLike: () async {
                        await ref.read(toastFeedProvider.notifier).toggleCommentLike(comment.commentId);
                        await _loadComments(); // Refresh comments
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}