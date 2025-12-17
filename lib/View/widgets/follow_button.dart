import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ViewModel/follow_provider.dart';
import '../../ViewModel/auth_provider.dart';

class FollowButton extends ConsumerStatefulWidget {
  final String targetUserId;
  final bool compact;
  final VoidCallback? onFollowSuccess;
  final VoidCallback? onFollowError;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.compact = false,
    this.onFollowSuccess,
    this.onFollowError,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followProvider.notifier).refreshFollowingStatus(widget.targetUserId);
    });
  }

  Future<void> _handleToggleFollow() async {
    try {
      await ref.read(followProvider.notifier).toggleFollowWithDebounce(widget.targetUserId);
      widget.onFollowSuccess?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(isFollowingProvider(widget.targetUserId)) ? 'Following' : 'Unfollowed',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      widget.onFollowError?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.value?.user.id;

    if (currentUserId == null || currentUserId == widget.targetUserId) {
      return const SizedBox.shrink();
    }
    final isFollowing = ref.watch(isFollowingProvider(widget.targetUserId));
    final isProcessing = ref.watch(isProcessingFollowProvider(widget.targetUserId));
    if (widget.compact) {
      return _buildCompactButton(isFollowing, isProcessing);
    } else {
      return _buildFullButton(isFollowing, isProcessing);
    }
  }

  Widget _buildCompactButton(bool isFollowing, bool isProcessing) {
    return GestureDetector(
      onTap: isProcessing ? null : _handleToggleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : Colors.blue,
          border: Border.all(
            color: isFollowing ? Colors.white : Colors.blue,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFullButton(bool isFollowing, bool isProcessing) {
    return ElevatedButton(
      onPressed: isProcessing ? null : _handleToggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey[800] : Colors.blue,
        foregroundColor: Colors.white,
        side: BorderSide(
          width: 2.0,
          color: isFollowing ? Colors.grey : Colors.blue,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: isProcessing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(isFollowing ? "Following" : "Follow"),
    );
  }
}

