import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

/// Simple service wrapper for calling the Go backend.
///
/// The `baseUrl` is now configurable at compile time via the
/// `--dart-define=BASE_URL=...` flag (see `flutter run` docs) and can also
/// be overridden at runtime using [setBaseUrl].
///
/// The default value (`10.0.2.2`) works with the Android emulator; if you
/// ever run the app on a physical device you'll want to redefine the host
/// address (e.g. your machine's LAN IP).
class ApiService {
  // ── Global Session State (For Simulation/One-Emulator Testing) ─────────────
  static bool isDriverOnline = false;
  static Map<String, dynamic>? activeTrip;
  static Timer? _backgroundPollTimer;

  /// Keeps the driver polling the database even if the UI is switched to Passenger
  static void startDriverPolling(String driverId) {
    _backgroundPollTimer?.cancel();
    _backgroundPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Only poll if driver is "online" and doesn't already have an active trip
      if (!isDriverOnline || activeTrip != null) return;
      
      try {
        final api = ApiService();
        final trip = await api.fetchActiveTrip(driverId);
        if (trip != null) {
          activeTrip = trip;
          debugPrint('🚩 Real-time trip detected in background for Driver ID: $driverId');
        }
      } catch (e) {
        debugPrint('⚠️ Background polling error: $e');
      }
    });
  }

  // use a mutable field so tests or higher‑level code can re‑configure
  static String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Override the base URL at runtime (e.g. after determining the device's
  /// network settings).
  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  /// Updates the driver's online/offline status in the database.
  /// This is called when the driver starts/ends their shift.
  Future<bool> updateDriverStatus(int driverId, bool online) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/drivers/$driverId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'is_active': online,
          'status': online ? 'Active' : 'Inactive',
        }),
      );
      isDriverOnline = online;
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating driver status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchStations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stations'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<List<dynamic>> fetchFares() async {
    final response = await http.get(Uri.parse('$baseUrl/api/fare'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Safely extract the list depending on how the backend wraps it
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return List<dynamic>.from(decoded['data'] ?? []);
      } else if (decoded is List) {
        return List<dynamic>.from(decoded);
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<List<dynamic>> fetchTrips(String passengerId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/trips?passenger_id=$passengerId'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return List<dynamic>.from(decoded['data'] ?? []);
      } else if (decoded is List) {
        return List<dynamic>.from(decoded);
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch trip history');
    }
  }

  Future<List<dynamic>> fetchDriverTrips(String driverId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/trips?driver_id=$driverId'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return List<dynamic>.from(decoded['data'] ?? []);
      } else if (decoded is List) {
        return List<dynamic>.from(decoded);
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch driver trip history');
    }
  }

  Future<Map<String, dynamic>?> fetchActiveTrip(String driverId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/trips/active?driver_id=$driverId'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return (decoded != null && decoded is Map<String, dynamic>) ? decoded : null;
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchDriverData() async {
    final response = await http.get(Uri.parse('$baseUrl/api/drivers'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<Map<String, dynamic>?> getDriverByQr(String qrCode) async {
    // Uses the backend search endpoint which now supports searching by QR ID
    final response =
        await http.get(Uri.parse('$baseUrl/api/drivers?search=$qrCode'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List<dynamic> data = [];
      
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        data = decoded['data'];
      } else if (decoded is List) {
        data = decoded;
      }

      // Return the first match if found, otherwise null
      if (data.isNotEmpty) return data.first;
      return null;
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<bool> submitComplaint(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/complaints'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Generic POST — used by PaymentMethodDialog ──────────────────────────────
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        // Handle both raw map and wrapped { success, data } responses
        if (decoded is Map<String, dynamic>) {
          // If backend wraps response in { success: true, data: {...} }
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            return Map<String, dynamic>.from(decoded['data']);
          }
          return decoded;
        }
        return {'raw': decoded};
      } else {
        debugPrint('ApiService.post $path → HTTP ${response.statusCode}: ${response.body}');
        return {};
      }
    } catch (e) {
      debugPrint('ApiService.post error [$path]: $e');
      return {};
    }
  }
}