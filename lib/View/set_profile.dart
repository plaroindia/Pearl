import 'dart:io';
import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';

class SetProfile extends StatefulWidget {
  const SetProfile({super.key});

  @override
  _SetProfileState createState() => _SetProfileState();
}

class _SetProfileState extends State<SetProfile> {
 // User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _profileImage;
  bool _isLoading = false;

  // // Pick image from gallery
  // Future<void> _pickImage() async {
  //   final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (pickedImage != null) {
  //     setState(() {
  //       _profileImage = File(pickedImage.path);
  //     });
  //   }
  // }
  //
  // // Save user details to Firebase
  // Future<void> _saveProfile() async {
  //   if (_formKey.currentState!.validate()) {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //
  //     try {
  //       // Upload profile picture to Firebase Storage
  //       final metadata = SettableMetadata(
  //         cacheControl: 'public,max-age=300',
  //         contentType: 'image/jpeg',
  //       );
  //       String? profileImageUrl;
  //       if (_profileImage != null) {
  //         final storageRef = FirebaseStorage.instance
  //             .ref()
  //             .child('profile_images/${FirebaseAuth.instance.currentUser!.uid}.jpg');
  //         await storageRef.putFile(_profileImage!, metadata);
  //         profileImageUrl = await storageRef.getDownloadURL();
  //       }
  //
  //       // Save user details to Firestore
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(FirebaseAuth.instance.currentUser!.uid)
  //           .update({
  //         // 'email': user!.email,
  //         // 'uid': user!.uid,
  //         'username': _usernameController.text,
  //         'userId': _userIdController.text,
  //         'school': _schoolController.text,
  //         'bio': _bioController.text,
  //         'profileImageUrl': profileImageUrl ?? '',
  //       });
  //
  //       QuerySnapshot feedSnapshot = await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(user!.uid)  // Ensure user is logged in and user!.uid is not null
  //           .collection('feeds')
  //           .get();
  //
  //       for (var doc in feedSnapshot.docs) {
  //         await doc.reference.update({
  //           'username': _usernameController.text,
  //           'prof_pic': profileImageUrl ?? '',
  //         });
  //       }
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Profile updated successfully!')),
  //       );
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to update profile: $e')),
  //       );
  //     } finally {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Profile',style: TextStyle(color: Colors.grey),),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.grey),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap:(){},// _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.black,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/default_profile.png')
                    as ImageProvider,
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username',
                      border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.blue),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(labelText: 'Custom User ID',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.blue),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a unique User ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _schoolController,
                  decoration: const InputDecoration(labelText: 'School/College',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.blue),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your school or college';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.blue),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a short bio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      side: const BorderSide(width: 3.0, color: Colors.blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0))
                  ),
                  onPressed:(){},// _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
