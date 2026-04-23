import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _driverData;
  dynamic _driverId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_driverData == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _driverId = args?['driver_id'] ?? args?['id'] ?? args?['ID'];

      if (args != null && args.containsKey('plate_number')) {
        _driverData = args;
        _isLoading = false;
        if (_driverId != null) _fetchDriverProfile();
      } else if (_driverId != null) {
        _fetchDriverProfile();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDriverProfile() async {
    try {
      final url = '${ApiService.baseUrl}/api/profile?role=driver&id=$_driverId';
      debugPrint("Fetching driver profile from: $url");
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('{') || body.startsWith('[')) {
          setState(() {
            _driverData = jsonDecode(body);
            _isLoading = false;
          });
        } else {
          throw FormatException("Expected JSON but received: ${body.substring(0, body.length > 50 ? 50 : body.length)}");
        }
      } else {
        logError("Server returned ${response.statusCode}: ${response.body}");
        if (_driverData != null) setState(() => _isLoading = false);
      }
    } catch (e) {
      logError("Fetch failed: $e");
      if (_driverData != null) setState(() => _isLoading = false);
    }
  }

  void logError(String msg) {
    debugPrint("❌ DriverProfile Error: $msg");
  }

  @override
  Widget build(BuildContext context) {
    String fullName = "DRIVER PROFILE";
    if (_driverData != null) {
      final fName = _driverData!['first_name'] ?? '';
      final mName = _driverData!['middle_name'] ?? '';
      final lName = _driverData!['last_name'] ?? '';
      fullName = "$fName $mName $lName".trim();
      if (fullName.isEmpty) fullName = _driverData!['full_name'] ?? "DRIVER PROFILE";
    }

    String getVal(String key, String fallback) {
      final val = _driverData?[key];
      if (val == null) return fallback;
      final str = val.toString().trim();
      return str.isEmpty ? fallback : str;
    }

    final String profilePic = getVal('profile_pic', '');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Driver Profile"),
        backgroundColor: Colors.transparent,
        foregroundColor: nagcarlanWhite,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: _isLoading && _driverData == null
            ? const Center(child: CircularProgressIndicator(color: nagcarlanYellow))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: nagcarlanWhite,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        backgroundImage: profilePic.isNotEmpty
                            ? NetworkImage('${ApiService.baseUrl}/uploads/$profilePic')
                            : null,
                        child: profilePic.isEmpty
                            ? const Icon(Icons.person, size: 70, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: nagcarlanYellow),
                    ),
                    if (_driverId != null)
                      Text(
                        "ID: DRV-${_driverId.toString().padLeft(4, '0')}",
                        style: TextStyle(fontSize: 14, color: nagcarlanWhite.withOpacity(0.8)),
                      ),
                    const SizedBox(height: 32),
                    InfoSectionCard(
                      title: "Contact & Vehicle",
                      icon: Icons.directions_car,
                      items: {
                        "Plate Number": getVal('plate_number', 'Not Set'),
                        "Body Number": getVal('body_number', 'Not Set'),
                        "Phone": getVal('phone_number', 'Not Set'),
                        "Email": getVal('email', 'Not Set'),
                      },
                    ),
                    const SizedBox(height: 12),
                    InfoSectionCard(
                      title: "Association Details",
                      icon: Icons.groups,
                      items: {
                        "Association": getVal('association', 'Not Set'),
                        "Franchise": getVal('franchise', 'Not Set'),
                      },
                    ),
                    const SizedBox(height: 12),
                    InfoSectionCard(
                      title: "Legal & License",
                      icon: Icons.badge,
                      items: {
                        "License #": getVal('license_number', 'N/A'),
                        "Username": getVal('username', 'N/A'),
                      },
                    ),
                    const SizedBox(height: 40),
                    const BrandingFooter(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
