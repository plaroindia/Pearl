import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../ViewModel/byte_provider.dart';
import '../ViewModel/auth_provider.dart';
import '../ViewModel/setProfileProvider.dart';

class ByteCreateScreen extends ConsumerStatefulWidget {
  const ByteCreateScreen({super.key});

  @override
  ConsumerState<ByteCreateScreen> createState() => _ByteCreateScreenState();
}

class _ByteCreateScreenState extends ConsumerState<ByteCreateScreen> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocusNode = FocusNode();
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() {
      ref.read(byteCreateProvider.notifier).updateCaption(_captionController.text);
    });

    // Load user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(authStateProvider).value;
      if (session != null) {
        ref.read(setProfileProvider.notifier).getUserProfile(session.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer(String videoPath) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.play();
      });
  }

  void _showVideoPicker() {
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text('Record Video', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Max 1 minute', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(byteCreateProvider.notifier).pickVideo(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.blue),
                title: const Text('Video Library', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Max 1 minute', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(byteCreateProvider.notifier).pickVideo();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCreateByte() async {
    final success = await ref.read(byteCreateProvider.notifier).createByte();
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Byte created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final byteCreateState = ref.watch(byteCreateProvider);
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);

    // Initialize video player when video is selected
    if (byteCreateState.selectedVideo != null && _videoController == null) {
      _initializeVideoPlayer(byteCreateState.selectedVideo!.path);
    }

    // Show error messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (byteCreateState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(byteCreateState.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(byteCreateProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    final canPost = byteCreateState.selectedVideo != null && !byteCreateState.isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Byte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: canPost ? _handleCreateByte : null,
            child: byteCreateState.isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
            )
                : Text(
              'Post',
              style: TextStyle(
                color: canPost ? Colors.blue : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Selection/Preview
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: byteCreateState.selectedVideo == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a video to get started',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showVideoPicker,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              )
                  : Stack(
                alignment: Alignment.center,
                children: [
                  if (_videoController != null && _videoController!.value.isInitialized)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                    const CircularProgressIndicator(color: Colors.blue),

                  // Video controls overlay
                  if (_videoController != null && _videoController!.value.isInitialized)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (_videoController!.value.isPlaying) {
                                  _videoController!.pause();
                                } else {
                                  _videoController!.play();
                                }
                              });
                            },
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: VideoProgressIndicator(
                              _videoController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.blue,
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(byteCreateProvider.notifier).clearVideo();
                              _videoController?.dispose();
                              _videoController = null;
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Change video button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: _showVideoPicker,
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upload Progress
            if (byteCreateState.isUploading)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uploading video...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: byteCreateState.uploadProgress,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(byteCreateState.uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Caption Input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _captionFocusNode.hasFocus ? Colors.blue : Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _captionController,
                focusNode: _captionFocusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
                maxLength: 280, // Twitter-like limit
                textInputAction: TextInputAction.done,
              ),
            ),

            const SizedBox(height: 24),

            // Tips section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for great bytes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Keep it short and engaging (max 1 minute)'),
                  _buildTip('Use good lighting and clear audio'),
                  _buildTip('Start with a hook to grab attention'),
                  _buildTip('Add captions for better accessibility'),
                ],
              ),
            ),

            const SizedBox(height: 80), // Bottom spacing
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}