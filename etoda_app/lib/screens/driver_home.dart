import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/widgets/ongoing_trip_card.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isShiftActive = false;
  bool _isTripActive = false;
  bool _isLoadingShift = false;
  bool _isInitialized = false;
  Timer? _uiRefreshTimer;
  StreamSubscription? _wsSubscription;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      // Sync local UI state with Global Session
      _isShiftActive = ApiService.isDriverOnline;
      _isTripActive = ApiService.activeTrip != null;

      // Re-attach listener and polling if already online (e.g. returning from completion screen)
      if (_isShiftActive) {
        final Map<String, dynamic>? driverData =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final String driverId = (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
        
        if (driverId.isNotEmpty) {
          _setupWebSocketListener();
          // Ensure background polling is active
          ApiService.startDriverPolling(driverId);
        }
      }

      // Start a small UI timer to watch for changes caught by the background poller
      _uiRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          bool hasActiveTrip = ApiService.activeTrip != null;
          if (hasActiveTrip != _isTripActive) {
            setState(() {
              _isTripActive = hasActiveTrip;
            });
          }
        }
      });

      _isInitialized = true;
    }
  }

  void _toggleShift() {
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId = (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
    final int idInt = int.tryParse(driverId) ?? 0;

    if (!_isShiftActive) {
      setState(() => _isLoadingShift = true);
      Timer(const Duration(seconds: 2), () async {
        // Sync status with the Database so passengers can see the driver is "Active"
        final success = await _apiService.updateDriverStatus(idInt, true); // Status becomes 'Active'

        if (mounted && success) {
          setState(() {
            _isLoadingShift = false;
            _isShiftActive = true;
            ApiService.isDriverOnline = true;
          });

          // Connect to WebSocket for real-time trip notifications
          await ApiService.connectWebSocket(driverId);
          _setupWebSocketListener();

          // Keep polling as fallback for potential WebSocket failures
          ApiService.startDriverPolling(driverId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You are now ONLINE."), backgroundColor: Colors.green),
          );
        } else if (mounted && !success) {
          setState(() => _isLoadingShift = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Connection error. Could not start shift."), backgroundColor: Colors.red),
          );
        }
      });
    } else {
      // Update database to "Inactive" so passengers can no longer start trips
      _apiService.updateDriverStatus(idInt, false); // Status becomes 'Inactive'

      setState(() {
        _isShiftActive = false;
        _isTripActive = false;
        ApiService.isDriverOnline = false;
        ApiService.activeTrip = null;
      });
      
      // Disconnect WebSocket when shift ends
      ApiService.disconnectWebSocket();
      _wsSubscription?.cancel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Shift ended. You are now offline."),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  /// Set up WebSocket listener for real-time trip notifications
  void _setupWebSocketListener() {
    _wsSubscription?.cancel();
    final wsStream = ApiService.getWebSocketStream();
    
    if (wsStream == null) {
      debugPrint('⚠️ WebSocket stream not available');
      return;
    }

    _wsSubscription = wsStream.listen(
      (message) {
        if (message['event'] == 'trip_started') {
          final tripData = message['trip'] as Map<String, dynamic>?;
          if (tripData != null) {
            debugPrint('✓ Real-time trip received: ${tripData['passenger_name']}');
            if (mounted) {
              setState(() {
                ApiService.activeTrip = tripData;
                _isTripActive = true;
              });
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

  void _endTrip() async {
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId = (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();

    if (ApiService.activeTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active trip to end")),
      );
      return;
    }

    try {
      // Call the backend to complete the trip
      final tripData = ApiService.activeTrip != null 
          ? Map<String, dynamic>.from(ApiService.activeTrip!) 
          : null;
          
      final response = await ApiService().post('/api/trips/complete', {
        'trip_code': tripData?['trip_code'],
        'driver_id': int.parse(driverId),
      });

      if (response.containsKey('message')) {
        // Clear local trip state
        setState(() {
          _isTripActive = false;
          ApiService.activeTrip = null;
        });

        // Navigate to the driver-specific completion screen and pass driver profile data
        // so it can return to the dashboard successfully.
        Navigator.of(context).pushReplacementNamed('/driver_trip_ended', arguments: driverData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to complete trip")),
        );
      }
    } catch (e) {
      debugPrint('Error completing trip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error completing trip")),
      );
    }
  }

  void _cancelTrip() async {
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId =
        (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
    final String tripCode = ApiService.activeTrip?['trip_code'] ?? '';

    if (tripCode.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Trip"),
        content: const Text("Are you sure you want to cancel this trip?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("YES", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _apiService.cancelTrip(tripCode, int.parse(driverId));
    if (success) {
      setState(() {
        _isTripActive = false;
        ApiService.activeTrip = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip cancelled. Returning to dashboard."), backgroundColor: Colors.orange),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to cancel trip."), backgroundColor: Colors.red),
      );
    }
  }

  void _showTripDetailsModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: nagcarlanGreen),
            SizedBox(width: 10),
            Text("Current Trip Details", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.person, "Passenger", ApiService.activeTrip?['passenger_name'] ?? 'Guest'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.route, "Route", ApiService.activeTrip?['route'] ?? '—'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.confirmation_number_outlined, "Ref Code", ApiService.activeTrip?['trip_code'] ?? '—'),
            const Divider(height: 32),
            _buildDetailRow(Icons.payments, "Fare Total", 
                "₱${(ApiService.activeTrip?['fare_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}", 
                isBold: true, valueColor: nagcarlanGreen),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? driverData =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: nagcarlanGreen, size: 30),
            onSelected: (value) {
              if (value == 'edit_profile') {
                Navigator.pushNamed(context, '/driver_edit_profile', arguments: driverData);
              } else if (value == 'logout') {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit_profile',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: nagcarlanGreen),
                    SizedBox(width: 10),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: nagcarlanGradient,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 80),
                const Text("eTODA", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: nagcarlanGreen)),
                const Text("NAGCARLAN", style: TextStyle(fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.bold, color: nagcarlanGreen)),

                Text(
                    "Welcome, ${driverData?['first_name'] ?? 'Driver'}",
                    style: const TextStyle(fontSize: 18, color: nagcarlanGreen, fontWeight: FontWeight.w500)
                ),

                const SizedBox(height: 10),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isShiftActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isShiftActive ? Colors.green : Colors.grey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isShiftActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isShiftActive ? "ONLINE" : "OFFLINE",
                        style: TextStyle(
                          color: _isShiftActive ? Colors.green : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                
                if (_isTripActive && _isShiftActive) ...[
                   OngoingTripCard(
                     tripData: ApiService.activeTrip ?? {},
                     onCompleteTap: _endTrip,
                     onCancelTap: _cancelTrip,
                   ),
                   const SizedBox(height: 20),
                ],

                MenuCard(
                  title: _isShiftActive ? "END SHIFT" : "START SHIFT",
                  subtitle: _isShiftActive ? "Go offline and take a break" : "Go online to start receiving trips",
                  icon: _isShiftActive ? Icons.power_settings_new : Icons.play_circle_outline,
                  color: _isShiftActive ? Colors.red[700]! : nagcarlanGreen,
                  textColor: Colors.white,
                  onTap: _isLoadingShift ? () {} : _toggleShift,
                ),
                
                const SizedBox(height: 20),
                
                MenuCard(
                  title: "MY PROFILE",
                  subtitle: "Trips, vehicle info & earnings",
                  icon: Icons.account_circle,
                  color: Colors.white,
                  textColor: nagcarlanGreen,
                  onTap: () => Navigator.pushNamed(context, '/driver_profile', arguments: driverData),
                ),
                
                const SizedBox(height: 20),
                
                MenuCard(
                  title: "TRIP HISTORY",
                  subtitle: "See your past rides",
                  icon: Icons.list_alt,
                  color: Colors.white,
                  textColor: nagcarlanGreen,
                  onTap: () {
                    // History is now accessible even if offline
                    Navigator.pushNamed(context, '/driver_trip_history', arguments: driverData);
                  },
                ),
                const Spacer(),
                
                const BrandingFooter(),
              ],
            ),
          ),
          if (_isLoadingShift)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Establishing secure link...",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTripCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.red.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.red, width: 2)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.red, size: 32),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TRIP IN PROGRESS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text("Passenger: ${ApiService.activeTrip?['passenger_name'] ?? 'Guest'}", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showTripDetailsModal,
                  child: const Text("DETAILS", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _endTrip,
                child: const Text("END TRIP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: textColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: textColor.withAlpha(178))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
