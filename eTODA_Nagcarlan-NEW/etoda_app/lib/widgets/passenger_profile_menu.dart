import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class PassengerProfileMenu extends StatelessWidget {
  final Map<String, dynamic>? passengerData;

  const PassengerProfileMenu({super.key, this.passengerData});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle, color: nagcarlanGreen, size: 28),
      onSelected: (value) {
        switch (value) {
          case 'edit_profile':
            Navigator.pushNamed(context, '/passenger_edit_profile', arguments: passengerData);
            break;
          case 'trip_history':
            Navigator.pushNamed(context, '/passenger_trip_history');
            break;
          case 'logout':
            // Navigate to landing screen and remove all previous routes
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            break;
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(icon: Icons.edit_outlined, title: 'Edit Profile', value: 'edit_profile'),
        _buildPopupMenuItem(icon: Icons.history_outlined, title: 'Trip History', value: 'trip_history'),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem(
          icon: Icons.logout,
          title: 'Logout',
          value: 'logout',
          color: Colors.red[600],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({required IconData icon, required String title, required String value, Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey[700]),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
