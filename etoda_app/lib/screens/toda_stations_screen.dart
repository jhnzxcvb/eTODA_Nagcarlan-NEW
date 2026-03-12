import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class TodaStationsScreen extends StatelessWidget {
  const TodaStationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TODA Terminal Stations"),
        backgroundColor: Colors.white,
        foregroundColor: nagcarlanGreen,
        elevation: 1,
      ),
      body: Stack(
        children: [
          // Map Background (Static Image Placeholder)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/map_placeholder.png"), // You need to add a map image to your assets
                fit: BoxFit.cover,
              ),
            ),
          ),
          // TODA Station Pins
          _buildStationPin(top: 100, left: 50, name: "Nagcarlan Public Market"),
          _buildStationPin(top: 300, left: 200, name: "Brgy. Poblacion I Terminal"),
          _buildStationPin(top: 500, left: 100, name: "Ansloc Medical Center"),
        ],
      ),
    );
  }

  Widget _buildStationPin({required double top, required double left, required String name}) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen),
            ),
          ),
          const SizedBox(height: 4),
          const Icon(Icons.location_on, size: 50, color: Colors.red),
        ],
      ),
    );
  }
}
