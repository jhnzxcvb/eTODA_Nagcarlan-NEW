import 'dart:async';
import 'package:etoda_nagcarlan/widgets/app_rating_banner.dart';
import 'package:etoda_nagcarlan/widgets/passenger_profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with RouteAware {
  bool _isTripInProgress = false;
  Map<String, dynamic>? _activeTripData;
  StreamSubscription? _wsSubscription; // Manages WebSocket subscription
  bool _isInitialized = false; // Tracks if initial setup is done
  bool _isRouteSubscribed = false; // Tracks if route observer is subscribed
  static const String _howToUseShownKey = 'howToUseShown'; // Key for SharedPreferences
  static bool _hasShownHowToUse = false; // Flag to prevent showing how-to-use dialog multiple times
  final ApiService _apiService = ApiService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_isRouteSubscribed && route is PageRoute) {
      routeObserver.subscribe(this, route);
      _isRouteSubscribed = true;
    }
    if (!_isInitialized) {
      // Clear any potential leftover driver state to prevent leakage
      if (ApiService.isDriverOnline) {
        ApiService.resetSession();
      }

      // Reset local state. We'll fetch the actual status from the server immediately.
      _isTripInProgress = false;
      _activeTripData = null;

      _refreshTripStatus();
      _setupWebSocket();
      _isInitialized = true;
    }

    // Show how-to-use dialog only once per session and if not a guest
    final Map<String, dynamic>? passengerData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isGuest = passengerData?['is_guest'] ?? false;
    if (!isGuest && !_hasShownHowToUse) {
      _hasShownHowToUse = true; 
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowHowToUseDialog());
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    if (_isRouteSubscribed) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshTripStatus();
    _setupWebSocket();
  }

  Future<void> _refreshTripStatus() async {
    final Map<String, dynamic>? passengerData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (passengerData == null || passengerData['is_guest'] == true) return;

    final String passengerId =
        (passengerData['user_id'] ?? passengerData['id'] ?? '').toString();
    if (passengerId.isEmpty) return;

    final trips = await _apiService.fetchOngoingPassengerTrips(passengerId);
    if (mounted) {
      if (trips == null || trips.isEmpty) {
        ApiService.cachedPassengerTripStartAt = null;
      } else {
        final activeTrip = trips.first;
        ApiService.cachedPassengerTripStartAt = activeTrip['started_at']?.toString() ??
            activeTrip['paid_at']?.toString() ??
            activeTrip['created_at']?.toString();
      }
      setState(() {
        _isTripInProgress = trips != null && trips.isNotEmpty;
        _activeTripData = _isTripInProgress ? trips!.first : null;
      });
    }
  }

  Future<void> _setupWebSocket() async {
    final Map<String, dynamic>? passengerData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (passengerData == null || passengerData['is_guest'] == true) return;
    final String passengerId =
        (passengerData['user_id'] ?? passengerData['id'] ?? '').toString();

    await ApiService.connectPassengerWebSocket(passengerId);
    final stream = ApiService.getWebSocketStream();
    if (stream != null) {
      _wsSubscription?.cancel();
      _wsSubscription = stream.listen((message) {
        final event = message['event'];
        if (event == 'trip_started' || event == 'trip_ended' || event == 'trip_cancelled') {
          if (mounted && (event == 'trip_ended' || event == 'trip_cancelled')) {
            // Only trigger navigation if the Home Screen is the current active route.
            // If TripStartedScreen is open, it will handle its own navigation.
            final bool isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
            
            if (isCurrent) {
              final Map<String, dynamic> tripData = message['trip'] != null
                  ? Map<String, dynamic>.from(message['trip'])
                  : {};
              
              // Set status for TripEndedScreen to handle UI variations
              tripData['status'] = (event == 'trip_cancelled') ? 'cancelled' : 'completed';
              
              Navigator.pushNamed(context, '/trip_ended', arguments: tripData);
            }
          }
          _refreshTripStatus();
        }
      });
    }
  }

  void _showGuestRestrictionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nagcarlanWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: nagcarlanGreen, size: 28),
            SizedBox(width: 12),
            Text(
              "Access Restricted",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: nagcarlanGreen,
              ),
              
            ),
          ],
        ),
        content: const Text(
          "This feature is only available for registered users. Please create an account to enjoy full access to eTODA Nagcarlan.",
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "LATER",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nagcarlanYellow,
              foregroundColor: nagcarlanGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/signup');
            },
            child: const Text(
              "SIGN UP NOW",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
    bool dontShowAgain = false; // State for the checkbox within the dialog

    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with buttons
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "How to Use eTODA Nagcarlan",
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
                      "Welcome to eTODA Nagcarlan! Here's a quick guide to get you started:",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),
                    _buildInstructionItem(
                      icon: Icons.qr_code_scanner,
                      title: "Scan Driver QR",
                      description:
                          "Tap 'SCAN DRIVER QR' to verify your driver's identity and start your trip securely. This ensures you're riding with a registered eTODA driver.",
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.payments,
                      title: "Fare Matrix",
                      description:
                          "Check the 'FARE MATRIX' to see the official rates for different routes. This helps you know the exact fare before your journey.",
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionItem(
                      icon: Icons.directions_car,
                      title: "Ongoing Trip Card",
                      description:
                          "If you have an active trip, a 'TRIP IN PROGRESS' card will appear. Tap it to view live details. You can also report any issues directly from the trip details screen.",
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (dontShowAgain) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_howToUseShownKey, true);
                }
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext); // Close the dialog
              },
              child: const Text("GOT IT!", style: TextStyle(fontWeight: FontWeight.bold)),
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
        const SizedBox(width: 10),
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

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? passengerData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bool isGuest = passengerData?['is_guest'] ?? false;

    final Map<String, dynamic> mergedData = {
      ...passengerData ?? {},
      if (_activeTripData != null) ..._activeTripData!,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isGuest
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: nagcarlanGreen),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
              )
            : null,
        actions: [
          if (!isGuest) PassengerProfileMenu(passengerData: passengerData),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: nagcarlanGradient,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text(
              "eTODA",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: nagcarlanGreen,
              ),
            ),
            const Text(
              "NAGCARLAN",
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            Text(
              isGuest
                  ? "Logged in as Guest"
                  : "Welcome, ${passengerData?['first_name'] ?? 'Passenger'}",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            if (_isTripInProgress) ...[
              _buildTripInProgressCard(context, mergedData),
              const SizedBox(height: 20),
            ],

            MenuCard(
              title: "SCAN DRIVER QR",
              subtitle: "Verify your driver safely",
              icon: Icons.qr_code_scanner,
              color: nagcarlanYellow,
              textColor: nagcarlanGreen,
              onTap: () {
                if (isGuest) {
                  _showGuestRestrictionDialog(context);
                } else {
                  Navigator.pushNamed(
                    context,
                    '/scan_qr',
                    arguments: passengerData,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            MenuCard(
              title: "FARE MATRIX",
              subtitle: "Check exact rates per area",
              icon: Icons.payments,
              color: Colors.white.withValues(alpha: 0.9),
              textColor: nagcarlanGreen,
              onTap: () => Navigator.pushNamed(context, '/fare_matrix'),
            ),
            if (!isGuest) const AppRatingBanner(),
            const Spacer(),
            const BrandingFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInProgressCard(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: nagcarlanYellow, width: 2),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/trip_started',
            arguments: {
              'passenger_id': data?['user_id'] ?? data?['id'] ?? 0,
              'driver_id': data?['driver_id'] ?? data?['last_driver_id'] ?? 0,
              'initial_trip_start': data?['started_at'] ??
                  data?['paid_at'] ?? data?['created_at'],
            },
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        nagcarlanYellow,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  Icon(Icons.directions_car, color: nagcarlanGreen, size: 28),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TRIP IN PROGRESS",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: nagcarlanGreen,
                      ),
                    ),
                    if (data != null &&
                        (data['driver_name'] != null ||
                            data['last_driver_name'] != null))
                      Text(
                        "You're riding with ${data['driver_name'] ?? data['last_driver_name']}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    Text(
                      "Tap to view details",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: nagcarlanGreen,
              ),
            ],
          ),
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
                        color: textColor.withAlpha(178),
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
