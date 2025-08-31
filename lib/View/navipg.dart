import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plaro_3/View/post_page.dart';
import 'home_page.dart';
import 'profile.dart';
import 'toast_page.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/user_feed_provider.dart';
import '../ViewModel/follow_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/user_profile.dart';
import 'byte_page.dart';
import 'byte_viewer.dart';
import '../View/course_page.dart';

void main() => runApp(MaterialApp(
  home: navCard(),
));

class navCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<navCard> createState() => _navCardState();
}

class _navCardState extends ConsumerState<navCard> {
  int _selectedIndex = 0;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user from Supabase
  User? get currentUser => _supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    // Don't load profile here - let OtherProfileScreen handle it
  }

  // Get the appropriate widget for each tab
  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return Container(); // Placeholder for create (won't be used due to modal)
      case 2:
        return ByteViewerPage();
      case 3:
        return NotificationsScreen();
      case 4:
        return _buildProfileScreen();
      default:
        return HomeScreen();
    }
  }

  // Build profile screen with proper error handling and loading states
  Widget _buildProfileScreen() {
    final user = currentUser;

    if (user == null) {
      return _buildAuthRequiredScreen();
    }

    // Pass null as userId to indicate this is the current user's profile
    // Don't pass initialUserData to force fresh loading
    return OtherProfileScreen(
      userId: null, // This indicates it's the current user's profile
      key: ValueKey('own_profile_${user.id}'), // Force rebuild when user changes
    );
  }

  // Build screen when user is not authenticated
  Widget _buildAuthRequiredScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              color: Colors.grey[400],
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Please log in to view profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                // You can implement this based on your app structure
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Show create modal instead of navigating
      _showCreateModal();
    } else {
      // Clear profile-related state when navigating to profile tab
      if (index == 3) {
        _clearProfileState();
      }

      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Clear profile state to ensure fresh data when switching to profile tab
  void _clearProfileState() {
    // Clear profile provider
    ref.read(setProfileProvider.notifier).clearProfile();
    // Clear feed provider
    ref.read(profileFeedProvider.notifier).clearFeed();
    // Clear follow provider
    ref.read(followProvider.notifier).clear();
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7), // Blur effect
      isScrollControlled: true,
      builder: (context) => CreateModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 0.0,
      ),
      body: _getPageForIndex(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 3.0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        iconSize: 20.0,
        backgroundColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Create'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Bytes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile'
          ),
        ],
      ),
    );
  }
}

// Create Modal Sheet Widget
class CreateModalSheet extends StatefulWidget {
  @override
  _CreateModalSheetState createState() => _CreateModalSheetState();
}

class _CreateModalSheetState extends State<CreateModalSheet> {
  int _selectedIndex = 0;
  final List<String> _options = ['Text', 'Post', 'Byte', 'Course'];

  void _onOptionSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _navigateToPage(index);
  }

  void _navigateToPage(int index) {
    // Close modal first
    Navigator.pop(context);

    // Handle navigation based on selection
    switch (index) {
      case 0: // Text
        Navigator.push(context,
            MaterialPageRoute(builder:  (context) =>  ToastPage()));
        break;
      case 1: // Post
        Navigator.push(context,
            MaterialPageRoute(builder:  (context) =>  PostCreateScreen()));
        break;
      case 2: // Byte
        Navigator.push(context,
            MaterialPageRoute(builder:  (context) =>  ByteCreateScreen()));
        break;
      case 3: // Course
        Navigator.push(context,
            MaterialPageRoute(builder:  (context) =>  CourseCreateScreen()));
        break;;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      height: screenHeight * 0.23, // Takes up 23% of screen height
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Bottom Section with Options
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Options Row
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      _options.length,
                          (index) => Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: GestureDetector(
                          onTap: () => _onOptionSelected(index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Option Icon
                              Container(
                                width: isTablet ? 60 : 50,
                                height: isTablet ? 60 : 50,
                                decoration: BoxDecoration(
                                  color: _selectedIndex == index
                                      ? Colors.blue
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedIndex == index
                                        ? Colors.blue
                                        : Colors.grey[700]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getOptionIcon(index),
                                  color: _selectedIndex == index
                                      ? Colors.white
                                      : Colors.grey[400],
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Option Label
                              Text(
                                _options[index],
                                style: TextStyle(
                                  color: _selectedIndex == index
                                      ? Colors.blue
                                      : Colors.grey[400],
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: _selectedIndex == index
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Selected Option Indicator
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Row(
                    children: List.generate(
                      _options.length,
                          (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            color: _selectedIndex == index
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getOptionIcon(int index) {
    switch (index) {
      case 0: // Text
        return Icons.text_fields;
      case 1: // Post
        return Icons.add_box_outlined;
      case 2: // Byte
        return Icons.video_library_outlined;
      case 3: // Course
        return Icons.school_outlined;
      default:
        return Icons.add;
    }
  }
}

// NotificationsScreen remains the same
class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreen();
}

class _NotificationsScreen extends State<NotificationsScreen> {
  Widget Noti_card(noticard) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade900.withOpacity(0.7),
            blurRadius: 5.0,
            spreadRadius: 2.0,
            offset: const Offset(0.0, 1.0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/plaro_logo.png'),
                radius: 15.0,
              ),
              SizedBox(width: 13.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 20.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 3.0),
                  Text("Note",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: 30.0),
          Text("Time",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.0,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        scrollDirection: Axis.vertical,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 400,
                  height: 53,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade900.withOpacity(0.7),
                        blurRadius: 5.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0.0, 1.0),
                      ),
                    ],
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "baan_kai_",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 20.0,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}