import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ViewModel/setprofileprovider.dart';
import 'package:image_picker/image_picker.dart';

class SetProfile extends ConsumerStatefulWidget {
  const SetProfile({super.key});

  @override
  ConsumerState<SetProfile> createState() => _SetProfileState();
}

class _SetProfileState extends ConsumerState<SetProfile> {
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;
  bool _isUploading = false; // Track upload state

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  File? _profileImage; // New selected image
  String? _profileImageUrl; // Current profile image URL from database

  @override
  void initState() {
    super.initState();
  }

  // Load user profile - following the same pattern as profile.dart
  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await ref.read(setProfileProvider.notifier).getUserProfile(user.id);

        // Populate fields after data is loaded
        final profileState = ref.read(setProfileProvider);
        profileState.whenData((profile) {
          if (profile != null) {
            _usernameController.text = profile.username;
            _userIdController.text = profile.userid;
            _schoolController.text = profile.study ?? '';
            _bioController.text = profile.bio ?? '';
            _locationController.text = profile.location ?? '';
            _roleController.text = profile.role ?? '';
            setState(() {
              _profileImageUrl = profile.profilePic;
            });
          }
        });

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

  // Refresh profile data - following the same pattern as profile.dart
  Future<void> _refreshProfile() async {
    setState(() {
      _isInitialized = false;
      _profileImage = null; // Reset selected image on refresh
    });
    await _loadUserProfile();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedImage != null) {
        setState(() {
          _profileImage = File(pickedImage.path);
        });
        print("Image selected: ${_profileImage?.path}");
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Error selecting image: $e', isError: true);
    }
  }

  // Upload profile image to Supabase Storage
  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      setState(() {
        _isUploading = true;
      });

      // Create unique filename
      final fileExtension = _profileImage!.path.split('.').last.toLowerCase();
      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '${user.id}/$fileName';

      // Delete old profile image if exists
      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        try {
          final oldFileName = _profileImageUrl!.split('/').last;
          final oldFilePath = '${user.id}/$oldFileName';
          await Supabase.instance.client.storage
              .from('avatars')
              .remove([oldFilePath]);
        } catch (e) {
          print('Warning: Could not delete old profile image: $e');
        }
      }

      // Upload new image
      final response = await Supabase.instance.client.storage
          .from('avatars')
          .upload(filePath, _profileImage!);

      if (response.isEmpty) {
        throw Exception('Upload failed - no response');
      }

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      print('Image uploaded successfully: $imageUrl');
      return imageUrl;

    } catch (e) {
      print('Error uploading image: $e');
      _showSnackBar('Failed to upload image: $e', isError: true);
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Save profile function
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showSnackBar('User not authenticated', isError: true);
        return;
      }

      String? finalImageUrl = _profileImageUrl; // Keep existing URL by default

      // Upload new image if selected
      if (_profileImage != null) {
        final uploadedUrl = await _uploadProfileImage();
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          _showSnackBar('Failed to upload image, but profile will be saved without image update', isError: true);
        }
      }

      // Save profile
      await ref.read(setProfileProvider.notifier).saveProfile(
        userid: user.id,
        username: _usernameController.text.trim(),
        email: user.email,
        role: _roleController.text.trim().isNotEmpty ? _roleController.text.trim() : null,
        profilePic: finalImageUrl,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        study: _schoolController.text.trim().isNotEmpty ? _schoolController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        isVerified: false,
      );

      // Update local state
      setState(() {
        _profileImageUrl = finalImageUrl;
        _profileImage = null; // Clear selected image after successful save
      });

      _showSnackBar('Profile saved successfully!', isError: false);

      // Optionally navigate back
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      String errorMessage = 'Failed to save profile';

      if (error is PostgrestException) {
        errorMessage = 'Database error: ${error.message}';
      } else if (error is AuthException) {
        errorMessage = 'Authentication error: ${error.message}';
      } else if (error is StorageException) {
        errorMessage = 'Storage error: ${error.message}';
      } else if (error is Exception) {
        errorMessage = error.toString();
      }

      _showSnackBar(errorMessage, isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Helper method to get the display image
  ImageProvider? _getDisplayImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(setProfileProvider);

    // Initialize profile loading if not done yet - same pattern as profile.dart
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserProfile();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Profile', style: TextStyle(color: Colors.grey)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.grey),
        actions: [
          // Add refresh button like in profile.dart
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: Colors.blue,
        backgroundColor: Colors.black,
        displacement: 40.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Show loading indicator if not initialized - same pattern as profile.dart
                  if (!_isInitialized && profileState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    ),

                  // Profile image section with upload indicator
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _profileImage != null ? Colors.blue : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.black,
                            backgroundImage: _getDisplayImage(),
                            child: _getDisplayImage() == null
                                ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                                : null,
                          ),
                        ),
                      ),
                      // Upload indicator overlay
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.7),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                          ),
                        ),
                      // Camera icon overlay for better UX
                      if (!_isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Image status text
                  if (_profileImage != null)
                    const Text(
                      'New image selected',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    )
                  else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    const Text(
                      'Current profile image',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    const Text(
                      'Tap to select profile image',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                  const SizedBox(height: 20),

                  // Username field
                  profileState.when(
                    data: (profile) => TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.blue),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    loading: () => TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Loading...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: TextStyle(color: Colors.blue),
                      enabled: false,
                    ),
                    error: (error, stack) => TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username (Error loading data)',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.blue),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Role field
                  profileState.when(
                    data: (profile) => TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role (Optional)',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.blue),
                    ),
                    loading: () =>  TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Loading...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: TextStyle(color: Colors.blue),
                      enabled: false,
                    ),
                    error: (error, stack) => TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role (Optional) - Error loading data',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // School field
                  profileState.when(
                    data: (profile) => TextFormField(
                      controller: _schoolController,
                      decoration: const InputDecoration(
                        labelText: 'School/College',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.blue),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your school or college';
                        }
                        return null;
                      },
                    ),
                    loading: () =>  TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Loading...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: TextStyle(color: Colors.blue),
                      enabled: false,
                    ),
                    error: (error, stack) => TextFormField(
                      controller: _schoolController,
                      decoration: const InputDecoration(
                        labelText: 'School/College - Error loading data',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.blue),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your school or college';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location field
                  profileState.when(
                    data: (profile) => TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.blue),
                    ),
                    loading: () => TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Loading...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: TextStyle(color: Colors.blue),
                      enabled: false,
                    ),
                    error: (error, stack) => TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional) - Error loading data',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bio field
                  profileState.when(
                    data: (profile) => TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.blue),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a short bio';
                        }
                        if (value.trim().length > 200) {
                          return 'Bio must be less than 200 characters';
                        }
                        return null;
                      },
                    ),
                    loading: () => TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Loading...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      style: TextStyle(color: Colors.blue),
                      maxLines: 3,
                      enabled: false,
                    ),
                    error: (error, stack) => TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio - Error loading data',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        labelStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.blue),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a short bio';
                        }
                        if (value.trim().length > 200) {
                          return 'Bio must be less than 200 characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Save button
                  profileState.when(
                    data: (profile) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        side: const BorderSide(width: 3.0, color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      onPressed: _isUploading ? null : _saveProfile,
                      child: _isUploading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    error: (error, stack) => Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error loading profile data',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            side: const BorderSide(width: 3.0, color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          ),
                          onPressed: _isUploading ? null : _saveProfile,
                          child: _isUploading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Save Profile',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _userIdController.dispose();
    _schoolController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _roleController.dispose();
    super.dispose();
  }
}