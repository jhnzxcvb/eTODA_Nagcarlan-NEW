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
  static String? cachedPassengerTripStartAt;
  static Timer? _backgroundPollTimer;

  /// Resets all global session data and stops background processes
  static void resetSession() {
    isDriverOnline = false;
    activeTrips = [];
    pendingRequests = [];
    _backgroundPollTimer?.cancel();
    _backgroundPollTimer = null;
    disconnectWebSocket();
  }

  /// Keeps the driver polling the database for all active ongoing trips
  static void startDriverPolling(String driverId) {
    _backgroundPollTimer?.cancel();
    _backgroundPollTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (!isDriverOnline) {
        activeTrips = [];
        return;
      }

      try {
        final api = ApiService();
        final trips = await api.fetchOngoingTrips(driverId);
        if (trips != null) {
          activeTrips = trips;
          debugPrint(
            '🚩 Background polling synced ${activeTrips.length} ongoing trips',
          );
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

  static String? _currentWsId;
  static String? _currentWsType;

  /// Get the WebSocket stream for incoming messages
  static Stream<Map<String, dynamic>>? getWebSocketStream() {
    return _wsStream?.stream;
  }

  /// Connect to WebSocket for real-time driver notifications
  static Future<void> connectWebSocket(String driverId) async {
    try {
      if (_wsChannel != null &&
          _currentWsId == driverId &&
          _currentWsType == 'driver') {
        return; // Already connected to this driver ID
      }

      // Ensure previous connection is closed
      await disconnectWebSocket();

      // Convert HTTP baseUrl to WS (http://... → ws://...)
      final wsUrl = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final uri = Uri.parse('$wsUrl/ws/driver?driverID=$driverId');

      _currentWsId = driverId;
      _currentWsType = 'driver';
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
      if (_wsChannel != null &&
          _currentWsId == passengerId &&
          _currentWsType == 'passenger') {
        return; // Already connected to this passenger ID
      }

      // Ensure previous connection is closed
      await disconnectWebSocket();

      // Convert HTTP baseUrl to WS (http://... → ws://...)
      final wsUrl = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final uri = Uri.parse('$wsUrl/ws/passenger?passengerID=$passengerId');

      _currentWsId = passengerId;
      _currentWsType = 'passenger';
      debugPrint('🔌 Connecting passenger to WebSocket: $uri');
      _wsChannel = WebSocketChannel.connect(uri);
      _wsStream = StreamController<Map<String, dynamic>>.broadcast();

      // Listen to WebSocket messages
      _wsChannel!.stream.listen(
        (message) {
          try {
            final decoded = json.decode(message);
            if (decoded is Map<String, dynamic>) {
              debugPrint(
                '📨 Passenger WebSocket message received: ${decoded['event']}',
              );
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
    _currentWsId = null;
    _currentWsType = null;
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
      debugPrint(
        '📡 Driver status updated: ${online ? "Active" : "Inactive"} (HTTP ${response.statusCode})',
      );
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
        body: json.encode({'trip_code': tripCode, 'driver_id': driverId}),
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
        body: json.encode({'trip_code': tripCode, 'driver_id': driverId}),
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

  Future<Map<String, dynamic>> createTripRequest(
    Map<String, dynamic> body,
  ) async {
    return await post('/api/trip_requests', body);
  }

  Future<Map<String, dynamic>> respondTripRequest(
    Map<String, dynamic> body,
  ) async {
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
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        debugPrint('⚠️ Failed to parse fares: $e');
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
      throw Exception('Failed to connect to Go Backend');
    }
  }

  Future<List<dynamic>> fetchTrips(String passengerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/trips?passenger_id=$passengerId'),
    );
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
    final response = await http.get(
      Uri.parse('$baseUrl/api/trips?driver_id=$driverId'),
    );
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

  /// Fetches all currently ongoing trips for a driver
  Future<List<Map<String, dynamic>>?> fetchOngoingTrips(String driverId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/trips/active?driver_id=$driverId'),
    );
    if (response.statusCode == 200) {
      debugPrint('Raw response from /api/trips/active: ${response.body}');
      try {
        final decoded = json.decode(response.body.trim());
        if (decoded == null) return [];

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final activeData = decoded['data'];
          if (activeData is List) {
            return List<Map<String, dynamic>>.from(activeData);
          } else if (activeData is Map<String, dynamic>) {
            return [activeData];
          }
          return [];
        }

        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map<String, dynamic>) {
          return [decoded];
        }
      } catch (e) {
        debugPrint('! FormatException in fetchOngoingTrips: $e');
      }
    }
    return null; // Return null on 404 to prevent wiping out active trips
  }

  /// Fetches all currently ongoing trips for a passenger
  Future<List<Map<String, dynamic>>?> fetchOngoingPassengerTrips(
    String passengerId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/trips/active?passenger_id=$passengerId'),
    );
    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body.trim());
        if (decoded == null) return [];

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final activeData = decoded['data'];
          if (activeData is List) {
            return List<Map<String, dynamic>>.from(activeData);
          } else if (activeData is Map<String, dynamic>) {
            return [activeData];
          }
          return [];
        }

        if (decoded is List) {
          final trips = List<Map<String, dynamic>>.from(decoded);
          if (trips.isNotEmpty) {
            final firstTrip = trips.first;
            cachedPassengerTripStartAt = firstTrip['started_at']?.toString() ??
                firstTrip['paid_at']?.toString() ??
                firstTrip['created_at']?.toString();
          }
          return trips;
        } else if (decoded is Map<String, dynamic>) {
          final trip = Map<String, dynamic>.from(decoded);
          cachedPassengerTripStartAt = trip['started_at']?.toString() ??
              trip['paid_at']?.toString() ??
              trip['created_at']?.toString();
          return [trip];
        }
      } catch (e) {
        debugPrint('! FormatException in fetchOngoingPassengerTrips: $e');
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchActiveTrip(String driverId) async {
    final trips = await fetchOngoingTrips(driverId);
    return (trips != null && trips.isNotEmpty) ? trips.first : null;
  }

  Future<Map<String, dynamic>> fetchDriverRating(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/drivers/$driverId/rating'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'average_rating': 0.0, 'total_ratings': 0};
    } catch (e) {
      return {'average_rating': 0.0, 'total_ratings': 0};
    }
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
    final response = await http.get(
      Uri.parse('$baseUrl/api/drivers?search=$qrCode'),
    );

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

  Future<Map<String, dynamic>?> getPassengerById(int passengerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/passengers/$passengerId'),
      );
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

  /// Fetches complaints filed by a specific passenger
  Future<List<Map<String, dynamic>>> fetchPassengerComplaints(String passengerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/complaints?passenger_id=$passengerId'),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // The Go backend wraps responses in a 'data' key
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
        } else if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching passenger complaints: $e');
    }
    return [];
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
    String path,
    Map<String, dynamic> body,
  ) async {
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
          debugPrint('⚠️ ApiService.post failed to parse JSON: $e');
          return {};
        }
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
        debugPrint(
          'ApiService.post $path → HTTP ${response.statusCode}: ${response.body}',
        );
        return {};
      }
    } catch (e) {
      debugPrint('ApiService.post error [$path]: $e');
      return {};
    }
  }

  /// Checks if the system is currently in maintenance mode.
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
      debugPrint('⚠️ Maintenance check error: $e');
      return false;
    }
  }
}
