import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

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
      appBar: AppBar(
        title: const Text("My Trip History"),
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: nagcarlanGreen))
            : _trips.isEmpty
                ? const Center(child: Text("No trips found."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.directions_car, color: nagcarlanGreen),
                          ),
                          title: Text(
                            trip['route'] ?? 'Unknown Route',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Driver: ${trip['driver_name']}"),
                              Text(trip['started_at'] ?? ''),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₱${trip['fare_amount']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: nagcarlanGreen, fontSize: 16),
                              ),
                              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
    );
  }
}