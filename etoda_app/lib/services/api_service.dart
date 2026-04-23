import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

/// Simple service wrapper for calling the Go backend.
class ApiService {
  // ── Global Session State ──────────────────────────────────────────────────
  static bool isDriverOnline = false;
  static List<Map<String, dynamic>> activeTrips = [];
  static List<Map<String, dynamic>> pendingRequests = [];
  static Timer? _backgroundPollTimer;

  /// Keeps the driver polling the database for all active ongoing trips
  static void startDriverPolling(String driverId) {
    _backgroundPollTimer?.cancel();
    _backgroundPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!isDriverOnline) return;
      
      try {
        final api = ApiService();
        final trips = await api.fetchOngoingTrips(driverId);
        if (trips != null) {
          activeTrips = trips;
          debugPrint('🚩 Background polling synced ${activeTrips.length} ongoing trips');
        }
      } catch (e) {
        debugPrint('⚠️ Background polling error: $e');
      }
    });
  }
  static String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
  /// WebSocket for real-time trip notifications
  static WebSocketChannel? _wsChannel;
  static StreamController<Map<String, dynamic>>? _wsStream;
  
  /// Get the WebSocket stream for incoming messages
  static Stream<Map<String, dynamic>>? getWebSocketStream() {
    return _wsStream?.stream;
  }

  /// Connect to WebSocket for real-time driver notifications
  static Future<void> connectWebSocket(String driverId) async {
    try {
      // Ensure previous connection is closed
      await disconnectWebSocket();

      // Convert HTTP baseUrl to WS (http://... → ws://...)
      final wsUrl = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final uri = Uri.parse('$wsUrl/ws/driver?driverID=$driverId');

      debugPrint('🔌 Connecting to WebSocket: $uri');
      _wsChannel = WebSocketChannel.connect(uri);
      _wsStream = StreamController<Map<String, dynamic>>.broadcast();

      // Listen to WebSocket messages
      _wsChannel!.stream.listen(
        (message) {
          try {
            final decoded = json.decode(message);
            if (decoded is Map<String, dynamic>) {
              debugPrint('📨 WebSocket message received: ${decoded['event']}');
              _wsStream!.add(decoded);
            }
          } catch (e) {
            debugPrint('⚠️ Failed to decode WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('⚠️ WebSocket error: $error');
          _wsStream!.addError(error);
        },
        onDone: () {
          debugPrint('❌ WebSocket closed');
          _wsStream?.close();
          _wsStream = null;
          _wsChannel = null;
        },
      );
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
    }
  }

  /// Connect to WebSocket for real-time passenger notifications
  static Future<void> connectPassengerWebSocket(String passengerId) async {
    try {
      // Ensure previous connection is closed
      await disconnectWebSocket();

      // Convert HTTP baseUrl to WS (http://... → ws://...)
      final wsUrl = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final uri = Uri.parse('$wsUrl/ws/passenger?passengerID=$passengerId');

      debugPrint('🔌 Connecting passenger to WebSocket: $uri');
      _wsChannel = WebSocketChannel.connect(uri);
      _wsStream = StreamController<Map<String, dynamic>>.broadcast();

      // Listen to WebSocket messages
      _wsChannel!.stream.listen(
        (message) {
          try {
            final decoded = json.decode(message);
            if (decoded is Map<String, dynamic>) {
              debugPrint('📨 Passenger WebSocket message received: ${decoded['event']}');
              _wsStream!.add(decoded);
            }
          } catch (e) {
            debugPrint('⚠️ Failed to decode passenger WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('⚠️ Passenger WebSocket error: $error');
          _wsStream!.addError(error);
        },
        onDone: () {
          debugPrint('❌ Passenger WebSocket closed');
          _wsStream?.close();
          _wsStream = null;
          _wsChannel = null;
        },
      );

      debugPrint('✓ Passenger WebSocket connected for passenger $passengerId');
    } catch (e) {
      debugPrint('❌ Passenger WebSocket connection failed: $e');
    }
  }

  /// Disconnect from WebSocket
  static Future<void> disconnectWebSocket() async {
    try {
      await _wsChannel?.sink.close();
      await _wsStream?.close();
    } catch (e) {
      debugPrint('⚠️ Error closing WebSocket: $e');
    }
    _wsChannel = null;
    _wsStream = null;
  }
  static void setBaseUrl(String url) {
    baseUrl = url;
  }
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
  
  Future<bool> completeTrip(String tripCode, int driverId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trips/complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_code': tripCode,
          'driver_id': driverId,
        }),
      );
      if (response.statusCode == 200) {
        activeTrips.removeWhere((t) => t['trip_code'] == tripCode);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error completing trip: $e');
      return false;
    }
  }

  Future<bool> cancelTrip(String tripCode, int driverId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trips/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_code': tripCode,
          'driver_id': driverId,
        }),
      );
      if (response.statusCode == 200) {
        activeTrips.removeWhere((t) => t['trip_code'] == tripCode);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createTripRequest(Map<String, dynamic> body) async {
    return await post('/api/trip_requests', body);
  }

  Future<Map<String, dynamic>> respondTripRequest(Map<String, dynamic> body) async {
    return await post('/api/trip_requests/respond', body);
  }

  Future<Map<String, dynamic>> fetchStations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stations'));
    if (response.statusCode == 200) {
      try {
        return json.decode(response.body);
      } catch (e) {
        debugPrint('⚠️ Failed to parse stations: $e');
        debugPrint('📦 Raw response: ${response.body}');
        return {'data': []};
      }
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<List<dynamic>> fetchFares() async {
    final response = await http.get(Uri.parse('$baseUrl/api/fare'));
    if (response.statusCode == 200) {
<<<<<<< HEAD
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        debugPrint('⚠️ Failed to parse fares: $e');
        return [];
      }
=======
<<<<<<< Updated upstream
      final decoded = json.decode(response.body);
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
      // Safely extract the list depending on how the backend wraps it
=======
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        return [];
      }
>>>>>>> Stashed changes
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
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        debugPrint('⚠️ Failed to parse passenger trips: $e');
        return [];
      }
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
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        debugPrint('⚠️ Failed to parse driver trips: $e');
        return [];
      }
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

