import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Model/toast.dart';
import '../../ViewModel/toast_feed_provider.dart';
import '../../ViewModel/theme_provider.dart';
import 'double_tap_like.dart';
import 'unified_comments_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                    debugPrint('🔵 Like button pressed for toast: ${toast.toast_id}');
                    if (toast.toast_id != null) {
                      ref.read(toastFeedProvider.notifier).toggleLike(toast.toast_id!);
                    } else {
                      debugPrint('🔴 Toast ID is null!');
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

// CommentsBottomSheet - Now uses unified bottom sheet
class CommentsBottomSheet extends ConsumerWidget {
  final String toastId;

  const CommentsBottomSheet({Key? key, required this.toastId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastFeedState = ref.read(toastFeedProvider);
    
    return UnifiedCommentsBottomSheet(
      contentId: toastId,
      title: 'Comments',
      commentCount: null,
      likingComments: toastFeedState.likingComments,
      callbacks: CommentSheetCallbacks(
        loadComments: () => ref.read(toastFeedProvider.notifier).loadComments(toastId),
        loadReplies: (parentCommentId) => ref.read(toastFeedProvider.notifier).loadReplies(toastId, int.parse(parentCommentId)),
        getRepliesCount: (parentCommentId) => ref.read(toastFeedProvider.notifier).getRepliesCount(int.parse(parentCommentId)),
        addComment: (content) => ref.read(toastFeedProvider.notifier).addComment(toastId, content),
        addReply: (parentCommentId, content) => ref.read(toastFeedProvider.notifier).addReply(toastId, int.parse(parentCommentId), content),
        toggleCommentLike: (commentId) => ref.read(toastFeedProvider.notifier).toggleCommentLike(int.parse(commentId)),
        getCurrentUserId: () => Supabase.instance.client.auth.currentUser?.id,
        getUserProfile: () async {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) return null;
          try {
            final response = await Supabase.instance.client
                .from('user_profiles')
                .select('profile_pic')
                .eq('user_id', user.id)
                .maybeSingle();
            return response;
          } catch (e) {
            debugPrint('Error fetching user profile: $e');
            return null;
          }
        },
      ),
    );
  }
}