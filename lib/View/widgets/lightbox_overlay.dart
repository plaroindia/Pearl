import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ViewModel/lightbox_provider.dart';
import '../../Model/post.dart';
import '../../Model/toast.dart';
import '../../Model/byte.dart';
import 'Post_card.dart';
import 'toast_card.dart';
import '../../View/byte_viewer.dart';
import 'package:video_player/video_player.dart';

class LightboxOverlay extends ConsumerStatefulWidget {
  const LightboxOverlay({super.key}
      );

@override
ConsumerState<LightboxOverlay> createState() => _LightboxOverlayState();
}

class _LightboxOverlayState extends ConsumerState<LightboxOverlay> {
  PageController? _controller;
  VideoPlayerController? _videoController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.read(lightboxProvider);
    if (state.isOpen) {
      // Dispose old controller if it exists
      _controller?.dispose();
      // Create new controller with the correct initial page
      _controller = PageController(initialPage: state.initialIndex);
    } else {
      // Dispose controller when lightbox is closed
      _controller?.dispose();
      _controller = null;
      _videoController?.dispose();
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoController(String videoUrl) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lightboxProvider);
    if (!state.isOpen) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _videoController?.dispose();
            _videoController = null;
            ref.read(lightboxProvider.notifier).close();
          },
        ),
        title: Text(
          '${((_controller?.page ?? state.initialIndex).round() + 1)}/${state.items.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: _controller != null
          ? PageView.builder(
        controller: _controller,
        itemCount: state.items.length,
        onPageChanged: (index) {
          // Update the page counter in the app bar
          setState(() {});

          // If navigating to a byte, initialize its video controller
          final item = state.items[index];
          if (item.type == LightboxType.byte) {
            final byte = item.data as Byte;
            _initializeVideoController(byte.videoUrl);
          } else {
            // Dispose video controller for non-byte items
            _videoController?.dispose();
            _videoController = null;
          }
        },
        itemBuilder: (context, index) {
          final item = state.items[index];
          switch (item.type) {
            case LightboxType.post:
              final post = item.data as Post_feed;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: PostCard(post: post, onTap: () {}, onUserInfo: () {}),
                ),
              );
            case LightboxType.toast:
              final toast = item.data as Toast_feed;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ToastCard(toast: toast, onTap: () {}, onUserInfo: () {}),
                ),
              );
            case LightboxType.byte:
              final byte = item.data as Byte;

              // Initialize video controller for the initial byte
              if (_videoController == null && index == state.initialIndex) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _initializeVideoController(byte.videoUrl);
                });
              }

              return ByteVideoPlayer(
                byte: byte,
                controller: _videoController ?? VideoPlayerController.networkUrl(Uri.parse(byte.videoUrl)),
                isCurrentVideo: true,
                onTogglePlayPause: () {
                  if (_videoController != null && _videoController!.value.isInitialized) {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  }
                },
                onLike: () {
                  // Like action is handled by double tap in ByteVideoPlayer
                  // No action needed here as it's already handled by the ByteDoubleTapLike widget
                },
                onSwipeUp: () {
                  // Show comments modal
                  _showCommentsModal(context, byte);
                },
                onShare: () {
                  // Show share modal
                  _showShareModal(context, byte);
                },
                showSwipeIndicator: false, // Hide swipe indicator in lightbox
              );
          }
        },
      )
          : const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  void _showCommentsModal(BuildContext context, Byte byte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // You'll need to import your ByteCommentsBottomSheet widget
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
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
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Comments feature coming soon',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showShareModal(BuildContext context, Byte byte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          Container(
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
                  title: const Text(
                      'Copy Link', style: TextStyle(color: Colors.white)),
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
                  title: const Text('Share via Message',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.more_horiz, color: Colors.white),
                  title: const Text(
                      'More Options', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}