import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/report_dialog.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'dart:async';

class TripStartedScreen extends StatefulWidget {
  final int passengerId;
  final int driverId;
  final String? initialTripStartAt;

  const TripStartedScreen({
    super.key,
    required this.passengerId,
    required this.driverId,
    this.initialTripStartAt,
  });

  @override
  State<TripStartedScreen> createState() => _TripStartedScreenState();
}

class _TripStartedScreenState extends State<TripStartedScreen> {
  StreamSubscription? _wsSubscription;
  Timer? _pollTimer;
  final ApiService _apiService = ApiService();
  DateTime? _startTime;
  bool _hasRealStartTime = false;
  bool _tripEnded = false;

  DateTime? _parseTripDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return null;

    try {
      return DateTime.parse(rawDate);
    } catch (_) {
      try {
        return DateTime.parse(rawDate.replaceFirst(' ', 'T'));
      } catch (_) {
        return null;
      }
    }
  }

  DateTime? _getTripStartTimestamp(Map<String, dynamic> trip) {
    final startedAt = trip['started_at'] ?? trip['paid_at'] ?? trip['created_at'];
    return _parseTripDate(startedAt?.toString());
  }

  bool _tripMatchesDriver(Map<String, dynamic> trip) {
    final driverVal = trip['driver_id'];
    if (driverVal == null) return false;
    if (driverVal is num) return driverVal.toInt() == widget.driverId;
    if (driverVal is String) return int.tryParse(driverVal) == widget.driverId;
    return false;
  }

  Map<String, dynamic>? _findMatchingTrip(List<Map<String, dynamic>> trips) {
    for (final trip in trips) {
      if (_tripMatchesDriver(trip)) return trip;
    }
    return trips.length == 1 ? trips.first : null;
  }

  bool _isTimestampInTheFuture(DateTime timestamp) {
    return timestamp.isAfter(DateTime.now().add(const Duration(seconds: 5)));
  }

  void _setStartTimeFromTrip(Map<String, dynamic> trip) {
    final parsed = _getTripStartTimestamp(trip);
    if (parsed != null && mounted) {
      final candidateStart = parsed.toLocal();
      if (!_isTimestampInTheFuture(candidateStart)) {
        ApiService.cachedPassengerTripStartAt = candidateStart.toIso8601String();
        if (!_hasRealStartTime || _startTime == null ||
            candidateStart != _startTime) {
          setState(() {
            _startTime = candidateStart;
            _hasRealStartTime = true;
          });
        }
      } else {
        debugPrint(
          '⚠️ Ignoring future trip start time from backend: $candidateStart',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize start time to now to ensure duration begins updating immediately
    if (widget.initialTripStartAt != null) {
      final parsed = _parseTripDate(widget.initialTripStartAt);
      if (parsed != null && !_isTimestampInTheFuture(parsed)) {
        _startTime = parsed.toLocal();
        _hasRealStartTime = true;
      } else {
        _startTime = DateTime.now();
      }
    } else if (ApiService.cachedPassengerTripStartAt != null) {
      final parsed = _parseTripDate(ApiService.cachedPassengerTripStartAt);
      if (parsed != null && !_isTimestampInTheFuture(parsed)) {
        _startTime = parsed.toLocal();
        _hasRealStartTime = true;
      } else {
        _startTime = DateTime.now();
      }
    } else {
      _startTime = DateTime.now();
    }
    _connectWebSocket();
    _fetchStartTime();
    _startPolling();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _pollTimer?.cancel();
    ApiService.disconnectWebSocket();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _tripEnded) return;

      var trips = await _apiService.fetchOngoingPassengerTrips(
        widget.passengerId.toString(),
      );
      if (trips == null || trips.isEmpty) {
        trips = await _apiService.fetchOngoingTrips(widget.driverId.toString());
      }
      if (!mounted) return;

      if (trips == null || trips.isEmpty) {
        _tripEnded = true;
        final history = await _apiService.fetchTrips(
          widget.passengerId.toString(),
        );
        if (history.isNotEmpty && mounted) {
          final latestTrip = Map<String, dynamic>.from(history.first);
          if ((latestTrip['driver_id'] as num?)?.toInt() == widget.driverId) {
            Navigator.of(
              context,
            ).pushReplacementNamed('/trip_ended', arguments: latestTrip);
          }
        }
        return;
      }

      if (!_hasRealStartTime) {
        final myTrip = trips.isNotEmpty ? _findMatchingTrip(trips) : null;
        if (myTrip != null && _getTripStartTimestamp(myTrip) != null) {
          _setStartTimeFromTrip(myTrip);
        }
      }

      final tripExists = trips.any(
        (t) => (t['driver_id'] as num?)?.toInt() == widget.driverId,
      );
      if (!tripExists && mounted && !_tripEnded) {
        _tripEnded = true;
        final history = await _apiService.fetchTrips(
          widget.passengerId.toString(),
        );
        if (history.isNotEmpty && mounted) {
          final latestTrip = Map<String, dynamic>.from(history.first);
          if ((latestTrip['driver_id'] as num?)?.toInt() == widget.driverId) {
            Navigator.of(
              context,
            ).pushReplacementNamed('/trip_ended', arguments: latestTrip);
          }
        }
      }
    });
  }

  void _fetchStartTime() async {
    // Use passenger-specific active trip lookup for the passenger trip screen.
    var trips = await _apiService.fetchOngoingPassengerTrips(
      widget.passengerId.toString(),
    );

    if (trips == null || trips.isEmpty) {
      // Fallback to driver's active trip list if the passenger endpoint does not return the trip yet.
      trips = await _apiService.fetchOngoingTrips(widget.driverId.toString());
    }

    if (trips == null) {
      // API error or network failure - do not trigger redirect logic
      return;
    }

    Map<String, dynamic>? myTrip;
    if (trips.isNotEmpty) {
      myTrip = _findMatchingTrip(trips);
    }

    if (myTrip != null && _getTripStartTimestamp(myTrip) != null) {
      _setStartTimeFromTrip(myTrip);
    } else {
      // If no active trip is found or start timestamp is missing, it's highly likely it was completed or cancelled.
      _checkIfTripAlreadyFinalized();
    }
  }

  Future<void> _checkIfTripAlreadyFinalized() async {
    final history = await _apiService.fetchTrips(widget.passengerId.toString());
    if (history.isNotEmpty && mounted) {
      // Fallback: Use the most recent completed trip for this passenger
      final latestTrip = Map<String, dynamic>.from(history.first);
      // Ensure the history item belongs to the driver being viewed to avoid false positives
      if ((latestTrip['driver_id'] as num?)?.toInt() == widget.driverId) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/trip_ended', arguments: latestTrip);
      }
    }
  }

  void _connectWebSocket() async {
    try {
      // Connect to passenger WebSocket
      await ApiService.connectPassengerWebSocket(widget.passengerId.toString());
      _setupWebSocketListener();
    } catch (e) {
      debugPrint('Failed to connect passenger WebSocket: $e');
    }
  }

  /// Set up WebSocket listener for real-time trip updates
  void _setupWebSocketListener() {
    _wsSubscription?.cancel();
    final wsStream = ApiService.getWebSocketStream();

    if (wsStream == null) {
      debugPrint('⚠️ WebSocket stream not available');
      return;
    }

    _wsSubscription = wsStream.listen(
      (message) {
        if (message['event'] == 'trip_ended' ||
            message['event'] == 'trip_cancelled') {
          debugPrint(
            '✓ Trip finalization notification received: ${message['event']}',
          );
          if (mounted && !_tripEnded) {
            _tripEnded = true;
            // Bundle the event into the trip data
            final Map<String, dynamic> tripData = message['trip'] != null
                ? Map<String, dynamic>.from(message['trip'])
                : {};
            if (message['event'] == 'trip_cancelled') {
              tripData['status'] = 'cancelled';
              Navigator.of(
                context,
              ).pushReplacementNamed('/trip_cancelled', arguments: tripData);
            } else {
              tripData['status'] = 'completed';
              Navigator.of(
                context,
              ).pushReplacementNamed('/trip_ended', arguments: tripData);
            }
          }
        }
      },
      onError: (error) {
        debugPrint('⚠️ WebSocket stream error: $error');
      },
      onDone: () {
        debugPrint('⚠️ WebSocket stream closed');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: nagcarlanGreen),
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: nagcarlanGradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: nagcarlanYellow.withOpacity(0.1), // Added yellow accent
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: nagcarlanGreen,
                size: 120,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Trip Started!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: nagcarlanGreen,
              ),
            ),

            const Spacer(flex: 1),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: nagcarlanYellow.withOpacity(0.3)), // Yellow border accent
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          nagcarlanGreen,
                        ),
                        backgroundColor: nagcarlanYellow.withOpacity(0.2), // Yellow accent
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Trip Status",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "IN PROGRESS",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: nagcarlanGreen,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the button
                children: [ // Removed Expanded to allow TextButton to size itself
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ReportDialog(
                          passengerId: widget.passengerId,
                          driverId: widget.driverId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_problem_outlined, color: Colors.redAccent, size: 20),
                    label: const Text(
                      "REPORT AN ISSUE",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ], // End of children
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
