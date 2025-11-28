import 'dart:convert';
import 'package:app_wallet/models/user_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this if using real device or deployed backend
  static const String baseUrl = "http://10.0.2.2:5000";

  // Register
  static Future<User?> register(
    String name,
    String email,
    String password, {
    String phone = '',
    String avatar = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'avatar': avatar,
      }),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['user'] != null) {
      return User.fromJson(body['user']);
    }
    return null;
  }

  // Login
  static Future<User?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['user'] != null) {
      return User.fromJson(body['user']);
    }
    return null;
  }

  // Fetch user by email
  static Future<User?> fetchUser(String email) async {
    final res = await http.get(Uri.parse('$baseUrl/user/$email'));
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // Update balance after payment (server expects amount in cents)
  static Future<User?> updateBalance(String email, int amountInCents) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payment-success'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'amount': amountInCents}),
    );
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // Send money (sender and receiver by phone or email depending on your backend)
  static Future<bool> sendMoney(
    int senderId,
    String receiverPhone,
    int amountInCents,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-money'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': senderId,
        'phone': receiverPhone,
        'amount': amountInCents,
      }),
    );
    final body = jsonDecode(res.body);
    return res.statusCode == 200 && body['success'] == true;
  }
}
