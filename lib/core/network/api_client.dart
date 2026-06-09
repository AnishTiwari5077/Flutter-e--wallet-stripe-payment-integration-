import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://192.168.1.8:5000';
  static bool debugMode = true;
  static const Duration timeoutDuration = Duration(seconds: 30);

  static Map<String, String> getHeaders([Map<String, String>? extraHeaders]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  static void debugPrint(String message) {
    if (debugMode) {
      // print(message);
    }
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http
        .get(url, headers: getHeaders(headers))
        .timeout(
          timeoutDuration,
          onTimeout: () => throw TimeoutException(
            'The connection has timed out, please try again.',
          ),
        );
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http
        .post(url, headers: getHeaders(headers), body: jsonEncode(body))
        .timeout(
          timeoutDuration,
          onTimeout: () => throw TimeoutException(
            'The connection has timed out, please try again.',
          ),
        );
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http
        .put(url, headers: getHeaders(headers), body: jsonEncode(body))
        .timeout(
          timeoutDuration,
          onTimeout: () => throw TimeoutException(
            'The connection has timed out, please try again.',
          ),
        );
  }
}
