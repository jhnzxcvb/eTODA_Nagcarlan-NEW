import 'package:etoda_nagcarlan/widgets/passenger_profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/widgets/fare_calculator_dialog.dart';

class ScannedDriverProfileScreen extends StatelessWidget {
  const ScannedDriverProfileScreen({super.key});

  void _showFareCalculator(BuildContext context, Map<String, dynamic> driverData) {
    showDialog(
      context: context,
      builder: (_) => FareCalculatorDialog(driverData: driverData),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Extract args from scanner ──
    final dynamic args = ModalRoute.of(context)!.settings.arguments;
    final Map<String, dynamic> d = (args is Map<String, dynamic>) ? args : {};

    debugPrint("!!! DRIVER DATA LOADED: $d");

    // ── Build full name from Go JSON tags: first_name, middle_name, last_name ──
    final String first  = d['first_name']?.toString().trim()  ?? '';
    final String middle = d['middle_name']?.toString().trim() ?? '';
    final String last   = d['last_name']?.toString().trim()   ?? '';
    final String fullName = [first, middle, last]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .toUpperCase();

    // ── Map Go JSON tags correctly ──
    final String bodyNo      = d['body_no']?.toString()      ?? 'N/A';   // Go: body_no
    final String plateNumber = d['plate_number']?.toString() ?? 'N/A';   // Go: plate_number
    final String franchise   = d['franchise']?.toString()    ?? 'N/A';   // Go: franchise
    final String licenseNo   = d['license_no']?.toString()   ?? 'N/A';   // Go: license_no
    final String contact     = d['contact']?.toString()      ?? 'N/A';   // Go: contact
    final String association = d['association']?.toString()   ?? 'Nagcarlan TODA'; // Go: association
    final String status      = d['status']?.toString()       ?? 'Unknown'; // Go: status — "Active" or "Inactive"
    final String qrStatus    = d['qr_status']?.toString()    ?? '';        // Go: qr_status

    final bool isActive = status == 'Active';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Details"),
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
        actions: const [PassengerProfileMenu()],
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // ── Avatar + verified badge ──
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 80, color: Color(0xFFA5D6A7)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      isActive ? Icons.verified : Icons.cancel,
                      color: isActive ? Colors.blue : Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Driver name ──
              Text(
                fullName.isEmpty ? 'UNKNOWN DRIVER' : fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: nagcarlanGreen,
                ),
              ),
              const SizedBox(height: 6),

              // ── Active / Suspended pill ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? '✓ Active Driver' : '✗ Suspended',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isActive ? nagcarlanGreen : Colors.red[700],
                  ),
                ),
              ),

              // ── Revoked QR warning ──
              if (qrStatus == 'Revoked') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'QR Code Revoked',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Vehicle details ──
              InfoSectionCard(
                title: "VEHICLE DETAILS",
                icon: Icons.directions_car_outlined,
                items: {
                  "Body Number":  bodyNo,
                  "Plate Number": plateNumber,
                  "Franchise":    franchise,
                },
              ),
              const SizedBox(height: 12),

              // ── Trust & Safety ──
              InfoSectionCard(
                title: "TRUST & SAFETY",
                icon: Icons.shield_outlined,
                items: {
                  "TODA Association": association,
                  "License No.":      licenseNo,
                  "Contact":          contact,
                  "Verification":     isActive ? "Verified & Active" : "Suspended",
                },
              ),
              const SizedBox(height: 24),

              // ── Start Trip button — disabled if suspended or revoked ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.trip_origin_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isActive && qrStatus != 'Revoked')
                        ? nagcarlanGreen
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (isActive && qrStatus != 'Revoked')
                      ? () => _showFareCalculator(context, d)
                      : null,
                  label: Text(
                    (isActive && qrStatus != 'Revoked')
                        ? "START TRIP NOW"
                        : "DRIVER UNAVAILABLE",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const BrandingFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}