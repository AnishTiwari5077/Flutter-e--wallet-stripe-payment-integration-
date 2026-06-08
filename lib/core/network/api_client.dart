import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://192.168.1.8:5000';
  static bool debugMode = true;

  static Map<String, String> getHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  static void debugPrint(String message) {
    if (debugMode) {
      // print(message);
    }
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: getHeaders());
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: getHeaders(), body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.put(url, headers: getHeaders(), body: jsonEncode(body));
  }
}