<<<<<<< HEAD
  Future<Map<String, dynamic>?> fetchActiveTrip(String driverId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/trips/active?driver_id=$driverId'));

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body.trim());
        return (decoded != null && decoded is Map<String, dynamic>) ? decoded : null;
      } catch (e) {
        debugPrint('! FormatException in fetchActiveTrip: $e');
        debugPrint('📦 Raw response: ${response.body}');
        return null;
      }
    }
    return null;
  }

  /// Fetches the average rating and review count for a specific driver
=======
  /// Fetches all currently ongoing trips for a driver
  Future<List<Map<String, dynamic>>?> fetchOngoingTrips(String driverId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/trips/active?driver_id=$driverId'));
    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body.trim());
        if (decoded == null) return [];
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map<String, dynamic>) {
          // Wrap single trip in a list if the API returns one
          return [decoded];
        }
      } catch (e) {
        debugPrint('! FormatException in fetchOngoingTrips: $e');
      }
    }
    return null; // Return null on 404 to prevent wiping out active trips
  }

  Future<Map<String, dynamic>?> fetchActiveTrip(String driverId) async {
    final trips = await fetchOngoingTrips(driverId);
    return (trips != null && trips.isNotEmpty) ? trips.first : null;
  }

>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
  Future<Map<String, dynamic>> fetchDriverRating(int driverId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/drivers/$driverId/rating'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'average_rating': 0.0, 'total_ratings': 0};
    } catch (e) {
<<<<<<< HEAD
      debugPrint('Error fetching driver rating: $e');
=======
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
      return {'average_rating': 0.0, 'total_ratings': 0};
    }
  }

<<<<<<< HEAD
=======
>>>>>>> Stashed changes
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
  Future<Map<String, dynamic>> fetchDriverData() async {
    final response = await http.get(Uri.parse('$baseUrl/api/drivers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<Map<String, dynamic>?> getDriverByQr(String qrCode) async {
<<<<<<< Updated upstream
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
=======
    final response = await http.get(Uri.parse('$baseUrl/api/drivers?search=$qrCode'));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List<dynamic> data = [];
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        data = decoded['data'];
      } else if (decoded is List) {
        data = decoded;
      }
>>>>>>> Stashed changes
      if (data.isNotEmpty) return data.first;
      return null;
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<Map<String, dynamic>?> getPassengerById(int passengerId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/passengers/$passengerId'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded.containsKey('data') ? decoded['data'] : decoded;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching passenger data: $e');
    }
    return null;
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
<<<<<<< HEAD

  // ── Generic POST — used by PaymentMethodDialog ──────────────────────────────
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
=======
<<<<<<< Updated upstream
}
=======

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
<<<<<<< HEAD

=======
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic decoded;
        try {
          decoded = json.decode(response.body);
        } catch (e) {
<<<<<<< HEAD
          debugPrint('⚠️ ApiService.post failed to parse JSON: $e');
          return {};
        }
        // Handle both raw map and wrapped { success, data } responses
        if (decoded is Map<String, dynamic>) {
          // If backend wraps response in { success: true, data: {...} }
=======
          return {};
        }
        if (decoded is Map<String, dynamic>) {
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            return Map<String, dynamic>.from(decoded['data']);
          }
          return decoded;
        }
        return {'raw': decoded};
      } else {
<<<<<<< HEAD
        debugPrint('ApiService.post $path → HTTP ${response.statusCode}: ${response.body}');
        return {};
      }
    } catch (e) {
      debugPrint('ApiService.post error [$path]: $e');
=======
        return {};
      }
    } catch (e) {
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
      return {};
    }
  }

<<<<<<< HEAD
  /// Checks if the system is currently in maintenance mode.
=======
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
  Future<bool> isMaintenanceMode() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/settings'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            return data['maintenance'] ?? false;
          }
        }
      }
      return false;
    } catch (e) {
<<<<<<< HEAD
      debugPrint('⚠️ Maintenance check error: $e');
      return false;
    }
  }
}
=======
      return false;
    }
  }
}
>>>>>>> Stashed changes
>>>>>>> ab5153e2982d6e3c0af19bc2ce6c59e3b29cf3e9
