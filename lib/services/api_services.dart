import 'dart:convert';
import 'package:app_wallet/models/user_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Change baseUrl based on your setup
  // Android Emulator: http://10.0.2.2:5000
  // iOS Simulator: http://localhost:5000
  // Real Device: http://YOUR_COMPUTER_IP:5000
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

      print('Register Status: ${res.statusCode}');
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

      print('Login Status: ${res.statusCode}');
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

      print('Fetch User Status: ${res.statusCode}');
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

      print('Create Payment Intent Status: ${res.statusCode}');
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

      print('Update Balance Status: ${res.statusCode}');
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
  // SEND MONEY
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

      print('Send Money Status: ${res.statusCode}');
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
  // BANK TRANSFER
  // ============================================
  static Future<Map<String, dynamic>> bankTransfer({
    required int userId,
    required String accountNumber,
    required String bankName,
    required double amount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/bank-transfer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'account_number': accountNumber,
          'bank_name': bankName,
          'amount': amount,
        }),
      );

      print('Bank Transfer Status: ${res.statusCode}');
      print('Bank Transfer Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'Bank transfer successful!',
        };
      }

      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'Bank transfer failed',
      };
    } catch (e) {
      print('Bank Transfer Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // COLLEGE PAYMENT
  // ============================================
  static Future<Map<String, dynamic>> collegePayment({
    required int userId,
    required String studentId,
    required String collegeName,
    required String semester,
    required double amount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/college-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'student_id': studentId,
          'college_name': collegeName,
          'semester': semester,
          'amount': amount,
        }),
      );

      print('College Payment Status: ${res.statusCode}');
      print('College Payment Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'College payment successful!',
        };
      }

      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'College payment failed',
      };
    } catch (e) {
      print('College Payment Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // MOBILE TOPUP
  // ============================================
  static Future<Map<String, dynamic>> mobileTopup({
    required int userId,
    required String phoneNumber,
    required String operator,
    required double amount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/mobile-topup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'phone_number': phoneNumber,
          'operator': operator,
          'amount': amount,
        }),
      );

      print('Mobile Topup Status: ${res.statusCode}');
      print('Mobile Topup Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'Mobile topup successful!',
        };
      }

      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'Mobile topup failed',
      };
    } catch (e) {
      print('Mobile Topup Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // BILL PAYMENT
  // ============================================
  static Future<Map<String, dynamic>> billPayment({
    required int userId,
    required String billType,
    required String accountNumber,
    required double amount,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/bill-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'bill_type': billType,
          'account_number': accountNumber,
          'amount': amount,
        }),
      );

      print('Bill Payment Status: ${res.statusCode}');
      print('Bill Payment Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'Bill payment successful!',
        };
      }

      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'Bill payment failed',
      };
    } catch (e) {
      print('Bill Payment Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // SHOPPING PAYMENT
  // ============================================
  static Future<Map<String, dynamic>> shoppingPayment({
    required int userId,
    required String merchantName,
    required double amount,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/shopping-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'merchant_name': merchantName,
          'amount': amount,
          'items': items ?? [],
        }),
      );

      print('Shopping Payment Status: ${res.statusCode}');
      print('Shopping Payment Response: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'Shopping payment successful!',
        };
      }

      final body = jsonDecode(res.body);
      return {
        'success': false,
        'message': body['error'] ?? 'Shopping payment failed',
      };
    } catch (e) {
      print('Shopping Payment Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // GET ALL TRANSACTIONS
  // ============================================
  static Future<List<dynamic>> getAllTransactions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/transactions'));

      print('Get All Transactions Status: ${res.statusCode}');

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

      print('Get User Transactions Status: ${res.statusCode}');

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
      return res.statusCode == 200;
    } catch (e) {
      print('Test DB Error: $e');
      return false;
    }
  }
}
