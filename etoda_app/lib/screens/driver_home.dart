import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etoda_nagcarlan/widgets/ongoing_trip_card.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with RouteAware {
  bool _isShiftActive = false;
  int _activeTripsCount = 0;
  bool _isLoadingShift = false;
  bool _isInitialized = false;
  bool _isRouteSubscribed = false;
  Timer? _uiRefreshTimer;
  StreamSubscription? _wsSubscription;
  static const String _howToUseShownKey = 'driverHowToUseShown';
  static bool _hasShownHowToUse = false;
  final ApiService _apiService = ApiService();
  bool _isRequestModalOpen = false;
  StateSetter? _requestModalSetState;
  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _wsSubscription?.cancel();
    if (_isRouteSubscribed) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_isRouteSubscribed && route is PageRoute) {
      routeObserver.subscribe(this, route);
      _isRouteSubscribed = true;
    }

    if (!_isInitialized) {
      // Clear static state to prevent data leakage from previous login sessions
      ApiService.activeTrips = [];
      ApiService.pendingRequests = [];

      _isShiftActive = ApiService.isDriverOnline;

      if (_isShiftActive) {
        final Map<String, dynamic>? driverData =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final String driverId =
            (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();

        if (driverId.isNotEmpty) {
          // Ensure WebSocket is connected and listener is set up on initialization
          ApiService.connectWebSocket(driverId).then((_) {
            if (mounted) _setupWebSocketListener();
            _refreshActiveTrips(driverId); // Fetch immediately on init
          });
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
      _isInitialized = true;
    }

    if (!_hasShownHowToUse) {
      _hasShownHowToUse = true;
      SchedulerBinding.instance.addPostFrameCallback((_) => _checkAndShowHowToUseDialog());
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId =
        (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
    if (_isShiftActive && driverId.isNotEmpty) {
      ApiService.connectWebSocket(driverId).then((_) {
        if (mounted) {
          _setupWebSocketListener();
        }
      });
      _refreshActiveTrips(driverId);
    }
  }

  Future<void> _refreshActiveTrips(String driverId) async {
    final trips = await _apiService.fetchOngoingTrips(driverId);
    if (mounted && trips != null) {
      setState(() {
        ApiService.activeTrips = trips;
        _activeTripsCount = trips.length;
      });
    }
  }

  void _toggleShift() {
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId =
        (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
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
          if (!mounted) return;
          _setupWebSocketListener();
          ApiService.startDriverPolling(driverId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You are now ONLINE."),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted && !success) {
          setState(() => _isLoadingShift = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Connection error. Could not start shift."),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } else {
      if (ApiService.activeTrips.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: nagcarlanWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.block, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  "Cannot End Shift",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: nagcarlanGreen,
                  ),
                ),
              ],
            ),
            content: const Text(
              "You have ongoing trips. Please complete all trips before going offline.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: nagcarlanGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

      _apiService.updateDriverStatus(idInt, false); // Initiates sync update
      setState(() {
        _isShiftActive = false;
        _activeTripsCount = 0;
        ApiService.isDriverOnline = false;
        ApiService.activeTrips = [];
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
    _wsSubscription = wsStream.listen((message) async {
      if (message['event'] == 'trip_started') {
        final tripData = message['trip'] as Map<String, dynamic>?;
        if (tripData != null && mounted) {
          setState(() {
            if (!ApiService.activeTrips.any(
              (t) => t['trip_code'] == tripData['trip_code'],
            )) {
              ApiService.activeTrips.add(tripData);
              _activeTripsCount = ApiService.activeTrips.length;
            }
          });
        }
      }
      if (message['event'] == 'trip_ended' ||
          message['event'] == 'trip_cancelled') {
        final tripData = message['trip'] as Map<String, dynamic>?;
        if (tripData != null && mounted) {
          setState(() {
            ApiService.activeTrips.removeWhere(
              (t) => t['trip_code'] == tripData['trip_code'],
            );
            _activeTripsCount = ApiService.activeTrips.length;
          });
        }

        final Map<String, dynamic>? driverData =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final String driverId =
            (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
        if (mounted && driverId.isNotEmpty) {
          await _refreshActiveTrips(driverId);
        }
      }
      if (message['event'] == 'trip_request') {
        final request = message['request'] as Map<String, dynamic>?;
        if (request != null && mounted) {
          final passengerName = request['passenger_name']?.toString().trim();
          if ((passengerName == null || passengerName.isEmpty) &&
              request['passenger_id'] != null) {
            final pId = _parsePassengerId(request['passenger_id']);
            if (pId != null) {
              final pData = await _apiService.getPassengerById(pId);
              if (pData != null && mounted) {
                request['passenger_name'] = _resolvePassengerName(pData);
              }
            }
          }
          setState(() {
            if (!ApiService.pendingRequests.any(
              (r) => r['request_id'] == request['request_id'],
            )) {
              ApiService.pendingRequests.add(request);
            }
          });
          if (!_isRequestModalOpen) {
            await _showTripRequestModal();
          } else if (_requestModalSetState != null) {
            _requestModalSetState!(() {});
          }
        }
      }
    });
  }

  Future<void> _checkAndShowHowToUseDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final bool howToUseShown = prefs.getBool(_howToUseShownKey) ?? false;

    if (!howToUseShown) {
      if (!mounted) return;
      _showHowToUseDialog();
    }
  }

  void _showHowToUseDialog() {
    bool dontShowAgain = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            "Driver Guide",
            style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Welcome, eTODA Driver! Here is how to manage your shift and trips:",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),
                    _buildInstructionItem(
                      icon: Icons.power_settings_new,
                      title: "Go Online/Offline",
                      description:
                          "Tap 'START SHIFT' to become visible to passengers. Toggle to 'END SHIFT' when you are taking a break.",
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      icon: Icons.hail_rounded,
                      title: "Receive Requests",
                      description:
                          "While online, trip requests will pop up automatically. Review the passenger, route, and fare before accepting.",
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      icon: Icons.view_carousel_rounded,
                      title: "Active Trips Carousel",
                      description:
                          "Ongoing rides appear in a carousel. You can handle multiple passengers and complete each trip upon arrival.",
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      icon: Icons.account_circle_outlined,
                      title: "Profile & Performance",
                      description:
                          "Visit 'MY PROFILE' to track your daily stats, earnings, and update your vehicle information.",
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      title: const Text(
                        "Don't show this again",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      value: dontShowAgain,
                      onChanged: (bool? newValue) {
                        setState(() {
                          dontShowAgain = newValue ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nagcarlanYellow,
                foregroundColor: nagcarlanGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                if (dontShowAgain) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_howToUseShownKey, true);
                }
                // Guard the dialog context specifically after the async gap
                if (!dialogContext.mounted) return;
                
                Navigator.of(dialogContext).pop();
              },
              child: const Text("READY TO DRIVE!", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: nagcarlanGreen, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: nagcarlanGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingTripsCarousel() {
    final ScrollController carouselController = ScrollController();

    return Column(
      children: [
        // Carousel with scroll indicators
        Stack(
          children: [
            SizedBox(
              height: 135, // Balanced height to match MenuCard proportions better
              child: ListView.builder(
                controller: carouselController,
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
                      isDriver: true,
                    ),
                  );
                },
              ),
            ),
            // Left scroll indicator
            if (ApiService.activeTrips.length > 1)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          nagcarlanGreen.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: nagcarlanWhite.withValues(alpha: 0.6),
                      size: 28,
                    ),
                  ),
                ),
              ),
            // Right scroll indicator
            if (ApiService.activeTrips.length > 1)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          nagcarlanGreen.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: nagcarlanWhite.withValues(alpha: 0.6),
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Page indicator dots
        if (ApiService.activeTrips.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                ApiService.activeTrips.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nagcarlanYellow.withValues(alpha: 0.5),
                    border: Border.all(color: nagcarlanYellow, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  int? _parsePassengerId(dynamic passengerId) {
    if (passengerId == null) return null;
    if (passengerId is num) return passengerId.toInt();
    if (passengerId is String) return int.tryParse(passengerId);
    return null;
  }

  String _resolvePassengerName(Map<String, dynamic> pData) {
    final firstName = pData['first_name']?.toString().trim();
    final lastName = pData['last_name']?.toString().trim();
    if (firstName != null && firstName.isNotEmpty) {
      final fullName =
          '$firstName${lastName != null && lastName.isNotEmpty ? ' $lastName' : ''}';
      return fullName.trim();
    }
    final name = pData['name']?.toString().trim();
    return (name != null && name.isNotEmpty) ? name : 'Passenger';
  }

  Future<void> _fetchMissingPassengerNames() async {
    for (final request in ApiService.pendingRequests) {
      final passengerName = request['passenger_name']?.toString().trim();
      if ((passengerName == null || passengerName.isEmpty) &&
          request['passenger_id'] != null) {
        final pId = _parsePassengerId(request['passenger_id']);
        if (pId != null) {
          final pData = await _apiService.getPassengerById(pId);
          if (pData != null && mounted) {
            request['passenger_name'] = _resolvePassengerName(pData);
          }
        }
      }
    }
  }

  Future<void> _showTripRequestModal() async {
    _isRequestModalOpen = true;
    final Map<String, dynamic>? driverData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String driverId =
        (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();

    // Ensure all passenger names are fetched before showing the modal
    await _fetchMissingPassengerNames();
    if (!context.mounted) return;

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: nagcarlanGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hail_rounded,
                      color: nagcarlanGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${ApiService.pendingRequests.length} New Request(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: nagcarlanGreen,
                      ),
                    ),
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
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: nagcarlanGreen.withValues(
                                  alpha: 0.1,
                                ),
                                radius: 24,
                                child: const Icon(
                                  Icons.person,
                                  color: nagcarlanGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          "Passenger",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: nagcarlanYellow.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            "₱${(request['fare'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: nagcarlanGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      request['passenger_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1),
                          ),
                          _buildDetailRow(
                            Icons.route_outlined,
                            "Route",
                            request['route'] ?? 'N/A',
                            isBold: true,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    ApiService().respondTripRequest({
                                      'request_id': request['request_id'],
                                      'driver_id': int.tryParse(driverId) ?? 0,
                                      'passenger_id':
                                          (request['passenger_id'] as num?)
                                              ?.toInt() ??
                                          0,
                                      'accepted': false,
                                    });
                                    setModalState(() {
                                      ApiService.pendingRequests.removeAt(
                                        index,
                                      );
                                    });
                                    setState(() {});
                                  },
                                  child: const Text(
                                    'Decline',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: nagcarlanGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    ApiService().respondTripRequest({
                                      'request_id': request['request_id'],
                                      'driver_id': int.tryParse(driverId) ?? 0,
                                      'passenger_id':
                                          (request['passenger_id'] as num?)
                                              ?.toInt() ??
                                          0,
                                      'accepted': true,
                                    });
                                    setModalState(() {
                                      ApiService.pendingRequests.removeAt(
                                        index,
                                      );
                                    });
                                    setState(() {});
                                  },
                                  child: const Text(
                                    'Accept Trip',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
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
    final String driverId =
        (driverData?['id'] ?? driverData?['driver_id'] ?? '').toString();
    try {
      final success = await _apiService.completeTrip(
        trip['trip_code'],
        int.tryParse(driverId) ?? 0,
      );
      if (success) {
        await _refreshActiveTrips(driverId);
        if (!mounted) return;
        if (_activeTripsCount == 0) {
          Navigator.of(
            context,
          ).pushNamed('/driver_trip_ended', arguments: driverData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Trip completed. You still have other ongoing trips.",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error completing trip: $e');
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: nagcarlanGreen.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
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
            icon: const Icon(
              Icons.account_circle,
              color: nagcarlanWhite,
              size: 35,
            ),
            onSelected: (value) {
              if (value == 'edit_profile') {
                Navigator.pushNamed(
                  context,
                  '/driver_edit_profile',
                  arguments: driverData,
                );
              } else if (value == 'logout') {
                ApiService.resetSession();
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
            decoration: nagcarlanGradient, // Background gradient
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 80), // Same as passenger_home
                          const Text(
                            "eTODA",
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: nagcarlanYellow,
                            ),
                          ),
                          const Text(
                            "NAGCARLAN",
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                              color: nagcarlanWhite,
                            ),
                          ),

                          Text(
                            "Welcome, ${driverData?['first_name'] ?? 'Driver'}",
                            style: const TextStyle(
                              fontSize: 18,
                              color: nagcarlanWhite,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: nagcarlanWhite.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isShiftActive
                                    ? nagcarlanYellow
                                    : Colors.white30,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _isShiftActive
                                        ? nagcarlanYellow
                                        : Colors.white30,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isShiftActive ? "ONLINE" : "OFFLINE",
                                  style: TextStyle(
                                    color: _isShiftActive
                                        ? nagcarlanYellow
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return SizeTransition(
                                    sizeFactor: animation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                            child:
                                (_isShiftActive &&
                                    ApiService.activeTrips.isNotEmpty)
                                ? Column(
                                    key: const ValueKey(
                                      'ongoing_trips_section',
                                    ),
                                    children: [
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "ONGOING TRIPS",
                                          style: TextStyle(
                                            color: nagcarlanYellow,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildOngoingTripsCarousel(),
                                      const SizedBox(height: 20),
                                    ],
                                  )
                                : const SizedBox(
                                    key: ValueKey('ongoing_trips_empty'),
                                  ),
                          ),

                          MenuCard(
                            title: _isShiftActive ? "END SHIFT" : "START SHIFT",
                            subtitle: _isShiftActive
                                ? "Go offline and take a break"
                                : "Go online to start receiving trips",
                            icon: _isShiftActive
                                ? Icons.power_settings_new
                                : Icons.play_circle_outline,
                            color: _isShiftActive
                                ? Colors.redAccent
                                : nagcarlanYellow,
                            textColor: _isShiftActive
                                ? nagcarlanWhite
                                : nagcarlanGreen,
                            onTap: _isLoadingShift ? () {} : _toggleShift,
                          ),

                          const SizedBox(
                            height: 20,
                          ), // Consistent spacing between MenuCards

                          MenuCard(
                            title: "MY PROFILE",
                            subtitle: "Trips, vehicle info & earnings",
                            icon: Icons.account_circle,
                            color: nagcarlanWhite.withValues(alpha: 0.9),
                            textColor: nagcarlanGreen,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/driver_profile',
                              arguments: driverData,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ), // Consistent spacing between MenuCards

                          MenuCard(
                            title: "TRIP HISTORY",
                            subtitle: "See your past rides",
                            icon: Icons.list_alt,
                            color: nagcarlanWhite.withValues(alpha: 0.9),
                            textColor: nagcarlanGreen,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/driver_trip_history',
                                arguments: driverData,
                              );
                            },
                          ),

                          const Spacer(), // Pushes menu cards up, footer to bottom
                          const BrandingFooter(), // Footer directly at the bottom
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoadingShift)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: nagcarlanYellow),
                    SizedBox(height: 20),
                    Text(
                      "Starting shift...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
      elevation: 4, // Matched with passenger_home
      shadowColor: Colors.black.withValues(alpha: 0.2),
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
