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
  String? activeStationFilter; // Track clicked station for filtering
  String passengerType = "Regular";
  String tripType = "Regular";
  String fare = "₱0.00";
  double discountAmount = 0.0;

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
        filtered.add(fare['origin'].toString());
        filtered.add(fare['destination'].toString());
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

      // Clear selections if they are no longer valid for this station filter
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
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
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

        // Fallback to existing terminal branding if matched, else use default green
        final branding = terminalBranding.containsKey(name)
            ? terminalBranding[name]!
            : {
                "color": dbColor,
                "logo": Icons.storefront_rounded,
                "range": "TODA",
              };

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
              curve: Curves.easeOutBack, // Fixed: changed from backOut to easeOutBack
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
                          spreadRadius: isHighlighted ? 2 : 0,
                          offset: const Offset(0, 3)
                        )
                      ],
                      border: Border.all(color: isHighlighted ? Colors.white : baseColor, width: 2),
                    ),
                    child: Text(
                      branding['range'] == "TODA" ? name : "${branding['range']}",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isHighlighted ? Colors.white : baseColor
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
                          child: fullLogoUrl.isNotEmpty
                              ? CircleAvatar(
                                  radius: isHighlighted ? 15 : 10,
                                  backgroundImage: NetworkImage(fullLogoUrl),
                                  backgroundColor: Colors.transparent,
                                )
                              : Icon(
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
      setState(() {
        fare = "₱0.00";
        discountAmount = 0.0;
      });
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
      setState(() {
        fare = "₱0.00";
        discountAmount = 0.0;
      });
      return;
    }

    double finalFare = 0.0;
    double currentDiscount = 0.0;

    if (tripType == "Special Trip") {
      finalFare = (routeFare['special_fare'] as num).toDouble();
      currentDiscount = 0.0;
    } else {
      if (passengerType == "Regular") {
        finalFare = (routeFare['base_fare'] as num).toDouble();
        currentDiscount = 0.0;
      } else {
        finalFare = (routeFare['discounted_fare'] as num).toDouble();
        double base = (routeFare['base_fare'] as num).toDouble();
        currentDiscount = base - finalFare;
      }
    }

    setState(() {
      fare = "₱${finalFare.toStringAsFixed(2)}";
      discountAmount = currentDiscount;
    });
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
                                  userAgentPackageName: 'com.etodanagcarlan.etoda_nagcarlan',
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
                      if (val != null) {
                        activeStationFilter = getStationForLocation(val);
                      }
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
    final validLocs = _filteredLocations;

    return Autocomplete<String>(
      optionsBuilder: (v) {
        if (v.text == '') return validLocs;
        return validLocs.where((o) => o.toLowerCase().contains(v.text.toLowerCase()));
      },
      onSelected: (val) {
        onChanged(val);
      },
      fieldViewBuilder: (ctx, ctrl, node, onSubmit) {
        if (selectedValue != null && ctrl.text != selectedValue) {
          ctrl.text = selectedValue;
        } else if (selectedValue == null && ctrl.text != "") {
          ctrl.text = "";
        }
        
        return TextFormField(
          controller: ctrl,
          focusNode: node,
          onChanged: (val) {
            if (val.isEmpty) {
              onChanged(null);
            }
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: nagcarlanGreen, fontSize: 14),
            prefixIcon: const Icon(Icons.location_on_rounded, color: nagcarlanGreen),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            suffixIcon: selectedValue != null 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    ctrl.clear();
                    onChanged(null);
                  },
                )
              : null,
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
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (tripType == "Special Trip")
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.yellow.withOpacity(0.5)),
                    ),
                    child: const Text(
                      "Special Trip",
                      style: TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.yellow.withOpacity(0.5)),
                    ),
                    child: Text(
                      "Discounted (₱${discountAmount.toStringAsFixed(0)} Off)",
                      style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

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
