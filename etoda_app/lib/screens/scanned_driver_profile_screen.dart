import 'dart:async';
import 'package:etoda_nagcarlan/widgets/passenger_profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/widgets/fare_calculator_dialog.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

class ScannedDriverProfileScreen extends StatefulWidget {
  const ScannedDriverProfileScreen({super.key});

  @override
  State<ScannedDriverProfileScreen> createState() =>
      _ScannedDriverProfileScreenState();
}

class _ScannedDriverProfileScreenState
    extends State<ScannedDriverProfileScreen> {
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isRatingLoading = true;
  String _currentStatus = 'Inactive';
  StreamSubscription? _wsSubscription;
  bool _isInitialized = false;

  void _showFareCalculator(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => FareCalculatorDialog(driverData: data),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      final Map<String, dynamic> d =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
          {};
      _currentStatus = d['status']?.toString() ?? 'Inactive';
      _loadRating();
      _setupWebSocketListener();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    ApiService.disconnectWebSocket();
    super.dispose();
  }

  Future<void> _loadRating() async {
    final Map<String, dynamic> d =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};

    if (d.containsKey('average_rating')) {
      if (mounted) {
        setState(() {
          _averageRating = (d['average_rating'] as num?)?.toDouble() ?? 0.0;
          _totalRatings = (d['total_ratings'] as num?)?.toInt() ?? 0;
          _isRatingLoading = false;
        });
      }
      return;
    }

    final int driverId = (d['id'] as num?)?.toInt() ?? (d['driver_id'] as num?)?.toInt() ?? 0;

    if (driverId != 0) {
      final ratingData = await ApiService().fetchDriverRating(driverId);
      if (mounted) {
        setState(() {
          _averageRating = (ratingData['average_rating'] as num?)?.toDouble() ?? 0.0;
          _totalRatings = (ratingData['total_ratings'] as num?)?.toInt() ?? 0;
          _isRatingLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isRatingLoading = false);
    }
  }

  Future<void> _setupWebSocketListener() async {
    final Map<String, dynamic> d =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};
    final int passengerId = (d['passenger_id'] as num?)?.toInt() ?? 0;
    final int driverId =
        (d['id'] as num?)?.toInt() ??
        (d['driver_id'] as num?)?.toInt() ??
        int.tryParse(d['id']?.toString() ?? '') ??
        0;

    debugPrint('🔌 Scanned screen: passengerId=$passengerId, driverId=$driverId');

    if (passengerId != 0 && driverId != 0) {
      _wsSubscription?.cancel();
      
      // Await the connection to ensure the stream is initialized
      await ApiService.connectPassengerWebSocket(passengerId.toString());
      final wsStream = ApiService.getWebSocketStream();
      
      if (wsStream != null) {
        _wsSubscription = wsStream.listen((message) {
          debugPrint('📨 Scanned screen received: $message');
          if (message['event'] == 'driver_status_update' &&
              int.tryParse(message['driver_id']?.toString() ?? '') == driverId &&
              mounted) {
            debugPrint('✅ Updating status to ${message['status']}');
            setState(() {
              _currentStatus = message['status']?.toString() ?? 'Inactive';
            });
          }
        });
      } else {
        debugPrint('❌ WebSocket stream is null');
      }
    } else {
      debugPrint('❌ Not connecting WebSocket: passengerId=$passengerId, driverId=$driverId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> d =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};

    final int passengerId = (d['passenger_id'] as num?)?.toInt() ?? 0;
    final int driverId =
        (d['id'] as num?)?.toInt() ??
        (d['driver_id'] as num?)?.toInt() ??
        int.tryParse(d['id']?.toString() ?? '') ??
        0;

    final String first = d['first_name']?.toString() ?? '';
    final String last = d['last_name']?.toString() ?? '';
    final String fullName = "$first $last".trim().toUpperCase();
    final String qrStat = d['qr_status']?.toString() ?? '';
    final bool isOnline = _currentStatus == 'Active';
    final bool isSuspended = _currentStatus == 'Suspended' || qrStat == 'Revoked';
    final bool isVerified = d['license_no']?.toString().isNotEmpty ?? false;
    final String profilePic = d['profile_pic']?.toString() ?? '';

    final String contactNumber =
        d['contact_number']?.toString() ??
        d['phone']?.toString() ??
        d['contact']?.toString() ??
        d['phone_number']?.toString() ??
        d['mobile']?.toString() ??
        '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: nagcarlanGreen,
        centerTitle: true,
        actions: const [PassengerProfileMenu()],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // ── Profile Photo ──────────────────────────────────────────
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: nagcarlanGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              backgroundImage: profilePic.isNotEmpty
                                  ? NetworkImage(
                                      '${ApiService.baseUrl}/uploads/$profilePic',
                                    )
                                  : null,
                              child: profilePic.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 75,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          if (isVerified)
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Driver Name ────────────────────────────────────────────
                      Text(
                        fullName.isEmpty ? 'DRIVER NAME' : fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: nagcarlanGreen,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ── Rating ─────────────────────────────────
                      if (_isRatingLoading)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded, color: nagcarlanYellow, size: 18),
                            SizedBox(width: 5),
                            Text(
                              '...',
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        )
                      else if (_totalRatings == 0)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: nagcarlanYellow,
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'No ratings yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: nagcarlanYellow,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: nagcarlanGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Rating',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '·',
                              style: TextStyle(color: Colors.black26, fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_totalRatings reviews',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // ── Status Pills ───────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSuspended)
                            _statusPill(label: "SUSPENDED", icon: Icons.block, color: Colors.redAccent)
                          else
                            _statusPill(
                            label: isOnline ? "ACTIVE" : "OFFLINE",
                            icon: isOnline ? Icons.check_circle_rounded : Icons.power_settings_new_rounded,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 10),
                            _statusPill(
                              label: "VERIFIED",
                              icon: Icons.shield_rounded,
                              color: Colors.blueAccent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Vehicle Details ────────────────────────────────────────
                      _buildElevatedCard(
                        child: InfoSectionCard(
                          title: "VEHICLE DETAILS",
                          icon: Icons.directions_car_filled_rounded,
                          items: {
                            "Body Number": d['body_no']?.toString() ?? 'N/A',
                            "Plate Number": d['plate_number']?.toString() ?? 'N/A',
                            "Franchise": d['franchise']?.toString() ?? 'N/A',
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Trust & Safety ─────────────────────────────────────────
                      _buildElevatedCard(
                        child: InfoSectionCard(
                          title: "TRUST & SAFETY",
                          icon: Icons.security_rounded,
                          items: {
                            "License": d['license_no']?.toString() ?? 'REGISTERED',
                            "Association":
                                d['association']?.toString() ?? 'Nagcarlan TODA',
                            "Member Since": d['created_at']?.toString() ?? 'N/A',
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Start Trip Button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nagcarlanGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        onPressed: () {
                          if (isOnline && !isSuspended) {
                            _showFareCalculator(context, {
                                ...d, 
                                'passenger_id': passengerId,
                                'driver_id': driverId,
                                'full_name': fullName,
                                'body_no': d['body_no'],
                                'contact_number': contactNumber,
                            });
                          } else if (isSuspended) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("BANNED: This driver's account has been suspended."),
                                backgroundColor: Colors.black,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("The driver is currently offline"),
                                backgroundColor: Colors.black87,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        label: const Text(
                          "START TRIP NOW",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const BrandingFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // Darker shadow for "elevated black" look
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statusPill({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
