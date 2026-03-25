import 'package:etoda_nagcarlan/widgets/passenger_profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/widgets/fare_calculator_dialog.dart';

class ScannedDriverProfileScreen extends StatelessWidget {
  const ScannedDriverProfileScreen({super.key});

  void _showFareCalculator(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => FareCalculatorDialog(driverData: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> d =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};

    final int passengerId = (d['passenger_id'] as num?)?.toInt() ?? 0;
    final int driverId = (d['id'] as num?)?.toInt() ?? 
                         (d['driver_id'] as num?)?.toInt() ?? 
                         int.tryParse(d['id']?.toString() ?? '') ?? 0;
    
    final String first = d['first_name']?.toString() ?? '';
    final String last = d['last_name']?.toString() ?? '';
    final String fullName = "$first $last".trim().toUpperCase();
    final String dbStatus = d['status']?.toString() ?? 'Inactive';
    final String qrStat = d['qr_status']?.toString() ?? '';
    final bool isActive = dbStatus == 'Active' && qrStat != 'Revoked';
    final bool isVerified = d['license_no']?.toString().isNotEmpty ?? false;

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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[100],
                      child: Icon(Icons.person, size: 85, color: Colors.green[200]),
                    ),
                  ),
                  if (isVerified)
                    Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified, color: Colors.blue, size: 36),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                fullName.isEmpty ? 'DRIVER NAME' : fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: nagcarlanGreen, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statusPill(
                    label: isActive ? "ACTIVE" : "INACTIVE", 
                    icon: isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 10),
                    _statusPill(label: "VERIFIED", icon: Icons.shield_rounded, color: Colors.blue),
                  ],
                ],
              ),
              const SizedBox(height: 30),
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
              InfoSectionCard(
                title: "TRUST & SAFETY",
                icon: Icons.security_rounded,
                items: {
                  "License": d['license_no']?.toString() ?? 'REGISTERED',
                  "Association": d['association']?.toString() ?? 'Nagcarlan TODA',
                  "Member Since": d['created_at']?.toString() ?? 'N/A',
                },
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? const Color(0xFF1B5E20) : Colors.grey[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isActive
                      ? () => _showFareCalculator(context, {
                            'passenger_id': passengerId,
                            'driver_id': driverId,
                            'full_name': fullName,
                            'body_no': d['body_no'],
                          })
                      : null,
                  label: Text(isActive ? "START TRIP NOW" : "DRIVER UNAVAILABLE", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _statusPill({required String label, required IconData icon, required Color color}) {
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
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}