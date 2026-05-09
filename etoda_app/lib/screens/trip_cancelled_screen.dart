import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class TripCancelledScreen extends StatelessWidget {
  const TripCancelledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? tripData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.cancel_rounded,
                  color: Colors.red,
                  size: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  "TRIP CANCELLED",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "The driver has cancelled the trip activity.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Any payments made will be processed according to standard policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                
                if (tripData != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildRow("Trip ID", "#${tripData['trip_code'] ?? '—'}"),
                        const Divider(height: 32),
                        _buildRow("Driver", tripData['driver_name'] ?? 'Driver'),
                        const Divider(height: 32),
                        _buildRow("Route", tripData['route'] ?? '—'),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "RETURN TO DASHBOARD",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
    );
  }
}