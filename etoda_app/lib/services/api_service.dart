import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // Default for Android Emulator
  );

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  Future<bool> submitComplaint(Map<String, dynamic> data) async {
    try {
      print('🚀 Sending Request to: $baseUrl/api/complaints');
      print('📦 Payload: ${json.encode(data)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/complaints'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Accept 200 (Go utils.JSONOK) or 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return false;
    }
  }
}