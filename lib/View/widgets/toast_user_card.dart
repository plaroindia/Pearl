import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Model/toast.dart';
import '../../ViewModel/toast_feed_provider.dart';
import 'dart:ui';

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
  Widget build(BuildContext context) {
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