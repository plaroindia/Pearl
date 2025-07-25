// widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../Model/post.dart';
import '../../ViewModel/post_feed_provider.dart';
import 'post_comment_card.dart';
import 'dart:io';


class _LocalVideoPlayer extends StatefulWidget {
  final File file;

  const _LocalVideoPlayer({required this.file});

  @override
  __LocalVideoPlayerState createState() => __LocalVideoPlayerState();
}

class __LocalVideoPlayerState extends State<_LocalVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}

bool _isVideoFile(String path) {
  final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
  return videoExtensions.any((ext) => path.toLowerCase().endsWith(ext));
}

class PostCard extends ConsumerStatefulWidget {
  final Post_feed post;
  final VoidCallback? onTap;
  final bool isPreview;


  const PostCard({
    Key? key,
    required this.post,
    this.onTap,
    this.isPreview = false,
  }) : super(key: key);

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    // For preview posts, use the widget.post directly and don't access postFeedState
    if (widget.isPreview) {
      return Card(
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0,8.0,8.0,0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.post.profile_pic != null
                          ? NetworkImage(widget.post.profile_pic!)
                          : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.username ?? 'Unknown User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatTimeAgo(widget.post.created_at),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Disable more options for preview
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: null, // Disabled for preview
                    ),
                  ],
                ),
              ),

              // Title
              if (widget.post.title != null && widget.post.title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0,0.0,8.0,2.0),
                  child: Text(
                    widget.post.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Media Section
              if ((widget.post.media_urls != null && widget.post.media_urls!.isNotEmpty) ||
                  (widget.post.localMediaFiles != null && widget.post.localMediaFiles!.isNotEmpty))
                _buildMediaSection(widget.post.media_urls ?? [], widget.post.localMediaFiles),

              // Content
              if (widget.post.content != null && widget.post.content!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.post.content!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Tags
              if (widget.post.tags != null && widget.post.tags!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.post.tags!.map((tag) {
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
                ),

              // Action Buttons - All disabled for preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like Button - disabled
                  _ActionButton(
                    icon: Icons.favorite_border,
                    label: '0',
                    color: Colors.grey,
                    onPressed: null, // Disabled for preview
                  ),

                  // Comment Button - disabled
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    label: '0',
                    color: Colors.grey,
                    onPressed: null, // Disabled for preview
                  ),

                  // Share Button - disabled
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: '0',
                    color: Colors.grey,
                    onPressed: null, // Disabled for preview
                  ),

                  // Bookmark Button - disabled
                  _ActionButton(
                    icon: Icons.bookmark_border,
                    label: '',
                    color: Colors.grey,
                    onPressed: null, // Disabled for preview
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Original code for non-preview posts
    final postFeedState = ref.watch(postFeedProvider);
    final currentPost = postFeedState.posts.firstWhere(
            (p) => p.post_id == widget.post.post_id,
        orElse: () => widget.post
    );

    final isLiking = postFeedState.likingPosts.contains(widget.post.post_id);

    // Show error if there's one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (postFeedState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(postFeedState.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(postFeedProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... rest of your existing non-preview code
            // User Info Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0,8.0,8.0,0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: currentPost.profile_pic != null
                        ? NetworkImage(currentPost.profile_pic!)
                        : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPost.username ?? 'Unknown User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimeAgo(currentPost.created_at),
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
                      _showMoreOptions(context, currentPost);
                    },
                  ),
                ],
              ),
            ),

            // Title
            if (currentPost.title != null && currentPost.title!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0,0.0,8.0,2.0),
                child: Text(
                  currentPost.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Media Section
            if ((currentPost.media_urls != null && currentPost.media_urls!.isNotEmpty) ||
                (currentPost.localMediaFiles != null && currentPost.localMediaFiles!.isNotEmpty))
              _buildMediaSection(currentPost.media_urls ?? [], currentPost.localMediaFiles),

            // Content
            if (currentPost.content != null && currentPost.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  currentPost.content!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Tags
            if (currentPost.tags != null && currentPost.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: currentPost.tags!.map((tag) {
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
              ),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like Button
                _ActionButton(
                  icon: currentPost.isliked ? Icons.favorite : Icons.favorite_border,
                  label: '${currentPost.like_count}',
                  color: currentPost.isliked ? Colors.red : Colors.grey,
                  isLoading: isLiking,
                  onPressed: isLiking ? null : () {
                    if (currentPost.post_id != null) {
                      ref.read(postFeedProvider.notifier).toggleLike(currentPost.post_id!);
                    }
                  },
                ),

                // Comment Button
                _ActionButton(
                  icon: Icons.comment_outlined,
                  label: '${currentPost.comment_count}',
                  color: Colors.grey,
                  onPressed: () {
                    _showCommentsSheet(context, currentPost.post_id!);
                  },
                ),

                // Share Button
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: '${currentPost.share_count ?? 0}',
                  color: Colors.grey,
                  onPressed: () {
                    _sharePost(context, currentPost);
                  },
                ),

                // Bookmark Button
                _ActionButton(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: '',
                  color: _isBookmarked ? Colors.blue : Colors.grey,
                  onPressed: () {
                    _toggleBookmark();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Media Section Builder
  Widget _buildMediaSection(List<String> mediaUrls, List<XFile>? localFiles) {
    if (localFiles != null && localFiles.isNotEmpty) {
      return _buildLocalMediaSection(localFiles);
    } else if (mediaUrls.isNotEmpty) {
      return mediaUrls.length == 1
          ? _buildSingleMedia(mediaUrls[0])
          : _buildMultipleMedia(mediaUrls);
    }
    return const SizedBox.shrink();
  }

  Widget _buildLocalMediaSection(List<XFile> files) {
    return AspectRatio(
      aspectRatio: 5/6,
      child: PageView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return _isVideoFile(file.path)
              ? _LocalVideoPlayer(file: File(file.path))
              : Image.file(File(file.path), fit: BoxFit.cover);
        },
      ),
    );
  }

  Widget _buildSingleMedia(String mediaUrl) {
    return AspectRatio(
      aspectRatio: 5/6 ,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: _isVideoUrl(mediaUrl)
            ? VideoPlayerWidget(videoUrl: mediaUrl)
            : Image.network(
          mediaUrl,
          fit: BoxFit.cover, // Important: center crop like Instagram
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.black87,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.blue,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black87,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 50,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMultipleMedia(List<String> mediaUrls) {
    final PageController pageController = PageController();
    int currentPage = 0; // Add this as a state variable in your widget class

    return AspectRatio(
      aspectRatio: 5/6,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: mediaUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final mediaUrl = mediaUrls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: _isVideoUrl(mediaUrl)
                        ? VideoPlayerWidget(videoUrl: mediaUrl)
                        : Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black87,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              // Media counter indicator - NOW UPDATES!
              Positioned(
                top: 8,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentPage + 1}/${mediaUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showMoreOptions(BuildContext context, Post_feed post) {
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
                leading: const Icon(Icons.report_outlined, color: Colors.red),
                title: const Text('Report Post', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _reportPost(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.orange),
                title: const Text('Block User', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: Colors.grey),
                title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _copyPostLink(context, post);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCommentsSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CommentSheet(postId: postId);
      },

      // shape: const RoundedRectangleBorder(
      //   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      // ),
      // builder: (context) {
      //   return DraggableScrollableSheet(
      //     initialChildSize: 0.7,
      //     minChildSize: 0.3,
      //     maxChildSize: 0.9,
      //     builder: (context, scrollController) {
      //       return CommentSheet(
      //         postId: postId,
      //         scrollController: scrollController,
      //       );
      //     },
      //   );
      // },

    );
  }

  void _sharePost(BuildContext context, Post_feed post) {
    final shareText = '''
${post.title ?? ''}
${post.content ?? ''}
${post.caption ?? ''}

Shared from MyApp
''';

    Share.share(shareText.trim());
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Post bookmarked' : 'Post removed from bookmarks'),
        backgroundColor: _isBookmarked ? Colors.blue : Colors.grey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _reportPost(BuildContext context, Post_feed post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Report Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to report this post? We will review it and take appropriate action.',
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
                  content: Text('Post reported successfully'),
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

  void _blockUser(BuildContext context, Post_feed post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Block User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to block ${post.username ?? 'this user'}? You won\'t see their posts anymore.',
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

  void _copyPostLink(BuildContext context, Post_feed post) {
    // In a real app, you'd generate an actual link
    final link = 'https://myapp.com/post/${post.post_id}';

    // Copy to clipboard (you'd need to import 'package:flutter/services.dart')
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: Colors.green,
      ),
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
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: 20),
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

// Video Player Widget
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
    }).catchError((error) {
      print('Error initializing video: $error');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

// Comment Sheet Widget
class CommentSheet extends ConsumerStatefulWidget {
  final String postId;
  //final ScrollController scrollController;

  const CommentSheet({
    Key? key,
    required this.postId,
    //required this.scrollController,
  }) : super(key: key);

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    final comments = await ref.read(postFeedProvider.notifier).loadComments(widget.postId);

    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await ref.read(postFeedProvider.notifier).addComment(
      widget.postId,
      _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      _loadComments(); // Reload comments
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
        return Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Comment Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(top: BorderSide(color: Colors.grey[700]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.black87,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                          : const Icon(Icons.send, color: Colors.blue),
                      onPressed: _isSubmitting ? null : _submitComment,
                    ),
                  ),
                ],
              ),
            ),

            // Comments List
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
                  : _comments.isEmpty
                  ? const Center(
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                controller: scrollController,
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return CommentCard(
                      comment: comment,
                    onTap: () async {
                      await ref.read(postFeedProvider.notifier).toggleCommentLike(comment.commentId);
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
}