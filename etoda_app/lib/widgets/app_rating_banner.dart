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
            const SnackBar(
              content: Text("Thank you for rating the app!"),
              backgroundColor: nagcarlanGreen,
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
        color: nagcarlanGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nagcarlanYellow.withOpacity(0.3)), // Minimal yellow border
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: nagcarlanYellow, size: 24), // Yellow star icon
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Enjoying this app?",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: _showAppRatingDialog,
            child: const Text("RATE US", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.black38),
            onPressed: () => setState(() => _isVisible = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
