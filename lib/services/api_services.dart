import 'dart:convert';
import 'package:app_wallet/models/user_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this if using real device or deployed backend
  // For Android Emulator: http://10.0.2.2:5000
  // For iOS Simulator: http://localhost:5000
  // For Real Device: http://YOUR_COMPUTER_IP:5000 (e.g., http://192.168.1.100:5000)
  static const String baseUrl = "http://10.0.2.2:5000";

  // ============================================
  // REGISTER USER
  // ============================================
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String phone = '',
    String avatar = '',
  }) async {
    try {
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

      print('Register Status Code: ${res.statusCode}');
      print('Register Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['user'] != null) {
          return {
            'success': true,
            'user': User.fromJson(body['user']),
            'message': body['message'] ?? 'User registered successfully!',
          };
        }
      }

      // Handle errors
      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'Registration failed',
      };
    } catch (e) {
      print('Register Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // LOGIN USER
  // ============================================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login Status Code: ${res.statusCode}');
      print('Login Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['user'] != null) {
          return {
            'success': true,
            'user': User.fromJson(body['user']),
            'message': 'Login successful!',
          };
        }
      }

      // Handle errors
      final body = jsonDecode(res.body);
      return {'success': false, 'message': body['error'] ?? 'Login failed'};
    } catch (e) {
      print('Login Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // FETCH USER BY ID
  // ============================================
  static Future<User?> fetchUser(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/user/$userId'));

      print('Fetch User Status Code: ${res.statusCode}');
      print('Fetch User Response: ${res.body}');

      if (res.statusCode == 200) {
        return User.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('Fetch User Error: $e');
      return null;
    }
  }

  // ============================================
  // CREATE PAYMENT INTENT (STRIPE)
  // ============================================
  static Future<String?> createPaymentIntent(double amount) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      print('Create Payment Intent Status Code: ${res.statusCode}');
      print('Create Payment Intent Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['clientSecret'];
      }
      return null;
    } catch (e) {
      print('Create Payment Intent Error: $e');
      return null;
    }
  }

  // ============================================
  // UPDATE BALANCE AFTER PAYMENT SUCCESS
  // ============================================
  static Future<Map<String, dynamic>> updateBalance(
    int userId,
    double amount,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/payment-success'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'amount': amount}),
      );

      print('Update Balance Status Code: ${res.statusCode}');
      print('Update Balance Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'user': body['user'] != null ? User.fromJson(body['user']) : null,
          'message': body['message'] ?? 'Balance updated successfully',
        };
      }

      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'Failed to update balance',
      };
    } catch (e) {
      print('Update Balance Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // SEND MONEY TO ANOTHER USER
  // ============================================
  static Future<Map<String, dynamic>> sendMoney(
    int senderId,
    String receiverPhone,
    double amount,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': senderId,
          'phone': receiverPhone,
          'amount': amount,
        }),
      );

      print('Send Money Status Code: ${res.statusCode}');
      print('Send Money Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'Money sent successfully!',
        };
      }

      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'Failed to send money',
      };
    } catch (e) {
      print('Send Money Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // GET ALL TRANSACTIONS
  // ============================================
  static Future<List<dynamic>> getAllTransactions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/transactions'));

      print('Get All Transactions Status Code: ${res.statusCode}');
      print('Get All Transactions Response: ${res.body}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Get All Transactions Error: $e');
      return [];
    }
  }

  // ============================================
  // GET USER TRANSACTIONS
  // ============================================
  static Future<List<dynamic>> getUserTransactions(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/transactions/$userId'));

      print('Get User Transactions Status Code: ${res.statusCode}');
      print('Get User Transactions Response: ${res.body}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Get User Transactions Error: $e');
      return [];
    }
  }

  // ============================================
  // TEST DATABASE CONNECTION
  // ============================================
  static Future<bool> testConnection() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/test-db'));

      print('Test DB Status Code: ${res.statusCode}');
      print('Test DB Response: ${res.body}');

      return res.statusCode == 200;
    } catch (e) {
      print('Test DB Error: $e');
      return false;
    }
  }
}
