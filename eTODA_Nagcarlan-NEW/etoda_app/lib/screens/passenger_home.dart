
import 'package:etoda_nagcarlan/widgets/app_rating_banner.dart';
import 'package:etoda_nagcarlan/widgets/passenger_profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  void _showGuestRestrictionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text("Access Restricted", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "This feature is only available for registered users. Please create an account to enjoy full access to eTODA Nagcarlan.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("LATER", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nagcarlanGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/signup');
            },
            child: const Text("SIGN UP NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get passenger data from arguments passed during login
    final Map<String, dynamic>? passengerData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final bool isGuest = passengerData?['is_guest'] ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // We control the leading manually
        leading: isGuest 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: nagcarlanGreen),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            )
          : null,
        actions: [
          if (!isGuest) PassengerProfileMenu(passengerData: passengerData),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: nagcarlanGradient,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text("eTODA", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: nagcarlanGreen)),
            const Text("NAGCARLAN", style: TextStyle(fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.bold, color: nagcarlanGreen)),
            
            // Welcome the passenger by name
            Text(
                isGuest ? "Logged in as Guest" : "Welcome, ${passengerData?['first_name'] ?? 'Passenger'}",
                style: const TextStyle(fontSize: 18, color: nagcarlanGreen, fontWeight: FontWeight.w500)
            ),

            const Spacer(),
            MenuCard(
              title: "SCAN DRIVER QR",
              subtitle: "Verify your driver safely",
              icon: Icons.qr_code_scanner,
              color: nagcarlanGreen,
              textColor: Colors.white,
              onTap: () {
                if (isGuest) {
                  _showGuestRestrictionDialog(context);
                } else {
                  Navigator.pushNamed(context, '/scan_qr');
                }
              },
            ),
            const SizedBox(height: 20),
            MenuCard(
              title: "FARE MATRIX",
              subtitle: "Check exact rates per area",
              icon: Icons.payments,
              color: Colors.white,
              textColor: nagcarlanGreen,
              onTap: () => Navigator.pushNamed(context, '/fare_matrix'),
            ),
            if (!isGuest) const AppRatingBanner(),
            const Spacer(),
            const BrandingFooter(),
          ],
        ),
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: textColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: textColor.withAlpha(178))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
