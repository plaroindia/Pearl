import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Model/byte.dart';
import '../ViewModel/user_feed_provider.dart';
import '../ViewModel/auth_provider.dart';
import '../ViewModel/byte_provider.dart';
import 'widgets/double_tap_like.dart';
import 'widgets/byte_comments.dart';
import 'widgets/content_actions.dart';
import 'byte_page.dart';

class BytesFullScreen extends ConsumerStatefulWidget {
  final List<Byte> bytes;
  final int initialIndex;

  const BytesFullScreen({
    Key? key,
    required this.bytes,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<BytesFullScreen> createState() => _BytesFullScreenState();
}

class _BytesFullScreenState extends ConsumerState<BytesFullScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
      debugPrint('🎥 Creating controller for index $index: $videoUrl');

      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      _controllers[index] = controller;

      controller.initialize().then((_) {
        if (!mounted) return;

        debugPrint('✅ Video initialized for index $index');
        setState(() {});

        if (index == _currentIndex) {
          controller.play();
          controller.setLooping(true);
        }
      }).catchError((error) {
        debugPrint('❌ Error initializing video: $error');
      });
    }
    return _controllers[index]!;
  }

  void _onPageChanged(int index) {
    debugPrint('🔄 Page changed from $_currentIndex to $index');

    // Pause and reset previous video
    if (_controllers.containsKey(_currentIndex)) {
      final prevController = _controllers[_currentIndex]!;
      if (prevController.value.isInitialized) {
        prevController.pause();
        prevController.seekTo(Duration.zero);
        debugPrint('⏸️ Paused video at index $_currentIndex');
      }
    }

    setState(() {
      _currentIndex = index;
    });

    // Play new video if initialized
    if (_controllers.containsKey(index)) {
      final newController = _controllers[index]!;
      if (newController.value.isInitialized) {
        newController.seekTo(Duration.zero);
        newController.play();
        newController.setLooping(true);
        debugPrint('▶️ Playing video at index $index');
      } else {
        debugPrint('⏳ Video at index $index not yet initialized');
      }
    } else {
      debugPrint('❓ No controller found for index $index');
    }
  }

  void _togglePlayPause(int index) {
    final controller = _controllers[index];
    if (controller != null && controller.value.isInitialized) {
      setState(() {
        if (controller.value.isPlaying) {
          controller.pause();
          debugPrint('⏸️ Manually paused video at index $index');
        } else {
          controller.play();
          debugPrint('▶️ Manually playing video at index $index');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.bytes.isEmpty
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
          ],
        ),
      )
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: widget.bytes.length,
            itemBuilder: (context, index) {
              final byte = widget.bytes[index];
              debugPrint('🏗️ Building page for index $index: ${byte.byteId}');

              return ByteVideoPlayer(
                byte: byte,
                controller: _getController(index, byte.videoUrl),
                isCurrentVideo: index == _currentIndex,
                onTogglePlayPause: () => _togglePlayPause(index),
                onLike: () async {
                  await ref.read(profileFeedProvider.notifier).toggleByteLike(byte.byteId);
                },
                onSwipeLeft: () => _showCommentsModal(byte),
                onShare: () => _showShareModal(byte),
                showSwipeIndicator: true,
              );
            },
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
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
  final VoidCallback onSwipeLeft;
  final VoidCallback onShare;
  final bool showSwipeIndicator;

  const ByteVideoPlayer({
    Key? key,
    required this.byte,
    required this.controller,
    required this.isCurrentVideo,
    required this.onTogglePlayPause,
    required this.onLike,
    required this.onSwipeLeft,
    required this.onShare,
    this.showSwipeIndicator = true,
  }) : super(key: key);

  @override
  ConsumerState<ByteVideoPlayer> createState() => _ByteVideoPlayerState();
}

class _ByteVideoPlayerState extends ConsumerState<ByteVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final feedState = ref.watch(profileFeedProvider);

    // Get the updated byte from the feed state
    final currentByte = feedState.bytes.firstWhere(
          (b) => b.byteId == widget.byte.byteId,
      orElse: () => widget.byte,
    );

    debugPrint('🎬 Building ByteVideoPlayer for ${currentByte.byteId} - '
        'Initialized: ${widget.controller.value.isInitialized}, '
        'Playing: ${widget.controller.value.isPlaying}');

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe left to show comments
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          widget.onSwipeLeft();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player with double tap like functionality
          ByteDoubleTapLike(
            byteId: currentByte.byteId,
            isliked: currentByte.isliked ?? false,
            onSingleTap: widget.onTogglePlayPause,
            onDoubleTapLike: widget.onLike,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Play/pause overlay
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
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
                      backgroundImage: currentByte.profilePic != null
                          ? CachedNetworkImageProvider(currentByte.profilePic!)
                          : null,
                      child: currentByte.profilePic == null
                          ? Text(
                        (currentByte.username?.isNotEmpty ?? false)
                            ? currentByte.username!.substring(0, 1).toUpperCase()
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
                        '@${currentByte.username ?? "unknown"}',
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
                    if (authState.value?.user != null && authState.value!.user.id != currentByte.userId)
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

                    // Like icon with count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentByte.isliked == true ? Icons.favorite : Icons.favorite_border,
                          color: currentByte.isliked == true ? Colors.red : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(currentByte.likeCount),
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
                    if (authState.value?.user != null)
                      ContentActionMenu(
                        data: ContentActionData(
                          contentId: currentByte.byteId,
                          userId: currentByte.userId,
                          contentType: ContentType.byte,
                          isHidden: false, // TODO: Add is_hidden field to Byte model
                          shareText: currentByte.caption,
                          shareUrl: 'https://yourapp.com/byte/${currentByte.byteId}',
                        ),
                        callbacks: ContentActionCallbacks(
                          onEdit: authState.value!.user.id == currentByte.userId
                              ? () => _handleEdit(context, ref, currentByte)
                              : null,
                          onDelete: authState.value!.user.id == currentByte.userId
                              ? () => _handleDelete(context, ref, currentByte)
                              : null,
                          onToggleHide: authState.value!.user.id == currentByte.userId
                              ? () => _handleToggleHide(context, ref, currentByte)
                              : null,
                          onShare: () => _handleShare(context, currentByte),
                        ),
                        currentUserId: authState.value!.user.id,
                      ),
                  ],
                ),

                // Caption
                if (currentByte.caption != null && currentByte.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      currentByte.caption!,
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

          // Swipe left indicator (only show if enabled)
          if (widget.showSwipeIndicator)
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).size.height / 2 - 40,
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
                      Icons.keyboard_arrow_left,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Swipe left for comments (${currentByte.commentCount})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref, Byte byte) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ByteCreateScreen(),
        // TODO: Pass byte data to edit mode when edit functionality is implemented
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref, Byte byte) async {
    final success = await ref.read(byteCreateProvider.notifier).deleteByte(byte.byteId);
    if (context.mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Byte deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh feed
        ref.read(bytesFeedProvider.notifier).refreshBytes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete byte'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleToggleHide(BuildContext context, WidgetRef ref, Byte byte) {
    // TODO: Implement hide/unhide functionality
    // This requires adding is_hidden field to bytes table and updating providers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hide functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleShare(BuildContext context, Byte byte) {
    // Share functionality - uses default from ContentActionMenu (copy link)
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

  const ShareModal({Key? key, required this.byte}) : super(key: key);

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

  const MoreOptionsModal({Key? key, required this.byte}) : super(key: key);

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