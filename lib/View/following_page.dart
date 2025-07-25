import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/user_profile.dart';
import 'widgets/Profile_card.dart';

// Following Page
class FollowingPage extends ConsumerStatefulWidget {
  const FollowingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends ConsumerState<FollowingPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;

  // Mock data - replace with your actual following data
  List<UserProfile> _following = [
    UserProfile(
      user_id: '5',
      username: 'tech_guru',
      profilePic: null,
      bio: 'Teaching the next generation of developers',
      study: 'Computer Science',
      location: 'Seattle, WA',
      followersCount: 15000,
      followingCount: 250,
      streakCount: 102,
      role: 'Tech Educator',
      isVerified: true,
    ),
    UserProfile(
      user_id: '6',
      username: 'design_master',
      profilePic: null,
      bio: 'Creating pixel-perfect designs',
      study: 'Graphic Design',
      location: 'Los Angeles, CA',
      followersCount: 8500,
      followingCount: 180,
      streakCount: 67,
      role: 'Senior Designer',
      isVerified: true,
    ),
    UserProfile(
      user_id: '7',
      username: 'ai_researcher',
      profilePic: null,
      bio: 'Exploring the frontiers of artificial intelligence',
      study: 'Machine Learning',
      location: 'Palo Alto, CA',
      followersCount: 3200,
      followingCount: 95,
      streakCount: 89,
      role: 'AI Researcher',
      isVerified: false,
    ),
  ];

  List<UserProfile> _filteredFollowing = [];

  @override
  void initState() {
    super.initState();
    _filteredFollowing = _following;
    _searchController.addListener(_onSearchChanged);
    _loadFollowing();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredFollowing = _following;
      } else {
        _filteredFollowing = _following
            .where((user) =>
        user.username.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (user.bio?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
            (user.role?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call to fetch following
    // final following = await ref.read(followingProvider.notifier).loadFollowing();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshFollowing() async {
    await _loadFollowing();
  }

  @override
  Widget build(BuildContext context) {
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
            hintText: 'Search following...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        )
            : const Text(
          'Following',
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
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filteredFollowing = _following;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFollowing,
        color: Colors.blue,
        backgroundColor: Colors.black,
        child: Column(
          children: [
            // Following count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_filteredFollowing.length} following',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),

            // Following list
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
                  : _filteredFollowing.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty
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
                      _searchController.text.isNotEmpty
                          ? 'Try a different search term'
                          : 'People you follow will appear here',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _filteredFollowing.length,
                itemBuilder: (context, index) {
                  final user = _filteredFollowing[index];
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
            ),
          ],
        ),
      ),
    );
  }
}