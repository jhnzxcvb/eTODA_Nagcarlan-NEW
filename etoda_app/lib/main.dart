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
import 'package:etoda_nagcarlan/screens/trip_ended_screen.dart';
import 'package:etoda_nagcarlan/screens/trip_cancelled_screen.dart';
import 'package:etoda_nagcarlan/screens/driver_trip_ended_screen.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

void main() {
  runApp(const EtodaApp());
}

// Brand Colors
const Color nagcarlanGreen = Color(0xFF14532D); // Primary: Deep green from admin sidebar
const Color nagcarlanWhite = Colors.white; // Secondary
const Color nagcarlanYellow = Color(0xFFFACC15); // Tertiary: Vibrant yellow accent

// Modern Gradient for Nagcarlan Branding (Main color green)
const BoxDecoration nagcarlanGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [nagcarlanGreen, Color(0xFF166534), nagcarlanGreen],
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: nagcarlanGreen,
          primary: nagcarlanGreen,
          secondary: nagcarlanWhite,
          tertiary: nagcarlanYellow,
          surface: nagcarlanWhite,
          onPrimary: Colors.white,
          onSecondary: nagcarlanGreen,
          onTertiary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: nagcarlanGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: nagcarlanGreen,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // Define initial route
      home: FutureBuilder<bool>(
        future: ApiService().isMaintenanceMode(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: nagcarlanGreen)),
            );
          }
          if (snapshot.hasData && snapshot.data == true) {
            return const MaintenanceScreen();
          }
          return const LandingScreen();
        },
      ),
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
        '/trip_ended': (context) => const TripEndedScreen(),
        '/trip_cancelled': (context) => const TripCancelledScreen(),
        '/driver_trip_ended': (context) => const DriverTripEndedScreen(),
      },
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        decoration: nagcarlanGradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 80,
                color: nagcarlanYellow,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'System Maintenance',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We are currently updating our systems to serve you better. We\'ll be back online shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => runApp(const EtodaApp()),
              style: ElevatedButton.styleFrom(
                backgroundColor: nagcarlanYellow,
                foregroundColor: nagcarlanGreen,
              ),
              child: const Text('CHECK AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
