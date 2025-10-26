import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/post.dart';
import '../ViewModel/user_feed_provider.dart';

class PostFullScreen extends ConsumerStatefulWidget {
  final Post_feed post;

  const PostFullScreen({Key? key, required this.post}) : super(key: key);

  @override
  ConsumerState<PostFullScreen> createState() => _PostFullScreenState();
}

class _PostFullScreenState extends ConsumerState<PostFullScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  int _currentMediaIndex = 0;

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

    // Find the current post from state (for real-time updates)
    final currentPost = feedState.posts.firstWhere(
          (p) => p.post_id == widget.post.post_id,
      orElse: () => widget.post,
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
              backgroundImage: currentPost.profile_pic != null
                  ? NetworkImage(currentPost.profile_pic!)
                  : const AssetImage('assets/plaro_logo.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentPost.username!,
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
                if (currentPost.media_urls != null && currentPost.media_urls!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildMediaSection(currentPost),
                  ),

                // Post Info Section
                SliverToBoxAdapter(
                  child: _buildPostInfoSection(currentPost),
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
                      'Comments (${currentPost.commentsList.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Comments List
                if (currentPost.commentsList.isEmpty)
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
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final comment = currentPost.commentsList[index];
                        return _buildCommentCard(comment);
                      },
                      childCount: currentPost.commentsList.length,
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

  Widget _buildMediaSection(Post_feed post) {
    return Container(
      height: 400,
      color: Colors.grey[900],
      child: Stack(
        children: [
          PageView.builder(
            itemCount: post.media_urls!.length,
            onPageChanged: (index) {
              setState(() => _currentMediaIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                post.media_urls![index],
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
              );
            },
          ),

          // Media indicator dots
          if (post.media_urls!.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  post.media_urls!.length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentMediaIndex == index
                          ? Colors.blue
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostInfoSection(Post_feed post) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like and Comment Count Row
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  post.isliked ? Icons.favorite : Icons.favorite_border,
                  color: post.isliked ? Colors.red : Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  ref.read(profileFeedProvider.notifier).togglePostLike(post.post_id!);
                },
              ),
              const SizedBox(width: 4),
              Text(
                '${post.like_count}',
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
                '${post.comment_count}',
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
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Caption
          if (post.caption != null && post.caption!.isNotEmpty)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${post.username} ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: post.caption!,
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
            _formatTimestamp(post.created_at),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.profileImage.isNotEmpty
                ? NetworkImage(comment.profileImage)
                : const AssetImage('assets/plaro_logo.png') as ImageProvider,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
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
                      onTap: () {
                        setState(() {
                          comment.toggleLike();
                        });
                      },
                      child: Text(
                        comment.isliked ? 'Liked' : 'Like',
                        style: TextStyle(
                          color: comment.isliked ? Colors.blue : Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comment.likes > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${comment.likes} likes',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              comment.isliked ? Icons.favorite : Icons.favorite_border,
              color: comment.isliked ? Colors.red : Colors.grey[600],
              size: 16,
            ),
            onPressed: () {
              setState(() {
                comment.toggleLike();
              });
            },
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
                // Save functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Copy link functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Report functionality
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
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}