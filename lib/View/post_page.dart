import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../ViewModel/post_provider.dart';

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

  final List<String> _options = ['Text', 'Photo', 'Video', 'Course'];

  // Controllers for text inputs
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

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
    _titleController.dispose();
    _contentController.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final postCreateState = ref.watch(postCreateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header with tabs
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: postCreateState.isLoading ? null : _createPost,
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: postCreateState.isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: _options.map((option) => Tab(text: option)).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content based on selected tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(isTablet),
                _buildPhotoTab(isTablet),
                _buildVideoTab(isTablet),
                _buildCourseTab(isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab(bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title input
          _buildInputField(
            controller: _titleController,
            label: 'Title',
            hint: 'Enter post title...',
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Content input
          _buildInputField(
            controller: _contentController,
            label: 'Content',
            hint: 'What\'s on your mind?',
            maxLines: 8,
          ),
          const SizedBox(height: 16),

          // Tags input
          _buildInputField(
            controller: _tagsController,
            label: 'Tags',
            hint: 'Enter tags separated by commas...',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Selected tags display
          if (_getTagsFromInput().isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _getTagsFromInput().map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoTab(bool isTablet) {
    final postCreateState = ref.watch(postCreateProvider);

    return Column(
      children: [
        // Selected media preview
        if (postCreateState.selectedMedia.isNotEmpty)
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: postCreateState.selectedMedia.length,
              itemBuilder: (context, index) {
                final media = postCreateState.selectedMedia[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(media.path),
                          fit: BoxFit.cover,
                          width: 150,
                          height: 200,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(postCreateProvider.notifier).removeMedia(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Photo action buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(postCreateProvider.notifier).pickMedia(fromCamera: false);
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(postCreateProvider.notifier).pickMedia(fromCamera: true);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Caption input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildInputField(
            controller: _captionController,
            label: 'Caption',
            hint: 'Write a caption...',
            maxLines: 3,
          ),
        ),

        const SizedBox(height: 16),

        // Recent Photos Grid
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Recent Photos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                          // Handle photo selection from recent photos
                          _selectRecentPhoto(_recentPhotos[index]);
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
    );
  }

  Widget _buildVideoTab(bool isTablet) {
    final postCreateState = ref.watch(postCreateProvider);

    return Column(
      children: [
        // Selected video preview
        if (postCreateState.selectedMedia.isNotEmpty)
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: postCreateState.selectedMedia.length,
              itemBuilder: (context, index) {
                final media = postCreateState.selectedMedia[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 150,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(postCreateProvider.notifier).removeMedia(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Video action buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(postCreateProvider.notifier).pickVideo(fromCamera: false);
                  },
                  icon: const Icon(Icons.video_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(postCreateProvider.notifier).pickVideo(fromCamera: true);
                  },
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Caption input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildInputField(
            controller: _captionController,
            label: 'Caption',
            hint: 'Write a caption...',
            maxLines: 3,
          ),
        ),

        const Spacer(),
      ],
    );
  }

  Widget _buildCourseTab(bool isTablet) {
    return const Center(
      child: Text(
        'Course creation coming soon',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getTagsFromInput() {
    if (_tagsController.text.isEmpty) return [];
    return _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  void _selectRecentPhoto(String photoUrl) {
    // For now, just show a message. In a real app, you'd convert this to XFile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recent photo selection not implemented yet'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createPost() async {
    // Update the provider with current text values
    ref.read(postCreateProvider.notifier).updateTitle(_titleController.text);
    ref.read(postCreateProvider.notifier).updateContent(_contentController.text);
    ref.read(postCreateProvider.notifier).updateCaption(_captionController.text);
    ref.read(postCreateProvider.notifier).updateTags(_getTagsFromInput());

    final success = await ref.read(postCreateProvider.notifier).createPost();

    if (success) {
      // Clear form
      _titleController.clear();
      _contentController.clear();
      _captionController.clear();
      _tagsController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to feed
      Navigator.pop(context);
    } else {
      // Error handling is done in the provider
      final error = ref.read(postCreateProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}