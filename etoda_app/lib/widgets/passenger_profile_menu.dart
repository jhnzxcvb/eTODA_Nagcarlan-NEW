import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/screens/passenger_complaints_screen.dart';

class PassengerProfileMenu extends StatelessWidget {
  final Map<String, dynamic>? passengerData;

  const PassengerProfileMenu({super.key, this.passengerData});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle, color: nagcarlanGreen, size: 35),
      onSelected: (value) {
        switch (value) {
          case 'edit_profile':
            Navigator.pushNamed(context, '/passenger_edit_profile', arguments: passengerData);
            break;
          case 'trip_history':
            Navigator.pushNamed(context, '/passenger_trip_history', arguments: passengerData);
            break;
          case 'my_complaints':
            final String passengerId = (passengerData?['user_id'] ?? passengerData?['id'] ?? '').toString();
            if (passengerId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PassengerComplaintsScreen(passengerId: passengerId),
                ),
              );
            }
            break;
          case 'logout':
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            break;
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Colors.white,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(icon: Icons.edit_outlined, title: 'Edit Profile', value: 'edit_profile'),
        _buildPopupMenuItem(icon: Icons.history_outlined, title: 'Trip History', value: 'trip_history'),
        _buildPopupMenuItem(
          icon: Icons.warning_amber_rounded,
          title: 'My Complaints',
          value: 'my_complaints',
        ),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem(
          icon: Icons.logout,
          title: 'Logout',
          value: 'logout',
          color: Colors.redAccent,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({required IconData icon, required String title, required String value, Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? nagcarlanGreen),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
