import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/byte.dart';
import '../ViewModel/byte_provider.dart';
import 'widgets/byte_comments.dart';
import 'byte_page.dart';
import '../widgets/shared/byte_video_player_widget.dart';
import '../widgets/shared/byte_video_player_manager.dart';

class ByteViewerPage extends ConsumerStatefulWidget {
  const ByteViewerPage({super.key});

  @override
  ConsumerState<ByteViewerPage> createState() => _ByteViewerPageState();
}

class _ByteViewerPageState extends ConsumerState<ByteViewerPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late final ByteVideoPlayerManager _videoManager;

  @override
  void initState() {
    super.initState();
    _videoManager = ByteVideoPlayerManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bytesFeedProvider.notifier).loadBytes();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoManager.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _videoManager.onPageChanged(index);
    setState(() {
      _currentIndex = index;
    });

    // Load more bytes when approaching the end
    final bytesState = ref.read(bytesFeedProvider);
    if (index >= bytesState.bytes.length - 3 && bytesState.hasMore && !bytesState.isLoadingMore) {
      ref.read(bytesFeedProvider.notifier).loadMoreBytes();
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
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: bytesState.bytes.length,
            itemBuilder: (context, index) {
              final byte = bytesState.bytes[index];
              final controller = _videoManager.getController(index, byte.videoUrl);
              
              if (controller == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return ByteVideoPlayerWidget(
                byte: byte,
                controller: controller,
                isCurrentVideo: index == _currentIndex,
                onTogglePlayPause: () => _videoManager.togglePlayPause(index),
                onLike: () async {
                  await ref.read(bytesFeedProvider.notifier).toggleLike(byte.byteId);
                },
                onSwipeLeft: () => _showCommentsModal(byte),
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