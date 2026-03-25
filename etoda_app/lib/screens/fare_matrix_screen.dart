import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

class FareMatrixScreen extends StatefulWidget {
  const FareMatrixScreen({super.key});

  @override
  State<FareMatrixScreen> createState() => _FareMatrixScreenState();
}

class _FareMatrixScreenState extends State<FareMatrixScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  // Nagcarlan Center Coordinates
  static const LatLng _nagcarlanCenter = LatLng(14.1382, 121.4116);

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
  String? activeStationFilter; 
  String passengerType = "Regular";
  String tripType = "Regular";
  String fare = "₱0.00";

  List<Marker> _markers = [];
  List<dynamic> _dynamicStations = [];
  List<dynamic> _fares = [];
  List<String> _allLocations = [];
  bool _isLoadingStations = true;

  List<String> get _filteredLocations {
    if (activeStationFilter == null) return _allLocations;
    final Set<String> filtered = {};
    for (var fare in _fares) {
      if (fare['association'] == activeStationFilter) {
        if (fare['origin'] != null) filtered.add(fare['origin'].toString());
        if (fare['destination'] != null) filtered.add(fare['destination'].toString());
      }
    }
    return filtered.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // FIX: Tinatawag ang mga methods mula sa ApiService
      final stationData = await _apiService.fetchStations();
      final fareData = await _apiService.fetchFares();
      
      if (mounted) {
        setState(() {
          if (stationData['success'] == true) {
            _dynamicStations = stationData['data'] ?? [];
          }
          _fares = fareData;
          _extractLocations();
          _isLoadingStations = false;
        });
        _updateMarkers();
      }
    } catch (e) {
      debugPrint('Failed to load data: $e');
      if (mounted) {
        setState(() {
          _isLoadingStations = false;
        });
      }
    }
  }

  void _extractLocations() {
    final Set<String> locs = {};
    for (var fare in _fares) {
      if (fare['origin'] != null) locs.add(fare['origin'].toString());
      if (fare['destination'] != null) locs.add(fare['destination'].toString());
    }
    _allLocations = locs.toList()..sort();
  }

  String? getStationForLocation(String location) {
    for (var fare in _fares) {
      if (fare['origin'] == location || fare['destination'] == location) {
        return fare['association']?.toString();
      }
    }
    return null;
  }

  void _onStationTapped(String stationName) {
    setState(() {
      activeStationFilter = (activeStationFilter == stationName) ? null : stationName;
      if (activeStationFilter != null) {
        final validLocs = _filteredLocations;
        if (fromLocation != null && !validLocs.contains(fromLocation)) {
          fromLocation = null;
        }
        if (toLocation != null && !validLocs.contains(toLocation)) {
          toLocation = null;
        }
      }
    });
    _updateMarkers();
    _calculateFare();
  }

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.tryParse(hexColor, radix: 16) ?? 0xFF16A34A);
  }

  void _updateMarkers() {
    setState(() {
      _markers = _dynamicStations.map((station) {
        final String name = station['name'] ?? 'Unknown Station';
        final double lat = double.tryParse(station['lat'].toString()) ?? 14.1382;
        final double lng = double.tryParse(station['lng'].toString()) ?? 121.4116;
        final String logoUrl = station['logo'] ?? '';
        final String dbColorHex = station['color'] ?? '';
        final Color dbColor = dbColorHex.isNotEmpty ? _parseHexColor(dbColorHex) : Colors.green;
        final String fullLogoUrl = logoUrl.isNotEmpty ? (logoUrl.startsWith('http') ? logoUrl : '${ApiService.baseUrl}/uploads/$logoUrl') : '';
        bool isHighlighted = name == activeStationFilter;

        final branding = terminalBranding.containsKey(name)
            ? terminalBranding[name]!
            : {"color": dbColor, "logo": Icons.storefront_rounded, "range": "TODA"};

        final Color baseColor = terminalBranding.containsKey(name) ? branding['color'] : dbColor;

        return Marker(
          point: LatLng(lat, lng),
          width: 120,
          height: 120,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _onStationTapped(name),
            child: AnimatedScale(
              scale: isHighlighted ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack, 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    constraints: const BoxConstraints(maxWidth: 100),
                    decoration: BoxDecoration(
                      color: isHighlighted ? Colors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isHighlighted ? Colors.orange.withOpacity(0.3) : Colors.black12, 
                          blurRadius: isHighlighted ? 12 : 6,
                          offset: const Offset(0, 3)
                        )
                      ],
                      border: Border.all(color: isHighlighted ? Colors.white : baseColor, width: 2),
                    ),
                    child: Text(
                      branding['range'] == "TODA" ? name : "${branding['range']}",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.white : baseColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.location_on, size: isHighlighted ? 85 : 60, color: isHighlighted ? Colors.orange : baseColor),
                      Positioned(
                        top: isHighlighted ? 15 : 12,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(isHighlighted ? 7 : 5),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: fullLogoUrl.isNotEmpty
                              ? CircleAvatar(
                                  radius: isHighlighted ? 15 : 10,
                                  backgroundImage: NetworkImage(fullLogoUrl),
                                  backgroundColor: Colors.transparent,
                                )
                              : Icon(branding['logo'], size: isHighlighted ? 30 : 20, color: isHighlighted ? Colors.orange : baseColor),
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

    Map<String, dynamic>? routeFare;
    for (var f in _fares) {
      if ((f['origin'] == fromLocation && f['destination'] == toLocation) ||
          (f['origin'] == toLocation && f['destination'] == fromLocation)) {
        routeFare = f;
        break;
      }
    }

    if (routeFare == null) {
      setState(() => fare = "₱0.00");
      return;
    }

    double finalFare = 0.0;
    if (tripType == "Special Trip") {
      finalFare = (routeFare['special_fare'] as num).toDouble();
    } else {
      finalFare = passengerType == "Regular" 
          ? (routeFare['base_fare'] as num).toDouble() 
          : (routeFare['discounted_fare'] as num).toDouble();
    }

    setState(() => fare = "₱${finalFare.toStringAsFixed(2)}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fare & Station Finder"), centerTitle: true),
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
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(initialCenter: _nagcarlanCenter, initialZoom: 12.5),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                          MarkerLayer(markers: _markers),
                        ],
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
                  _buildSearchableDropdown("Pick-up Point", fromLocation, (val) {
                    setState(() {
                      fromLocation = val;
                      if (val != null) activeStationFilter = getStationForLocation(val);
                    });
                    _updateMarkers(); _calculateFare();
                  }),
                  const SizedBox(height: 16),
                  _buildSearchableDropdown("Drop-off Destination", toLocation, (val) {
                    setState(() {
                      toLocation = val;
                      if (val != null) activeStationFilter = getStationForLocation(val);
                    });
                    _updateMarkers(); _calculateFare();
                  }),
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

  // --- Reusable Widgets ---
  Widget _buildSectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [Row(children: [Icon(icon, color: nagcarlanGreen), const SizedBox(width: 10), Text(title)]), const Divider(), ...children]),
      ),
    );
  }

  Widget _buildSearchableDropdown(String label, String? selectedValue, ValueChanged<String?> onChanged) {
    final validLocs = _filteredLocations;
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: selectedValue ?? ''),
      optionsBuilder: (v) => validLocs.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
      onSelected: onChanged,
      fieldViewBuilder: (ctx, ctrl, node, onSubmit) => TextFormField(
        controller: ctrl, focusNode: node,
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.location_on, color: nagcarlanGreen)),
      ),
    );
  }

  Widget _buildFareDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: nagcarlanGreen, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        const Text("TOTAL ESTIMATED FARE", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        Text(fare, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}