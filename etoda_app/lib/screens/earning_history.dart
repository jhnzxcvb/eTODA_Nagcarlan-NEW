import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Earnings History"),
        backgroundColor: Colors.white,
        foregroundColor: nagcarlanGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                color: nagcarlanGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: nagcarlanYellow, width: 1),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CURRENT BALANCE",
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "₱12,340.00",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "RECENT PAYOUTS",
                style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen, letterSpacing: 0.5),
              ),
            ),
            const EarningsItem(date: "Feb 12, 2026", amount: "₱450.00", trips: "12 trips"),
            const EarningsItem(date: "Feb 11, 2026", amount: "₱620.00", trips: "15 trips"),
          ],
        ),
      ),
    );
  }
}

class EarningsItem extends StatelessWidget {
  final String date;
  final String amount;
  final String trips;

  const EarningsItem({super.key, required this.date, required this.amount, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: nagcarlanYellow.withOpacity(0.3)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen, fontSize: 16)),
                const SizedBox(height: 4),
                Text(trips, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: nagcarlanGreen)),
          ],
        ),
      ),
    );
  }
}
