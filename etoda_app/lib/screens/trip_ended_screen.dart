import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/rating_dialog.dart';
import 'package:etoda_nagcarlan/widgets/report_dialog.dart';

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

    // Extract and format the end time. 
    // We check if the backend already sent a pre-formatted string (e.g. "03:04 PM")
    String formattedEndTime = TimeOfDay.fromDateTime(DateTime.now()).format(context);
    final rawTimestamp = tripData?['ended_at'] ?? 
                        tripData?['completed_at'] ?? 
                        tripData?['cancelled_at'];

    if (rawTimestamp != null) {
      final String tsStr = rawTimestamp.toString();
      // If the string already contains AM/PM, it's pre-formatted by the backend.
      if (tsStr.contains(RegExp(r'(AM|PM)'))) {
        formattedEndTime = tsStr;
      } else {
        try {
          final DateTime parsedTime = DateTime.parse(tsStr).toLocal();
          formattedEndTime = TimeOfDay.fromDateTime(parsedTime).format(context);
        } catch (e) {
          debugPrint("Error parsing ended_at: $e");
        }
      }
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
                const SizedBox(height: 12),
                if (tripData != null)
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => ReportDialog(
                          passengerId: (tripData['passenger_id'] as num?)?.toInt() ?? 0,
                          driverId: (tripData['driver_id'] as num?)?.toInt() ?? 0,
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_problem_outlined, color: Colors.redAccent, size: 20),
                    label: const Text(
                      "REPORT AN ISSUE",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 16),
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