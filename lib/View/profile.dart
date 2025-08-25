import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'set_profile.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/auth_provider.dart';
import '../ViewModel/user_feed_provider.dart';
import '../ViewModel/follow_provider.dart';
import 'widgets/post_user_card.dart';
import 'widgets/toast_user_card.dart';
import '../Model/toast.dart';
import '../Model/post.dart';
import '../Model/user_profile.dart';
import '../View/foll_page.dart';
import 'package:google_fonts/google_fonts.dart';

class OtherProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // null = current user, otherwise other user
  final UserProfile? initialUserData; // passed from search card

  const OtherProfileScreen({
    super.key,
    this.userId,
    this.initialUserData,
  });

  @override
  ConsumerState<OtherProfileScreen> createState() => _OtherProfileScreen();
}

class _OtherProfileScreen extends ConsumerState<OtherProfileScreen> with TickerProviderStateMixin {
  bool _isInitialized = false;
  late TabController _tabController;
  final ScrollController _postsScrollController = ScrollController();
  final ScrollController _toastsScrollController = ScrollController();

  // Computed properties
  bool get isOwnProfile => widget.userId == null || widget.userId == Supabase.instance.client.auth.currentUser?.id;
  String get targetUserId => widget.userId ?? Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _postsScrollController.addListener(_onPostsScroll);
    _toastsScrollController.addListener(_onToastsScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postsScrollController.dispose();
    _toastsScrollController.dispose();
    super.dispose();
  }

