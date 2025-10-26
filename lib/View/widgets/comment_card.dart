import 'package:flutter/material.dart';
import '../../../Model/toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentCard extends ConsumerWidget {
  final Comment comment;
  final VoidCallback onLike;
  final VoidCallback? onReply;

  const CommentCard({
    Key? key,
    required this.comment,
    required this.onLike,
    this.onReply,
  }) : super(key: key);



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comment.profileImage != null
            ? NetworkImage(comment.profileImage)
            : const AssetImage('assets/plaro new logo.png') as ImageProvider,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            comment.username,
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
          Text(
            comment.timeAgo,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.content,
            style: TextStyle(color: Colors.grey.shade300),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  comment.uliked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: Colors.blue,
                ),
                onPressed: onLike,
              ),
              Text(
                '${comment.likes}',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(width: 10),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.reply, size: 16, color: Colors.blue),
                onPressed: onReply,
              ),
              const Text('Reply', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ],
      ),
      onTap: () {
        // Optional interaction handler
      },
    );
  }
}