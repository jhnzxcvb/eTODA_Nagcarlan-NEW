import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

Widget buildBadge(String label, {required Color bg, required Color fg, required TextStyle sansStyle}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: sansStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: fg,
        letterSpacing: 0.4,
      ),
    ),
  );
}

class TripCardWidget extends StatefulWidget {
  final dynamic trip;
  final TextStyle monoStyle;
  final TextStyle sansStyle;
  final Color accentGreen;
  final Color accentYellow;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color textFaint;

  const TripCardWidget({
    super.key,
    required this.trip,
    required this.monoStyle,
    required this.sansStyle,
    required this.accentGreen,
    required this.accentYellow,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
  });

  @override
  State<TripCardWidget> createState() => _TripCardWidgetState();
}

class _TripCardWidgetState extends State<TripCardWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final fare = (trip['fare_amount'] as num?)?.toDouble() ?? 0.0;
    final duration = (trip['duration_min'] as num?)?.toInt() ?? 0;
    final isCancelled = trip['status']?.toString().toLowerCase() == 'cancelled';
    final tripCode = trip['trip_code'] ?? '—';
    final endedAt = trip['ended_at'] ?? '—';
    final passengerName = trip['passenger_name'] ?? 'Guest';
    final driverName = trip['driver_name'] ?? 'Driver';
    final route = trip['route'] ?? '—';
    final payment = trip['payment_method'] ?? 'Cash';
    final status = trip['status']?.toString().toUpperCase() ?? 'COMPLETED';

    final parts = route.split('→');
    final routeFrom = parts.isNotEmpty ? parts.first.trim() : route;
    final routeTo = parts.length > 1 ? parts.last.trim() : '';

    final mainPersonName = trip['passenger_id'] != null ? passengerName : driverName;
    final initials = mainPersonName.trim().isNotEmpty
        ? mainPersonName.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    final String detailRoute = trip['passenger_id'] != null ? '/driver_trip_details' : '/passenger_trip_details';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isHovered || _isPressed ? nagcarlanGreen : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isPressed || _isHovered ? 0.08 : 0.03),
            blurRadius: _isPressed || _isHovered ? 16 : 8,
            offset: Offset(0, _isPressed || _isHovered ? 8 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onHover: (v) => setState(() => _isHovered = v),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () => Navigator.pushNamed(context, detailRoute, arguments: trip),
          borderRadius: BorderRadius.circular(18),
          splashColor: nagcarlanGreen.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: nagcarlanGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: widget.sansStyle.copyWith(
                          color: nagcarlanGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mainPersonName,
                            style: widget.sansStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$endedAt · $duration min",
                            style: widget.sansStyle.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Total fare",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black38,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "₱${fare.toStringAsFixed(2)}",
                          style: widget.sansStyle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: nagcarlanGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.black12),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: nagcarlanGreen, shape: BoxShape.circle)),
                        Container(width: 1, height: 10, color: Colors.black12),
                        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black26, width: 1))),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routeFrom,
                            style: widget.sansStyle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(routeTo.isNotEmpty ? routeTo : route, style: widget.sansStyle.copyWith(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          buildBadge(status, bg: isCancelled ? Colors.red.withOpacity(0.1) : nagcarlanGreen.withOpacity(0.1), fg: isCancelled ? Colors.redAccent : nagcarlanGreen, sansStyle: widget.sansStyle),
                          const SizedBox(width: 6),
                          buildBadge(payment, bg: Colors.black.withOpacity(0.03), fg: Colors.black54, sansStyle: widget.sansStyle),
                        ],
                      ),
                      Text(tripCode, style: widget.monoStyle.copyWith(fontSize: 10, color: Colors.black26)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
