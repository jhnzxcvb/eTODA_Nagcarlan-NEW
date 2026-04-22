
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class BrandingFooter extends StatelessWidget {
  const BrandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: nagcarlanYellow, size: 16),
            SizedBox(width: 4),
            Text("Safe • Fair • Verified", style: TextStyle(color: nagcarlanYellow, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        Text("Powered by CardBank", style: TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}
