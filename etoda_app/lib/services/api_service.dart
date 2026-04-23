import 'package:http/http.dart' as http;
import 'dart:convert';

/// Simple service wrapper for calling the Go backend.
class ApiService {
<<<<<<< Updated upstream
  // use a mutable field so tests or higher‑level code can re‑configure
=======
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

>>>>>>> Stashed changes
  static String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

<<<<<<< Updated upstream
  /// Override the base URL at runtime (e.g. after determining the device's
  /// network settings).
=======
  /// WebSocket for real-time trip notifications
  static WebSocketChannel? _wsChannel;
  static StreamController<Map<String, dynamic>>? _wsStream;
  
  static Stream<Map<String, dynamic>>? getWebSocketStream() {
    return _wsStream?.stream;
  }

  static Future<void> connectWebSocket(String driverId) async {
    try {
      await disconnectWebSocket();
      final wsUrl = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final uri = Uri.parse('$wsUrl/ws/driver?driverID=$driverId');

      debugPrint('🔌 Connecting to WebSocket: $uri');
      _wsChannel = WebSocketChannel.connect(uri);
      _wsStream = StreamController<Map<String, dynamic>>.broadcast();

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

  static Future<void> connectPassengerWebSocket(String passengerId) async {
    try {
      await disconnectWebSocket();
      final wsUrl = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final uri = Uri.parse('$wsUrl/ws/passenger?passengerID=$passengerId');

      debugPrint('🔌 Connecting passenger to WebSocket: $uri');
      _wsChannel = WebSocketChannel.connect(uri);
      _wsStream = StreamController<Map<String, dynamic>>.broadcast();

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
    } catch (e) {
      debugPrint('❌ Passenger WebSocket connection failed: $e');
    }
  }

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

>>>>>>> Stashed changes
  static void setBaseUrl(String url) {
    baseUrl = url;
  }

<<<<<<< Updated upstream
=======
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

>>>>>>> Stashed changes
  Future<Map<String, dynamic>> fetchStations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stations'));
    if (response.statusCode == 200) {
<<<<<<< Updated upstream
      return json.decode(response.body);
=======
      try {
        return json.decode(response.body);
      } catch (e) {
        return {'data': []};
      }
>>>>>>> Stashed changes
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<List<dynamic>> fetchFares() async {
    final response = await http.get(Uri.parse('$baseUrl/api/fare'));
    if (response.statusCode == 200) {
<<<<<<< Updated upstream
      final decoded = json.decode(response.body);
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

<<<<<<< Updated upstream
=======
  Future<List<dynamic>> fetchTrips(String passengerId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/trips?passenger_id=$passengerId'));
    if (response.statusCode == 200) {
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
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

  Future<Map<String, dynamic>> fetchDriverRating(int driverId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/drivers/$driverId/rating'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'average_rating': 0.0, 'total_ratings': 0};
    } catch (e) {
      return {'average_rating': 0.0, 'total_ratings': 0};
    }
  }

>>>>>>> Stashed changes
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
    final response = await http.get(Uri.parse('$baseUrl/api/drivers?search=$qrCode'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
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
<<<<<<< Updated upstream
}
=======

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic decoded;
        try {
          decoded = json.decode(response.body);
        } catch (e) {
          return {};
        }
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            return Map<String, dynamic>.from(decoded['data']);
          }
          return decoded;
        }
        return {'raw': decoded};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

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
      return false;
    }
  }
}
>>>>>>> Stashed changes
