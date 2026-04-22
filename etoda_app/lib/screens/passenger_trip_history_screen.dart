import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class PassengerTripHistoryScreen extends StatefulWidget {
  const PassengerTripHistoryScreen({super.key});

  @override
  State<PassengerTripHistoryScreen> createState() => _PassengerTripHistoryScreenState();
}

class _PassengerTripHistoryScreenState extends State<PassengerTripHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _trips = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final passengerId = args?['user_id'] ?? args?['passenger_id'];

    if (passengerId != null) {
      _fetchHistory(passengerId.toString());
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHistory(String id) async {
    try {
      final response = await ApiService().fetchTrips(id);
      setState(() {
        _trips = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('History fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Trip History"),
        backgroundColor: Colors.transparent,
        foregroundColor: nagcarlanWhite,
        elevation: 0,
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: nagcarlanYellow))
                  : _trips.isEmpty
                      ? const Center(child: Text("No trips found.", style: TextStyle(color: nagcarlanWhite, fontSize: 16)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _trips.length,
                          itemBuilder: (context, index) {
                            final trip = _trips[index];
                            final isCancelled = trip['status']?.toString().toLowerCase() == 'cancelled';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: nagcarlanWhite.withOpacity(0.9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: nagcarlanGreen.withOpacity(0.1),
                                  child: const Icon(Icons.directions_car, color: nagcarlanGreen),
                                ),
                                title: Text(
                                  trip['route'] ?? 'Unknown Route',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Driver: ${trip['driver_name']}", style: const TextStyle(color: Colors.black87)),
                                    Text(trip['started_at'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isCancelled ? Colors.red : nagcarlanGreen).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (trip['status']?.toString().toUpperCase() ?? 'COMPLETED'),
                                        style: TextStyle(
                                          fontSize: 10, 
                                          fontWeight: FontWeight.bold,
                                          color: isCancelled ? Colors.red : nagcarlanGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₱${trip['fare_amount']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, color: nagcarlanGreen, fontSize: 18),
                                    ),
                                    const Icon(Icons.chevron_right, size: 16, color: nagcarlanGreen),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context, '/passenger_trip_details', arguments: trip);
                                },
                              ),
                            );
                          },
                        ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: BrandingFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
