import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/toast.dart';
import '../ViewModel/user_feed_provider.dart';
import '../ViewModel/toast_feed_provider.dart';
import '../ViewModel/user_provider.dart';
import 'widgets/content_actions.dart';
import 'widgets/unified_comments_bottom_sheet.dart';
import 'toast_page.dart';

class ToastFullScreen extends ConsumerStatefulWidget {
  final Toast_feed toast;

  const ToastFullScreen({Key? key, required this.toast}) : super(key: key);

  @override
  ConsumerState<ToastFullScreen> createState() => _ToastFullScreenState();
}

class _ToastFullScreenState extends ConsumerState<ToastFullScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(profileFeedProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // Find the current toast from state (for real-time updates)
    final currentToast = feedState.toasts.firstWhere(
          (t) => t.toast_id == widget.toast.toast_id,
      orElse: () => widget.toast,
    );

    final isOwner = currentUserId != null && currentUserId == currentToast.user_id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: currentToast.profile_pic != null
                  ? NetworkImage(currentToast.profile_pic!)
                  : const AssetImage('assets/plaro_logo.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentToast.username!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (currentUserId != null)
            ContentActionMenu(
              data: ContentActionData(
                contentId: currentToast.toast_id ?? '',
                userId: currentToast.user_id ?? '',
                contentType: ContentType.toast,
                isHidden: false, // TODO: Add is_hidden field to Toast model
                shareText: currentToast.content,
                shareUrl: 'https://yourapp.com/toast/${currentToast.toast_id}',
              ),
              callbacks: ContentActionCallbacks(
                onEdit: isOwner ? () => _handleEdit(context, ref) : null,
                onDelete: isOwner ? () => _handleDelete(context, ref) : null,
                onToggleHide: isOwner ? () => _handleToggleHide(context, ref) : null,
                onShare: () => _handleShare(context),
              ),
              currentUserId: currentUserId,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Toast Content Section
                SliverToBoxAdapter(
                  child: _buildToastContent(currentToast),
                ),

                // Divider
                const SliverToBoxAdapter(
                  child: Divider(color: Colors.grey, height: 1),
                ),

                // Interaction Section
                SliverToBoxAdapter(
                  child: _buildInteractionSection(currentToast),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildToastContent(Toast_feed toast) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toast Title
          if (toast.title != null && toast.title!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      toast.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (toast.title != null && toast.title!.isNotEmpty)
            const SizedBox(height: 20),

          // Toast Content
          if (toast.content != null && toast.content!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Text(
                toast.content!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Timestamp
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                _formatTimestamp(_parseDateTime(toast.created_at)),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionSection(Toast_feed toast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              toast.isliked ? Icons.favorite : Icons.favorite_border,
              color: toast.isliked ? Colors.red : Colors.white,
              size: 28,
            ),
            onPressed: () {
              ref.read(profileFeedProvider.notifier).toggleToastLike(toast.toast_id!);
            },
          ),
          const SizedBox(width: 4),
          Text(
            '${toast.like_count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => _showCommentsBottomSheet(context, ref, toast.toast_id!),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.comment_outlined, color: Colors.white, size: 26),
                const SizedBox(width: 4),
                Text(
                  '${toast.comment_count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, WidgetRef ref, String toastId) {
    final toastFeedState = ref.read(toastFeedProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UnifiedCommentsBottomSheet(
        contentId: toastId,
        title: 'Comments',
        commentCount: null, // Will be shown from loaded comments
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
      ),
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ToastPage(),
        // TODO: Pass toast data to edit mode when edit functionality is implemented
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) async {
    final feedState = ref.read(profileFeedProvider);
    final toast = feedState.toasts.firstWhere(
      (t) => t.toast_id == widget.toast.toast_id,
      orElse: () => widget.toast,
    );

    if (toast.toast_id == null) return;

    final success = await ref.read(profileFeedProvider.notifier).deleteToast(toast.toast_id!);
    if (context.mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toast deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete toast'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleToggleHide(BuildContext context, WidgetRef ref) {
    // TODO: Implement hide/unhide functionality
    // This requires adding is_hidden field to toasts table and updating providers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hide functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleShare(BuildContext context) {
    // Share functionality - uses default from ContentActionMenu (copy link)
    // Could be enhanced to use platform share dialog
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}