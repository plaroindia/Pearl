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
  const LightboxOverlay({super.key});

  @override
  ConsumerState<LightboxOverlay> createState() => _LightboxOverlayState();
}

class _LightboxOverlayState extends ConsumerState<LightboxOverlay> {
  PageController? _controller;

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
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
          onPressed: () => ref.read(lightboxProvider.notifier).close(),
        ),
        title: Text(
          '${( (_controller?.page ?? state.initialIndex).round() + 1)}/${state.items.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: _controller != null ? PageView.builder(
        controller: _controller,
        itemCount: state.items.length,
        onPageChanged: (index) {
          // Update the page counter in the app bar
          setState(() {});
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
              return ByteVideoPlayer(
                byte: byte,
                controller: VideoPlayerController.networkUrl(Uri.parse(byte.byte)),
                isCurrentVideo: true,
                onTogglePlayPause: () {},
                onLike: () {},
                onComment: () {},
                onShare: () {},
              );
          }
        },
      ) : const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }
}