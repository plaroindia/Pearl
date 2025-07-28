import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/user_profile.dart';
import '../ViewModel/follow_provider.dart';
import 'widgets/Profile_card.dart';

class FollowPage extends ConsumerStatefulWidget {
  final String userId; // The user whose followers/following we're viewing
  final int initialTab; // 0 for followers, 1 for following

  const FollowPage({
    Key? key,
    required this.userId,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  ConsumerState<FollowPage> createState() => _FollowPageState();
}

class _FollowPageState extends ConsumerState<FollowPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _followersScrollController = ScrollController();
  final ScrollController _followingScrollController = ScrollController();

  bool _isSearching = false;
  String _searchQuery = '';

  // Filtered lists for search
  List<UserProfile> _filteredFollowers = [];
  List<UserProfile> _filteredFollowing = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    _searchController.addListener(_onSearchChanged);
    _followersScrollController.addListener(_onFollowersScroll);
    _followingScrollController.addListener(_onFollowingScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _followersScrollController.dispose();
    _followingScrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final followNotifier = ref.read(followProvider.notifier);
    followNotifier.loadFollowers(widget.userId, refresh: true);
    followNotifier.loadFollowing(widget.userId, refresh: true);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _updateFilteredLists();
    });
  }

  void _updateFilteredLists() {
    final followState = ref.read(followProvider);

    if (_searchQuery.isEmpty) {
      _filteredFollowers = followState.followers;
      _filteredFollowing = followState.following;
    } else {
      _filteredFollowers = followState.followers.where((user) =>
      user.username.toLowerCase().contains(_searchQuery) ||
          (user.bio?.toLowerCase().contains(_searchQuery) ?? false) ||
          (user.role?.toLowerCase().contains(_searchQuery) ?? false)
      ).toList();

      _filteredFollowing = followState.following.where((user) =>
      user.username.toLowerCase().contains(_searchQuery) ||
          (user.bio?.toLowerCase().contains(_searchQuery) ?? false) ||
          (user.role?.toLowerCase().contains(_searchQuery) ?? false)
      ).toList();
    }
  }

  void _onFollowersScroll() {
    if (_followersScrollController.position.pixels >=
        _followersScrollController.position.maxScrollExtent - 200) {
      ref.read(followProvider.notifier).loadMoreFollowers(widget.userId);
    }
  }

  void _onFollowingScroll() {
    if (_followingScrollController.position.pixels >=
        _followingScrollController.position.maxScrollExtent - 200) {
      ref.read(followProvider.notifier).loadMoreFollowing(widget.userId);
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(followProvider.notifier).refresh(widget.userId);
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _updateFilteredLists();
      }
      _isSearching = !_isSearching;
    });
  }

  @override
  Widget build(BuildContext context) {
    final followState = ref.watch(followProvider);

    // Update filtered lists when provider state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateFilteredLists();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        )
            : const Text(
          'Connections',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.blue,
          indicatorWeight: 2,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Followers'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_searchQuery.isEmpty ? followState.followers.length : _filteredFollowers.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Following'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_searchQuery.isEmpty ? followState.following.length : _filteredFollowing.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Followers Tab
          _buildFollowersList(followState),
          // Following Tab
          _buildFollowingList(followState),
        ],
      ),
    );
  }

  Widget _buildFollowersList(FollowState followState) {
    if (followState.isLoadingFollowers && followState.followers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (followState.error != null && followState.followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading followers',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              followState.error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(followProvider.notifier).loadFollowers(widget.userId, refresh: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final displayList = _searchQuery.isEmpty ? followState.followers : _filteredFollowers;

    if (displayList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.blue,
        backgroundColor: Colors.black,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No followers found'
                        : 'No followers yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Followers will appear here',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.blue,
      backgroundColor: Colors.black,
      child: ListView.builder(
        controller: _followersScrollController,
        itemCount: displayList.length + (followState.hasMoreFollowers && _searchQuery.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayList.length) {
            // Loading indicator for pagination
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            );
          }

          final user = displayList[index];
          return ProfileCard(
            user: user,
            onTap: () {
              // Navigate to user profile
              print('Navigate to user profile: ${user.username}');
              // Navigator.pushNamed(context, '/user_profile', arguments: user);
            },
          );
        },
      ),
    );
  }

  Widget _buildFollowingList(FollowState followState) {
    if (followState.isLoadingFollowing && followState.following.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (followState.error != null && followState.following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading following',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              followState.error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(followProvider.notifier).loadFollowing(widget.userId, refresh: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final displayList = _searchQuery.isEmpty ? followState.following : _filteredFollowing;

    if (displayList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.blue,
        backgroundColor: Colors.black,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No users found'
                        : 'Not following anyone yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'People you follow will appear here',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.blue,
      backgroundColor: Colors.black,
      child: ListView.builder(
        controller: _followingScrollController,
        itemCount: displayList.length + (followState.hasMoreFollowing && _searchQuery.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayList.length) {
            // Loading indicator for pagination
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            );
          }

          final user = displayList[index];
          return ProfileCard(
            user: user,
            onTap: () {
              // Navigate to user profile
              print('Navigate to user profile: ${user.username}');
              // Navigator.pushNamed(context, '/user_profile', arguments: user);
            },
          );
        },
      ),
    );
  }
}