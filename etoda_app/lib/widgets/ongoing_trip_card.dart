import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

/// OngoingTripCard displays an active trip with passenger details, route, and fare.
/// 
/// Constructor parameters:
/// - tripData: Map containing trip information (passenger_name, origin, destination, fare, status)
/// - onCompleteTap: Callback when "Complete Trip" button is tapped
class OngoingTripCard extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final VoidCallback onCompleteTap;
  final VoidCallback onCancelTap;

  const OngoingTripCard({
    super.key,
    required this.tripData,
    required this.onCompleteTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    final String passengerName = tripData['passenger_name'] ?? 'Passenger';
    final String origin = tripData['origin'] ?? '—';
    final String destination = tripData['destination'] ?? '—';
    final double fare = (tripData['fare'] is num) 
        ? (tripData['fare'] as num).toDouble() 
        : (tripData['fare_amount'] is num) 
            ? (tripData['fare_amount'] as num).toDouble()
            : 0.0;
    final String status = tripData['status']?.toString().toLowerCase() ?? 'ongoing';

    return Card(
      elevation: 8,
      shadowColor: nagcarlanGreen.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: nagcarlanGreen, width: 2),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header: Passenger name & status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: nagcarlanGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Passenger',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.substring(0, 1).toUpperCase() + status.substring(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Route: Origin → Destination
            Row(
              children: [
                const Icon(Icons.location_on, color: nagcarlanGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$origin → $destination',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              color: Colors.grey[300],
            ),

            const SizedBox(height: 20),

            // Fare amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare Amount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${fare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: nagcarlanGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: nagcarlanGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: nagcarlanGreen,
                    size: 28,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons: Cancel and End Trip
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancelTap,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text(
                      'CANCEL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCompleteTap,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'END TRIP',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nagcarlanGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
