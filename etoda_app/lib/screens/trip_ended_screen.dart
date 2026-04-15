import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/rating_dialog.dart';

class TripEndedScreen extends StatelessWidget {
  const TripEndedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve arguments passed via Navigator. 
    // These contain the final details of the completed trip.
    final Map<String, dynamic>? tripData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String status = tripData?['status']?.toString().toLowerCase() ?? 'completed';
    final bool isCancelled = status == 'cancelled';
    final Color themeColor = isCancelled ? Colors.red : nagcarlanGreen;

    // Extract and format the end time from the WebSocket payload if available
    String formattedEndTime = "Just now";
    try {
      // Use payload timestamp or fallback to current system time for a "real-time" finish clock
      // prioritize 'ended_at' from the database logs
      final timestamp = tripData?['ended_at'] ?? 
                        tripData?['completed_at'] ?? 
                        tripData?['cancelled_at'] ??
                        DateTime.now().toIso8601String();

      if (timestamp != null) {
        final DateTime endTime = DateTime.parse(timestamp.toString()).toLocal();
        final int hour = endTime.hour > 12 ? endTime.hour - 12 : (endTime.hour == 0 ? 12 : endTime.hour);
        final String period = endTime.hour >= 12 ? 'PM' : 'AM';
        final String minutes = endTime.minute.toString().padLeft(2, '0');
        formattedEndTime = "$hour:$minutes $period";
      }
    } catch (e) {
      debugPrint("Error parsing ended_at: $e");
    }

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
                Icon(
                  isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  color: themeColor,
                  size: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  isCancelled ? "TRIP CANCELLED" : "TRIP COMPLETED",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: themeColor,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  isCancelled ? "This trip was cancelled by the driver." : "The trip has been successfully finalized.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                if (tripData != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow("Trip ID", "#${tripData['trip_code'] ?? '—'}"),
                        const Divider(height: 32),
                        _buildSummaryRow("Passenger", tripData['passenger_name'] ?? 'Guest'),
                        const Divider(height: 32),
                        _buildSummaryRow(isCancelled ? "Cancelled At" : "Finished At", formattedEndTime),
                        const Divider(height: 32),
                        // Handle both 'fare' and 'fare_amount' keys found in your logs
                        _buildSummaryRow(
                          "Total Fare", 
                          "₱${((tripData['fare'] ?? tripData['fare_amount']) as num?)?.toStringAsFixed(2) ?? '0.00'}",
                          isTotal: true, color: themeColor,
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isCancelled 
                      ? () => Navigator.of(context).pop()
                      : () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => RatingDialog(
                              passengerId: (tripData?['passenger_id'] as num?)?.toInt() ?? 0,
                              driverId: (tripData?['driver_id'] as num?)?.toInt() ?? 0,
                              onSubmitted: () {
                                Navigator.of(dialogContext).pop(); 
                                Navigator.of(context).pop();       
                              },
                            ),
                          );
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
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

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
            color: isTotal ? (color ?? nagcarlanGreen) : Colors.black87,
          ),
        ),
      ],
    );
  }
}