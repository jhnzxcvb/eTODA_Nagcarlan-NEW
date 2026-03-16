import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class DriverTripEndedScreen extends StatefulWidget {
  const DriverTripEndedScreen({super.key});

  @override
  State<DriverTripEndedScreen> createState() => _DriverTripEndedScreenState();
}

class _DriverTripEndedScreenState extends State<DriverTripEndedScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get driver data passed from the home screen
    final Map<String, dynamic>? driverData =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      body: Container(
        decoration: nagcarlanGradient,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(nagcarlanGreen)),
                    SizedBox(height: 16),
                    Text("Finalizing Trip...", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: nagcarlanGreen, size: 100),
                    const SizedBox(height: 24),
                    const Text(
                      "Trip Completed!",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: nagcarlanGreen),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "The passenger has been notified. You can now take your next trip.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nagcarlanGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // Pass back the driver data and ensure shift is active
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/driver_home', 
                            (route) => false,
                            arguments: {
                              ...?driverData,
                              'is_shift_active': true,
                            }
                          );
                        },
                        child: const Text("BACK TO HOME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const BrandingFooter(),
                  ],
                ),
        ),
      ),
    );
  }
}
