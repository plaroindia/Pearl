import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../Model/user_profile.dart';

class ProfileCard extends ConsumerStatefulWidget {
  final UserProfile user;
  final VoidCallback? onTap;

  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  ConsumerState<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  @override
  Widget build(BuildContext context) {
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
                      Text(
                        widget.user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                        Text(
                          widget.user.location!,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Stats
            if (widget.user.followersCount != null) ...[
              Column(
                children: [
                  Text(
                    '${widget.user.followersCount}',
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
            ],
          ],
        ),
      ),
    );
  }
}