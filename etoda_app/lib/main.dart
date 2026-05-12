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

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const EtodaApp());
}

// Brand Colors
const Color nagcarlanWhite = Colors.white; // Primary
const Color nagcarlanGreen = Color(0xFF14532D); // Secondary: Deep green
const Color nagcarlanYellow = Color(0xFFFACC15); // Tertiary: Vibrant yellow accent

// Modern Gradient for Nagcarlan Branding (Main color white)
const BoxDecoration nagcarlanGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [nagcarlanWhite, Color(0xFFF8F9FA), Color(0xFFF1F3F5)],
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
          primary: nagcarlanWhite,
          onPrimary: Colors.black,
          secondary: nagcarlanGreen,
          onSecondary: Colors.white,
          tertiary: nagcarlanYellow,
          onTertiary: Colors.black,
          surface: nagcarlanWhite,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: nagcarlanWhite,
        appBarTheme: const AppBarTheme(
          backgroundColor: nagcarlanWhite,
          foregroundColor: nagcarlanGreen,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: nagcarlanGreen),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: nagcarlanGreen,
            foregroundColor: nagcarlanWhite,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: nagcarlanGreen),
            foregroundColor: nagcarlanGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: FutureBuilder<bool>(
        future: ApiService().isMaintenanceMode(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: nagcarlanGreen),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data == true) {
            return const MaintenanceScreen();
          }
          return const LandingScreen();
        },
      ),
      navigatorObservers: [routeObserver],
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
        '/passenger_edit_profile': (context) =>
            const PassengerEditProfileScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/driver_profile': (context) => const DriverProfileScreen(),
        '/driver_edit_profile': (context) => const DriverEditProfileScreen(),
        '/driver_trip_history': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final String driverId = (args?['id'] ?? args?['driver_id'] ?? '')
              .toString();
          return DriverTripHistoryScreen(driverId: driverId);
        },
        '/scan_qr': (context) => const ScanQRScreen(),
        '/driver_profile_scanned': (context) =>
            const ScannedDriverProfileScreen(),
        '/fare_matrix': (context) => const FareMatrixScreen(),
        '/passenger_trip_history': (context) =>
            const PassengerTripHistoryScreen(),
        '/passenger_trip_details': (context) =>
            const PassengerTripDetailsScreen(),
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
              decoration: BoxDecoration(
                color: nagcarlanGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 80,
                color: nagcarlanGreen,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'System Maintenance',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: nagcarlanGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We are currently updating our systems to serve you better. We\'ll be back online shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 16),
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
