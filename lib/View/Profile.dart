import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'set_profile.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/auth_provider.dart';
import '../ViewModel/user_feed_provider.dart';
import 'widgets/post_user_card.dart';
import 'widgets/toast_user_card.dart';
import '../Model/toast.dart';
import '../Model/post.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends ConsumerState<ProfileScreen> with TickerProviderStateMixin {
  bool _isInitialized = false;
  late TabController _tabController;
  final ScrollController _postsScrollController = ScrollController();
  final ScrollController _toastsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add scroll listeners for pagination
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

  void _onPostsScroll() {
    if (_postsScrollController.position.pixels >= _postsScrollController.position.maxScrollExtent - 200) {
      ref.read(profileFeedProvider.notifier).loadMoreUserPosts();
    }
  }

  void _onToastsScroll() {
    if (_toastsScrollController.position.pixels >= _toastsScrollController.position.maxScrollExtent - 200) {
      ref.read(profileFeedProvider.notifier).loadMoreUserToasts();
    }
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await ref.read(setProfileProvider.notifier).getUserProfile(user.id);
        // Load user's posts and toasts
        await _loadUserContent();
        setState(() {
          _isInitialized = true;
        });
      }
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
      profileFeedNotifier.loadUserPosts(),
      profileFeedNotifier.loadUserToasts(),
    ]);
  }

  // Refresh profile data
  Future<void> _refreshProfile() async {
    setState(() {
      _isInitialized = false;
    });
    await ref.read(profileFeedProvider.notifier).refreshUserContent();
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);
    final feedState = ref.watch(profileFeedProvider);

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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header container with user email
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Profile picture in header
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: profileState.when(
                            data: (profile) => CircleAvatar(
                              backgroundImage: profile?.profilePic != null
                                  ? NetworkImage(profile!.profilePic!)
                                  : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                              radius: 15.0,
                            ),
                            loading: () => const CircleAvatar(
                              radius: 15.0,
                              backgroundColor: Colors.grey,
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            ),
                            error: (error, stack) => const CircleAvatar(
                              backgroundImage: AssetImage('assets/plaro_logo.png'),
                              radius: 15.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // User email or username
                        Expanded(
                          child: authState.when(
                            data: (session) {
                              return profileState.when(
                                data: (profile) => Text(
                                  profile?.username ?? session?.user.email ?? 'No user',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                loading: () => const Text(
                                  'Loading...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                error: (error, stack) => Text(
                                  session?.user.email ?? 'Error loading user',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            },
                            loading: () => const Text(
                              'Loading...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            error: (error, stack) => const Text(
                              'Error loading user',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),

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

                    // Profile information section
                    Column(
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
                              radius: 45.0,
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
                            profile?.username ?? 'No username',
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
                          error: (error, stack) => const Text(
                            'Error loading username',
                            style: TextStyle(
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

                        // Role (if exists)
                        profileState.when(
                          data: (profile) => profile?.role != null
                              ? Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Text(
                              profile!.role!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12.0,
                                letterSpacing: 1.0,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (error, stack) => const SizedBox.shrink(),
                        ),

                        // Location (if exists)
                        profileState.when(
                          data: (profile) => profile?.location != null
                              ? Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile!.location!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (error, stack) => const SizedBox.shrink(),
                        ),

                        // Stats (followers, following, streak)
                        profileState.when(
                          data: (profile) => profile != null
                              ? Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  'Followers',
                                  profile.followersCount?.toString() ?? '0',
                                ),
                                _buildStatItem(
                                  'Following',
                                  profile.followingCount?.toString() ?? '0',
                                ),
                                _buildStatItem(
                                  'Streak',
                                  profile.streakCount?.toString() ?? '0',
                                ),
                              ],
                            ),
                          )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (error, stack) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 20.0),

                        // Action buttons
                        Row(
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
                                  // Refresh profile after returning from SetProfile
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
                              child: const Text("Friends"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                      ],
                    ),

                    //const SizedBox(height: 15.0),

                    // Tab Bar for Posts and Toasts
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.transparent,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar View Content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Posts Tab
                  _buildPostsTab(feedState),
                  // Toasts Tab
                  _buildToastsTab(feedState),
                ],
              ),
            ),
          ],
        ),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_array_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your posts will appear here',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (feedState.error != null)
          Container(
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

        Expanded(
          child: ProfilePostsGrid(
            posts: feedState.posts,
            scrollController: _postsScrollController,
            onPostTap: (post) {
              // Navigate to full post view
              print('Tapped post: ${post.post_id}');
            },
            onLike: (postId) {
              ref.read(profileFeedProvider.notifier).togglePostLike(postId);
            },
            onDelete: (postId) {
              _showDeleteConfirmation('post', () {
                ref.read(profileFeedProvider.notifier).deletePost(postId);
              });
            },
            isLoadingMore: feedState.isLoadingMorePosts,
            hasMore: feedState.hasMorePosts,
          ),
        ),
      ],
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No toasts yet',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your toasts will appear here',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (feedState.error != null)
          Container(
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

        Expanded(
          child: ProfileToastsGrid(
            toasts: feedState.toasts,
            scrollController: _toastsScrollController,
            onToastTap: (toast) {
              // Navigate to full toast view
              print('Tapped toast: ${toast.toast_id}');
            },
            onLike: (toastId) {
              ref.read(profileFeedProvider.notifier).toggleToastLike(toastId);
            },
            onDelete: (toastId) {
              _showDeleteConfirmation('toast', () {
                ref.read(profileFeedProvider.notifier).deleteToast(toastId);
              });
            },
            isLoadingMore: feedState.isLoadingMoreToasts,
            hasMore: feedState.hasMoreToasts,
          ),
        ),
      ],
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

  // Helper method to build stat items
  Widget _buildStatItem(String label, String value) {
    return Column(
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
    );
  }
}

// Updated Profile Posts Grid with enhanced functionality
class ProfilePostsGrid extends ConsumerWidget {
  final List<Post_feed> posts;
  final ScrollController scrollController;
  final Function(Post_feed) onPostTap;
  final Function(String) onLike;
  final Function(String) onDelete;
  final bool isLoadingMore;
  final bool hasMore;

  const ProfilePostsGrid({
    Key? key,
    required this.posts,
    required this.scrollController,
    required this.onPostTap,
    required this.onLike,
    required this.onDelete,
    required this.isLoadingMore,
    required this.hasMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
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
      ),
    );
  }
}

// Updated Profile Toasts Grid with enhanced functionality
class ProfileToastsGrid extends ConsumerWidget {
  final List<Toast_feed> toasts;
  final ScrollController scrollController;
  final Function(Toast_feed) onToastTap;
  final Function(String) onLike;
  final Function(String) onDelete;
  final bool isLoadingMore;
  final bool hasMore;

  const ProfileToastsGrid({
    Key? key,
    required this.toasts,
    required this.scrollController,
    required this.onToastTap,
    required this.onLike,
    required this.onDelete,
    required this.isLoadingMore,
    required this.hasMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
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