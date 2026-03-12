
import 'dart:async';
import 'package:etoda_nagcarlan/main.dart';
import 'package:flutter/material.dart';

class AppRatingDialog extends StatefulWidget {
  final VoidCallback onSubmitted;
  const AppRatingDialog({super.key, required this.onSubmitted});

  @override
  State<AppRatingDialog> createState() => _AppRatingDialogState();
}

class _AppRatingDialogState extends State<AppRatingDialog> {
  int _rating = 0;
  bool _isSubmitted = false;

  void _submitRating() {
    if (_rating == 0) return;

    setState(() {
      _isSubmitted = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        widget.onSubmitted();      // Trigger the callback
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isSubmitted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: nagcarlanGreen, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Thanks for your feedback!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: nagcarlanGreen),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Rate the App",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: nagcarlanGreen),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enjoying the experience? Let us know!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 38,
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber[600],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nagcarlanGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _rating > 0 ? _submitRating : null,
                    child: const Text("SUBMIT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }
}
