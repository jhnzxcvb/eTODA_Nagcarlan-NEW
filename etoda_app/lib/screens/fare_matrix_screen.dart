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

  // Helper to determine station based on alphabetical range
  String getStationForLocation(String name) {
    String firstLetter = name[0].toUpperCase();
    if (firstLetter.compareTo('A') >= 0 && firstLetter.compareTo('L') <= 0) {
      return "Central Terminal";
    } else if (firstLetter.compareTo('M') >= 0 && firstLetter.compareTo('S') <= 0) {
      return "North Terminal";
    } else if (firstLetter.compareTo('T') >= 0 && firstLetter.compareTo('Z') <= 0) {
      return "East Terminal";
    }
    return "Central Terminal";
  }

  // Real Station Data with Coordinates
  final Map<String, LatLng> stationCoords = {
    "Central Terminal": const LatLng(14.1382, 121.4116),
    "North Terminal": const LatLng(14.1550, 121.4050),
    "East Terminal": const LatLng(14.1320, 121.4300),
  };

  // Terminal Branding Config
  final Map<String, Map<String, dynamic>> terminalBranding = {
    "Central Terminal": {
      "color": Colors.blue,
      "logo": Icons.hub_rounded,
      "range": "A-L",
    },
    "North Terminal": {
      "color": Colors.red,
      "logo": Icons.north_rounded,
      "range": "M-S",
    },
    "East Terminal": {
      "color": Colors.orange,
      "logo": Icons.east_rounded,
      "range": "T-Z",
    },
  };

  String? fromLocation;
  String? toLocation;
  String? activeStationFilter; // Track clicked station for filtering
  String passengerType = "Normal";
  String tripType = "Regular";
  String fare = "₱0.00";

  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  void _onStationTapped(String stationName) {
    setState(() {
      activeStationFilter = (activeStationFilter == stationName) ? null : stationName;

      // Clear selections if they no longer match the filter
      if (activeStationFilter != null) {
        if (fromLocation != null && getStationForLocation(fromLocation!) != activeStationFilter) {
          fromLocation = null;
        }
        if (toLocation != null && getStationForLocation(toLocation!) != activeStationFilter) {
          toLocation = null;
        }
      }
    });
    _updateMarkers();
    _calculateFare();

    if (activeStationFilter != null) {
      _mapController.move(stationCoords[stationName]!, 15);
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers = stationCoords.entries.map((entry) {
        bool isHighlighted = entry.key == activeStationFilter;
        final branding = terminalBranding[entry.key]!;
        final Color baseColor = branding['color'];

        return Marker(
          point: entry.value,
          width: isHighlighted ? 120 : 80,
          height: isHighlighted ? 120 : 80,
          child: GestureDetector(
            onTap: () => _onStationTapped(entry.key),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHighlighted ? Colors.orange : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    border: Border.all(color: isHighlighted ? Colors.white : baseColor, width: 1),
                  ),
                  child: Text(
                    "${branding['range']}",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted ? Colors.white : baseColor
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: isHighlighted ? 70 : 45,
                      color: isHighlighted ? Colors.orange : baseColor,
                    ),
                    Positioned(
                      top: isHighlighted ? 12 : 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          branding['logo'],
                          size: isHighlighted ? 24 : 15,
                          color: isHighlighted ? Colors.orange : baseColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList();
    });
  }

  void _calculateFare() {
    if (fromLocation == null || toLocation == null) {
      setState(() => fare = "₱0.00");
      return;
    }

    double baseFare = (tripType == "Special Trip") ? 50.0 : 30.0;
    if (passengerType != "Normal") baseFare *= 0.80;

    setState(() => fare = "₱${baseFare.toStringAsFixed(2)}");
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
                  if (activeStationFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                              "Showing $activeStationFilter (${terminalBranding[activeStationFilter]!['range']})",
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _onStationTapped(activeStationFilter!),
                            child: const Text("Clear Filter", style: TextStyle(fontSize: 12)),
                          )
                        ],
                      ),
                    ),
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
                    setState(() {
                      fromLocation = val;
                      if (val != null) activeStationFilter = getStationForLocation(val);
                    });
                    _updateMarkers();
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
              _buildSectionCard(
                icon: Icons.tune,
                title: "Trip Options",
                children: [
                  _buildDropdown(
                    "Passenger Type",
                    passengerType,
                    ["Normal", "Senior", "PWD", "Student"],
                        (val) {
                      setState(() => passengerType = val!);
                      _calculateFare();
                    },
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    "Trip Type",
                    tripType,
                    ["Regular", "Special Trip"],
                        (val) {
                      setState(() => tripType = val!);
                      _calculateFare();
                    },
                    icon: Icons.alt_route,
                  ),
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

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {required IconData icon}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: nagcarlanGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withAlpha(230),
      ),
      items: items.map((String category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSearchableDropdown(String label, String? selectedValue, ValueChanged<String?> onChanged) {
    // Filter locations based on the active station pin range
    final filteredOptions = activeStationFilter == null
        ? locations
        : locations.where((loc) => getStationForLocation(loc) == activeStationFilter).toList();

    return Autocomplete<String>(
      optionsBuilder: (v) => v.text == '' ? filteredOptions : filteredOptions.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
      onSelected: onChanged,
      fieldViewBuilder: (ctx, ctrl, node, onSubmit) {
        if (selectedValue != null && ctrl.text == "") ctrl.text = selectedValue;
        if (selectedValue == null && ctrl.text != "" && !filteredOptions.contains(ctrl.text)) ctrl.text = "";
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