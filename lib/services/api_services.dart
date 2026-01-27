import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_wallet/models/user_model.dart';

class ApiService {
  // IMPORTANT: Replace this with your actual Flask server IP or domain.
  // If running locally on an emulator, use 10.0.2.2 for Android or localhost for iOS/Web.
  static const String _baseUrl = 'http://192.168.1.65:5000';

  static Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  // Helper function to handle common API response parsing
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successful response (2xx - e.g., 201 for register)
        if (data.containsKey('user')) {
          try {
            // --- ADDED: Specific error logging for parsing failure ---
            // Attempt to parse the User model
            return {'success': true, 'user': User.fromJson(data['user'])};
          } catch (e) {
            // If User.fromJson fails, log the error and return failure map
            print(
              'Error during User model parsing (2xx response). Check user_model.dart for type mismatches: $e',
            );
            return {
              'success': false,
              'message': 'Failed to parse user data: $e',
            };
          }
        }
        // Success structure for other endpoints (e.g., balance update)
        return {
          'success': true,
          'message': data['message'] ?? 'Success',
          'data': data,
        };
      } else {
        // Error response (4xx, 5xx)
        final errorMessage =
            data['error'] ?? 'Server error (Status: ${response.statusCode})';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to process server response: $e',
      };
    }
  }

  // ============================================
  // REGISTER
  // ============================================
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String phone = '',
    String avatar = '', // Base64 string for avatar
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'avatar': avatar,
    };

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error during registration: $e',
      };
    }
  }

  // ============================================
  // LOGIN
  // ============================================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/login');
    final body = {'email': email, 'password': password};

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      // The login route also returns a 'user' object upon success (200)
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error during login: $e'};
    }
  }

  // ============================================
  // FETCH USER
  // ============================================
  static Future<User?> fetchUser(int userId) async {
    final url = Uri.parse('$_baseUrl/user/$userId');
    try {
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Direct conversion since this endpoint only returns the user object
        try {
          return User.fromJson(data);
        } catch (e) {
          print(
            'Error during User model parsing (200 fetch response). Check user_model.dart for type mismatches: $e',
          );
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Fetch user error: $e');
      return null;
    }
  }

  // ============================================
  // UPDATE USER PROFILE
  // ============================================
  static Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> updates,
  ) async {
    final url = Uri.parse('$_baseUrl/user/$userId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(updates),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error during update: $e'};
    }
  }

  static Future<String?> createPaymentIntent(double amount) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/create-payment-intent'),
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
        Uri.parse('$_baseUrl/payment-success'),
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
        Uri.parse('$_baseUrl/send'),
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
        Uri.parse('$_baseUrl/bank-transfer'),
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
        Uri.parse('$_baseUrl/college-payment'),
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
        Uri.parse('$_baseUrl/mobile-topup'),
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
        Uri.parse('$_baseUrl/bill-payment'),
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
        Uri.parse('$_baseUrl/shopping-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'merchant_name': merchantName,
          'amount': amount,
          'items': items ?? [],
        }),
      );

      //  print('Shopping Payment Status: ${res.statusCode}');
      //  print('Shopping Payment Response: ${res.body}');

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
      //     print('Shopping Payment Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // GET ALL TRANSACTIONS
  // ============================================
  static Future<List<dynamic>> getAllTransactions() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/transactions'));

      //  print('Get All Transactions Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      //     print('Get All Transactions Error: $e');
      return [];
    }
  }

  // ============================================
  // GET USER TRANSACTIONS
  // ============================================
  static Future<List<dynamic>> getUserTransactions(int userId) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/transactions/$userId'));

      // print('Get User Transactions Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      //   print('Get User Transactions Error: $e');
      return [];
    }
  }

  // ============================================
  // TEST DATABASE CONNECTION
  // ============================================
  static Future<bool> testConnection() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/test-db'));
      return res.statusCode == 200;
    } catch (e) {
      //  print('Test DB Error: $e');
      return false;
    }
  }
}

// Other financial transaction methods (send, topup, etc.) would go here...
