import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../Model/user_profile.dart';
import '../../ViewModel/follow_provider.dart';

class ProfileCard extends ConsumerStatefulWidget {
  final UserProfile user;
  final VoidCallback? onTap;
  final bool showFollowButton;

  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.showFollowButton = true,
  });

  @override
  ConsumerState<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  bool get _isCurrentUser => _currentUserId == widget.user.user_id;

  @override
  Widget build(BuildContext context) {
    final isFollowing = ref.watch(isFollowingProvider(widget.user.user_id));
    final isProcessing = ref.watch(isProcessingFollowProvider(widget.user.user_id));

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
                border: Border.all(
                  color: Colors.grey[600]!,
                  width: 2,
                ),
              ),
              child: widget.user.profilePic != null
                  ? ClipOval(
                child: Image.network(
                  widget.user.profilePic!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 24,
                    );
                  },
                ),
              )
                  : Icon(
                Icons.person,
                color: Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.user.isVerified == true) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          color: Colors.blue[400],
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (widget.user.role != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.user.role!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.user.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey[500],
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            widget.user.location!,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Stats and Follow Button
            Column(
              children: [
                if (widget.user.followersCount != null) ...[
                  Column(
                    children: [
                      Text(
                        _formatCount(widget.user.followersCount!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Followers',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Follow/Unfollow Button
                if (widget.showFollowButton && !_isCurrentUser && _currentUserId != null)
                  _buildFollowButton(isFollowing, isProcessing),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(bool isFollowing, bool isProcessing) {
    return SizedBox(
      width: 90,
      height: 32,
      child: ElevatedButton(
        onPressed: isProcessing ? null : () => _handleFollowToggle(),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.grey[800] : Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: isFollowing
                ? BorderSide(color: Colors.grey[600]!, width: 1)
                : BorderSide.none,
          ),
        ),
        child: isProcessing
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        )
            : Text(
          isFollowing ? 'Following' : 'Follow',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleFollowToggle() {
    final followNotifier = ref.read(followProvider.notifier);
    followNotifier.toggleFollow(widget.user.user_id);

    // Provide haptic feedback
    // HapticFeedback.lightImpact();
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}