
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, String> items;

  const InfoSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: nagcarlanGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: TextStyle(color: Colors.grey[600])),
                    Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
