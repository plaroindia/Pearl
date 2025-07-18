import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/auth_provider.dart';
import '../ViewModel/toast_feed_provider.dart';
import '../ViewModel/post_feed_provider.dart';
import 'widgets/toast_card.dart';
import 'widgets/post_card.dart';
import 'search_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _feedsInitialized = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more content for both feeds
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    final toastFeedState = ref.read(toastFeedProvider);
    final postFeedState = ref.read(postFeedProvider);

    // Load more for both feeds if they have more content
    final futures = <Future>[];

    if (toastFeedState.hasMore && !toastFeedState.isLoading) {
      futures.add(ref.read(toastFeedProvider.notifier).loadMorePosts());
    }

    if (postFeedState.hasMore && !postFeedState.isLoadingMore) {
      futures.add(ref.read(postFeedProvider.notifier).loadMorePosts());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _loadUserProfile() async {
    if (_isInitialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await ref.read(setProfileProvider.notifier).getUserProfile(user.id);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeFeeds() async {
    if (_feedsInitialized) return;

    final toastFeedState = ref.read(toastFeedProvider);
    final postFeedState = ref.read(postFeedProvider);

    final futures = <Future>[];

    // Initialize toast feed if not loaded
    if (toastFeedState.posts.isEmpty && !toastFeedState.isLoading) {
      futures.add(ref.read(toastFeedProvider.notifier).loadPosts());
    }

    // Initialize post feed if not loaded
    if (postFeedState.posts.isEmpty && !postFeedState.isLoading) {
      futures.add(ref.read(postFeedProvider.notifier).loadPosts());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    setState(() {
      _feedsInitialized = true;
    });
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider).logout();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFeed() async {
    print('🔄 Refreshing feeds...');

    // Reset initialization flag to allow re-initialization
    setState(() {
      _feedsInitialized = false;
    });

    try {
      // Refresh both feeds in parallel
      await Future.wait([
        ref.read(toastFeedProvider.notifier).refreshPosts(),
        ref.read(postFeedProvider.notifier).refreshPosts(),
      ]);

      setState(() {
        _feedsInitialized = true;
      });

      print('🟢 Feeds refreshed successfully');
    } catch (e) {
      print('🔴 Error refreshing feeds: $e');
    }
  }

  // Helper method to combine and sort posts by timestamp
  List<Map<String, dynamic>> _getCombinedFeed(toastFeedState, postFeedState) {
    List<Map<String, dynamic>> combinedFeed = [];

    // Add toasts with type identifier
    for (var toast in toastFeedState.posts) {
      DateTime timestamp;
      try {
        timestamp = toast.created_at ?? DateTime.now();
      } catch (e) {
        timestamp = DateTime.now();
      }

      combinedFeed.add({
        'type': 'toast',
        'data': toast,
        'timestamp': timestamp,
      });
    }

    // Add posts with type identifier
    for (var post in postFeedState.posts) {
      DateTime timestamp;
      try {
        timestamp = post.created_at ?? DateTime.now();
      } catch (e) {
        timestamp = DateTime.now();
      }

      combinedFeed.add({
        'type': 'post',
        'data': post,
        'timestamp': timestamp,
      });
    }

    // Sort by timestamp (newest first)
    combinedFeed.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    return combinedFeed;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);
    final toastFeedState = ref.watch(toastFeedProvider);
    final postFeedState = ref.watch(postFeedProvider);

    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserProfile();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white54,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "PLARO",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 20.0,
                letterSpacing: 0.0,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/create_post');
                  },
                  icon: const Icon(Icons.add_box_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black87,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10.0),
                    Center(
                      child: profileState.when(
                        data: (profile) => CircleAvatar(
                          backgroundImage: profile?.profilePic != null
                              ? NetworkImage(profile!.profilePic!)
                              : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                          radius: 60.0,
                        ),
                        loading: () => const CircleAvatar(
                          radius: 30.0,
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
                          radius: 30.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    authState.when(
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
                  ],
                ),
              ),

              // Navigation Items
              ListTile(
                leading: const Icon(Icons.event_note, color: Colors.grey),
                title: const Text(
                  'Events',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text(
                  'Settings',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Divider(color: Colors.grey),

              // Sign Out
              ListTile(
                leading: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
                    : const Icon(Icons.logout, color: Colors.grey),
                title: Text(
                  _isLoading ? 'Signing out...' : 'Sign Out',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: _isLoading ? null : _handleSignOut,
              ),
            ],
          ),
        ),
      ),
      body: authState.when(
        data: (session) {
          if (session == null) {
            return const Center(
              child: Text(
                'Please log in to continue',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            );
          }

          // Initialize feeds when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (toastFeedState.posts.isEmpty && !toastFeedState.isLoading) {
              ref.read(toastFeedProvider.notifier).loadPosts();
            }
            if (postFeedState.posts.isEmpty && !postFeedState.isLoading) {
              ref.read(postFeedProvider.notifier).loadPosts();
            }
          });

          return _buildCombinedFeed(toastFeedState, postFeedState);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedFeed(dynamic toastFeedState, dynamic postFeedState) {
    final combinedFeed = _getCombinedFeed(toastFeedState, postFeedState);
    final hasError = toastFeedState.error != null || postFeedState.error != null;
    final isLoading = toastFeedState.isLoading || postFeedState.isLoading;
    final isEmpty = combinedFeed.isEmpty;

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      backgroundColor: Colors.grey[900],
      color: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Error handling
          if (hasError)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        toastFeedState.error ?? postFeedState.error ?? 'Unknown error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (toastFeedState.error != null) {
                          ref.read(toastFeedProvider.notifier).clearError();
                        }
                        if (postFeedState.error != null) {
                          ref.read(postFeedProvider.notifier).clearError();
                        }
                        _refreshFeed();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Combined feed list
          if (combinedFeed.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final feedItem = combinedFeed[index];
                  final type = feedItem['type'] as String;
                  final data = feedItem['data'];

                  if (type == 'toast') {
                    return ToastCard(
                      toast: data,
                      onTap: () {
                        // Navigate to toast details if needed
                      },
                    );
                  } else {
                    return PostCard(
                      post: data,
                      onTap: () {
                        // Navigate to post details if needed
                      },
                    );
                  }
                },
                childCount: combinedFeed.length,
              ),
            ),

          // Loading and empty states
          _buildEmptyOrLoadingState(isEmpty, isLoading, hasError),

          // Loading indicator for pagination
          if (isLoading && combinedFeed.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildEmptyOrLoadingState(bool isEmpty, bool isLoading, bool hasError) {
    if (isEmpty && isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      );
    }

    if (isEmpty && !isLoading && !hasError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.article_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No posts yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Be the first to share something!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_post');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Create Post'),
              ),
            ],
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}