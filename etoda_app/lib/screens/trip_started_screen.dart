
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/report_dialog.dart';

class TripStartedScreen extends StatefulWidget {
  const TripStartedScreen({super.key});

  @override
  State<TripStartedScreen> createState() => _TripStartedScreenState();
}

class _TripStartedScreenState extends State<TripStartedScreen> {

  @override
  void initState() {
    super.initState();
    // Show the notification after the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 16),
              Expanded(child: Text('Payment successful! Your trip is starting.')),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    });
  }

  void _endTrip(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/trip_ended');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),
            const Icon(Icons.check_circle_outline, color: nagcarlanGreen, size: 120),
            const SizedBox(height: 24),
            const Text(
              "Trip Started!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: nagcarlanGreen),
            ),
            const SizedBox(height: 8),
            Text(
              "Enjoy your ride. We're here to ensure your safety.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const Spacer(flex: 3),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700], // A distinct color for ending the trip
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _endTrip(context),
              child: const Text("END TRIP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ReportDialog(),
                );
              },
              icon: Icon(Icons.support_agent, color: Colors.blue[700]),
              label: Text("Report or Get Help", style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
            ),
             const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
