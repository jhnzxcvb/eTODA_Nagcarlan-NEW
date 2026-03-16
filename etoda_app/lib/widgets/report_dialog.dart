
import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final List<String> reasons = ["Reckless Driving", "Overcharging", "Harassment", "Other"];
  String? selectedReason;

  @override
  void initState() {
    super.initState();
    selectedReason = reasons.first;
  }

  void _submitReport(BuildContext context) {
    // Close the dialog first
    Navigator.of(context).pop();

    // Show a confirmation SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 16),
            Expanded(child: Text('Report submitted. Thank you for your feedback.')),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem_outlined, color: Colors.red[700], size: 28),
                const SizedBox(width: 12),
                Text("Report an Issue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red[800])),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Your feedback helps keep our community safe. Please provide details below.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: reasons.map((reason) => DropdownMenuItem(value: reason, child: Text(reason))).toList(),
              onChanged: (value) => setState(() => selectedReason = value),
              decoration: InputDecoration(
                labelText: "Reason for Report",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Provide additional details (optional)",
                hintText: "e.g., location, time, what happened",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: () => _submitReport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  label: const Text("Submit Report"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
