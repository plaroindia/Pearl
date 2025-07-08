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

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  File? _profileImage;
  String? _profileImageUrl;

  @override
  void initState(){
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
            _profileImageUrl = profile.profilePic;
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
    });
    await _loadUserProfile();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
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

      // TODO: Upload profile image to Supabase Storage if needed
      String? uploadedImageUrl;

      if (_profileImage != null) {
        uploadedImageUrl = await _uploadProfileImage();
      }

      await ref.read(setProfileProvider.notifier).saveProfile(
        userid: user.id,
        username: _usernameController.text.trim(),
        email: user.email,
        role: _roleController.text.trim().isNotEmpty ? _roleController.text.trim() : null,
        profilePic: uploadedImageUrl,// _profileImageUrl, // Use uploaded image URL
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        study: _schoolController.text.trim().isNotEmpty ? _schoolController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        isVerified: false,
      );

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
      } else if (error is Exception) {
        errorMessage = error.toString();
      }

      _showSnackBar(errorMessage, isError: true);
    }
  }

  // Upload profile image to Supabase Storage
  Future<String?> _uploadProfileImage() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _profileImage == null) return null;

      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profiles/$fileName';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(filePath, _profileImage!);

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
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

                  // Profile image section
                  profileState.when(
                    data: (profile) => GestureDetector(
                      onTap:  _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.black,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : profile?.profilePic != null
                            ? NetworkImage(profile!.profilePic!)
                            : const AssetImage('assets/plaro_logo.png') as ImageProvider,
                        child: _profileImage == null && profile?.profilePic == null
                            ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    loading: () => const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    error: (error, stack) => GestureDetector(
                      onTap: _pickImage, // _pickImage,
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.black,
                        backgroundImage: AssetImage('assets/plaro_logo.png'),
                        child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      ),
                    ),
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
                      onPressed: _saveProfile,
                      child: const Text(
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
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error loading profile data',
                                  style: const TextStyle(color: Colors.red),
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
                          onPressed: _saveProfile,
                          child: const Text(
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