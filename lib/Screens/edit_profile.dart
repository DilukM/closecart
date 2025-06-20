import 'dart:io';

import 'package:closecart/services/imageUploadService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class EditProfilePage extends StatefulWidget {
  Map<dynamic, dynamic>? profileData;
  EditProfilePage({super.key, required this.profileData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  String _selectedGender = 'Male'; // Default value
  List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  bool _isLoading = false;
  DateTime? _selectedDate;
  String? _imageUrl;
  bool _isUploadingImage = false;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _nameController.text = widget.profileData!['name'];
    _emailController.text = widget.profileData!['email'];
    _phoneController.text = widget.profileData!['phone'].toString();
    _imageUrl = widget.profileData!['imageUrl'];

    // Initialize birthday and gender if they exist in profile data
    if (widget.profileData!['birthday'] != null) {
      try {
        // Parse ISO date format
        DateTime parsedDate = DateTime.parse(widget.profileData!['birthday']);
        _selectedDate = parsedDate;
        // Format the date to yyyy-MM-dd
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        // Handle parsing error
        print("Error parsing date: ${e.toString()}");
        _birthdayController.text = "";
      }
    }

    if (widget.profileData!['gender'] != null) {
      _selectedGender = widget.profileData!['gender'];
    }

    super.initState();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(
              const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleImageUpload() async {
    try {
      // Get user ID from JWT token
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) {
        throw Exception("Authentication token not found");
      }

      final jwtToken = JWT.decode(jwt);
      final userId = jwtToken.payload['id'];

      // Show image picker dialog
      final File? imageFile =
          await ImageUploadService.showImagePickerDialog(context);

      if (imageFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload the image
      final result =
          await ImageUploadService.uploadProfileImage(imageFile, userId);

      setState(() {
        _isUploadingImage = false;
      });

      if (result['success']) {
        setState(() {
          _imageUrl = result['imageUrl'];
          widget.profileData!['imageUrl'] = result['imageUrl'];
        });

        // Show success message
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text('Profile picture updated'),
          description:
              Text('Your profile picture has been updated successfully'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      } else {
        // Show error message
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text('Upload failed'),
          description: Text(result['message']),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    } catch (error) {
      setState(() {
        _isUploadingImage = false;
      });

      // Show error message
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text('Error'),
        description: Text(error.toString()),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  // Modify the Profile Image Stack to include image upload functionality
  Widget _buildProfileImageSection() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            image: _imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(_imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
                Theme.of(context).colorScheme.secondary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(60),
          ),
          child: _imageUrl == null
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: Theme.of(context).colorScheme.onPrimary,
                )
              : null,
        ),
        _isUploadingImage
            ? Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            : const SizedBox(),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.background,
                width: 2,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.camera_alt,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _isUploadingImage ? null : _handleImageUpload,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Profile Image with upload functionality
                      _buildProfileImageSection(),

                      const SizedBox(height: 40),

                      // Form Fields
                      _buildTextField(
                        context: context,
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        context: context,
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'Enter your email address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        context: context,
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Birthday Field
                      _buildDateField(
                        context: context,
                        controller: _birthdayController,
                        labelText: 'Birthday',
                        hintText: 'Select your birthday',
                        prefixIcon: Icons.cake_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Gender Field
                      _buildGenderSelector(context),
                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            labelText,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            labelText,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(context),
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Gender',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedGender,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              iconSize: 24,
              elevation: 16,
              style: Theme.of(context).textTheme.bodyLarge,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
              items: _genders.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Male'
                            ? Icons.male
                            : value == 'Female'
                                ? Icons.female
                                : Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the JWT token and user ID from Hive
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) {
        throw Exception("Authentication token not found");
      }

      // Decode the JWT token to get the user ID
      final jwtToken = JWT.decode(jwt);
      final userId = jwtToken.payload['id'];

      // Prepare updated user data
      final updatedUserData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'birthday': _birthdayController.text,
        'gender': _selectedGender,
        'imageUrl': _imageUrl,
      };

      // Make API request to update profile
      final response = await http.put(
        Uri.parse(
            'https://closecart-backend.vercel.app/api/v1/consumer/update-profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'userId': userId,
          ...updatedUserData,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Update local profile data
        final responseData = jsonDecode(response.body);

        // Update Hive cache with new profile data
        box.put('profileData', updatedUserData);

        // Show success message
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text('Profile updated successfully'),
          description: Text('Your profile has been updated'),
          autoCloseDuration: const Duration(seconds: 3),
        );

        // Return to settings page with updated data
        Navigator.pop(context, responseData['data']);
      } else {
        // Handle error response
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to update profile';

        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text('Update failed'),
          description: Text(errorMessage),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text('Error'),
        description: Text(error.toString()),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }
}
