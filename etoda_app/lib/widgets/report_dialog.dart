import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

class ReportDialog extends StatefulWidget {
  final int passengerId;
  final int driverId;

  const ReportDialog({
    super.key,
    required this.passengerId,
    required this.driverId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final List<String> reasons = ["Reckless Driving", "Overcharging", "Harassment", "Other"];
  String? selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    selectedReason = reasons.first;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport(BuildContext context) async {
    setState(() => _isSubmitting = true);

    final api = ApiService();
    bool success = await api.submitComplaint({
      'passenger_id': widget.passengerId,
      'driver_id': widget.driverId,
      'violation_type': selectedReason ?? "Other",
      'details': _detailsController.text,
    });

    if (!context.mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Report submitted successfully!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit. Please check connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // Softer corners
      child: SingleChildScrollView( // Prevents overflow on small screens
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visual Indicator
              CircleAvatar(
                backgroundColor: Colors.red[50]!,
                radius: 30,
                child: Icon(Icons.report_problem_rounded, color: Colors.red[800], size: 32),
              ),
              const SizedBox(height: 16),
              
              Text(
                "Report an Issue",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.red[800],
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Help us keep eTODA Nagcarlan safe by reporting any violations.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Reason Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: _isSubmitting ? null : (v) => setState(() => selectedReason = v),
                decoration: InputDecoration(
                  labelText: "Reason for Report",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.list_alt_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Details Input
              TextField(
                controller: _detailsController,
                maxLines: 4,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  labelText: "Additional Details (Optional)",
                  hintText: "Describe what happened...",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submitReport(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Submit Report", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}