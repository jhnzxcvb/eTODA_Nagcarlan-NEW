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

  // Fetch Station Data
  Future<Map<String, dynamic>> fetchStations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stations'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  // Fetch All Drivers
  Future<List<dynamic>> fetchDriverData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/drivers'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load drivers');
      }
    } catch (e) {
      print('❌ Driver Fetch Error: $e');
      return [];
    }
  }

  // Submit a Complaint (The missing method)
  Future<bool> submitComplaint(Map<String, dynamic> data) async {
    try {
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