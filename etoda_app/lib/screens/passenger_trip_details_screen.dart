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

    final fare = (trip['fare_amount'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: nagcarlanWhite,
        elevation: 0,
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: Column(
          children: [
            const SizedBox(height: 100),
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
                        "Status": trip['status']?.toString().toUpperCase() ?? 'COMPLETED',
                        "Fare Paid": "₱${fare.toStringAsFixed(2)}",
                        "Payment Method": trip['payment_method'] ?? 'N/A',
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
                        "Contact": trip['driver_contact'] ?? '—',
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone_in_talk_outlined),
                        onPressed: () {
                          final contact = trip['driver_contact'] ?? 'N/A';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Calling driver ($contact)...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nagcarlanYellow,
                          foregroundColor: nagcarlanGreen,
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
