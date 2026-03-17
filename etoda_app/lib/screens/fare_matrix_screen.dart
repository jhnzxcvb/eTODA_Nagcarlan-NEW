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
  String passengerType = "Regular";
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
  }

  void _updateMarkers() {
    setState(() {
      _markers = stationCoords.entries.map((entry) {
        bool isHighlighted = entry.key == activeStationFilter;
        final branding = terminalBranding[entry.key]!;
        final Color baseColor = branding['color'];

        return Marker(
          point: entry.value,
          width: 120,
          height: 120,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _onStationTapped(entry.key),
            child: AnimatedScale(
              scale: isHighlighted ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack, // Fixed: changed from backOut to easeOutBack
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isHighlighted ? Colors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isHighlighted ? Colors.orange.withOpacity(0.3) : Colors.black12, 
                          blurRadius: isHighlighted ? 12 : 6,
                          spreadRadius: isHighlighted ? 2 : 0,
                          offset: const Offset(0, 3)
                        )
                      ],
                      border: Border.all(color: isHighlighted ? Colors.white : baseColor, width: 2),
                    ),
                    child: Text(
                      "${branding['range']}",
                      style: TextStyle(
                          fontSize: 12,
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
                        size: isHighlighted ? 85 : 60,
                        color: isHighlighted ? Colors.orange : baseColor,
                      ),
                      Positioned(
                        top: isHighlighted ? 15 : 12,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(isHighlighted ? 7 : 5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            branding['logo'],
                            size: isHighlighted ? 30 : 20,
                            color: isHighlighted ? Colors.orange : baseColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    if (passengerType != "Regular") baseFare *= 0.80;

    setState(() => fare = "₱${baseFare.toStringAsFixed(2)}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fare & Station Finder"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: nagcarlanGradient,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSectionCard(
                icon: Icons.map_rounded,
                title: "Station Map Explorer",
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Select a terminal pin to filter nearby locations",
                      style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: const MapOptions(
                                initialCenter: _nagcarlanCenter,
                                initialZoom: 12.5,
                                maxZoom: 18,
                                minZoom: 11,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.etoda.nagcarlan',
                                ),
                                MarkerLayer(markers: _markers),
                              ],
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildEnhancedMapButton(
                                    icon: Icons.add_rounded,
                                    onPressed: () {
                                      _mapController.move(
                                        _mapController.camera.center,
                                        (_mapController.camera.zoom + 1).clamp(11, 18),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEnhancedMapButton(
                                    icon: Icons.remove_rounded,
                                    onPressed: () {
                                      _mapController.move(
                                        _mapController.camera.center,
                                        (_mapController.camera.zoom - 1).clamp(11, 18),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEnhancedMapButton(
                                    icon: Icons.center_focus_strong_rounded,
                                    onPressed: () {
                                      _mapController.move(_nagcarlanCenter, 12.5);
                                    },
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.route_rounded,
                title: "Plan Your Trip",
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: activeStationFilter != null
                        ? Padding(
                            key: ValueKey(activeStationFilter),
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.filter_alt_rounded, size: 18, color: Colors.orange),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Terminal Filter Active",
                                          style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          activeStationFilter!,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_rounded, color: Colors.orange),
                                    onPressed: () => _onStationTapped(activeStationFilter!),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  _buildSearchableDropdown("Pick-up Point", fromLocation, (val) {
                    setState(() {
                      fromLocation = val;
                      if (val != null) activeStationFilter = getStationForLocation(val);
                    });
                    _updateMarkers();
                    _calculateFare();
                  }),
                  const SizedBox(height: 16),
                  _buildSearchableDropdown("Drop-off Destination", toLocation, (val) {
                    setState(() => toLocation = val);
                    _calculateFare();
                  }),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.settings_suggest_rounded,
                title: "Trip Customization",
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactDropdown(
                          "Passenger",
                          passengerType,
                          ["Regular", "Senior", "PWD", "Student"],
                          (val) {
                            setState(() => passengerType = val!);
                            _calculateFare();
                          },
                          icon: Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactDropdown(
                          "Trip Type",
                          tripType,
                          ["Regular", "Special Trip"],
                          (val) {
                            setState(() => tripType = val!);
                            _calculateFare();
                          },
                          icon: Icons.local_taxi_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFareDisplay(),
              const SizedBox(height: 24),
              const BrandingFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: nagcarlanGreen)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: nagcarlanGreen, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          items: items.map((String category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown(String label, String? selectedValue, ValueChanged<String?> onChanged) {
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
            labelStyle: const TextStyle(color: nagcarlanGreen, fontSize: 14),
            prefixIcon: const Icon(Icons.location_on_rounded, color: nagcarlanGreen),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: nagcarlanGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        gradient: LinearGradient(
          colors: [nagcarlanGreen, nagcarlanGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text("TOTAL ESTIMATED FARE", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(fare, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 4),
          const Text("Safe travels in Nagcarlan!", style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: nagcarlanGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: nagcarlanGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: nagcarlanGreen)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.black12),
          ),
          ...children
        ],
      ),
    );
  }

  Widget _buildEnhancedMapButton({required IconData icon, required VoidCallback onPressed, Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Icon(icon, color: color ?? nagcarlanGreen, size: 24),
        ),
      ),
    );
  }
}