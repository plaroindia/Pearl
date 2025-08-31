// course_create_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../ViewModel/course_provider.dart';
import '../ViewModel/auth_provider.dart';

class CourseCreateScreen extends ConsumerStatefulWidget {
  const CourseCreateScreen({super.key});

  @override
  ConsumerState<CourseCreateScreen> createState() => _CourseCreateScreenState();
}

class _CourseCreateScreenState extends ConsumerState<CourseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  String? _selectedCategory;
  File? _thumbnailFile;
  final List<VideoUpload> _videos = [];
  bool _isCreating = false;
  String? _error;

  final List<String> _categories = [
    'Programming',
    'Design',
    'Business',
    'Data Science',
    'Marketing',
    'Photography',
    'Music',
    'Health & Fitness',
    'Language Learning',
    'Personal Development',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();

    // Dispose video controllers
    for (final video in _videos) {
      video.controller?.dispose();
    }

    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 30), // 30 minute limit for course videos
    );

    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);
      final controller = VideoPlayerController.file(videoFile);

      await controller.initialize();

      setState(() {
        _videos.add(VideoUpload(
          file: videoFile,
          controller: controller,
          title: 'Video ${_videos.length + 1}',
          description: '',
        ));
      });
    }
  }

  Future<void> _recordVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 30),
    );

    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);
      final controller = VideoPlayerController.file(videoFile);

      await controller.initialize();

      setState(() {
        _videos.add(VideoUpload(
          file: videoFile,
          controller: controller,
          title: 'Video ${_videos.length + 1}',
          description: '',
        ));
      });
    }
  }

  void _showVideoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text('Record Video', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Max 30 minutes', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _recordVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.blue),
                title: const Text('Video Library', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Max 30 minutes', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _addVideo();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_videos.isEmpty) {
      setState(() {
        _error = 'Please add at least one video to the course';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final notifier = ref.read(courseFeedProvider.notifier);

      // Upload thumbnail if selected
      String? thumbnailUrl;
      if (_thumbnailFile != null) {
        final thumbnailBytes = await _thumbnailFile!.readAsBytes();
        final fileName = 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
        thumbnailUrl = await notifier.uploadThumbnail(thumbnailBytes, fileName);
      }

      // Create the course
      final course = await notifier.createCourse(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        thumbnailUrl: thumbnailUrl,
        category: _selectedCategory,
      );

      if (course != null) {
        // Upload videos
        for (int i = 0; i < _videos.length; i++) {
          final video = _videos[i];
          final videoBytes = await video.file.readAsBytes();
          final fileName = 'video_${course.courseId}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

          final videoUrl = await notifier.uploadVideo(videoBytes, fileName);

          if (videoUrl != null) {
            await notifier.addVideoToCourse(
              courseId: course.courseId,
              title: video.title,
              description: video.description.isEmpty ? null : video.description,
              videoUrl: videoUrl,
              duration: video.controller?.value.duration,
              position: i + 1,
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _error = 'Failed to create course. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error creating course: $e';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _removeVideo(int index) {
    setState(() {
      _videos[index].controller?.dispose();
      _videos.removeAt(index);

      // Update video titles
      for (int i = 0; i < _videos.length; i++) {
        if (_videos[i].title == 'Video ${i + 2}') {
          _videos[i].title = 'Video ${i + 1}';
        }
      }
    });
  }

  void _editVideoDetails(int index) {
    final video = _videos[index];
    final titleController = TextEditingController(text: video.title);
    final descController = TextEditingController(text: video.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Video Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Video Title',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Video Description (Optional)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _videos[index].title = titleController.text.trim();
                _videos[index].description = descController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _titleController.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _videos.isNotEmpty &&
        !_isCreating;

    // Show error messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => setState(() => _error = null),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Course',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: canCreate ? _createCourse : null,
            child: _isCreating
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
            )
                : Text(
              'Create',
              style: TextStyle(
                color: canCreate ? Colors.blue : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Title
              const Text(
                'Course Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _titleFocusNode.hasFocus ? Colors.blue : Colors.grey[700]!,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Course title',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a course title';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
              ),

              const SizedBox(height: 16),

              // Course Description
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _descriptionFocusNode.hasFocus ? Colors.blue : Colors.grey[700]!,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Course description (optional)',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
              ),

              const SizedBox(height: 16),

              // Category Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Select category',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  dropdownColor: Colors.grey[800],
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Thumbnail Section
              const Text(
                'Course Thumbnail',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: _thumbnailFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add thumbnail',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommended: 1920x1080px',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                      : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _thumbnailFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => setState(() => _thumbnailFile = null),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Videos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Course Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showVideoOptions,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Videos List
              if (_videos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos added yet',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add videos to make your course engaging',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _videos.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _videos.removeAt(oldIndex);
                      _videos.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return VideoListItem(
                      key: ValueKey(video.file.path),
                      video: video,
                      index: index,
                      onEdit: () => _editVideoDetails(index),
                      onRemove: () => _removeVideo(index),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Tips section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tips_and_updates, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for great courses',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Create clear, descriptive titles'),
                    _buildTip('Organize videos in logical order'),
                    _buildTip('Keep videos focused on specific topics'),
                    _buildTip('Add engaging thumbnails and descriptions'),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoUpload {
  String title;
  String description;
  final File file;
  VideoPlayerController? controller;

  VideoUpload({
    required this.title,
    required this.description,
    required this.file,
    this.controller,
  });
}

class VideoListItem extends StatefulWidget {
  final VideoUpload video;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const VideoListItem({
    super.key,
    required this.video,
    required this.index,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  State<VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<VideoListItem> {
  @override
  Widget build(BuildContext context) {
    final duration = widget.video.controller?.value.duration;
    final durationText = duration != null
        ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : 'Loading...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.video.controller?.value.isInitialized == true
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: widget.video.controller!.value.aspectRatio,
                  child: VideoPlayer(widget.video.controller!),
                ),
              )
                  : Icon(
                Icons.video_file,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        title: Text(
          widget.video.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.video.description.isNotEmpty)
              Text(
                widget.video.description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              'Duration: $durationText',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            ),
          ],
        ),
        isThreeLine: widget.video.description.isNotEmpty,
      ),
    );
  }
}