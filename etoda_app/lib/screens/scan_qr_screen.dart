
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate scanning for 2 seconds then navigate
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/driver_profile_scanned');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Driver QR")),
      body: Container(
        decoration: nagcarlanGradient,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: nagcarlanGreen, width: 4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(nagcarlanGreen),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Scanning QR Code...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: nagcarlanGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
