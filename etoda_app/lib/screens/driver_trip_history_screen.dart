import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class DriverTripHistoryScreen extends StatelessWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for driver's past trips
    final List<Map<String, String>> pastTrips = [
      {
        "date": "Oct 24, 2023 - 10:30 AM",
        "passenger": "Maria Santos",
        "route": "Poblacion to Talangan",
        "fare": "₱30.00",
        "type": "Regular",
      },
      {
        "date": "Oct 24, 2023 - 09:15 AM",
        "passenger": "John Doe",
        "route": "Oobi to Poblacion",
        "fare": "₱50.00",
        "type": "Special Trip",
      },
      {
        "date": "Oct 23, 2023 - 04:45 PM",
        "passenger": "Ana Reyes",
        "route": "Talangan to Malinao",
        "fare": "₱24.00",
        "type": "Student Discount",
      },
      {
        "date": "Oct 23, 2023 - 02:20 PM",
        "passenger": "Roberto Cruz",
        "route": "Nagcarlan Market to Yukos",
        "fare": "₱30.00",
        "type": "Regular",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip History"),
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pastTrips.length,
                itemBuilder: (context, index) {
                  final trip = pastTrips[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(trip['date']!, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: nagcarlanGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(trip['type']!, style: const TextStyle(color: nagcarlanGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18, color: nagcarlanGreen),
                              const SizedBox(width: 8),
                              Text(trip['passenger']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.route_outlined, size: 18, color: nagcarlanGreen),
                              const SizedBox(width: 8),
                              Expanded(child: Text(trip['route']!, style: const TextStyle(color: Colors.black87))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text("Fare Collected: ", style: TextStyle(color: Colors.black54)),
                              Text(trip['fare']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: nagcarlanGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const BrandingFooter(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
