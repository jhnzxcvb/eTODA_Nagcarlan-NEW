
import 'package:etoda_nagcarlan/main.dart';
import 'package:flutter/material.dart';

class PassengerTripHistoryScreen extends StatelessWidget {
  const PassengerTripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trip History'),
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: const [
            // Placeholder for a list of trips
            TripHistoryItem(
              route: "Poblacion to Talangan",
              driver: "Juan A. Dela Cruz",
              fare: "₱15.00",
              date: "FEB 22, 2026",
            ),
            TripHistoryItem(
              route: "Special Trip (Malinao)",
              driver: "Pedro Penduko",
              fare: "₱50.00",
              date: "FEB 20, 2026",
            ),
            // Add more trips here
          ],
        ),
      ),
    );
  }
}

class TripHistoryItem extends StatelessWidget {
  final String route;
  final String driver;
  final String fare;
  final String date;

  const TripHistoryItem({
    super.key,
    required this.route,
    required this.driver,
    required this.fare,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/passenger_trip_details');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.directions_car_filled_outlined, color: nagcarlanGreen, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Driver: $driver", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fare, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: nagcarlanGreen)),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
