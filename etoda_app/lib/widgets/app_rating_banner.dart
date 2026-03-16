
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/app_rating_dialog.dart';

class AppRatingBanner extends StatefulWidget {
  const AppRatingBanner({super.key});

  @override
  State<AppRatingBanner> createState() => _AppRatingBannerState();
}

class _AppRatingBannerState extends State<AppRatingBanner> {
  bool _isVisible = true;

  void _showAppRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AppRatingDialog(
        onSubmitted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Thank you for rating the app!"),
              backgroundColor: Colors.green[600],
            ),
          );
          setState(() {
            _isVisible = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink(); // Takes no space when hidden
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_border, color: Colors.grey[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Enjoying this app?",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ),
          TextButton(
            onPressed: _showAppRatingDialog,
            child: const Text("RATE US", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
            onPressed: () => setState(() => _isVisible = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
