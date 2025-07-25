import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/user_profile.dart';
import 'widgets/Profile_card.dart';

// Followers Page
class FollowersPage extends ConsumerStatefulWidget {
  const FollowersPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends ConsumerState<FollowersPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;

  // Mock data - replace with your actual followers data
  List<UserProfile> _followers = [
    UserProfile(
      user_id: '1',
      username: 'john_doe',
      profilePic: null,
      bio: 'Flutter developer and coffee enthusiast',
      study: 'Computer Science',
      location: 'New York, NY',
      followersCount: 250,
      followingCount: 180,
      streakCount: 15,
      role: 'Developer',
      isVerified: true,
    ),
    UserProfile(
      user_id: '2',
      username: 'jane_smith',
      profilePic: null,
      bio: 'Designer who loves creating beautiful UIs',
      study: 'Design',
      location: 'San Francisco, CA',
      followersCount: 420,
      followingCount: 95,
      streakCount: 8,
      role: 'UI/UX Designer',
      isVerified: false,
    ),
    UserProfile(
      user_id: '3',
      username: 'mike_wilson',
      profilePic: null,
      bio: 'Student at MIT, passionate about AI',
      study: 'Artificial Intelligence',
      location: 'Boston, MA',
      followersCount: 89,
      followingCount: 156,
      streakCount: 23,
      role: 'Student',
      isVerified: false,
    ),
    UserProfile(
      user_id: '4',
      username: 'sarah_code',
      profilePic: null,
      bio: 'Full-stack developer building the future',
      study: 'Software Engineering',
      location: 'Austin, TX',
      followersCount: 312,
      followingCount: 200,
      streakCount: 45,
      role: 'Full Stack Developer',
      isVerified: true,
    ),
  ];

  List<UserProfile> _filteredFollowers = [];

  @override
  void initState() {
    super.initState();
    _filteredFollowers = _followers;
    _searchController.addListener(_onSearchChanged);
    _loadFollowers();
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
        _filteredFollowers = _followers;
      } else {
        _filteredFollowers = _followers
            .where((user) =>
        user.username.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (user.bio?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
            (user.role?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call to fetch followers
    // final followers = await ref.read(followersProvider.notifier).loadFollowers();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshFollowers() async {
    await _loadFollowers();
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
            hintText: 'Search followers...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        )
            : const Text(
          'Followers',
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
                  _filteredFollowers = _followers;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFollowers,
        color: Colors.blue,
        backgroundColor: Colors.black,
        child: Column(
          children: [
            // Followers count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_filteredFollowers.length} followers',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),

            // Followers list
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
                  : _filteredFollowers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty
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
                      _searchController.text.isNotEmpty
                          ? 'Try a different search term'
                          : 'Followers will appear here',
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
                itemCount: _filteredFollowers.length,
                itemBuilder: (context, index) {
                  final user = _filteredFollowers[index];
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