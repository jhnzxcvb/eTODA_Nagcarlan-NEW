import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool _isScanning = true;
  MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        debugPrint('Barcode found! $code');
        setState(() => _isScanning = false);
        
        // The QR code usually contains a "driver_id" or a special "qr_id"
        // Example format: "QR-AES-NVC001A-c88d" or just a number "1"
        _processScannedCode(code);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: nagcarlanGreen)),
    );

    try {
      // 1. We try to find the driver by their QR ID or Driver Code
      // In your system, the QR ID looks like "QR-AES-NVC001A-c88d"
      // We need an endpoint to resolve this QR code to a driver profile
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/qrcodes/$code'),
      );

      if (mounted) Navigator.pop(context); // Remove loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Navigate to the scanned profile screen and pass the driver data
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/driver_profile_scanned', 
            arguments: data
          );
        }
      } else {
        _showError("Invalid QR Code", "This QR code is not recognized by the eTODA system.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Connection Error", "Could not connect to the server to verify this driver.");
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true); // Resume scanning
            },
            child: const Text("TRY AGAIN", style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Driver QR"),
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Align Driver's QR Code inside the box",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
