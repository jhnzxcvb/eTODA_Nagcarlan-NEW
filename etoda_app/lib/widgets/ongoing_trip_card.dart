import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'dart:async';

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
    
    // In details pop up, we show the combined route.
    final String route = widget.tripData['route'] ?? 
        "${widget.tripData['origin'] ?? '—'} → ${widget.tripData['destination'] ?? '—'}";

    final double fare = (widget.tripData['fare'] is num)
        ? (widget.tripData['fare'] as num).toDouble()
        : (widget.tripData['fare_amount'] is num)
            ? (widget.tripData['fare_amount'] as num).toDouble()
            : 0.0;
    final String status = widget.tripData['status']?.toString().toLowerCase() ?? 'ongoing';

    return Column(
      children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trip Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: nagcarlanGreen,
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
                                color: nagcarlanGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: nagcarlanGreen.withOpacity(0.1),
                          border: Border.all(color: nagcarlanGreen, width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: nagcarlanGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status.substring(0, 1).toUpperCase() + status.substring(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: nagcarlanGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),

                  _buildDetailSection(
                    icon: Icons.route_outlined,
                    label: 'Route',
                    value: route,
                    iconColor: nagcarlanGreen,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailSection(
                    icon: Icons.timer_outlined,
                    label: 'Live Duration',
                    value: '${widget.elapsedSeconds ~/ 60}m ${widget.elapsedSeconds % 60}s',
                    iconColor: nagcarlanYellow,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailSection(
                    icon: Icons.attach_money,
                    label: 'Fare Amount',
                    value: '₱${fare.toStringAsFixed(2)}',
                    iconColor: nagcarlanGreen,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCompleteTap();
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 24),
                      label: const Text(
                        'END TRIP NOW',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.2),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nagcarlanYellow,
                        foregroundColor: nagcarlanGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
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

class OngoingTripCard extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final int tripIndex;
  final int totalTrips;
  final VoidCallback onCompleteTap;

  const OngoingTripCard({
    super.key,
    required this.tripData,
    this.tripIndex = 0,
    this.totalTrips = 1,
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
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.75,
        minChildSize: 0.4,
        builder: (context, scrollController) => TripDetailsModal(
          tripData: widget.tripData,
          elapsedSeconds: _elapsedSeconds,
          onCompleteTap: widget.onCompleteTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only display the destination on the trip card itself.
    final String destination = widget.tripData['destination'] ?? '—';
    final String passengerName = widget.tripData['passenger_name'] ?? 'Passenger';

    return GestureDetector(
      onTap: () => _showTripDetailsModal(context),
      child: Card(
        elevation: 6,
        shadowColor: nagcarlanGreen.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: nagcarlanGreen.withOpacity(0.15), width: 1.5),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(nagcarlanYellow),
                      strokeWidth: 2,
                    ),
                  ),
                  Icon(Icons.directions_car, color: nagcarlanGreen, size: 24),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.totalTrips > 1 ? "ONGOING TRIP (${widget.tripIndex + 1}/${widget.totalTrips})" : "ONGOING TRIP",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: nagcarlanGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Passenger: $passengerName",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
