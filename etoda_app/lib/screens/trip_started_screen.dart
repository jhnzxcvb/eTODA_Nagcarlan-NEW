import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/report_dialog.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'dart:async';

class TripStartedScreen extends StatefulWidget {
  final int passengerId;
  final int driverId;

  const TripStartedScreen({
    super.key,
    required this.passengerId,
    required this.driverId,
  });

  @override
  State<TripStartedScreen> createState() => _TripStartedScreenState();
}

class _TripStartedScreenState extends State<TripStartedScreen> {
  StreamSubscription? _wsSubscription;
  final ApiService _apiService = ApiService();
  DateTime? _startTime;
  int _elapsedMinutes = 0;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchStartTime();
    _startTimer();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _durationTimer?.cancel();
    ApiService.disconnectWebSocket();
    super.dispose();
  }
  
  void _fetchStartTime() async {
    final trip = await _apiService.fetchActiveTrip(widget.driverId.toString());
    if (trip != null && trip['started_at'] != null) {
      if (mounted) {
        setState(() {
          _startTime = DateTime.parse(trip['started_at']).toLocal();
          final diff = DateTime.now().difference(_startTime!);
          _elapsedMinutes = diff.inMinutes >= 0 ? diff.inMinutes : 0;
        });
      }
    }
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _startTime != null) {
        setState(() {
          final diff = DateTime.now().difference(_startTime!);
          _elapsedMinutes = diff.inMinutes >= 0 ? diff.inMinutes : 0;
        });
      }
    });
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
        if (message['event'] == 'trip_ended' || message['event'] == 'trip_cancelled') {
          debugPrint('✓ Trip finalization notification received: ${message['event']}');
          if (mounted) {
            // Bundle the event into the trip data
            final tripData = Map<String, dynamic>.from(message['trip'] ?? {});
            if (message['event'] == 'trip_cancelled') {
              tripData['status'] = 'cancelled';
              Navigator.of(context).pushReplacementNamed(
                '/trip_cancelled',
                arguments: tripData,
              );
            } else {
              tripData['status'] = 'completed';
              Navigator.of(context).pushReplacementNamed(
                '/trip_ended',
                arguments: tripData,
              );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: nagcarlanGreen),
          onPressed: () => Navigator.of(context).pop(),
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
                color: Colors.white.withOpacity(0.2),
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
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                            nagcarlanGreen),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Trip Status",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "IN PROGRESS (${_elapsedMinutes}m)",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: nagcarlanGreen,
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
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ReportDialog(
                      passengerId: widget.passengerId,
                      driverId: widget.driverId,
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 20),
                label: const Text(
                  "Report an Issue",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[700]!, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}