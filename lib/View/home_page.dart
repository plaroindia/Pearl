import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plaro_3/View/allcourses_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/auth_provider.dart';
import '../ViewModel/toast_feed_provider.dart';
import '../ViewModel/post_feed_provider.dart';
import 'widgets/toast_card.dart';
import 'widgets/post_card.dart';
import 'search_page.dart';
import '../ViewModel/theme_provider.dart';
import 'allevents_page.dart';
import 'profile.dart';
import '../ViewModel/user_provider.dart';

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
  final Map<String, DateTime> _lastRefreshTime = {};

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
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    final toastFeedState = ref.read(toastFeedProvider);
    final postFeedState = ref.read(postFeedProvider);

    // Use optimized loadMorePosts for both providers
    final futures = <Future>[];

    if (toastFeedState.hasMore && !toastFeedState.isLoadingMore) {
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

    // Check cache first - if cache exists and not expired, skip loading
    final bool shouldLoadToasts = toastFeedState.posts.isEmpty &&
        (toastFeedState.lastFetchTime == null ||
            DateTime.now().difference(toastFeedState.lastFetchTime!) > Duration(minutes: 5));

    final bool shouldLoadPosts = postFeedState.posts.isEmpty &&
        (postFeedState.lastFetchTime == null ||
            DateTime.now().difference(postFeedState.lastFetchTime!) > Duration(minutes: 5));

    if (shouldLoadToasts && !toastFeedState.isLoading) {
      futures.add(ref.read(toastFeedProvider.notifier).loadTosts());
    }

    if (shouldLoadPosts && !postFeedState.isLoading) {
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
    print('🔄 Refreshing feeds with cache invalidation...');

    setState(() {
      _feedsInitialized = false;
    });

    try {
      // Use the optimized refreshPosts methods that clear cache
      await Future.wait([
        ref.read(toastFeedProvider.notifier).refreshPosts(),
        ref.read(postFeedProvider.notifier).refreshPosts(),
      ]);

      setState(() {
        _feedsInitialized = true;
      });

      print('✅ Feeds refreshed successfully with fresh data');
    } catch (e) {
      print('❌ Error refreshing feeds: $e');
      setState(() {
        _feedsInitialized = true;
      });
    }
  }

  // OPTIMIZED: Improved combined feed with better timestamp handling
  List<Map<String, dynamic>> _getCombinedFeed(toastFeedState, postFeedState) {
    final List<Map<String, dynamic>> combinedFeed = [];

    // Add toasts with type identifier
    for (final toast in toastFeedState.posts) {
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(toast.created_at);
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
    for (final post in postFeedState.posts) {
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(post.created_at);
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

  // OPTIMIZED: Cache-aware feed initialization
  bool _shouldInitializeFeeds(toastFeedState, postFeedState) {
    final bool hasCachedData = toastFeedState.posts.isNotEmpty || postFeedState.posts.isNotEmpty;
    final bool isCacheFresh = toastFeedState.lastFetchTime != null &&
        DateTime.now().difference(toastFeedState.lastFetchTime!) < Duration(minutes: 5);

    return !hasCachedData || !isCacheFresh;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);
    final toastFeedState = ref.watch(toastFeedProvider);
    final postFeedState = ref.watch(postFeedProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserProfile();
      });
    }

    // OPTIMIZED: Initialize feeds only when needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldInitializeFeeds(toastFeedState, postFeedState) && !_feedsInitialized) {
        _initializeFeeds();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PLARO",
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
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
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat_list');
                  },
                  icon: Icon(
                    Icons.message,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context, themeMode),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authStateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeMode themeMode) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 16.0, top: 32.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10.0),
                  Center(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final currentUserProfile = ref.watch(currentUserProfileProvider);
                        return currentUserProfile.when(
                          data: (profile) => CircleAvatar(
                            backgroundImage: profile?.profilePic != null
                                ? NetworkImage(profile!.profilePic!)
                                : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                            radius: 40.0,
                          ),
                          loading: () => const CircleAvatar(
                            radius: 40.0,
                            backgroundColor: Colors.grey,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                          error: (error, stack) => const CircleAvatar(
                            backgroundImage: AssetImage('assets/plaro_logo.png'),
                            radius: 40.0,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authStateProvider);
                        final currentUserProfile = ref.watch(currentUserProfileProvider);

                        return authState.when(
                          data: (session) {
                            return currentUserProfile.when(
                              data: (profile) => Text(
                                profile?.username ?? session?.user.email ?? 'No user',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              loading: () => const Text(
                                'Loading...',
                                style: TextStyle(color: Colors.white70),
                              ),
                              error: (error, stack) => Text(
                                session?.user.email ?? 'Error loading user',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          loading: () => const Text(
                            'Loading...',
                            style: TextStyle(color: Colors.white70),
                          ),
                          error: (error, stack) => const Text(
                            'Error loading user',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            ListTile(
              leading: Icon(
                Icons.event_note,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Events',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllEventsPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add your settings navigation here
              },
            ),

            // Dark Mode Toggle
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeNotifierProvider.notifier).toggleTheme(value);
              },
              secondary: Icon(
                themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).iconTheme.color,
              ),
              activeColor: Theme.of(context).colorScheme.primary,
            ),

            Divider(color: Theme.of(context).dividerColor),

            // Sign Out
            ListTile(
              leading: _isLoading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).iconTheme.color ?? Colors.grey,
                  ),
                ),
              )
                  : Icon(
                Icons.logout,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                _isLoading ? 'Signing out...' : 'Sign Out',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: _isLoading ? null : _handleSignOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedFeed(dynamic toastFeedState, dynamic postFeedState) {
    final combinedFeed = _getCombinedFeed(toastFeedState, postFeedState);
    final hasError = toastFeedState.error != null || postFeedState.error != null;
    final isLoading = toastFeedState.isLoading || postFeedState.isLoading;
    final isLoadingMore = toastFeedState.isLoadingMore || postFeedState.isLoadingMore;
    final isEmpty = combinedFeed.isEmpty;

    // OPTIMIZED: Show cached data immediately while loading
    final bool showCachedData = combinedFeed.isNotEmpty && isLoading;

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      color: Theme.of(context).colorScheme.primary,
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

          // Combined feed list - show cached data even while loading
          if (showCachedData || combinedFeed.isNotEmpty)
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
                        // Handle toast tap
                      },
                      onUserInfo: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherProfileScreen(
                              userId: data.user_id,
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return PostCard(
                      post: data,
                      onTap: () {
                        // Handle post tap
                      },
                      onUserInfo: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherProfileScreen(
                              userId: data.user_id,
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
                childCount: combinedFeed.length,
              ),
            ),

          // Loading and empty states
          _buildEmptyOrLoadingState(isEmpty, isLoading, hasError, showCachedData),

          // Loading indicator for pagination
          if (isLoadingMore && combinedFeed.isNotEmpty)
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

  Widget _buildEmptyOrLoadingState(bool isEmpty, bool isLoading, bool hasError, bool showCachedData) {
    // Don't show loading state if we're showing cached data
    if (showCachedData) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

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
              Icon(
                Icons.article_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share something!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_post');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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