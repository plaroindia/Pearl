import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plaro_3/ViewModel/auth_provider.dart';
import '../../Model/toast.dart';
import '../../ViewModel/toast_feed_provider.dart';
import 'dart:ui';
import '../../ViewModel/user_feed_provider.dart';
import '../../ViewModel/user_provider.dart';

class ToastProfileCard extends ConsumerWidget {
  final Toast_feed toast;
  final VoidCallback? onTap;

  const ToastProfileCard({
    Key? key,
    required this.toast,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            if (toast.title != null && toast.title!.isNotEmpty)
              Row(
                children: [
                  Text(
                    toast.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(toast.created_at),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),


            if (toast.title != null && toast.title!.isNotEmpty)
              const SizedBox(height: 6),

            // Content
            if (toast.content != null && toast.content!.isNotEmpty)
              Text(
                toast.content!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),

            // Tags (limited to 2)
            if (toast.tags != null && toast.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: toast.tags!.take(2).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 8),

            // Bottom Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side stats
                Row(
                  children: [
                    _StatIcon(
                      icon: toast.isliked ? Icons.favorite : Icons.favorite_border,
                      count: toast.like_count,
                      color: toast.isliked ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _StatIcon(
                      icon: Icons.comment_outlined,
                      count: toast.comment_count,
                      color: Colors.grey,
                    ),
                  ],
                ),
                IconButton(
                  icon:Icon(Icons.more_vert),
                  onPressed: (){
                    _showMoreOptions(context,toast);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final DateTime postTime = DateTime.parse(createdAt);
      final Duration difference = DateTime.now().difference(postTime);

      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()}w';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }
}

class _StatIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatIcon({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context ) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          _formatCount(count),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}


void _showMoreOptions(BuildContext context, Toast_feed toast) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        // Get current user ID from user provider
        final currentUserId = ref.watch(currentUserIdProvider);

        // Check if toast belongs to current user
        final isOwner = currentUserId != null && currentUserId == toast.user_id;

        return Container(
          padding: const EdgeInsets.all(16),
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
              // Only show Edit option for owner
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                  title: const Text('Edit Toast', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to edit toast screen
                    // Navigator.pushNamed(context, '/edit-toast', arguments: toast);
                  },
                ),
              // Only show Delete option for owner
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Toast', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('Delete Toast', style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to delete this toast?',
                            style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () async {
                              final success = await ref.read(profileFeedProvider.notifier).deleteToast(toast.toast_id!);
                              Navigator.pop(context);
                              Navigator.pop(context);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Toast deleted successfully')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to delete toast')),
                                );
                              }
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              // Show Copy Link for everyone
              ListTile(
                leading: const Icon(Icons.link_outlined, color: Colors.blue),
                title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Copy toast link to clipboard
                  // Clipboard.setData(ClipboardData(text: 'https://yourapp.com/toast/${toast.toast_id}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

