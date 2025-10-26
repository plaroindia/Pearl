import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/byte.dart';
import '../ViewModel/user_feed_provider.dart';

class BytesFullScreen extends ConsumerStatefulWidget {
  final Byte byteData;

  const BytesFullScreen({Key? key, required this.byteData}) : super(key: key);

  @override
  ConsumerState<BytesFullScreen> createState() => _BytesFullScreenState();
}

class _BytesFullScreenState extends ConsumerState<BytesFullScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(profileFeedProvider);

    // Find the current byte from state (for real-time updates)
    final currentByte = feedState.bytes.firstWhere(
          (b) => b.byteId == widget.byteData.byteId,
      orElse: () => widget.byteData,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: currentByte.profilePic != null
                  ? NetworkImage(currentByte.profilePic!)
                  : const AssetImage('assets/plaro_logo.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentByte.username ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Media Section
                SliverToBoxAdapter(
                  child: _buildMediaSection(currentByte),
                ),

                // Byte Info Section
                SliverToBoxAdapter(
                  child: _buildByteInfoSection(currentByte),
                ),

                // Divider
                const SliverToBoxAdapter(
                  child: Divider(color: Colors.grey, height: 1),
                ),

                // Comments Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Comments (${currentByte.commentCount})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Comments placeholder (since Byte model doesn't have commentsList)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to comment',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom padding for comment input
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),

          // Comment Input Section
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildMediaSection(Byte byte) {
    return Container(
      height: 500,
      color: Colors.grey[900],
      child: Center(
        child: byte.byte.isNotEmpty
            ? Image.network(
          byte.byte,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 48),
            );
          },
        )
            : const Center(
          child: Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildByteInfoSection(Byte byte) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like, Comment, Share Count Row
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  byte.isliked == true ? Icons.favorite : Icons.favorite_border,
                  color: byte.isliked == true ? Colors.red : Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  // Note: You'll need to implement toggleByteLike in profileFeedProvider
                  // ref.read(profileFeedProvider.notifier).toggleByteLike(byte.byteId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Like feature coming soon!'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Text(
                '${byte.likeCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.comment_outlined, color: Colors.white, size: 26),
              const SizedBox(width: 4),
              Text(
                '${byte.commentCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.share_outlined, color: Colors.white, size: 26),
              const SizedBox(width: 4),
              Text(
                '${byte.shareCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
                onPressed: () {
                  // Share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature coming soon!'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Caption
          if (byte.caption != null && byte.caption!.isNotEmpty)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${byte.username ?? 'Unknown'} ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: byte.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Timestamp
          Text(
            _formatTimestamp(byte.createdAt),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.grey[850],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _postComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }

  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;

    // TODO: Implement comment posting logic with your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment feature coming soon!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    _commentController.clear();
    _commentFocusNode.unfocus();
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_outline, color: Colors.white),
              title: const Text('Save', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Save feature coming soon!'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied!'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report feature coming soon!'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}