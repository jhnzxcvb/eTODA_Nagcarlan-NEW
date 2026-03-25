import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Ginamit natin ang static String para ma-access sa buong app
  // 10.0.2.2 ang default para sa Android Studio Emulator papuntang localhost (Go)
  static String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', 
  );

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  // --- FARE MATRIX METHODS ---

  /// Kukuha ng lahat ng fare data para sa FareMatrixScreen
  /// Inaasahan nito ang JSON array mula sa Go backend
  Future<List<dynamic>> fetchFares() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/fares'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load fares: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fare Fetch Error: $e');
      return [];
    }
  }

  // --- STATION & MAP METHODS ---

  /// Kukuha ng terminal/station locations para sa Map Explorer
  Future<Map<String, dynamic>> fetchStations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/stations'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to connect to Go Backend');
      }
    } catch (e) {
      print('❌ Station Fetch Error: $e');
      return {'success': false, 'data': []};
    }
  }

  // --- DRIVER METHODS ---

  /// Kukuha ng listahan ng mga drivers para sa registry
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

  // --- COMPLAINTS METHODS ---

  /// Mag-submit ng reklamo (Passenger to Admin)
  Future<bool> submitComplaint(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/complaints'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print('📥 Response Status: ${response.statusCode}');
      
      // Tumatanggap ng 200 OK o 201 Created mula sa Go utils.JSONOK
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