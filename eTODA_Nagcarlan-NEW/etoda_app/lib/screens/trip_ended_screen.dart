
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/rating_dialog.dart';

class TripEndedScreen extends StatefulWidget {
  const TripEndedScreen({super.key});

  @override
  State<TripEndedScreen> createState() => _TripEndedScreenState();
}

class _TripEndedScreenState extends State<TripEndedScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => isLoading = false);
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => RatingDialog(
                onSubmitted: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/passenger_home', (route) => false);
                },
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: nagcarlanGradient,
        child: Center(
          child: isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(nagcarlanGreen)),
                    SizedBox(height: 16),
                    Text("Ending Trip...", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: nagcarlanGreen, size: 100),
                    SizedBox(height: 16),
                    Text("Arrived!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: nagcarlanGreen)),
                  ],
            ),
        ),
      ),
    );
  }
}
