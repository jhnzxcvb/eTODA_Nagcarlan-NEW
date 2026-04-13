import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:etoda_nagcarlan/screens/landing_screen.dart';
import 'package:etoda_nagcarlan/screens/login_screen.dart';
import 'package:etoda_nagcarlan/screens/signup_screen.dart';
import 'package:etoda_nagcarlan/screens/passenger_home.dart';
import 'package:etoda_nagcarlan/screens/passenger_edit_profile_screen.dart';
import 'package:etoda_nagcarlan/screens/driver_home.dart';
import 'package:etoda_nagcarlan/screens/driver_profile.dart';
import 'package:etoda_nagcarlan/screens/driver_edit_profile_screen.dart';
import 'package:etoda_nagcarlan/screens/driver_trip_history_screen.dart';
import 'package:etoda_nagcarlan/screens/scan_qr_screen.dart';
import 'package:etoda_nagcarlan/screens/scanned_driver_profile_screen.dart';
import 'package:etoda_nagcarlan/screens/fare_matrix_screen.dart';
import 'package:etoda_nagcarlan/screens/forgot_password_screen.dart';
import 'package:etoda_nagcarlan/screens/trip_started_screen.dart';
import 'package:etoda_nagcarlan/screens/passenger_trip_history_screen.dart';
import 'package:etoda_nagcarlan/screens/passenger_trip_details_screen.dart';
import 'package:etoda_nagcarlan/screens/driver_trip_details_screen.dart';

void main() {
  runApp(const EtodaApp());
}

// Brand Colors
const Color nagcarlanGreen = Color(0xFF16A34A);
const Color nagcarlanYellow = Color(0xFFFACC15);

// Modern Gradient for Nagcarlan Branding
const BoxDecoration nagcarlanGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [nagcarlanYellow, Colors.white, nagcarlanYellow],
  ),
);

class EtodaApp extends StatelessWidget {
  const EtodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eTODA Nagcarlan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: nagcarlanGreen),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // Define initial route
      home: const LandingScreen(),
      // Define routes for navigation
      onGenerateRoute: (settings) {
        if (settings.name == '/trip_started') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TripStartedScreen(
              passengerId: args['passenger_id'],
              driverId: args['driver_id'],
            ),
          );
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/passenger_home': (context) => const PassengerHomeScreen(),
        '/passenger_edit_profile': (context) => const PassengerEditProfileScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/driver_profile': (context) => const DriverProfileScreen(),
        '/driver_edit_profile': (context) => const DriverEditProfileScreen(),
        '/driver_trip_history': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final String driverId = (args?['id'] ?? args?['driver_id'] ?? '').toString();
          return DriverTripHistoryScreen(driverId: driverId);
        },
        '/scan_qr': (context) => const ScanQRScreen(),
        '/driver_profile_scanned': (context) => const ScannedDriverProfileScreen(),
        '/fare_matrix': (context) => const FareMatrixScreen(),
        '/passenger_trip_history': (context) => const PassengerTripHistoryScreen(),
        '/passenger_trip_details': (context) => const PassengerTripDetailsScreen(),
        '/driver_trip_details': (context) => const DriverTripDetailsScreen(),
      },
    );
  }
}
