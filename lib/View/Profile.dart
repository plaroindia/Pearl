import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'set_profile.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends ConsumerState<ProfileScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  // Load user profile
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
      print('Error loading profile: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  // Refresh profile data
  Future<void> _refreshProfile() async {
    setState(() {
      _isInitialized = false;
    });
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);

    // Initialize profile loading if not done yet
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserProfile();
      });
    }

    return Center(
      child: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: Colors.blue,
        backgroundColor: Colors.black,
        displacement: 40.0,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            Padding(
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

                  const SizedBox(height: 6.0),

                  // Posts section header
                  const Row(
                    children: [
                      Icon(
                        Icons.view_array_outlined,
                        color: Colors.grey,
                        size: 40.0,
                      ),
                      SizedBox(width: 6.0),
                      Text(
                        "Your Posts :",
                        style: TextStyle(color: Colors.grey, fontSize: 20.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  const Divider(
                    height: 1.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10.0),

                  // Posts grid (placeholder for now)
                  Container(
                    height: 200,
                    child: const Center(
                      child: Text(
                        'No posts yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),



                ],
              ),
            ),
          ],
        ),
      ),
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