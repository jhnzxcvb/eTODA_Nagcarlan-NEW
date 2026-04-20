import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'dart:async';

/// TripDetailsModal displays the full trip details in a modal with live duration updates
class TripDetailsModal extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final int elapsedSeconds;
  final VoidCallback onCompleteTap;

  const TripDetailsModal({
    super.key,
    required this.tripData,
    required this.elapsedSeconds,
    required this.onCompleteTap,
  });

  @override
  State<TripDetailsModal> createState() => _TripDetailsModalState();
}

class _TripDetailsModalState extends State<TripDetailsModal> {
  Widget _buildDetailSection({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String passengerName = widget.tripData['passenger_name'] ?? 'Passenger';
    final double fare = (widget.tripData['fare'] is num)
        ? (widget.tripData['fare'] as num).toDouble()
        : (widget.tripData['fare_amount'] is num)
            ? (widget.tripData['fare_amount'] as num).toDouble()
            : 0.0;
    final String status = widget.tripData['status']?.toString().toLowerCase() ?? 'ongoing';

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trip Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Passenger name & status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Passenger',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              passengerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green, width: 1.5),
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
                  const SizedBox(height: 12),

                  // Divider
                  Container(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),

                  // Route
                  _buildDetailSection(
                    icon: Icons.location_on_outlined,
                    label: 'Route',
                    value: widget.tripData['route'] ?? '—',
                    iconColor: nagcarlanGreen,
                  ),
                  const SizedBox(height: 12),

                  // Duration
                  _buildDetailSection(
                    icon: Icons.timer_outlined,
                    label: 'Live Duration',
                    value: '${widget.elapsedSeconds ~/ 60}m ${widget.elapsedSeconds % 60}s',
                    iconColor: Colors.orange,
                  ),
                  const SizedBox(height: 12),

                  // Fare
                  _buildDetailSection(
                    icon: Icons.attach_money,
                    label: 'Fare Amount',
                    value: '₱${fare.toStringAsFixed(2)}',
                    iconColor: nagcarlanGreen,
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCompleteTap();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'END TRIP',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nagcarlanGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// OngoingTripCard displays an active trip with passenger details, route, and fare.
/// Click to view full trip details in a modal.
///
/// - tripData: Map containing trip information
/// - onCompleteTap: Callback when "Complete Trip" button is tapped
class OngoingTripCard extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final VoidCallback onCompleteTap;

  const OngoingTripCard({
    super.key,
    required this.tripData,
    required this.onCompleteTap,
  });

  @override
  State<OngoingTripCard> createState() => _OngoingTripCardState();
}

class _OngoingTripCardState extends State<OngoingTripCard> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _calculateInitialElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateInitialElapsed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateInitialElapsed() {
    if (widget.tripData['started_at'] != null) {
      DateTime start = DateTime.parse(widget.tripData['started_at']).toLocal();
      final diff = DateTime.now().difference(start);
      setState(() {
        _elapsedSeconds = diff.inSeconds >= 0 ? diff.inSeconds : 0;
      });
    }
  }

  void _showTripDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Update modal state when elapsed seconds change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setModalState(() {});
            }
          });

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5, // Reduced from 0.6 to minimize white space
            maxChildSize: 0.75, // Reduced from 0.85
            minChildSize: 0.4,
            builder: (context, scrollController) => TripDetailsModal(
              tripData: widget.tripData,
              elapsedSeconds: _elapsedSeconds,
              onCompleteTap: widget.onCompleteTap,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String status = widget.tripData['status']?.toString().toLowerCase() ?? 'ongoing';

    return GestureDetector(
      onTap: () => _showTripDetailsModal(context),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status badge only
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green, width: 1.5),
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

              const SizedBox(height: 12),

              // Route display
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: nagcarlanGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.route_outlined,
                      color: nagcarlanGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.tripData['route'] ?? 'Unknown Route',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // End Trip Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onCompleteTap,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'END TRIP',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nagcarlanGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
