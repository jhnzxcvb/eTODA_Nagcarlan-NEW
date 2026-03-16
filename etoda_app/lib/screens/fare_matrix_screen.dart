import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class FareMatrixScreen extends StatefulWidget {
  const FareMatrixScreen({super.key});

  @override
  State<FareMatrixScreen> createState() => _FareMatrixScreenState();
}

class _FareMatrixScreenState extends State<FareMatrixScreen> {
  final MapController _mapController = MapController();

  // Nagcarlan Center Coordinates
  static const LatLng _nagcarlanCenter = LatLng(14.1382, 121.4116);

  final List<String> locations = [
    "Abo", "Alibungbungan", "Alumbrado", "Balayong", "Balite", "Banago",
    "Banca-banca", "Bangcuro", "Bukal", "Bunga", "Cabuyew", "Calumpang",
    "Kanluran Kabubuhayan", "Silangan Kabubuhayan", "Labangan", "Lawaguin",
    "Malaya", "Malinao", "Manaol", "Maravilla", "Nagcarlan Public Market",
    "Oobi", "Palayan", "Palina", "Poblacion", "Sabang", "San Francisco",
    "Santa Lucia", "Sibulan", "Sinipian", "Sulsuguin", "Talangan", "Tanza",
    "Taytay", "Tipacan", "Yukos",
  ]..sort();

  final Map<String, String> locationToStation = {
    "Poblacion": "Central Terminal",
    "Nagcarlan Public Market": "Central Terminal",
    "Sabang": "Central Terminal",
    "Yukos": "Central Terminal",
    "Talangan": "North Terminal",
    "Malinao": "North Terminal",
    "Oobi": "East Terminal",
    "Alumbrado": "East Terminal",
  };

  // Real Station Data with Coordinates
  final Map<String, LatLng> stationCoords = {
    "Central Terminal": const LatLng(14.1382, 121.4116),
    "North Terminal": const LatLng(14.1550, 121.4050),
    "East Terminal": const LatLng(14.1320, 121.4300),
  };

  String? fromLocation;
  String? toLocation;
  String passengerType = "Normal";
  String tripType = "Regular";
  String fare = "₱0.00";

  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  void _updateMarkers() {
    String? selectedStation = fromLocation != null ? locationToStation[fromLocation] : null;

    setState(() {
      _markers = stationCoords.entries.map((entry) {
        bool isHighlighted = entry.key == selectedStation;
        return Marker(
          point: entry.value,
          width: isHighlighted ? 60 : 40,
          height: isHighlighted ? 60 : 40,
          child: Icon(
            Icons.location_on,
            size: isHighlighted ? 50 : 35,
            color: isHighlighted ? Colors.orange : nagcarlanGreen,
          ),
        );
      }).toList();
    });

    if (selectedStation != null) {
      _mapController.move(stationCoords[selectedStation]!, 15);
    }
  }

  void _calculateFare() {
    if (fromLocation == null || toLocation == null) {
      setState(() => fare = "₱0.00");
      return;
    }
    double baseFare = (tripType == "Special Trip") ? 50.0 : 30.0;
    if (passengerType != "Normal") baseFare *= 0.80;
    setState(() => fare = "₱${baseFare.toStringAsFixed(2)}");
    _updateMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fare & Station Finder")),
      body: Container(
        decoration: nagcarlanGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildSectionCard(
                icon: Icons.map_outlined,
                title: "Station Map (Nagcarlan)",
                children: [
                  SizedBox(
                    height: 250,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _nagcarlanCenter,
                          initialZoom: 13,
                          maxZoom: 18,
                          minZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.etoda.nagcarlan',
                          ),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                icon: Icons.search,
                title: "Search Route",
                children: [
                  _buildSearchableDropdown("From", fromLocation, (val) {
                    setState(() => fromLocation = val);
                    _calculateFare();
                  }),
                  const SizedBox(height: 16),
                  _buildSearchableDropdown("To", toLocation, (val) {
                    setState(() => toLocation = val);
                    _calculateFare();
                  }),
                ],
              ),
              const SizedBox(height: 20),
              _buildFareDisplay(),
              const SizedBox(height: 20),
              const BrandingFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableDropdown(String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Autocomplete<String>(
      optionsBuilder: (v) => v.text == '' ? locations : locations.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
      onSelected: onChanged,
      fieldViewBuilder: (ctx, ctrl, node, onSubmit) {
        if (selectedValue != null && ctrl.text == "") ctrl.text = selectedValue;
        return TextFormField(
          controller: ctrl,
          focusNode: node,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.location_on, color: nagcarlanGreen),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white.withAlpha(230),
          ),
        );
      },
    );
  }

  Widget _buildFareDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: nagcarlanGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text("ESTIMATED FARE", style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(fare, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(children: [Icon(icon, color: nagcarlanGreen), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const Divider(height: 24),
          ...children
        ]),
      ),
    );
  }
}
