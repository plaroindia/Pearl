import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ViewModel/byte_provider.dart';
import '../../Model/comment.dart';
import 'package:collection/collection.dart';

class ByteCommentsBottomSheet extends ConsumerStatefulWidget {
  final String byteId;

  const ByteCommentsBottomSheet({super.key, required this.byteId});

  @override
  ConsumerState<ByteCommentsBottomSheet> createState() => _ByteCommentsBottomSheetState();
}

class _ByteCommentsBottomSheetState extends ConsumerState<ByteCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final FocusNode _replyFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  final Map<String, List<Comment>> _repliesByParent = {};
  final Set<String> _loadingReplies = {};
  final Set<String> _expandedComments = {};
  String? _activeReplyParentId;
  String? _activeReplyUsername;

  @override
  void initState() {
    super.initState();
    // Schedule the load after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadComments();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _commentFocusNode.dispose();
    _replyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('profile_pic')
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _loadComments() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Call loadComments and wait for it to complete
      final comments = await ref.read(bytesFeedProvider.notifier).loadComments(widget.byteId);

      debugPrint('✅ Loaded ${comments.length} comments for byte ${widget.byteId}');

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stack) {
      debugPrint('❌ Error loading comments: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load comments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _loadReplies(String parentCommentId) async {
    if (_loadingReplies.contains(parentCommentId)) return;

    setState(() => _loadingReplies.add(parentCommentId));

    final replies = await ref.read(bytesFeedProvider.notifier).loadReplies(
        widget.byteId,
        parentCommentId
    );

    if (!mounted) return;

    setState(() {
      _repliesByParent[parentCommentId] = replies;
      _loadingReplies.remove(parentCommentId);
      _expandedComments.add(parentCommentId);
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(bytesFeedProvider.notifier).addComment(
      widget.byteId,
      text,
    );

    if (success && mounted) {
      _commentController.clear();
      _commentFocusNode.unfocus();

      // Force rebuild to show new comment (state already updated optimistically)
      setState(() {});

      // Scroll to top to show new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post comment'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _submitReply(String parentCommentId, String parentUsername) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    String content = text;
    // Ensure @mention is at the start
    if (!content.startsWith('@'+parentUsername)) {
      content = '@'+parentUsername+' '+content;
    }

    final success = await ref.read(bytesFeedProvider.notifier).addReply(
      widget.byteId,
      parentCommentId,
      content,
    );

    if (success && mounted) {
      _replyController.clear();
      _replyFocusNode.unfocus();
      setState(() {
        _activeReplyParentId = null;
        _activeReplyUsername = null;
      });

      // Reload replies for this comment to show the new reply
      await _loadReplies(parentCommentId);

      // Force UI update
      setState(() {});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post reply'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _toggleCommentLike(String commentId) async {
    await ref.read(bytesFeedProvider.notifier).toggleCommentLike(commentId);
  }

  String _formatTimeAgo(DateTime createdAt) {
    final Duration diff = DateTime.now().difference(createdAt);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _startReply(String parentCommentId, String parentUsername) {
    setState(() {
      _activeReplyParentId = parentCommentId;
      _activeReplyUsername = parentUsername;
      _replyController.text = '@$parentUsername ';
      _replyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _replyController.text.length),
      );
    });

    // Request focus with slight delay for better UX
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_replyFocusNode);
      }
    });
  }

  void _cancelReply() {
    setState(() {
      _activeReplyParentId = null;
      _activeReplyUsername = null;
      _replyController.clear();
    });
    _replyFocusNode.unfocus();
  }

  void _toggleRepliesVisibility(String commentId) {
    setState(() {
      if (_expandedComments.contains(commentId)) {
        _expandedComments.remove(commentId);
      } else {
        _expandedComments.add(commentId);
        if (!_repliesByParent.containsKey(commentId)) {
          _loadReplies(commentId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytesState = ref.watch(bytesFeedProvider);
    final comments = ref.watch(bytesFeedProvider.select(
            (state) => state.commentsByByteId[widget.byteId] ?? []
    ));

    debugPrint('🎨 Building comments UI - ${comments.length} comments available');

    final likingComments = bytesState.likingComments;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final bytesState = ref.watch(bytesFeedProvider);
                          final currentByte = bytesState.bytes.firstWhereOrNull(
                                (b) => b.byteId == widget.byteId,
                          );
                          final count = currentByte?.commentCount ?? comments.length;

                          return Text(
                            '$count',
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.grey[800], height: 1, thickness: 1),

              // Comments list
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 3,
                  ),
                )
                    : comments.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _loadComments,
                  color: Colors.blue,
                  backgroundColor: Colors.grey[850],
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: comments.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey[850],
                      height: 1,
                      thickness: 1,
                      indent: 60,
                    ),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isLiking = likingComments.contains(comment.commentId.toString());
                      final isExpanded = _expandedComments.contains(comment.commentId.toString());
                      final replies = _repliesByParent[comment.commentId.toString()] ?? [];
                      final isOwnComment = currentUserId == comment.userId;

                      return _buildCommentItem(
                        comment: comment,
                        isLiking: isLiking,
                        isExpanded: isExpanded,
                        replies: replies,
                        isOwnComment: isOwnComment,
                        currentUserId: currentUserId,
                      );
                    },
                  ),
                ),
              ),

              // Input section
              _buildInputSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem({
    required Comment comment,
    required bool isLiking,
    required bool isExpanded,
    required List<Comment> replies,
    required bool isOwnComment,
    required String? currentUserId,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  // Navigate to user profile
                  // Navigator.pushNamed(context, '/profile', arguments: comment.userId);
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[700],
                  backgroundImage: comment.profileImage.isNotEmpty
                      ? CachedNetworkImageProvider(comment.profileImage)
                      : null,
                  child: comment.profileImage.isEmpty
                      ? Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (isOwnComment) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Comment text
                    Text(
                      comment.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Action buttons
                    Row(
                      children: [
                        // Like button
                        GestureDetector(
                          onTap: isLiking ? null : () => _toggleCommentLike(comment.commentId.toString()),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: isLiking
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey,
                                  ),
                                )
                                    : Icon(
                                  comment.isliked ? Icons.favorite : Icons.favorite_border,
                                  size: 19,
                                  color: comment.isliked ? Colors.red : Colors.grey[400],
                                  key: ValueKey(comment.isliked),
                                ),
                              ),
                              if (comment.likes > 0) ...[
                                const SizedBox(width: 5),
                                Text(
                                  '${comment.likes}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Reply button
                        GestureDetector(
                          onTap: () => _startReply(comment.commentId.toString(), comment.username),
                          child: Row(
                            children: [
                              Icon(Icons.reply, size: 18, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // View/Hide replies button
          if (comment.parentCommentId == null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 10),
              child: _loadingReplies.contains(comment.commentId.toString())
                  ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[600],
                ),
              )
                  : FutureBuilder<int>(
                future: ref.read(bytesFeedProvider.notifier).getRepliesCount(comment.commentId.toString()),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0 && replies.isEmpty) return const SizedBox.shrink();

                  final displayCount = replies.isNotEmpty ? replies.length : count;

                  return GestureDetector(
                    onTap: () => _toggleRepliesVisibility(comment.commentId.toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded ? Icons.remove : Icons.add,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpanded
                                ? 'Hide replies'
                                : 'View $displayCount ${displayCount == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Replies section
          if (isExpanded && replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 12),
              child: Column(
                children: replies.map((reply) {
                  final bytesState = ref.watch(bytesFeedProvider);
                  final isLikingReply = bytesState.likingComments.contains(reply.commentId.toString());
                  final isOwnReply = currentUserId == reply.userId;

                  return _buildReplyItem(reply, isLikingReply, isOwnReply);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Comment reply, bool isLiking, bool isOwnReply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[700],
            backgroundImage: reply.profileImage.isNotEmpty
                ? CachedNetworkImageProvider(reply.profileImage)
                : null,
            child: reply.profileImage.isEmpty
                ? Text(
              reply.username.isNotEmpty ? reply.username[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reply.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeAgo(reply.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    if (isOwnReply) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Like button for reply
                GestureDetector(
                  onTap: isLiking ? null : () => _toggleCommentLike(reply.commentId.toString()),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isLiking
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        )
                            : Icon(
                          reply.isliked ? Icons.favorite : Icons.favorite_border,
                          size: 17,
                          color: reply.isliked ? Colors.red : Colors.grey[500],
                          key: ValueKey(reply.isliked),
                        ),
                      ),
                      if (reply.likes > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${reply.likes}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    final isReplying = _activeReplyParentId != null;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (isReplying)
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: Colors.blue[300],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to @$_activeReplyUsername',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // User avatar
                FutureBuilder<Map<String, dynamic>?>(
                  future: _getUserProfile(),
                  builder: (context, snapshot) {
                    final profilePic = snapshot.data?['profile_pic'];

                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[700],
                      backgroundImage: profilePic != null && profilePic.toString().isNotEmpty
                          ? CachedNetworkImageProvider(profilePic)
                          : null,
                      child: (profilePic == null || profilePic.toString().isEmpty)
                          ? Icon(Icons.person, size: 20, color: Colors.grey[400])
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: isReplying ? _replyController : _commentController,
                      focusNode: isReplying ? _replyFocusNode : _commentFocusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: isReplying ? 'Write a reply...' : 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Send button
                GestureDetector(
                  onTap: _isSubmitting
                      ? null
                      : (isReplying
                      ? () => _submitReply(_activeReplyParentId!, _activeReplyUsername!)
                      : _submitComment),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isSubmitting ? Colors.grey[700] : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
