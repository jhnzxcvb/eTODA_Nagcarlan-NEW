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
  bool _isLoading = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isLoading) return;

    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _isScanning = false;
          _isLoading = true;
        });
        await _processScannedCode(code);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String qrId) async {
    // Get passenger data passed from passenger_home
    final Map<String, dynamic>? passengerData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final int passengerId = (passengerData?['user_id'] ??
            passengerData?['id'] ??
            0) as int;

    debugPrint('🔍 Scanned QR: $qrId');
    debugPrint('🔍 Passenger ID: $passengerId');

    try {
      final encodedId = Uri.encodeComponent(qrId);
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/qrcodes/lookup?qr_id=$encodedId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check if QR is revoked
        if (data['status'] == 'Revoked') {
          _showError(
            "QR Code Revoked",
            "This driver's QR code has been revoked by the eTODA admin. Please choose another driver.",
            icon: Icons.block,
            iconColor: Colors.red,
          );
          return;
        }

        // Add passenger context to the driver data map before passing
        data['passenger_id'] = passengerId;

        // Navigate to profile and pass the full data map from Go backend
        Navigator.of(context).pushReplacementNamed(
          '/driver_profile_scanned',
          arguments: data, 
        );
      } else if (response.statusCode == 404) {
        _showError(
          "Invalid QR Code",
          "This QR code is not registered in the eTODA Nagcarlan system.",
          icon: Icons.qr_code,
          iconColor: Colors.orange,
        );
      } else {
        _showError(
          "Verification Failed",
          "The server could not verify this QR code. Please try again.",
        );
      }
    } on http.ClientException {
      if (!mounted) return;
      _showError(
        "Connection Error",
        "Could not connect to the eTODA server. Please check your internet connection.",
        icon: Icons.cloud_off,
        iconColor: Colors.blueGrey,
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Error", "Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(
    String title,
    String message, {
    IconData icon = Icons.error_outline,
    Color iconColor = Colors.red,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true);
            },
            child: const Text("TRY AGAIN", style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Driver QR"),
        backgroundColor: nagcarlanGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: "Toggle flashlight",
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
            tooltip: "Switch camera",
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isLoading ? Colors.orange : nagcarlanGreen,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _corner()),
                  Positioned(top: 0, right: 0, child: Transform.scale(scaleX: -1, child: _corner())),
                  Positioned(bottom: 0, left: 0, child: Transform.scale(scaleY: -1, child: _corner())),
                  Positioned(bottom: 0, right: 0, child: Transform.scale(scaleX: -1, scaleY: -1, child: _corner())),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: Container(
                width: 260,
                height: 260,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: nagcarlanGreen),
                      SizedBox(height: 12),
                      Text("Verifying driver...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isLoading
                      ? "Please wait..."
                      : "Align the driver's QR code inside the box",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: nagcarlanGreen, width: 4),
          left: BorderSide(color: nagcarlanGreen, width: 4),
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6)),
      ),
    );
  }
}