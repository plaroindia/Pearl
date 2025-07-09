import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  int _selectedIndex = 0;

  final List<String> _options = ['Text', 'Post', 'Byte', 'Course'];

  // Mock recent photos - replace with actual user photos
  final List<String> _recentPhotos = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=300&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _options.length, vsync: this);
    _scrollController = ScrollController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onOptionSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _tabController.animateTo(index);

    // Handle navigation to different pages based on selection
    _navigateToPage(index);
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0: // Text
       // _showComingSoon('Text Creation');
        break;
      case 1: // Post
       // _showComingSoon('Post Creation');
        break;
      case 2: // Byte
        //_showComingSoon('Byte Creation');
        break;
      case 3: // Course
        //_showComingSoon('Course Creation');
        break;
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Recent Photos Section
          Container(
            height: screenHeight * 0.7, // Fixed height instead of Expanded
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add status bar padding
                SizedBox(height: MediaQuery.of(context).padding.top),

                // Header with recent photos title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Recent Photos',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: isTablet ? 20 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Photo Grid
                Expanded(
                  child: _recentPhotos.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: isTablet ? 80 : 60,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recent photos',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 4 : 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _recentPhotos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Handle photo selection
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Photo ${index + 1} selected'),
                                backgroundColor: Colors.blue,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[900],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _recentPhotos[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                      size: isTablet ? 40 : 30,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Section with Back Button and Options
          Expanded(
            child: Container(
              height: screenHeight * 0.1, // Fixed height instead of Expanded
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Back Button Row
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // GestureDetector(
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //   },
                        //   child: Container(
                        //     padding: const EdgeInsets.all(8),
                        //     decoration: BoxDecoration(
                        //       color: Colors.black,
                        //       borderRadius: BorderRadius.circular(12),
                        //       border: Border.all(
                        //         color: Colors.grey[700]!,
                        //         width: 1,
                        //       ),
                        //     ),
                        //     child: Icon(
                        //       Icons.arrow_back_ios,
                        //       color: Colors.grey[400],
                        //       size: isTablet ? 24 : 20,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(width: 16),
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

                  // Options Row (Instagram-like filter style)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Scrollable Options
                        Expanded(
                          child: Row(
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
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
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
                                    borderRadius: BorderRadius.circular(4),
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