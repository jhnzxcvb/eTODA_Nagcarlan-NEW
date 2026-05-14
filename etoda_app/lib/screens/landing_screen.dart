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
                backgroundColor: nagcarlanGreen,
                foregroundColor: Colors.white,
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
              // Logo image section with Yellow Ring
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: nagcarlanYellow, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: nagcarlanYellow.withOpacity(0.25),
                      blurRadius: 25,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Brand Text
              const Text(
                "eTODA",
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: nagcarlanGreen,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                "NAGCARLAN",
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: nagcarlanYellow
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your companion for tricycle transport in Nagcarlan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
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
                    // Login Button - Changed to Yellow
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nagcarlanGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        shadowColor: nagcarlanGreen.withOpacity(0.3),
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
                    // Sign Up Button - Added Yellow Border
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: nagcarlanGreen, width: 2),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        foregroundColor: nagcarlanGreen,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text(
                        "SIGN UP",
                        style: TextStyle(
                          fontSize: 18,
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
                    color: Colors.black45,
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
