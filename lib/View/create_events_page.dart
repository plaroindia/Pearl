import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../ViewModel/auth_provider.dart';
import '../ViewModel/setProfileProvider.dart';
import '../ViewModel/event_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();

  String? _selectedCategory;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  DateTime? _registrationDeadline;
  File? _bannerImage;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  final List<String> _categories = [
    'Technology',
    'Business',
    'Arts & Culture',
    'Sports',
    'Education',
    'Health & Wellness',
    'Social',
    'Music',
    'Gaming',
    'Other'
  ];

  @override
  void initState() {
    super.initState();

    // Load user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(authStateProvider).value;
      if (session != null) {
        ref.read(setProfileProvider.notifier).getUserProfile(session.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _showImagePicker() {
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
                  'Select Banner Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _bannerImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              surface: Colors.grey[900],
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              surface: Colors.grey[900],
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectRegistrationDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _startDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              surface: Colors.grey[900],
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _registrationDeadline = picked;
      });
    }
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return 'Select date';
    if (time == null) return '${date.day}/${date.month}/${date.year}';
    return '${date.day}/${date.month}/${date.year} at ${time.format(context)}';
  }

  Future<void> _handleCreateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _startTime == null) {
      _showErrorSnackBar('Please select start date and time');
      return;
    }

    if (_endDate == null || _endTime == null) {
      _showErrorSnackBar('Please select end date and time');
      return;
    }

    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Set banner image in provider BEFORE creating event
      if (_bannerImage != null) {
        ref.read(eventCreateProvider.notifier).setBannerImage(_bannerImage);
      }

      // Combine date and time
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Validate datetime logic
      if (endDateTime.isBefore(startDateTime)) {
        _showErrorSnackBar('End time must be after start time');
        return;
      }

      if (_registrationDeadline != null && _registrationDeadline!.isAfter(startDateTime)) {
        _showErrorSnackBar('Registration deadline must be before event start');
        return;
      }

      final success = await ref.read(eventCreateProvider.notifier).createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        location: _locationController.text,
        startTime: startDateTime,
        endTime: endDateTime,
        registrationDeadline: _registrationDeadline,
        latitude: _latitude,
        longitude: _longitude,
        contactName: _contactNameController.text.isNotEmpty ? _contactNameController.text : null,
        contactEmail: _contactEmailController.text.isNotEmpty ? _contactEmailController.text : null,
        contactPhone: _contactPhoneController.text.isNotEmpty ? _contactPhoneController.text : null,
      );

      // Simulate success for now
      // await Future.delayed(const Duration(seconds: 2));
      // final success = true;

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create event: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(setProfileProvider);

    final canPost = _titleController.text.isNotEmpty &&
        _selectedCategory != null &&
        _startDate != null &&
        _startTime != null &&
        _endDate != null &&
        _endTime != null &&
        !_isLoading;

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
          'Create Event',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: canPost ? _handleCreateEvent : null,
            child: _isLoading
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
                color: canPost ? Colors.blue : Colors.grey,
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
              // Banner Image Selection
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: _bannerImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add banner image (optional)',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showImagePicker,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _bannerImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _showImagePicker,
                            icon: const Icon(Icons.edit, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              shape: const CircleBorder(),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _bannerImage = null;
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.7),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Event Title
              _buildInputField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                label: 'Event Title',
                hint: 'Enter event title...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Event title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Event Description
              _buildInputField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                label: 'Description',
                hint: 'Describe your event...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Event description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category Selection
              _buildCategorySelector(),

              const SizedBox(height: 16),

              // Location
              _buildInputField(
                controller: _locationController,
                focusNode: _locationFocusNode,
                label: 'Location',
                hint: 'Event location...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Coordinates Section
              _buildSectionHeader('Event Coordinates (Optional)'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Latitude', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'e.g., 12.9716',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setState(() {
                              _latitude = double.tryParse(value);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Longitude', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'e.g., 77.5946',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setState(() {
                              _longitude = double.tryParse(value);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Date & Time Section
              _buildSectionHeader('Date & Time'),
              const SizedBox(height: 12),

              // Start Date & Time
              _buildDateTimeSelector(
                'Start Date & Time',
                _formatDateTime(_startDate, _startTime),
                    () async {
                  await _selectDate(context, true);
                  if (_startDate != null) {
                    await _selectTime(context, true);
                  }
                },
              ),

              const SizedBox(height: 12),

              // End Date & Time
              _buildDateTimeSelector(
                'End Date & Time',
                _formatDateTime(_endDate, _endTime),
                    () async {
                  await _selectDate(context, false);
                  if (_endDate != null) {
                    await _selectTime(context, false);
                  }
                },
              ),

              const SizedBox(height: 12),

              // Registration Deadline
              _buildDateTimeSelector(
                'Registration Deadline (optional)',
                _registrationDeadline != null
                    ? '${_registrationDeadline!.day}/${_registrationDeadline!.month}/${_registrationDeadline!.year}'
                    : 'Select deadline',
                    () => _selectRegistrationDeadline(context),
              ),

              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              const SizedBox(height: 12),

              _buildInputField(
                controller: _contactNameController,
                label: 'Contact Name',
                hint: 'Organizer name...',
              ),

              const SizedBox(height: 16),

              _buildInputField(
                controller: _contactEmailController,
                label: 'Contact Email',
                hint: 'contact@example.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              _buildInputField(
                controller: _contactPhoneController,
                label: 'Contact Phone',
                hint: '+91 12345 67890',
                keyboardType: TextInputType.phone,
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
                          'Tips for successful events',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Use clear, descriptive titles'),
                    _buildTip('Add detailed descriptions with agenda'),
                    _buildTip('Include contact information for queries'),
                    _buildTip('Set appropriate registration deadlines'),
                    _buildTip('Choose an attractive banner image'),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNode?.hasFocus == true ? Colors.blue : Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'Select category',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
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
      ],
    );
  }

  Widget _buildDateTimeSelector(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: TextStyle(
                    color: value.startsWith('Select') ? Colors.grey[600] : Colors.white,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
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