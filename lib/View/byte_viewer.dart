import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Model/byte.dart';
import '../ViewModel/byte_provider.dart';
import '../ViewModel/auth_provider.dart';
import 'widgets/double_tap_like.dart';
import 'widgets/byte_comments.dart';
import 'byte_page.dart';

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
        }).catchError((error) {
          debugPrint('Error initializing video: $error');
        });
    }
    return _controllers[index]!;
  }

  void _onPageChanged(int index) {
    if (_controllers[_currentIndex] != null) {
      _controllers[_currentIndex]!.pause();
      _controllers[_currentIndex]!.seekTo(Duration.zero);
    }

    setState(() {
      _currentIndex = index;
    });

    if (_controllers[index] != null && _controllers[index]!.value.isInitialized) {
      _controllers[index]!.seekTo(Duration.zero);
      _controllers[index]!.play();
    }

    // Load more bytes when approaching the end
    final bytesState = ref.read(bytesFeedProvider);
    if (index >= bytesState.bytes.length - 3 && bytesState.hasMore && !bytesState.isLoadingMore) {
      ref.read(bytesFeedProvider.notifier).loadMoreBytes();
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
          : bytesState.bytes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: Colors.grey[600],
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No bytes yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a byte!',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ByteCreateScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Byte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (bytesState.error != null) ...[
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bytesState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  ref.read(bytesFeedProvider.notifier).refreshBytes();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      )
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            onPageChanged: _onPageChanged,
            itemCount: bytesState.bytes.length,
            itemBuilder: (context, index) {
              final byte = bytesState.bytes[index];
              return ByteVideoPlayer(
                byte: byte,
                controller: _getController(index, byte.videoUrl),
                isCurrentVideo: index == _currentIndex,
                onTogglePlayPause: () => _togglePlayPause(index),
                onLike: () async {
                  await ref.read(bytesFeedProvider.notifier).toggleLike(byte.byteId);
                },
                onSwipeUp: () => _showCommentsModal(byte),
                onShare: () => _showShareModal(byte),
              );
            },
          ),
          // Loading more indicator
          if (bytesState.isLoadingMore)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading more...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

class ByteVideoPlayer extends ConsumerStatefulWidget {
  final Byte byte;
  final VideoPlayerController controller;
  final bool isCurrentVideo;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onLike;
  final VoidCallback onSwipeUp;
  final VoidCallback onShare;
  final bool showSwipeIndicator; // Optional parameter for showing swipe up indicator

  const ByteVideoPlayer({
    super.key,
    required this.byte,
    required this.controller,
    required this.isCurrentVideo,
    required this.onTogglePlayPause,
    required this.onLike,
    required this.onSwipeUp,
    required this.onShare,
    this.showSwipeIndicator = true, // Default to true
  });

  @override
  ConsumerState<ByteVideoPlayer> createState() => _ByteVideoPlayerState();
}

class _ByteVideoPlayerState extends ConsumerState<ByteVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final bytesState = ref.watch(bytesFeedProvider);
    final isLiking = bytesState.likingBytes.contains(widget.byte.byteId);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe up to show comments
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          widget.onSwipeUp();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ByteDoubleTapLike(
            byteId: widget.byte.byteId,
            isliked: widget.byte.isliked ?? false,
            onSingleTap: widget.onTogglePlayPause,
            onDoubleTapLike: () {
              ref.read(bytesFeedProvider.notifier).toggleLike(widget.byte.byteId);
            },
            child: Container(
              color: Colors.black,
              child: widget.controller.value.isInitialized
                  ? Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              )
                  : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

          if (widget.controller.value.isInitialized && !widget.controller.value.isPlaying)
            IgnorePointer(
              child: Center(
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
            ),

          // Bottom gradient
          IgnorePointer(
            child: Positioned(
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
          ),

          // Bottom content area
          Positioned(
            bottom: 3,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile row with follow, like, share, more buttons
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[600],
                      backgroundImage: widget.byte.profilePic != null
                          ? CachedNetworkImageProvider(widget.byte.profilePic!)
                          : null,
                      child: widget.byte.profilePic == null
                          ? Text(
                        (widget.byte.username?.isNotEmpty ?? false)
                            ? widget.byte.username!.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '@${widget.byte.username ?? "unknown"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Follow button (if not own profile)
                    if (authState.value?.user != null && authState.value!.user.id != widget.byte.userId)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Follow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(width: 10),

                    // Like icon with count (non-functional, just display)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.byte.isliked == true ? Icons.favorite : Icons.favorite_border,
                          color: widget.byte.isliked == true ? Colors.red : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(widget.byte.likeCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // Share button
                    GestureDetector(
                      onTap: widget.onShare,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // More options button
                    GestureDetector(
                      onTap: () => _showMoreOptions(context, widget.byte),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                // Caption
                if (widget.byte.caption != null && widget.byte.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.byte.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Video progress indicator
                if (widget.controller.value.isInitialized)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: VideoProgressIndicator(
                      widget.controller,
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

          // Swipe up indicator (only show if enabled)
          if (widget.showSwipeIndicator)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe up for comments (${widget.byte.commentCount})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Share',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.white),
            title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard!'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.message, color: Colors.white),
            title: const Text('Share via Message', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.more_horiz, color: Colors.white),
            title: const Text('More Options', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
            leading: const Icon(Icons.bookmark_outline, color: Colors.white),
            title: const Text('Save', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined, color: Colors.red),
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