import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'dart:async';

class TripDetailsModal extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final VoidCallback onCompleteTap;
  final ScrollController scrollController;
  final DateTime? initialStartTime;

  const TripDetailsModal({
    super.key,
    required this.tripData,
    required this.onCompleteTap,
    required this.scrollController,
    this.initialStartTime,
  });

  @override
  State<TripDetailsModal> createState() => _TripDetailsModalState();
}

class _TripDetailsModalState extends State<TripDetailsModal> {
  Timer? _timer;
  final ValueNotifier<int> _elapsedSecondsNotifier = ValueNotifier<int>(0);
  DateTime? _tripStartTime;

  @override
  void initState() {
    super.initState();
    // Parse and store the start time once to prevent resets on modal reopen
    _tripStartTime = widget.initialStartTime ?? _parseTripStartTime();
    _calculateElapsed();

    // Start a local timer that updates the modal's UI every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateElapsed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedSecondsNotifier.dispose();
    super.dispose();
  }

  DateTime? _parseTripDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return null;

    try {
      DateTime parsed = DateTime.parse(rawDate.contains(' ') && !rawDate.contains('T')
          ? rawDate.replaceFirst(' ', 'T')
          : rawDate);
      return parsed.toLocal();
    } catch (_) { return null; }
  }

  DateTime? _parseTripStartTime() {
    final startStr = widget.tripData['started_at'] ?? 
                     widget.tripData['paid_at'] ?? 
                     widget.tripData['created_at'];
    return _parseTripDate(startStr);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  void _calculateElapsed() {
    try {
      if (_tripStartTime != null) {
        final now = DateTime.now();
        final diff = now.difference(_tripStartTime!);
        // Clamp to 0 to prevent negative durations if clocks are slightly out of sync
        _elapsedSecondsNotifier.value = diff.inSeconds > 0 ? diff.inSeconds : 0;
      } else {
        _elapsedSecondsNotifier.value = 0;
      }
    } catch (e) {
      debugPrint("Error calculating live duration: $e");
      _elapsedSecondsNotifier.value = 0;
    }
  }

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
            color: iconColor.withValues(alpha: 0.1),
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
    final String passengerName =
        widget.tripData['passenger_name'] ?? 'Passenger';

    // In details pop up, we show the combined route.
    final String route =
        widget.tripData['route'] ??
        "${widget.tripData['origin'] ?? '—'} → ${widget.tripData['destination'] ?? '—'}";

    final double fare = (widget.tripData['fare'] is num)
        ? (widget.tripData['fare'] as num).toDouble()
        : (widget.tripData['fare_amount'] is num)
        ? (widget.tripData['fare_amount'] as num).toDouble()
        : 0.0;
    final String status =
        widget.tripData['status']?.toString().toLowerCase() ?? 'ongoing';

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
            controller: widget.scrollController,
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
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black54,
                          ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: nagcarlanGreen.withValues(alpha: 0.1),
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
                              status.substring(0, 1).toUpperCase() +
                                  status.substring(1),
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

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: nagcarlanYellow.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          color: nagcarlanYellow,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Duration',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<int>(
                              valueListenable: _elapsedSecondsNotifier,
                              builder: (context, seconds, child) {
                                return Text(
                                  _formatDuration(Duration(seconds: seconds)),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
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
  final bool isDriver;

  const OngoingTripCard({
    super.key,
    required this.tripData,
    this.tripIndex = 0,
    this.totalTrips = 1,
    required this.onCompleteTap,
    this.isDriver = false,
  });

  @override
  State<OngoingTripCard> createState() => _OngoingTripCardState();
}

class _OngoingTripCardState extends State<OngoingTripCard> {
  DateTime? _tripStartTime;

  @override
  void initState() {
    super.initState();
    final parsed = _parseTripStartTime();
    // If parsed date is valid and not in the future, use it. Otherwise, fallback to now.
    if (parsed != null && !parsed.isAfter(DateTime.now().add(const Duration(seconds: 2)))) {
      _tripStartTime = parsed;
    } else {
      _tripStartTime = DateTime.now();
    }
  }

  DateTime? _parseTripDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return null;

    try {
      DateTime parsed = DateTime.parse(rawDate.contains(' ') && !rawDate.contains('T')
          ? rawDate.replaceFirst(' ', 'T')
          : rawDate);
      return parsed.toLocal();
    } catch (_) { return null; }
  }

  DateTime? _parseTripStartTime() {
    final startStr = widget.tripData['started_at'] ?? 
                     widget.tripData['paid_at'] ?? 
                     widget.tripData['created_at'];
    return _parseTripDate(startStr);
  }
  String _extractDestinationFromRoute(String route) {
    if (route.isEmpty) return '';

    final arrowParts = route.split('→');
    if (arrowParts.length > 1) {
      final lastPart = arrowParts.last.trim();
      if (lastPart.isNotEmpty) return lastPart;
    }

    final separators = [' to ', ' - ', '–', ':'];
    for (final separator in separators) {
      if (route.toLowerCase().contains(separator)) {
        final parts = route.split(RegExp(separator, caseSensitive: false));
        if (parts.length > 1) {
          final lastPart = parts.last.trim();
          if (lastPart.isNotEmpty) return lastPart;
        }
      }
    }

    return '';
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
          onCompleteTap: widget.onCompleteTap,
          scrollController: scrollController,
          initialStartTime: _tripStartTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String rawRoute = widget.tripData['route']?.toString().trim() ?? '';
    final String destination = widget.tripData['destination']?.toString().trim() ?? '';
    final String routeText = rawRoute.isNotEmpty ? rawRoute : destination;
    final String extractedDestination = _extractDestinationFromRoute(routeText);
    final String effectiveDestination = extractedDestination.isNotEmpty ? extractedDestination : routeText;

    return GestureDetector(
      onTap: () => _showTripDetailsModal(context),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: nagcarlanYellow, width: 1.5),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              const Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        nagcarlanYellow,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  Icon(Icons.directions_car, color: nagcarlanGreen, size: 24),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.totalTrips > 1
                          ? "ONGOING TRIP (${widget.tripIndex + 1}/${widget.totalTrips})"
                          : "ONGOING TRIP",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: nagcarlanGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "To: $effectiveDestination",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Tap to view details",
                      style: TextStyle(
                        fontSize: 12,
                        color: nagcarlanGreen.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: nagcarlanGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
