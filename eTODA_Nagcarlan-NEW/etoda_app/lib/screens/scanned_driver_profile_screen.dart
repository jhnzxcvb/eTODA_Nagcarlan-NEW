
import 'package:etoda_nagcarlan/widgets/passenger_profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/widgets/fare_calculator_dialog.dart';

class ScannedDriverProfileScreen extends StatelessWidget {
  const ScannedDriverProfileScreen({super.key});

  void _showFareCalculator(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const FareCalculatorDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Details"),
        actions: const [
          PassengerProfileMenu(),
        ],
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // --- Enhanced Driver Avatar with Verification ---
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, color: Colors.blue, size: 32),
                  )
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "JUAN A. DELA CRUZ",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: nagcarlanGreen),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.star_rounded, color: nagcarlanGold, size: 20),
                   SizedBox(width: 4),
                   Text("4.8 Rating", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen, fontSize: 15)),
                   SizedBox(width: 16),
                   Icon(Icons.history_toggle_off_rounded, color: nagcarlanGreen, size: 18),
                   SizedBox(width: 4),
                   Text("5k+ Trips", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 24),
              // --- Updated Vehicle Details ---
              const InfoSectionCard(
                title: "VEHICLE DETAILS",
                icon: Icons.directions_car_outlined,
                items: {
                  "Body Number": "01",
                  "Plate Number": "NA 12345",
                  "Model": "Kawasaki Barako 175", // Added for easier identification
                },
              ),
              const SizedBox(height: 12),
              // --- Updated Trust & Safety Details ---
              const InfoSectionCard(
                title: "TRUST & SAFETY",
                icon: Icons.shield_outlined,
                items: {
                  "Member Since": "June 2023",
                  "Franchise Status": "Verified & Active",
                  "Health Status": "Fully Vaccinated", // Added for passenger confidence
                  "Languages": "Tagalog, English",   // Added for communication clarity
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.trip_origin_rounded),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: nagcarlanGreen, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showFareCalculator(context),
                  label: const Text(
                    "START TRIP NOW",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
