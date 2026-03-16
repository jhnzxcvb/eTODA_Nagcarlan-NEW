import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/info_cards.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
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
  int? _driverId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_driverId == null) {
      // Retrieve the Map arguments passed from DriverHomeScreen
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _driverId = args?['driver_id'];

      if (_driverId != null) {
        _fetchDriverProfile();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDriverProfile() async {
    try {
      // URL matches the Go endpoint: /profile?role=driver&id=X
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/profile?role=driver&id=$_driverId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _driverData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        logError("Server returned ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      logError("Connection failed: $e");
      setState(() => _isLoading = false);
    }
  }

  void logError(String msg) {
    debugPrint("❌ DriverProfile Error: $msg");
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Name Construction
    String fullName = "DRIVER PROFILE";
    if (_driverData != null) {
      final fName = _driverData!['first_name'] ?? '';
      final mName = _driverData!['middle_name'] ?? '';
      final lName = _driverData!['last_name'] ?? '';
      fullName = "$fName $mName $lName".trim();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Driver Profile"),
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true, // Re-enables the default back button
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: nagcarlanGreen))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 65,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 70, color: Color(0xFFA5D6A7)),
              ),
              const SizedBox(height: 12),
              Text(
                fullName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: nagcarlanGreen),
              ),
              Text(
                "ID: DRV-${_driverId.toString().padLeft(4, '0')}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // Dynamic Vehicle Info from Database
              InfoSectionCard(
                title: "Vehicle Info",
                icon: Icons.directions_car,
                items: {
                  "Plate Number": _driverData?['plate_number'] ?? 'Not Set',
                  "Body Number": _driverData?['body_number'] ?? 'Not Set',
                  "Phone": _driverData?['phone_number'] ?? 'Not Set',
                },
              ),
              const SizedBox(height: 12),

              // Legal Info (Modify Go scan to include these if needed)
              InfoSectionCard(
                title: "Legal & License",
                icon: Icons.badge,
                items: {
                  "License #": _driverData?['license_number'] ?? 'N/A',
                  "Username": _driverData?['username'] ?? 'N/A',
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: nagcarlanGreen,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    // Logic for Start Shift
                  },
                  child: const Text(
                    "START SHIFT",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
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