  // Clear state when component unmounts or userId changes
  @override
  void didUpdateWidget(OtherProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // User changed, reset state
      setState(() {
        _isInitialized = false;
      });
      // Clear providers
      _clearProvidersState();
      // Load new user data
      _loadUserProfile();
    }
  }

  void _clearProvidersState() {
    // Reset follow provider if not own profile
    if (!isOwnProfile) {
      ref.read(followProvider.notifier).clear();
    }
  }

  void _onPostsScroll() {
    if (_postsScrollController.position.pixels >= _postsScrollController.position.maxScrollExtent - 200) {
      ref.read(profileFeedProvider.notifier).loadMoreUserPosts(targetUserId);
    }
  }

  void _onToastsScroll() {
    if (_toastsScrollController.position.pixels >= _toastsScrollController.position.maxScrollExtent - 200) {
      ref.read(profileFeedProvider.notifier).loadMoreUserToasts(targetUserId);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      if (isOwnProfile) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await ref.read(setProfileProvider.notifier).getUserProfile(user.id);
          await _loadUserContent();
        }
      } else {
        // Load other user's profile
        await ref.read(setProfileProvider.notifier).getUserProfile(targetUserId);
        await _loadUserContent();
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadUserContent() async {
    final profileFeedNotifier = ref.read(profileFeedProvider.notifier);
    await Future.wait([
      profileFeedNotifier.loadUserPosts(targetUserId),
      profileFeedNotifier.loadUserToasts(targetUserId),
    ]);
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isInitialized = false;
    });
    await ref.read(profileFeedProvider.notifier).refreshUserContent(targetUserId);
    await _loadUserProfile();
  }

  Future<void> _toggleFollow() async {
    if (!isOwnProfile) {
      await ref.read(followProvider.notifier).toggleFollow(targetUserId);
    }
  }

  void _openChat() {
    if (!isOwnProfile) {
      // Navigate to chat screen
      // Navigator.pushNamed(context, '/chat', arguments: {'userId': targetUserId});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);
    final feedState = ref.watch(profileFeedProvider);
    final followState = isOwnProfile ? null : ref.watch(followProvider);

    // Initialize profile loading if not done yet
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserProfile();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: Colors.blue,
        backgroundColor: Colors.black,
        displacement: 40.0,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header container - Now shows back button and username for all profiles
                      _buildHeader(profileState, authState),

                      // Show loading indicator if not initialized
                      if (!_isInitialized && profileState.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        ),

                      // Profile information section - Same for both
                      _buildProfileInfo(profileState),

                      // Action buttons - DIFFERENT for own vs other profile
                      _buildActionButtons(followState),

                      const SizedBox(height: 6.0),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 50.0,
                  maxHeight: 50.0,
                  child: _buildTabBar(feedState),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(feedState),
              _buildToastsTab(feedState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue profileState, AsyncValue authState) {
    return Column(
      children: [
        Row(
          children: [
            // Back button - only show for other profiles
            if (!isOwnProfile)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),

            // Add spacing only when back button is present
            if (!isOwnProfile) const SizedBox(width: 10),

            // Username for all profiles
            Expanded(
              child: profileState.when(
                data: (profile) => Text(
                  profile?.username ?? widget.initialUserData?.username ?? 'Unknown User',
                  style: GoogleFonts.playwriteFrModerne(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.blue,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const Text(
                  'Loading...',
                  style: TextStyle(color: Colors.grey),
                ),
                error: (error, stack) => Text(
                  widget.initialUserData?.username ?? 'Error loading user',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),

            // Optional: Add action buttons for own profile
            if (isOwnProfile)
              IconButton(
                onPressed: () {
                  // Add edit profile functionality here
                  // For example: _showEditProfileDialog();
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileInfo(AsyncValue profileState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main profile picture
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
          child: profileState.when(
            data: (profile) => CircleAvatar(
              backgroundImage: profile?.profilePic != null
                  ? NetworkImage(profile!.profilePic!)
                  : const AssetImage('assets/plaro_logo.png') as ImageProvider,
              radius: 68.0,
            ),
            loading: () => const CircleAvatar(
              radius: 45.0,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            error: (error, stack) => const CircleAvatar(
              backgroundImage: AssetImage('assets/plaro_logo.png'),
              radius: 45.0,
            ),
          ),
        ),

        // Username
        profileState.when(
          data: (profile) => Text(
            profile?.username ?? widget.initialUserData?.username ?? 'No username',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 20.0,
              letterSpacing: 2.0,
            ),
          ),
          loading: () => const Text(
            'Loading...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 20.0,
              letterSpacing: 2.0,
            ),
          ),
          error: (error, stack) => Text(
            widget.initialUserData?.username ?? 'Error loading username',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20.0,
              letterSpacing: 2.0,
            ),
          ),
        ),

        // Study/School
        profileState.when(
          data: (profile) => Text(
            profile?.study ?? 'No school info',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.0,
              letterSpacing: 1.0,
            ),
          ),
          loading: () => const Text(
            'Loading...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              letterSpacing: 1.0,
            ),
          ),
          error: (error, stack) => const Text(
            'Error loading school',
            style: TextStyle(
              color: Colors.red,
              fontSize: 15.0,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // Bio
        profileState.when(
          data: (profile) => Text(
            profile?.bio ?? 'No bio',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 13.0,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          loading: () => const Text(
            'Loading...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13.0,
              letterSpacing: 1.0,
            ),
          ),
          error: (error, stack) => const Text(
            'Error loading bio',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13.0,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // Role and Location in horizontal layout
        profileState.when(
          data: (profile) {
            final hasRole = profile?.role != null;
            final hasLocation = profile?.location != null;

            if (hasRole || hasLocation) {
              return Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasRole)
                      Row(
                        children: [
                          const Icon(
                            Icons.work_history_outlined,
                            color: Colors.lightBlue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              profile!.role!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12.0,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (hasLocation && hasRole)
                      const SizedBox(width: 20),
                    if (hasLocation)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.lightBlue, size: 16),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              profile!.location!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),

        // Stats (followers, following, streak)
        profileState.when(
          data: (profile) => profile != null
              ? Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: _buildStatItem(
                      'Followers',
                      profile.followersCount?.toString() ?? '0',
                      profile,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      color: Colors.grey[600],
                      thickness: 1,
                      width: 1,
                    ),
                  ),
                  Flexible(
                    child: _buildStatItem(
                      'Following',
                      profile.followingCount?.toString() ?? '0',
                      profile,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      color: Colors.grey[600],
                      thickness: 1,
                      width: 1,
                    ),
                  ),
                  Flexible(
                    child: _buildStatItem(
                      'Streak',
                      profile.streakCount?.toString() ?? '0',
                      profile,
                    ),
                  ),
                ],
              ),
            ),
          )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget _buildActionButtons(FollowState? followState) {
    if (isOwnProfile) {
      // Own profile buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black54,
              side: const BorderSide(width: 3.0, color: Colors.blue),
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SetProfile(),
                ),
              ).then((_) {
                _refreshProfile();
              });
            },
            child: const Text("Profile"),
          ),
          const SizedBox(width: 30.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.blue,
              backgroundColor: Colors.black54,
              side: const BorderSide(width: 3.0, color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () {},
            child: const Text("Stats"),
          ),
        ],
      );
    } else {
      // Other user's profile buttons
      final isFollowing = followState?.followingStatus[targetUserId] ?? false;
      final isProcessing = followState?.processingFollowRequests.contains(targetUserId) ?? false;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
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
            onPressed: isProcessing ? null : _toggleFollow,
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
          ),
          const SizedBox(width: 30.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black54,
              side: const BorderSide(width: 2.0, color: Colors.blue),
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: _openChat,
            child: const Text("Message"),
          ),
        ],
      );
    }
  }

  Widget _buildTabBar(ProfileFeedState feedState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 1.5,
            color: Colors.blue[400]!,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 90.0),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.view_array_outlined, size: 16),
                const SizedBox(width: 4),
                Text('Posts (${feedState.posts.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.campaign_outlined, size: 16),
                const SizedBox(width: 4),
                Text('Toasts (${feedState.toasts.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(ProfileFeedState feedState) {
    if (feedState.isLoadingPosts && feedState.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (feedState.posts.isEmpty && !feedState.isLoadingPosts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.view_array_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isOwnProfile ? 'No posts yet' : 'No posts to show',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwnProfile ? 'Your posts will appear here' : 'This user hasn\'t posted anything yet',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ProfilePostsGrid(
      posts: feedState.posts,
      scrollController: _postsScrollController,
      onPostTap: (post) {
        print('Tapped post: ${post.post_id}');
      },
      onLike: (postId) {
        ref.read(profileFeedProvider.notifier).togglePostLike(postId);
      },
      onDelete: isOwnProfile ? (postId) {
        _showDeleteConfirmation('post', () {
          ref.read(profileFeedProvider.notifier).deletePost(postId);
        });
      } : null,
      isLoadingMore: feedState.isLoadingMorePosts,
      hasMore: feedState.hasMorePosts,
    );
  }

  Widget _buildToastsTab(ProfileFeedState feedState) {
    if (feedState.isLoadingToasts && feedState.toasts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (feedState.toasts.isEmpty && !feedState.isLoadingToasts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isOwnProfile ? 'No toasts yet' : 'No toasts to show',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwnProfile ? 'Your toasts will appear here' : 'This user hasn\'t shared any toasts yet',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ProfileToastsGrid(
      toasts: feedState.toasts,
      scrollController: _toastsScrollController,
      onToastTap: (toast) {
        print('Tapped toast: ${toast.toast_id}');
      },
      onLike: (toastId) {
        ref.read(profileFeedProvider.notifier).toggleToastLike(toastId);
      },
      onDelete: isOwnProfile ? (toastId) {
        _showDeleteConfirmation('toast', () {
          ref.read(profileFeedProvider.notifier).deleteToast(toastId);
        });
      } : null,
      isLoadingMore: feedState.isLoadingMoreToasts,
      hasMore: feedState.hasMoreToasts,
    );
  }

  void _showDeleteConfirmation(String type, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Delete $type',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete this $type? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, UserProfile? userProfile) {
    return GestureDetector(
      onTap: isOwnProfile ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowPage(
              userId: targetUserId,
              initialTab: label == 'Following' ? 1 : 0,
            ),
          ),
        );
      } : null,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class ProfilePostsGrid extends ConsumerWidget {
  final List<Post_feed> posts;
  final ScrollController scrollController;
  final Function(Post_feed) onPostTap;
  final Function(String) onLike;
  final Function(String)? onDelete;
  final bool isLoadingMore;
  final bool hasMore;

  const ProfilePostsGrid({
    Key? key,
    required this.posts,
    required this.scrollController,
    required this.onPostTap,
    required this.onLike,
    this.onDelete,
    required this.isLoadingMore,
    required this.hasMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(profileFeedProvider);

    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            if (feedState.error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedState.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(profileFeedProvider.notifier).clearError(),
                        icon: const Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                    ],
                  ),
                ),
              ),

            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final post = posts[index];
                  return PostProfileCard(
                    post: post,
                    onTap: () => onPostTap(post),
                  );
                },
                childCount: posts.length,
              ),
            ),
            if (isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
              ),
            if (!hasMore && posts.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No more posts',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ));
  }
}

class ProfileToastsGrid extends ConsumerWidget {
  final List<Toast_feed> toasts;
  final ScrollController scrollController;
  final Function(Toast_feed) onToastTap;
  final Function(String) onLike;
  final Function(String)? onDelete;
  final bool isLoadingMore;
  final bool hasMore;

  const ProfileToastsGrid({
    Key? key,
    required this.toasts,
    required this.scrollController,
    required this.onToastTap,
    required this.onLike,
    this.onDelete,
    required this.isLoadingMore,
    required this.hasMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(profileFeedProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 56, 8, 8),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (feedState.error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedState.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(profileFeedProvider.notifier).clearError(),
                      icon: const Icon(Icons.close, color: Colors.red, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final toast = toasts[index];
                return ToastProfileCard(
                  toast: toast,
                  onTap: () => onToastTap(toast),
                );
              },
              childCount: toasts.length,
            ),
          ),
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
            ),
          if (!hasMore && toasts.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No more toasts',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}