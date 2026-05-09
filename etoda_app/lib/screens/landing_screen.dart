import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:etoda_nagcarlan/main.dart';


class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static bool _sessionPrivacyNoticeShown = false; // Session-level flag

  @override
  void initState() {
    super.initState();
    _checkAndShowPrivacyNotice();
  }

  Future<void> _checkAndShowPrivacyNotice() async {
    if (_sessionPrivacyNoticeShown) return; // Skip if already evaluated this session

    _sessionPrivacyNoticeShown = true;
    // Show the dialog after the first frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrivacyNotice();
    });
  }

  void _showPrivacyNotice() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Data Privacy Notice",
            style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              "eTODA Nagcarlan collects and processes personal information to facilitate tricycle transport services. "
              "By clicking 'AGREE', you consent to our terms of service and acknowledge our data privacy policy in compliance with the Data Privacy Act.\n\n"
              "Do you agree to proceed?",
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Automatically closes the app
                SystemNavigator.pop();
              },
              child: const Text("DECLINE", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nagcarlanYellow,
                foregroundColor: nagcarlanGreen,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("AGREE"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo/Icon Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: nagcarlanWhite.withValues(alpha: 0.95), // Fix: Deprecated withOpacity
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2), // Fix: Deprecated withOpacity
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.electric_rickshaw,
                  size: 80,
                  color: nagcarlanGreen,
                ),
              ),
              const SizedBox(height: 32),
              // Brand Text
              const Text(
                "eTODA",
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: nagcarlanYellow,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                "NAGCARLAN",
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: nagcarlanWhite,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your companion for tricycle transport in Nagcarlan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nagcarlanYellow,
                        foregroundColor: nagcarlanGreen,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: nagcarlanWhite, width: 2),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text(
                        "SIGN UP",
                        style: TextStyle(
                          color: nagcarlanWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              // Footer Info
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Drivers must register at the eTODA Admin office to activate their accounts.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
