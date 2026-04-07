
import 'package:etoda_nagcarlan/main.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class PassengerTripDetailsScreen extends StatelessWidget {
  const PassengerTripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> trip =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    InfoSectionCard(
                      title: "TRIP OVERVIEW",
                      icon: Icons.receipt_long_outlined,
                      items: {
                        "Date": trip['started_at'] ?? 'N/A',
                        "Route": trip['route'] ?? 'N/A',
                        "Fare Paid": "₱${trip['fare_amount'] ?? '0.00'}",
                        "Reference": trip['trip_code'] ?? 'N/A',
                      },
                    ),
                    const SizedBox(height: 16),
                    InfoSectionCard(
                      title: "DRIVER DETAILS",
                      icon: Icons.person_outline,
                      items: {
                        "Name": trip['driver_name'] ?? 'N/A',
                        "Plate Number": trip['plate_number'] ?? 'N/A',
                        "Body Number": trip['body_no'] ?? 'N/A',
                      },
                    ),
                    const SizedBox(height: 24),
                    // --- Contact Driver Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone_in_talk_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Calling driver (simulation)...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nagcarlanGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          "CALL DRIVER",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: BrandingFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
