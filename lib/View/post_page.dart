import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostCreateScreen extends ConsumerStatefulWidget {
  const PostCreateScreen({super.key});

  @override
  ConsumerState<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends ConsumerState<PostCreateScreen>
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ),
                    ),
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
                  ],
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
        ],
      ),
    );
  }
}