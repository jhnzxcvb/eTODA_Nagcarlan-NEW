import 'package:etoda_nagcarlan/main.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class DriverTripDetailsScreen extends StatelessWidget {
  const DriverTripDetailsScreen({super.key});

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
                        "Date": trip['ended_at'] ?? 'N/A',
                        "Route": trip['route'] ?? 'N/A',
                        "Status": trip['status']?.toString().toUpperCase() ?? 'COMPLETED',
                        "Fare Collected": "₱${fare.toStringAsFixed(2)}",
                        "Payment Method": trip['payment_method'] ?? 'N/A',
                        "Reference": trip['trip_code'] ?? 'N/A',
                        "Duration": "${trip['duration_min'] ?? 0} min",
                      },
                    ),
                    const SizedBox(height: 16),
                    InfoSectionCard(
                      title: "PASSENGER DETAILS",
                      icon: Icons.person_outline,
                      items: {
                        "Name": trip['passenger_name'] ?? 'Guest',
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "This trip record is saved in the official TODA ledger.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
