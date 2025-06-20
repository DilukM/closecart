import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:closecart/models/user_model.dart';

class AuthService {
  final String baseUrl =
      "https://closecart-backend.vercel.app/api/v1/consumer/";

  Future<http.Response> signIn(String email, String password) async {
    final url = Uri.parse('${baseUrl}signin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final token = responseBody['token'];
      var box = Hive.box('authBox');
      box.put('jwtToken', token);
    }

    return response;
  }

  Future<http.Response> signUp(
      String email, String password, String name, String phone) async {
    final url = Uri.parse('${baseUrl}signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'email': email, 'password': password, 'name': name, 'phone': phone}),
    );
    return response;
  }

  Future<http.Response> forgetPassword(String email) async {
    final url = Uri.parse('${baseUrl}forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response;
  }

  Future<http.Response> changePassword(
      String email, String oldPassword, String newPassword) async {
    final url = Uri.parse('${baseUrl}change-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    return response;
  }

  Future<UserModel> fetchProfileData() async {
    var box = Hive.box('authBox');
    var jwt = box.get('jwtToken');
    final jwtToken = JWT.decode(jwt);
    final userId = jwtToken.payload['id'];
    final url = Uri.parse('${baseUrl}$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Profile data fetched successfully: $responseBody');

      final userData = responseBody['data'];
      final userModel = UserModel.fromJson(userData);

      // Store both raw data and user model
      box.put('profileData', userData);
      box.put('userModel', userModel.toMap());

      return userModel;
    } else {
      throw Exception('Failed to load profile data');
    }
  }

  // Get the current user from local storage
  UserModel? getCurrentUser() {
    var box = Hive.box('authBox');
    final userData = box.get('userModel');

    if (userData != null) {
      return UserModel.fromMap(Map<String, dynamic>.from(userData));
    }
    return null;
  }

  // Update user profile with specified fields
  Future<UserModel> updateProfile(Map<String, dynamic> updateData) async {
    var box = Hive.box('authBox');
    var jwt = box.get('jwtToken');

    if (jwt == null) {
      throw Exception('Not authenticated');
    }

    final jwtToken = JWT.decode(jwt);
    final userId = jwtToken.payload['id'];
    final url = Uri.parse('${baseUrl}$userId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final updatedUserData = responseBody['data'];
      final updatedUser = UserModel.fromJson(updatedUserData);

      // Update local storage
      box.put('profileData', updatedUserData);
      box.put('userModel', updatedUser.toMap());

      return updatedUser;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }
}
