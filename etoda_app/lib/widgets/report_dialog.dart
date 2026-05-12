import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
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
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: nagcarlanWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                radius: 30,
                child: const Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),
              
              const Text(
                "Report an Issue",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.redAccent,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Help us keep eTODA Nagcarlan safe by reporting any violations.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: selectedReason,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: nagcarlanGreen),
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: _isSubmitting ? null : (v) => setState(() => selectedReason = v),
                decoration: InputDecoration(
                  labelText: "Reason for Report",
                  labelStyle: const TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.02),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.list_alt_rounded, color: nagcarlanGreen),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _detailsController,
                maxLines: 4,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  labelText: "Additional Details (Optional)",
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: "Describe what happened...",
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.02),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submitReport(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
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
