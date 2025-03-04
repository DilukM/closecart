import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class AuthService {
  final String baseUrl = "https://closecart-backend.vercel.app/api/v1/consumer/";

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

  Future<http.Response> signUp(String email, String password, String name, String phone) async {
    final url = Uri.parse('${baseUrl}signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name':name, 'phone':phone}),
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

  Future<http.Response> changePassword(String email, String oldPassword, String newPassword) async {
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
}