
import 'package:etoda_nagcarlan/main.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class PassengerTripDetailsScreen extends StatelessWidget {
  const PassengerTripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    const InfoSectionCard(
                      title: "TRIP OVERVIEW",
                      icon: Icons.receipt_long_outlined,
                      items: {
                        "Date": "FEB 22, 2026",
                        "Route": "Poblacion to Talangan",
                        "Fare Paid": "P15.00",
                        "Status": "Completed",
                      },
                    ),
                    const SizedBox(height: 16),
                    const InfoSectionCard(
                      title: "DRIVER DETAILS",
                      icon: Icons.person_outline,
                      items: {
                        "Name": "Juan A. Dela Cruz",
                        "Contact Number": "0912-345-6789",
                        "Plate Number": "NA 12345",
                        "Body Number": "01",
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
