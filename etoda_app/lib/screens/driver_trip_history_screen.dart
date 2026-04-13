import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  final String driverId;
  const DriverTripHistoryScreen({super.key, required this.driverId});

  @override
  State<DriverTripHistoryScreen> createState() => _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.fetchDriverTrips(widget.driverId);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _historyFuture = _apiService.fetchDriverTrips(widget.driverId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip History"),
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _handleRefresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: FutureBuilder<List<dynamic>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            } else if (snapshot.hasError) {
              return const Center(child: Text("Error loading trip history", style: TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No trips found.", style: TextStyle(color: Colors.white, fontSize: 16)));
            }

            final trips = snapshot.data!;

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final fare = (trip['fare_amount'] as num?)?.toDouble() ?? 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/driver_trip_details',
                                arguments: trip);
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(trip['started_at'] ?? '—', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: nagcarlanGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(trip['payment_method'] ?? 'Cash', style: const TextStyle(color: nagcarlanGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 18, color: nagcarlanGreen),
                                  const SizedBox(width: 8),
                                  Text(trip['passenger_name'] ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.route_outlined, size: 18, color: nagcarlanGreen),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(trip['route'] ?? '—', style: const TextStyle(color: Colors.black87))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text("Fare Collected: ", style: TextStyle(color: Colors.black54)),
                                  Text("₱${fare.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: nagcarlanGreen)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
                const BrandingFooter(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
