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
      _isShiftActive = ApiService.isDriverOnline;
      _isTripActive = ApiService.activeTrip != null;

      if (_isShiftActive) {
        final Map<String, dynamic>? driverData =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final String driverId = (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
        
        if (driverId.isNotEmpty) {
          _setupWebSocketListener();
          ApiService.startDriverPolling(driverId);
        }
      }

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
        final success = await _apiService.updateDriverStatus(idInt, true);

        if (mounted && success) {
          setState(() {
            _isLoadingShift = false;
            _isShiftActive = true;
            ApiService.isDriverOnline = true;
          });

          await ApiService.connectWebSocket(driverId);
          _setupWebSocketListener();
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
      _apiService.updateDriverStatus(idInt, false);

      setState(() {
        _isShiftActive = false;
        _isTripActive = false;
        ApiService.isDriverOnline = false;
        ApiService.activeTrip = null;
      });
      
      ApiService.disconnectWebSocket();
      _wsSubscription?.cancel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shift ended. You are now offline."),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  void _setupWebSocketListener() {
    _wsSubscription?.cancel();
    final wsStream = ApiService.getWebSocketStream();
    
    if (wsStream == null) return;

    _wsSubscription = wsStream.listen(
      (message) {
        if (message['event'] == 'trip_started') {
          final tripData = message['trip'] as Map<String, dynamic>?;
          if (tripData != null && mounted) {
            setState(() {
              ApiService.activeTrip = tripData;
              _isTripActive = true;
            });
          }
        }
        if (message['event'] == 'trip_request') {
          final request = message['request'] as Map<String, dynamic>?;
          if (request != null && mounted) {
            _showTripRequestModal(request);
          }
        }
      },
    );
  }

  void _showTripRequestModal(Map<String, dynamic> request) {
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId = (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: nagcarlanWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: nagcarlanGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hail_rounded, color: nagcarlanGreen, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('New Trip Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: nagcarlanGreen)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildDetailRow(Icons.person_outline, "Passenger", request['passenger_name'] ?? 'Unknown'),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.route_outlined, "Route", request['route'] ?? 'N/A'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      "FARE AMOUNT",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₱${(request['fare'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: nagcarlanGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[700]!, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ApiService().respondTripRequest({
                        'request_id': request['request_id'],
                        'driver_id': int.tryParse(driverId) ?? 0,
                        'passenger_id': (request['passenger_id'] as num?)?.toInt() ?? 0,
                        'accepted': false,
                      });
                    },
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nagcarlanGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ApiService().respondTripRequest({
                        'request_id': request['request_id'],
                        'driver_id': int.tryParse(driverId) ?? 0,
                        'passenger_id': (request['passenger_id'] as num?)?.toInt() ?? 0,
                        'accepted': true,
                      });
                    },
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _endTrip() async {
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId = (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();

    if (ApiService.activeTrip == null) return;

    try {
      final tripData = ApiService.activeTrip != null 
          ? Map<String, dynamic>.from(ApiService.activeTrip!) 
          : null;
          
      final response = await ApiService().post('/api/trips/complete', {
        'trip_code': tripData?['trip_code'],
        'driver_id': int.tryParse(driverId) ?? 0,
      });

      if (response.isNotEmpty) {
        setState(() {
          _isTripActive = false;
          ApiService.activeTrip = null;
        });
        Navigator.of(context).pushReplacementNamed('/driver_trip_ended', arguments: driverData);
      }
    } catch (e) {
      debugPrint('Error completing trip: $e');
    }
  }

  void _showTripDetailsModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nagcarlanWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: nagcarlanGreen),
            SizedBox(width: 10),
            Text("Current Trip Details", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
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
        Icon(icon, size: 20, color: nagcarlanGreen.withOpacity(0.7)),
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
            icon: const Icon(Icons.account_circle, color: nagcarlanWhite, size: 35),
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
                const Text("eTODA", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: nagcarlanYellow)),
                const Text("NAGCARLAN", style: TextStyle(fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.bold, color: nagcarlanWhite)),

                Text(
                    "Welcome, ${driverData?['first_name'] ?? 'Driver'}",
                    style: const TextStyle(fontSize: 18, color: nagcarlanWhite, fontWeight: FontWeight.w500)
                ),

                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: nagcarlanWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isShiftActive ? nagcarlanYellow : Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isShiftActive ? nagcarlanYellow : Colors.white30,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isShiftActive ? "ONLINE" : "OFFLINE",
                        style: TextStyle(
                          color: _isShiftActive ? nagcarlanYellow : Colors.white,
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
                   ),
                   const SizedBox(height: 20),
                ],

                MenuCard(
                  title: _isShiftActive ? "END SHIFT" : "START SHIFT",
                  subtitle: _isShiftActive ? "Go offline and take a break" : "Go online to start receiving trips",
                  icon: _isShiftActive ? Icons.power_settings_new : Icons.play_circle_outline,
                  color: _isShiftActive ? Colors.redAccent : nagcarlanYellow,
                  textColor: _isShiftActive ? nagcarlanWhite : nagcarlanGreen,
                  onTap: _isLoadingShift ? () {} : _toggleShift,
                ),
                
                const SizedBox(height: 20),
                
                MenuCard(
                  title: "MY PROFILE",
                  subtitle: "Trips, vehicle info & earnings",
                  icon: Icons.account_circle,
                  color: nagcarlanWhite.withOpacity(0.9),
                  textColor: nagcarlanGreen,
                  onTap: () => Navigator.pushNamed(context, '/driver_profile', arguments: driverData),
                ),
                
                const SizedBox(height: 20),
                
                MenuCard(
                  title: "TRIP HISTORY",
                  subtitle: "See your past rides",
                  icon: Icons.list_alt,
                  color: nagcarlanWhite.withOpacity(0.9),
                  textColor: nagcarlanGreen,
                  onTap: () {
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
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: nagcarlanYellow),
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
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
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
