import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../Model/post.dart';
import '../../ViewModel/post_feed_provider.dart';
import 'dart:io';
import '../../ViewModel/user_feed_provider.dart';
import '../../ViewModel/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostProfileCard extends ConsumerWidget {
  final Post_feed post;
  final VoidCallback? onTap;

  const PostProfileCard({
    Key? key,
    required this.post,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Section (if exists)
            if (_hasMedia())
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildMediaPreview(),
                ),
              ),

            // Content Section
            Expanded(
              flex: _hasMedia() ? 2 : 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    if (post.title != null && post.title!.isNotEmpty)
                      Text(
                        post.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    if (post.title != null && post.title!.isNotEmpty)
                      const SizedBox(height: 6),

                    // Content
                    if (post.content != null && post.content!.isNotEmpty)
                      Expanded(
                        child: Text(
                          post.content!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: _hasMedia() ? 3 : 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const Spacer(),

                    // Bottom Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time
                        Text(
                          _formatTimeAgo(post.created_at),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),

                        // Stats
                        Row(
                          children: [
                            _StatIcon(
                              icon: post.isliked ? Icons.favorite : Icons.favorite_border,
                              count: post.like_count,
                              color: post.isliked ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            _StatIcon(
                              icon: Icons.comment_outlined,
                              count: post.comment_count,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        IconButton(
                          icon:Icon(Icons.more_vert),
                          onPressed: (){
                            _showMoreOptions(context,post);
                            },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMedia() {
    return (post.media_urls != null && post.media_urls!.isNotEmpty) ||
        (post.localMediaFiles != null && post.localMediaFiles!.isNotEmpty);
  }

  Widget _buildMediaPreview() {
    if (post.localMediaFiles != null && post.localMediaFiles!.isNotEmpty) {
      final file = post.localMediaFiles!.first;
      return _isVideoFile(file.path)
          ? _buildVideoThumbnail(File(file.path))
          : Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (post.media_urls != null && post.media_urls!.isNotEmpty) {
      final mediaUrl = post.media_urls!.first;
      return Stack(
        children: [
          _isVideoUrl(mediaUrl)
              ? _buildNetworkVideoThumbnail(mediaUrl)
              : Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              );
            },
          ),

          // Media count indicator for multiple media
          if (post.media_urls!.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${post.media_urls!.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildVideoThumbnail(File videoFile) {
    return Container(
      color: Colors.grey[800],
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkVideoThumbnail(String videoUrl) {
    return Container(
      color: Colors.grey[800],
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }

  bool _isVideoFile(String path) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

void _showMoreOptions(BuildContext context, Post_feed post) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  builder: (context) => Consumer(
  builder: (context, ref, child) {
      final currentUserId = ref.watch(currentUserIdProvider);

      // Check if toast belongs to current user
      final isOwner = currentUserId != null && currentUserId == post.user_id;

      return Consumer(
        builder: (context, ref, child) {
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
                if (isOwner)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                  title: const Text('Edit Post', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to edit post screen
                    // Navigator.pushNamed(context, '/edit-post', arguments: post);
                  },
                ),
                if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                  showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to delete this post?',
                            style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () async{
                                final success = await ref.read(profileFeedProvider.notifier).deletePost(post.post_id!);

                                Navigator.pop(context);
                                Navigator.pop(context);

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Post deleted successfully')),
                                  );

                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to delete post')),
                                  );
                                  // Navigator.pop(context);
                                  // Navigator.pop(context);
                                }
                            },// => Navigator.pop(context, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  //Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined, color: Colors.orange),
                  title: const Text('Hide Post', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement hide post functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post hidden')),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  ),
  );
}