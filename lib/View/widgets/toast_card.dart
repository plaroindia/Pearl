// widgets/toast_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Model/toast.dart';
import '../../ViewModel//toast_feed_provider.dart';

class ToastCard extends ConsumerWidget {
  final Toast_feed toast;
  final VoidCallback? onTap;

  const ToastCard({
    Key? key,
    required this.toast,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header
              Row(
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimeAgo(toast.created_at),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () {
                      _showMoreOptions(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              if (toast.title != null && toast.title!.isNotEmpty)
                Text(
                  toast.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 8),

              // Content
              if (toast.content != null && toast.content!.isNotEmpty)
                Text(
                  toast.content!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Tags
              if (toast.tags != null && toast.tags!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: toast.tags!.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like Button
                  _ActionButton(
                    icon: toast.isliked ? Icons.favorite : Icons.favorite_border,
                    label: '${toast.like_count}',
                    color: toast.isliked ? Colors.red : Colors.grey,
                    onPressed: () {
                      ref.read(toastFeedProvider.notifier).toggleLike(toast.toast_id!);
                    },
                  ),

                  // Comment Button
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    label: '${toast.comment_count}',
                    color: Colors.grey,
                    onPressed: () {
                      _showComments(context);
                    },
                  ),

                  // Share Button
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: '${toast.share_count}',
                    color: Colors.grey,
                    onPressed: () {
                      _sharePost(context);
                    },
                  ),

                  // Bookmark Button
                  _ActionButton(
                    icon: Icons.bookmark_border,
                    label: '',
                    color: Colors.grey,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Handle report
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: Colors.orange),
              title: const Text('Block User', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Handle block user
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined, color: Colors.blue),
              title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
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

  void _showComments(BuildContext context) {
    // Navigate to comments screen or show comments modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comments functionality coming soon')),
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
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
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