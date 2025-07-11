import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/auth_provider.dart';
import '../ViewModel//toast_feed_provider.dart';
import 'widgets/toast_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(toastFeedProvider.notifier).loadMorePosts();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await ref.read(setProfileProvider.notifier).getUserProfile(user.id);
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      //print('Error loading profile: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider).logout();

      // Show success message
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
      // Show error message
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
    await ref.read(toastFeedProvider.notifier).refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);
    final toastFeedState = ref.watch(toastFeedProvider);

    // Initialize profile loading if not done yet
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search functionality coming soon')),
                    );
                  },
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: () {
                    // Navigate to create post screen
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
                leading: const Icon(Icons.home, color: Colors.grey),
                title: const Text(
                  'Compete',
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

          // Load posts when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (toastFeedState.posts.isEmpty && !toastFeedState.isLoading) {
              ref.read(toastFeedProvider.notifier).loadPosts();
            }
          });

          return RefreshIndicator(
            onRefresh: _refreshFeed,
            backgroundColor: Colors.grey[900],
            color: Colors.white,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Error handling
                if (toastFeedState.error != null)
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
                              toastFeedState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(toastFeedProvider.notifier).clearError();
                              ref.read(toastFeedProvider.notifier).loadPosts();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Posts list
                if (toastFeedState.posts.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final post = toastFeedState.posts[index];
                        return ToastCard(
                          toast: post,
                          onTap: () {
                            // // Navigate to post details
                            // Navigator.pushNamed(
                            //   context,
                            //   '/post_details',
                            //   arguments: post,
                            // );
                          },
                        );
                      },
                      childCount: toastFeedState.posts.length,
                    ),
                  ),

                // Loading indicator for initial load
                if (toastFeedState.posts.isEmpty && toastFeedState.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                      ),
                    ),
                  ),

                // Empty state
                if (toastFeedState.posts.isEmpty && !toastFeedState.isLoading && toastFeedState.error == null)
                  SliverFillRemaining(
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
                  ),

                // Loading indicator for pagination
                if (toastFeedState.isLoading && toastFeedState.posts.isNotEmpty)
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

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          );
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
}