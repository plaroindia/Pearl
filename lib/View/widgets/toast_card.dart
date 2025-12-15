import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Model/toast.dart';
import '../../ViewModel/toast_feed_provider.dart';
import '../../ViewModel/theme_provider.dart';
import 'comment_card.dart';
import 'double_tap_like.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Model/comment.dart';

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
    ref.watch(themeNotifierProvider);

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), // Remove horizontal margin
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0), // Remove border radius for Instagram style
      ),
      elevation: 0, // Remove shadow for flat design
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Header - Keep padding here
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 8.0, 8.0),
            child: GestureDetector(
              onTap: onUserInfo,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: toast.profile_pic != null
                        ? CachedNetworkImageProvider(toast.profile_pic!)
                        : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                    radius: 16,
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
                            fontSize: 14, // Slightly smaller
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
                    icon: Icon(Icons.more_vert, color: theme.dividerColor, size: 20),
                    onPressed: () {
                      _showMoreOptions(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Title - with padding
          if (toast.title != null && toast.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
              child: Text(
                toast.title!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16, // Slightly smaller
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Content - Full width with edge-to-edge design
          if (toast.content != null && toast.content!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: ToastDoubleTapLike(
                toastId: toast.toast_id ?? '',
                isliked: toast.isliked,
                child: Text(
                  toast.content!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Tags - with padding
          if (toast.tags != null && toast.tags!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: toast.tags!.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
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

          // Action Buttons - with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like Button
                _ActionButton(
                  icon: toast.isliked ? Icons.favorite : Icons.favorite_border,
                  label: '${toast.like_count}',
                  color: toast.isliked ? Colors.red : theme.dividerColor,
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
                  color: theme.dividerColor,
                  onPressed: () {
                    _showCommentsSheet(context, toast.toast_id!);
                  },
                ),

                // Share Button
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: '${toast.share_count}',
                  color: theme.dividerColor,
                  onPressed: () {
                    _sharePost(context);
                  },
                ),

                // Bookmark Button - Align to end
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ActionButton(
                      icon: Icons.bookmark_border,
                      label: '',
                      color: theme.dividerColor,
                      onPressed: () {
                        _bookmarkPost(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
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
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmittingReply = false;
  final Map<int, List<Comment>> _repliesByParent = {};
  final Set<int> _loadingReplies = {};
  int? _activeReplyParentId;

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

  Future<void> _loadReplies(int parentCommentId) async {
    setState(() { _loadingReplies.add(parentCommentId); });
    final replies = await ref.read(toastFeedProvider.notifier).loadReplies(widget.toastId, parentCommentId);
    if (!mounted) return;
    setState(() {
      _repliesByParent[parentCommentId] = replies;
      _loadingReplies.remove(parentCommentId);
    });
  }

  void _toggleReplies(int parentCommentId) {
    final hasReplies = _repliesByParent[parentCommentId]?.isNotEmpty == true;
    if (hasReplies) {
      setState(() {
        _repliesByParent.remove(parentCommentId);
      });
    } else {
      _loadReplies(parentCommentId);
    }
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

  Future<void> _submitReply(int parentCommentId, String parentUsername) async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSubmittingReply = true);

    final content = _replyController.text.trim().startsWith('@')
        ? _replyController.text.trim()
        : '@$parentUsername ${_replyController.text.trim()}';

    final ok = await ref.read(toastFeedProvider.notifier).addReply(
      widget.toastId,
      parentCommentId,
      content,
    );

    if (ok) {
      _replyController.clear();
      await _loadReplies(parentCommentId);
    }

    if (mounted) setState(() => _isSubmittingReply = false);
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
                    color: theme.dividerColor.withOpacity(0.5),
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

              // Comment / Reply input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _activeReplyParentId != null ? _replyController : _commentController,
                        focusNode: _activeReplyParentId != null ? _replyFocusNode : null,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: _activeReplyParentId != null ? 'Reply…' : 'Add a comment...',
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
                        icon: (_activeReplyParentId != null ? _isSubmittingReply : _isSubmitting)
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        )
                            : Icon(Icons.send, color: theme.colorScheme.primary),
                        onPressed: (_activeReplyParentId != null)
                            ? (_isSubmittingReply ? null : () {
                          final parent = _comments.firstWhere((c) => c.commentId == _activeReplyParentId);
                          _submitReply(_activeReplyParentId!, parent.username);
                        })
                            : (_isSubmitting ? null : _submitComment),
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
                    final isLoadingReplies = _loadingReplies.contains(comment.commentId);
                    final replies = _repliesByParent[comment.commentId] ?? const <Comment>[];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommentCard(
                            comment: comment,
                            onLike: () async {
                              await ref.read(toastFeedProvider.notifier).toggleCommentLike(comment.commentId);
                              await _loadComments();
                            },
                            onReply: () {
                              setState(() {
                                _activeReplyParentId = comment.commentId;
                                _replyController.text = '@${comment.username} ';
                                _replyController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _replyController.text.length),
                                );
                              });
                              FocusScope.of(context).requestFocus(_replyFocusNode);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 56.0),
                            child: FutureBuilder<int>(
                              future: ref.read(toastFeedProvider.notifier).getRepliesCount(comment.commentId),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                final hasRepliesLoaded = (_repliesByParent[comment.commentId] ?? const <Comment>[]).isNotEmpty;
                                if (count <= 0) return const SizedBox.shrink();
                                return TextButton(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                  onPressed: () => _toggleReplies(comment.commentId),
                                  child: Text(
                                    hasRepliesLoaded ? 'Hide replies' : 'View replies ($count)',
                                    style: TextStyle(color: theme.dividerColor, fontSize: 13),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (isLoadingReplies)
                            const Padding(
                              padding: EdgeInsets.only(left: 56.0, top: 4),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          if (replies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 56.0, top: 4),
                              child: Column(
                                children: replies.map((r) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 12,
                                      backgroundImage: r.profileImage.isNotEmpty
                                          ? NetworkImage(r.profileImage)
                                          : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(r.username, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 6),
                                        Text(r.timeAgo, style: TextStyle(color: theme.dividerColor, fontSize: 11)),
                                      ],
                                    ),
                                    subtitle: Text(r.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    trailing: IconButton(
                                      icon: Icon(r.isliked ? Icons.favorite : Icons.favorite_border, size: 16, color: r.isliked ? Colors.red : theme.dividerColor),
                                      onPressed: () async {
                                        await ref.read(toastFeedProvider.notifier).toggleCommentLike(r.commentId);
                                        await _loadReplies(comment.commentId);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
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
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }
}