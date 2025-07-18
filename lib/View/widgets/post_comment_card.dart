// widgets/comment_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Model/post.dart';
import '../../ViewModel/post_feed_provider.dart';

class CommentCard extends ConsumerStatefulWidget {
  final Comment comment;
  final VoidCallback? onTap;
  final bool showReplies;

  const CommentCard({
    Key? key,
    required this.comment,
    this.onTap,
    this.showReplies = true,
  }) : super(key: key);

  @override
  ConsumerState<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<CommentCard> {
  bool _showReplyField = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postFeedState = ref.watch(postFeedProvider);
    // For now, we'll use a simple loading state - you can add likingComments to your state later
    final isLiking = false; // TODO: Add likingComments Set<int> to your PostFeedState

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main comment content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  CircleAvatar(
                    backgroundImage: widget.comment.profileImage.isNotEmpty
                        ? NetworkImage(widget.comment.profileImage)
                        : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                    radius: 16,
                  ),
                  const SizedBox(width: 12),

                  // Comment content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username and timestamp
                        Row(
                          children: [
                            Text(
                              widget.comment.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.comment.timeAgo,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Comment text
                        Text(
                          widget.comment.content,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Action buttons
                        Row(
                          children: [
                            // Like button
                            _CommentActionButton(
                              icon: widget.comment.isliked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: widget.comment.likes > 0
                                  ? '${widget.comment.likes}'
                                  : '',
                              color: widget.comment.isliked
                                  ? Colors.red
                                  : Colors.grey,
                              isLoading: isLiking,
                              onPressed: () {
                                // Toggle like locally for now
                                setState(() {
                                  widget.comment.toggleLike();
                                });
                                // TODO: Implement server-side comment like toggle
                                // ref.read(postFeedProvider.notifier).toggleCommentLike(widget.comment.commentId);
                              },
                            ),
                            const SizedBox(width: 16),

                            // Reply button
                            _CommentActionButton(
                              icon: Icons.reply_outlined,
                              label: 'Reply',
                              color: Colors.grey,
                              onPressed: () {
                                setState(() {
                                  _showReplyField = !_showReplyField;
                                });
                              },
                            ),
                            const SizedBox(width: 16),

                            // More options button
                            _CommentActionButton(
                              icon: Icons.more_horiz,
                              label: '',
                              color: Colors.grey,
                              onPressed: () {
                                _showCommentOptions(context);
                              },
                            ),
                          ],
                        ),

                        // Reply field
                        if (_showReplyField)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _replyController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Reply to ${widget.comment.username}...',
                                      hintStyle: TextStyle(color: Colors.grey[600]),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    maxLines: null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    _submitReply();
                                  },
                                  icon: const Icon(Icons.send, color: Colors.blue, size: 20),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Replies section (if enabled)
              if (widget.showReplies)
                _buildRepliesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepliesSection() {
    // This is a placeholder for replies - you can implement nested comments here
    return Container();
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty) return;

    // TODO: Implement reply submission
    final replyText = _replyController.text.trim();

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reply submitted: $replyText'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    _replyController.clear();
    setState(() {
      _showReplyField = false;
    });
  }

  void _showCommentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: Colors.grey),
                title: const Text('Copy Comment', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _copyComment();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.red),
                title: const Text('Report Comment', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _reportComment();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.orange),
                title: const Text('Block User', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _copyComment() {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reportComment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Report Comment', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to report this comment? We will review it and take appropriate action.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment reported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Block User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to block ${widget.comment.username}? You won\'t see their comments anymore.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User blocked successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CommentActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _CommentActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: 16),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
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