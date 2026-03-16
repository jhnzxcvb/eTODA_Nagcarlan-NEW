
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Earnings History")),
      body: Container(
        decoration: nagcarlanGradient,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                color: nagcarlanGreen,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CURRENT BALANCE",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "₱12,340.00",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "RECENT PAYOUTS",
                style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen),
              ),
            ),
            EarningsItem(date: "Feb 12, 2026", amount: "₱450.00", trips: "12 trips"),
            EarningsItem(date: "Feb 11, 2026", amount: "₱620.00", trips: "15 trips"),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
                Text(trips, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: nagcarlanGreen)),
          ],
        ),
      ),
    );
  }
}
