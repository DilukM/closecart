import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class ImageUploadService {
  /// Pick an image from gallery or camera
  static Future<File?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Show an image picker dialog with options for gallery or camera
  static Future<File?> showImagePickerDialog(BuildContext context) async {
    ImageSource? selectedSource = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Image Source',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('Camera'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );

    if (selectedSource == null) {
      print('No source selected.');
      return null;
    }

    File? image = await pickImage(selectedSource);

    if (image == null) {
      print('No image selected.');
    } else {
      print('Image selected successfully.');
    }

    return image;
  }

  /// Upload profile image to the server
  static Future<Map<String, dynamic>> uploadProfileImage(
      File imageFile, String userId) async {
    try {
      var box = Hive.box('authBox');
      var jwt = box.get('jwtToken');

      if (jwt == null) {
        throw Exception('Authentication token not found');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://closecart-backend.vercel.app/api/v1/consumer/upload-image/$userId'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $jwt',
      });

      // Determine file type
      String fileExtension = path.extension(imageFile.path).toLowerCase();
      String contentType;

      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      // Add file to request
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'profileImage', // Field name expected by the server
        stream,
        length,
        filename: path.basename(imageFile.path),
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedData = jsonDecode(responseData);

      print('Response status: ${response.statusCode}');
      print('Response body: $decodedData');

      if (response.statusCode == 200) {
        // Update the profile data in Hive with new image URL
        var profileData = box.get('profileData');
        if (profileData != null && profileData is Map) {
          profileData['imageUrl'] = decodedData['data']['imageUrl'];
          box.put('profileData', profileData);
        }

        return {
          'success': true,
          'imageUrl': decodedData['data']['imageUrl'],
          'message': 'Profile image updated successfully'
        };
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Failed to upload image'
        };
      }
    } catch (error) {
      print('Error uploading image: $error');
      return {'success': false, 'message': error.toString()};
    }
  }
}
