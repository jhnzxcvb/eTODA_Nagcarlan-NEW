import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart'; // To access nagcarlanGreen
import 'package:etoda_nagcarlan/widgets/report_dialog.dart';

class TripStartedScreen extends StatefulWidget {
  final int passengerId;
  final int driverId;

  const TripStartedScreen({
    super.key,
    required this.passengerId,
    required this.driverId,
  });

  @override
  State<TripStartedScreen> createState() => _TripStartedScreenState();
}

class _TripStartedScreenState extends State<TripStartedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: nagcarlanGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: nagcarlanGradient, // Using your existing yellow/green gradient
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            
            // Large Checkmark Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: nagcarlanGreen,
                size: 120,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              "Trip Started!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: nagcarlanGreen,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              "Have a safe and comfortable ride.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            
            const Spacer(flex: 2),

            // Refined Report Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ReportDialog(
                      passengerId: widget.passengerId,
                      driverId: widget.driverId,
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 20),
                label: const Text(
                  "Report an Issue",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[700]!, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}