import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

// Export constants so files importing main.dart can still see them
export 'package:etoda_nagcarlan/constants.dart';
import 'package:etoda_nagcarlan/constants.dart';

// Screen Imports
import 'package:etoda_nagcarlan/screens/fare_matrix_screen.dart';
import 'package:etoda_nagcarlan/screens/passenger_edit_profile_screen.dart';
import 'package:etoda_nagcarlan/screens/passenger_trip_details_screen.dart';
import 'package:etoda_nagcarlan/screens/passenger_trip_history_screen.dart';
import 'package:etoda_nagcarlan/screens/trip_ended_screen.dart';
import 'package:etoda_nagcarlan/screens/driver_trip_ended_screen.dart';
import 'package:etoda_nagcarlan/screens/driver_trip_history_screen.dart'; // Added
import 'package:etoda_nagcarlan/screens/trip_started_screen.dart';
import 'package:etoda_nagcarlan/screens/landing_screen.dart';
import 'package:etoda_nagcarlan/screens/passenger_home.dart';
import 'package:etoda_nagcarlan/screens/driver_home.dart';
import 'package:etoda_nagcarlan/screens/driver_profile.dart';
import 'package:etoda_nagcarlan/screens/driver_edit_profile_screen.dart';
import 'package:etoda_nagcarlan/screens/scan_qr_screen.dart';
import 'package:etoda_nagcarlan/screens/scanned_driver_profile_screen.dart';
import 'package:etoda_nagcarlan/screens/login_screen.dart';
import 'package:etoda_nagcarlan/screens/signup_screen.dart';
import 'package:etoda_nagcarlan/screens/forgot_password_screen.dart';

// --- OSM MAP WIDGET ---
class NagcarlanMap extends StatelessWidget {
  const NagcarlanMap({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(14.1325, 121.4136),
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.etoda.nagcarlan',
        ),
        const MarkerLayer(
          markers: [
            Marker(
              point: LatLng(14.1325, 121.4136),
              width: 40,
              height: 40,
              child: Icon(Icons.location_on, color: nagcarlanGreen, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}

// --- CONNECTION TEST ---
Future<void> testConnection() async {
  try {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/api/drivers'));
    if (response.statusCode == 200) {
      debugPrint("✅ SUCCESS: Connected to Go Backend!");
    } else {
      debugPrint("❌ ERROR: Server responded with ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ CONNECTION FAILED: $e");
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  testConnection();
  runApp(const EtodaApp());
}

class EtodaApp extends StatelessWidget {
  const EtodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eTODA Nagcarlan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: nagcarlanGreen),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: nagcarlanGreen,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/passenger_home': (context) => const PassengerHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/driver_profile': (context) => const DriverProfileScreen(),
        '/driver_edit_profile': (context) => const DriverEditProfileScreen(),
        '/scan_qr': (context) => const ScanQRScreen(),
        '/driver_profile_scanned': (context) => const ScannedDriverProfileScreen(),
        '/trip_started': (context) => const TripStartedScreen(),
        '/trip_ended': (context) => const TripEndedScreen(),
        '/driver_trip_ended': (context) => const DriverTripEndedScreen(),
        '/driver_trip_history': (context) => const DriverTripHistoryScreen(), // Added
        '/fare_matrix': (context) => const FareMatrixScreen(),
        '/passenger_edit_profile': (context) => const PassengerEditProfileScreen(),
        '/passenger_trip_history': (context) => const PassengerTripHistoryScreen(),
        '/passenger_trip_details': (context) => const PassengerTripDetailsScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
