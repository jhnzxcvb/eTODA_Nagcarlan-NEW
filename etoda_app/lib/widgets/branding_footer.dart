import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class BrandingFooter extends StatelessWidget {
  const BrandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: nagcarlanGreen, size: 16),
            SizedBox(width: 4),
            Text("Safe • ", style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold, fontSize: 12)),
            Text("Fair", style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(" • Verified", style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
