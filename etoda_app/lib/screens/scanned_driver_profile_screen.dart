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

  void _showFareCalculator(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => FareCalculatorDialog(driverData: data),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final Map<String, dynamic> d =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};

    // If data is already bundled from QR scan, use it immediately
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
    final String dbStatus = d['status']?.toString() ?? 'Inactive';
    final String qrStat = d['qr_status']?.toString() ?? '';
    final bool isOnline = dbStatus == 'Active';
    final bool isSuspended = dbStatus == 'Suspended' || qrStat == 'Revoked';
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
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
        actions: const [PassengerProfileMenu()],
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Profile Photo ──────────────────────────────────────────
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: profilePic.isNotEmpty
                          ? NetworkImage(
                              '${ApiService.baseUrl}/uploads/$profilePic',
                            )
                          : null,
                      child: profilePic.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 85,
                              color: Colors.green[200],
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
                        size: 36,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Driver Name ────────────────────────────────────────────
              Text(
                fullName.isEmpty ? 'DRIVER NAME' : fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: nagcarlanGreen,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // ── Rating (no background) ─────────────────────────────────
              if (_isRatingLoading)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 5),
                    Text(
                      '...',
                      style: TextStyle(fontSize: 14, color: Color(0xFF4E342E)),
                    ),
                  ],
                )
              else if (_totalRatings == 0)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'No ratings yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E342E),
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
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF33691E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Rating',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E342E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '·',
                      style: TextStyle(color: Color(0xFF4E342E), fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalRatings reviews',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4E342E),
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
                    _statusPill(label: "SUSPENDED", icon: Icons.block, color: Colors.red)
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
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 30),

              // ── Vehicle Details ────────────────────────────────────────
              InfoSectionCard(
                title: "VEHICLE DETAILS",
                icon: Icons.directions_car_filled_rounded,
                items: {
                  "Body Number": d['body_no']?.toString() ?? 'N/A',
                  "Plate Number": d['plate_number']?.toString() ?? 'N/A',
                  "Franchise": d['franchise']?.toString() ?? 'N/A',
                },
              ),
              const SizedBox(height: 16),

              // ── Trust & Safety ─────────────────────────────────────────
              InfoSectionCard(
                title: "TRUST & SAFETY",
                icon: Icons.security_rounded,
                items: {
                  "License": d['license_no']?.toString() ?? 'REGISTERED',
                  "Association":
                      d['association']?.toString() ?? 'Nagcarlan TODA',
                  "Member Since": d['created_at']?.toString() ?? 'N/A',
                },
              ),
              const SizedBox(height: 35),

              // ── Start Trip Button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    // Visually dim the button if inactive
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  onPressed: () {
                    if (isOnline && !isSuspended) {
                      _showFareCalculator(context, {
                          ...d,  // Include all driver data from QR lookup
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
                        SnackBar(
                          content: const Text("The driver is currently offline"),
                          backgroundColor: Colors.orange[800],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  label: Text(
                    "START TRIP NOW",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const BrandingFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
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
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
