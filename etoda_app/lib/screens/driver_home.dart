import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isShiftActive = false;
  int _activeTripsCount = 0;
  bool _isLoadingShift = false;
  bool _isInitialized = false;
<<<<<<< Updated upstream
=======
  Timer? _uiRefreshTimer;
  StreamSubscription? _wsSubscription;
  final ApiService _apiService = ApiService();

  bool _isRequestModalOpen = false;
  StateSetter? _requestModalSetState;

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _wsSubscription?.cancel();
    super.dispose();
  }
>>>>>>> Stashed changes

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize state from arguments (e.g., when returning from a trip)
    if (!_isInitialized) {
<<<<<<< Updated upstream
      final Map<String, dynamic>? args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && args['is_shift_active'] == true) {
        setState(() {
          _isShiftActive = true;
        });
      }
=======
      _isShiftActive = ApiService.isDriverOnline;
      _activeTripsCount = ApiService.activeTrips.length;

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
          int currentCount = ApiService.activeTrips.length;
          if (currentCount != _activeTripsCount) {
            setState(() {
              _activeTripsCount = currentCount;
            });
          }
        }
      });

>>>>>>> Stashed changes
      _isInitialized = true;
    }
  }

  void _toggleShift() {
    if (!_isShiftActive) {
      // STARTING SHIFT
      setState(() {
        _isLoadingShift = true;
      });

      // Simulation: Load for 2 seconds then start shift and show trip
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoadingShift = false;
            _isShiftActive = true;
            _isTripActive = true; // Auto-show trip for simulation
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Going Online... A passenger is waiting for you."),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } else {
<<<<<<< Updated upstream
      // ENDING SHIFT
      setState(() {
        _isShiftActive = false;
        _isTripActive = false;
=======
      if (ApiService.activeTrips.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: nagcarlanWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.block, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Cannot End Shift", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
              ],
            ),
            content: const Text("You have ongoing trips. Please complete all trips before going offline."),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK", style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold))),
            ],
          ),
        );
        return;
      }

      _apiService.updateDriverStatus(idInt, false);

      setState(() {
        _isShiftActive = false;
        _activeTripsCount = 0;
        ApiService.isDriverOnline = false;
        ApiService.activeTrips = [];
>>>>>>> Stashed changes
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Shift ended. You are now offline."),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  void _endTrip() {
    setState(() {
      _isTripActive = false;
    });
    
<<<<<<< Updated upstream
=======
    if (wsStream == null) return;

    _wsSubscription = wsStream.listen(
      (message) async {
        if (message['event'] == 'trip_started') {
          final tripData = message['trip'] as Map<String, dynamic>?;
          if (tripData != null && mounted) {
            setState(() {
              if (!ApiService.activeTrips.any((t) => t['trip_code'] == tripData['trip_code'])) {
                ApiService.activeTrips.add(tripData);
                _activeTripsCount = ApiService.activeTrips.length;
              }
            });
          }
        }
        if (message['event'] == 'trip_request') {
          final request = message['request'] as Map<String, dynamic>?;
          if (request != null && mounted) {
            // Dynamically fetch passenger name if it is missing from the payload
            if (request['passenger_name'] == null && request['passenger_id'] != null) {
              final pId = (request['passenger_id'] as num).toInt();
              final pData = await _apiService.getPassengerById(pId);
              if (pData != null && mounted) {
                request['passenger_name'] = pData['first_name'] != null 
                    ? '${pData['first_name']} ${pData['last_name'] ?? ''}'.trim()
                    : (pData['name'] ?? 'Passenger');
              }
            }

            setState(() {
              if (!ApiService.pendingRequests.any((r) => r['request_id'] == request['request_id'])) {
                ApiService.pendingRequests.add(request);
              }
            });
            if (!_isRequestModalOpen) {
              _showTripRequestsModal();
            } else if (_requestModalSetState != null) {
              _requestModalSetState!(() {});
            }
          }
        }
      },
    );
  }

  void _showTripRequestsModal() {
    _isRequestModalOpen = true;
>>>>>>> Stashed changes
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

<<<<<<< Updated upstream
    // Pass the driver data to the completion screen
    Navigator.of(context).pushNamed('/driver_trip_ended', arguments: driverData);
=======
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            _requestModalSetState = setModalState;

            if (ApiService.pendingRequests.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_isRequestModalOpen && mounted) {
                  Navigator.of(ctx).pop();
                  _isRequestModalOpen = false;
                  _requestModalSetState = null;
                }
              });
              return const SizedBox.shrink();
            }

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
                  Expanded(
                    child: Text(
                      '${ApiService.pendingRequests.length} New Request(s)', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: nagcarlanGreen)
                    )
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ApiService.pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = ApiService.pendingRequests[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: nagcarlanGreen.withOpacity(0.1),
                                radius: 24,
                                child: const Icon(Icons.person, color: nagcarlanGreen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Passenger", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(
                                      request['passenger_name'] ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: nagcarlanYellow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "₱${(request['fare'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: nagcarlanGreen),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1),
                          ),
                          _buildDetailRow(Icons.route_outlined, "Route", request['route'] ?? 'N/A', isBold: true),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    ApiService().respondTripRequest({
                                      'request_id': request['request_id'],
                                      'driver_id': int.tryParse(driverId) ?? 0,
                                      'passenger_id': (request['passenger_id'] as num?)?.toInt() ?? 0,
                                      'accepted': false,
                                    });
                                    setModalState(() {
                                      ApiService.pendingRequests.removeAt(index);
                                    });
                                    setState(() {});
                                  },
                                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: nagcarlanGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    ApiService().respondTripRequest({
                                      'request_id': request['request_id'],
                                      'driver_id': int.tryParse(driverId) ?? 0,
                                      'passenger_id': (request['passenger_id'] as num?)?.toInt() ?? 0,
                                      'accepted': true,
                                    });
                                    setModalState(() {
                                      ApiService.pendingRequests.removeAt(index);
                                    });
                                    setState(() {});
                                  },
                                  child: const Text('Accept Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _isRequestModalOpen = false;
      _requestModalSetState = null;
    });
  }

  void _endTrip(Map<String, dynamic> trip) async {
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId = (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();

    try {
      final success = await _apiService.completeTrip(
        trip['trip_code'], 
        int.tryParse(driverId) ?? 0
      );

      if (success) {
        setState(() {
          ApiService.activeTrips.removeWhere((t) => t['trip_code'] == trip['trip_code']);
          _activeTripsCount = ApiService.activeTrips.length;
        });
        
        if (_activeTripsCount == 0) {
          Navigator.of(context).pushNamed('/driver_trip_ended', arguments: driverData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trip completed. You still have other ongoing trips."), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Error completing trip: $e');
    }
>>>>>>> Stashed changes
  }

  void _showTripDetailsModal(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: nagcarlanGreen),
            SizedBox(width: 10),
<<<<<<< Updated upstream
            Text("Current Trip Details", style: TextStyle(fontWeight: FontWeight.bold)),
=======
            Text("Trip Details", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
>>>>>>> Stashed changes
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
            _buildDetailRow(Icons.person, "Passenger", "Maria Santos"),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, "From", "Poblacion"),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.flag, "To", "Talangan"),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.category, "Passenger Type", "Normal"),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.alt_route, "Trip Type", "Regular"),
            const Divider(height: 32),
            _buildDetailRow(Icons.payments, "Fare Total", "₱30.00", isBold: true, valueColor: nagcarlanGreen),
=======
            _buildDetailRow(Icons.person, "Passenger", trip['passenger_name'] ?? 'Guest'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.route, "Route", trip['route'] ?? '—'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.confirmation_number_outlined, "Ref Code", trip['trip_code'] ?? '—'),
            const Divider(height: 32),
            _buildDetailRow(Icons.payments, "Fare Total", 
                "₱${(trip['fare_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}", 
                isBold: true, valueColor: nagcarlanGreen),
>>>>>>> Stashed changes
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
            height: double.infinity,
            decoration: nagcarlanGradient,
<<<<<<< Updated upstream
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
=======
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                    const Text("eTODA", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: nagcarlanYellow)),
                    const Text("NAGCARLAN", style: TextStyle(fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.bold, color: nagcarlanWhite)),

                    Text(
                        "Welcome, ${driverData?['first_name'] ?? 'Driver'}",
                        style: const TextStyle(fontSize: 18, color: nagcarlanWhite, fontWeight: FontWeight.w500)
                    ),

                    const SizedBox(height: 24),
                    
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

                    const SizedBox(height: 32),

                    if (_isShiftActive && ApiService.activeTrips.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "ONGOING TRIPS",
                          style: TextStyle(color: nagcarlanYellow, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: ApiService.activeTrips.length,
                          itemBuilder: (context, index) {
                            final trip = ApiService.activeTrips[index];
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              margin: const EdgeInsets.only(right: 15),
                              child: OngoingTripCard(
                                tripData: trip,
                                tripIndex: index,
                                totalTrips: ApiService.activeTrips.length,
                                onCompleteTap: () => _endTrip(trip),
                              ),
                            );
                          },
>>>>>>> Stashed changes
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

<<<<<<< Updated upstream
                const Spacer(),
                
                if (_isTripActive && _isShiftActive) ...[
                   _buildActiveTripCard(),
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
                    Navigator.pushNamed(context, '/driver_trip_history');
                  },
                ),
                const Spacer(),
                
                const BrandingFooter(),
              ],
=======
                    Column(
                      children: [
                            MenuCard(
                              title: _isShiftActive ? "END SHIFT" : "START SHIFT",
                              subtitle: _isShiftActive ? "Go offline and take a break" : "Go online to start receiving trips",
                              icon: _isShiftActive ? Icons.power_settings_new : Icons.play_circle_outline,
                              color: _isShiftActive ? Colors.redAccent : nagcarlanYellow,
                              textColor: _isShiftActive ? nagcarlanWhite : nagcarlanGreen,
                              onTap: _isLoadingShift ? () {} : _toggleShift,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            MenuCard(
                              title: "MY PROFILE",
                              subtitle: "Trips, vehicle info & earnings",
                              icon: Icons.account_circle,
                              color: nagcarlanWhite.withOpacity(0.9),
                              textColor: nagcarlanGreen,
                              onTap: () => Navigator.pushNamed(context, '/driver_profile', arguments: driverData),
                            ),
                            
                            const SizedBox(height: 16),
                            
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
                          ],
                        ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    const BrandingFooter(),
                    const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
>>>>>>> Stashed changes
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TRIP IN PROGRESS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text("Passenger: Maria Santos", style: TextStyle(fontSize: 14, color: Colors.black87)),
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
