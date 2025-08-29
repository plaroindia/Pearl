import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Model/byte.dart';
import '../ViewModel/byte_provider.dart';
import '../ViewModel/auth_provider.dart';

class ByteViewerPage extends ConsumerStatefulWidget {
  const ByteViewerPage({super.key});

  @override
  ConsumerState<ByteViewerPage> createState() => _ByteViewerPageState();
}

class _ByteViewerPageState extends ConsumerState<ByteViewerPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Load bytes when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bytesFeedProvider.notifier).loadBytes();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeAllControllers();
    super.dispose();
  }

  void _disposeAllControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  VideoPlayerController _getController(int index, String videoUrl) {
    if (!_controllers.containsKey(index)) {
      _controllers[index] = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted && index == _currentIndex) {
            setState(() {});
            _controllers[index]!.play();
            _controllers[index]!.setLooping(true);
          }
        });
    }
    return _controllers[index]!;
  }

  void _onPageChanged(int index) {
    // Stop and reset previous video to beginning
    if (_controllers[_currentIndex] != null) {
      _controllers[_currentIndex]!.pause();
      _controllers[_currentIndex]!.seekTo(Duration.zero);
    }

    setState(() {
      _currentIndex = index;
    });

    // Play current video from beginning
    if (_controllers[index] != null && _controllers[index]!.value.isInitialized) {
      _controllers[index]!.seekTo(Duration.zero);
      _controllers[index]!.play();
    }
  }

  void _togglePlayPause(int index) {
    final controller = _controllers[index];
    if (controller != null && controller.value.isInitialized) {
      setState(() {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytesState = ref.watch(bytesFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: bytesState.isLoading && bytesState.bytes.isEmpty
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : bytesState.error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-byte');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Byte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: bytesState.bytes.length,
        itemBuilder: (context, index) {
          final byte = bytesState.bytes[index];
          return ByteVideoPlayer(
            byte: byte,
            controller: _getController(index, byte.byte),
            isCurrentVideo: index == _currentIndex,
            onTogglePlayPause: () => _togglePlayPause(index),
            onLike: () async {
              await ref.read(bytesFeedProvider.notifier).toggleLike(byte.byteId);
            },
            onComment: () => _showCommentsModal(byte),
            onShare: () => _showShareModal(byte),
          );
        },
      ),
    );
  }

  void _showCommentsModal(Byte byte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ByteCommentsBottomSheet(byteId: byte.byteId),
    );
  }

  void _showShareModal(Byte byte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ShareModal(byte: byte),
    );
  }
}

class ByteVideoPlayer extends ConsumerWidget {
  final Byte byte;
  final VideoPlayerController controller;
  final bool isCurrentVideo;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const ByteVideoPlayer({
    super.key,
    required this.byte,
    required this.controller,
    required this.isCurrentVideo,
    required this.onTogglePlayPause,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLiking = ref.watch(bytesFeedProvider).likingBytes.contains(byte.byteId);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        GestureDetector(
          onTap: onTogglePlayPause,
          child: Container(
            color: Colors.black,
            child: controller.value.isInitialized
                ? Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
                : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),

        // Play/Pause Overlay
        if (controller.value.isInitialized && !controller.value.isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),

        // Bottom Gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black54,
                  Colors.black87,
                ],
              ),
            ),
          ),
        ),

        // User Info and Caption
        Positioned(
          bottom: 3,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[600],
                    backgroundImage: byte.profilePic != null
                        ? CachedNetworkImageProvider(byte.profilePic!)
                        : null,
                    child: byte.profilePic == null
                        ? Text(
                      (byte.username?.isNotEmpty ?? false)
                          ? byte.username!.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '@${byte.username ?? "unknown"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Follow Button (if not own video)
                  if (authState.value?.user?.id != byte.userId)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Caption
              if (byte.caption != null && byte.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    byte.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Video Progress Indicator
              if (controller.value.isInitialized)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ),

        // Action Buttons (Right Side)
        Positioned(
          bottom: 20,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like Button
              _ActionButton(
                icon: Icons.favorite,
                count: byte.likeCount,
                onTap: onLike,
                isActive: byte.isLiked ?? false,
                isLoading: isLiking,
              ),
              const SizedBox(height: 24),

              // Comment Button
              _ActionButton(
                icon: Icons.comment,
                count: byte.commentCount,
                onTap: onComment,
                isDisabled: false,
              ),
              const SizedBox(height: 24),

              // Share Button
              _ActionButton(
                icon: Icons.share,
                count: byte.shareCount,
                onTap: onShare,
              ),
              const SizedBox(height: 24),

              // More Options
              _ActionButton(
                icon: Icons.more_vert,
                onTap: () => _showMoreOptions(context, byte),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context, Byte byte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MoreOptionsModal(byte: byte),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDisabled;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    this.count,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(
              icon,
              color: isDisabled
                  ? Colors.grey
                  : isActive
                  ? Colors.red
                  : Colors.white,
              size: 28,
            ),
          ),
          if (count != null && count! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatCount(count!),
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// New Byte Comments Bottom Sheet (inspired by toast_card)
class ByteCommentsBottomSheet extends ConsumerStatefulWidget {
  final String byteId;

  const ByteCommentsBottomSheet({Key? key, required this.byteId}) : super(key: key);

  @override
  ConsumerState<ByteCommentsBottomSheet> createState() => _ByteCommentsBottomSheetState();
}

class _ByteCommentsBottomSheetState extends ConsumerState<ByteCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<ByteComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final comments = await ref.read(bytesFeedProvider.notifier).loadComments(widget.byteId);
    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(bytesFeedProvider.notifier).addComment(
      widget.byteId,
      _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      await _loadComments(); // Reload comments
    }

    setState(() => _isSubmitting = false);
  }

  String _formatTimeAgo(DateTime createdAt) {
    final Duration difference = DateTime.now().difference(createdAt);

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
            color: Colors.grey[900],
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
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_comments.length}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.grey, height: 1),

              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  border: Border(top: BorderSide(color: Colors.grey[700]!)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[600],
                      child: const Text(
                        'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _submitComment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Comments list
              Expanded(
                child: _isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: Colors.white)
                )
                    : _comments.isEmpty
                    ? const Center(
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[600],
                            backgroundImage: comment.profilePic != null
                                ? CachedNetworkImageProvider(comment.profilePic!)
                                : null,
                            child: comment.profilePic == null
                                ? Text(
                              comment.username.isNotEmpty
                                  ? comment.username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimeAgo(comment.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        await ref.read(bytesFeedProvider.notifier)
                                            .toggleCommentLike(comment.commentId);
                                        await _loadComments();
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                                            size: 16,
                                            color: comment.isLiked ? Colors.red : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${comment.likeCount}',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Reply functionality coming soon')),
                                        );
                                      },
                                      child: Text(
                                        'Reply',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    super.dispose();
  }
}

// Share Modal
class ShareModal extends StatelessWidget {
  final Byte byte;

  const ShareModal({super.key, required this.byte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Share',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share options coming soon...',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


// More Options Modal
class MoreOptionsModal extends StatelessWidget {
  final Byte byte;

  const MoreOptionsModal({super.key, required this.byte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'More Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: const Text('Report', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.orange),
            title: const Text('Block User', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}