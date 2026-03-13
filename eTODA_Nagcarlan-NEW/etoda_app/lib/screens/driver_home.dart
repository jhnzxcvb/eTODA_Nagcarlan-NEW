import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the full data map passed from the Login screen
    final Map<String, dynamic>? driverData =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevents the default back button
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: nagcarlanGreen, size: 30),
            onSelected: (value) {
              if (value == 'edit_profile') {
                Navigator.pushNamed(context, '/driver_edit_profile', arguments: driverData);
              } else if (value == 'logout') {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit_profile',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: nagcarlanGreen),
                    SizedBox(width: 10),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
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

            // Welcome the driver by name if data is available
            Text(
                "Welcome, ${driverData?['first_name'] ?? 'Driver'}",
                style: const TextStyle(fontSize: 18, color: nagcarlanGreen, fontWeight: FontWeight.w500)
            ),

            const Spacer(),
            MenuCard(
              title: "MY PROFILE",
              subtitle: "Trips, vehicle info & earnings",
              icon: Icons.account_circle,
              color: nagcarlanGreen,
              textColor: Colors.white,
              onTap: () => Navigator.pushNamed(context, '/driver_profile', arguments: driverData),
            ),
            const SizedBox(height: 20),
            MenuCard(
              title: "TRIP HISTORY",
              subtitle: "See your past rides",
              icon: Icons.list_alt,
              color: Colors.white,
              textColor: nagcarlanGreen,
              onTap: () {},
            ),
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
