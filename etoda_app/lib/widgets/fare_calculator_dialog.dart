
import 'dart:async';
import 'package:etoda_nagcarlan/widgets/payment_method_dialog.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

class FareCalculatorDialog extends StatefulWidget {
  final bool isFullScreen;
  const FareCalculatorDialog({super.key, this.isFullScreen = false});

  @override
  State<FareCalculatorDialog> createState() => _FareCalculatorDialogState();
}

class _FareCalculatorDialogState extends State<FareCalculatorDialog> {
  final List<String> locations = ["Select Location", "Poblacion", "Talangan", "Oobi", "Malinao"];
  final List<String> passengerTypes = ["Normal", "Senior", "PWD", "Student"];
  final List<String> tripTypes = ["Regular", "Special Trip"];

  String fromLocation = "Select Location";
  String toLocation = "Select Location";
  String passengerType = "Normal";
  String tripType = "Regular";
  String fare = "₱0.00";
  bool isCalculated = false;

  @override
  void initState() {
    super.initState();
    fromLocation = locations.first;
    toLocation = locations.first;
    passengerType = passengerTypes.first;
    tripType = tripTypes.first;
  }

  void _calculateFare() {
    if (fromLocation == "Select Location" || toLocation == "Select Location") {
      setState(() {
        fare = "₱0.00";
        isCalculated = false;
      });
    } else {
      double baseFare = (tripType == "Special Trip") ? 50.0 : 30.0;
      if (passengerType != "Normal") {
        baseFare *= 0.80; // 20% discount
      }
      setState(() {
        fare = "₱${baseFare.toStringAsFixed(2)}";
        isCalculated = true;
      });
    }
  }

  void _showPaymentDialog() {
    // We are inside a dialog, so we get the navigator from the parent context
    final parentNavigator = Navigator.of(context, rootNavigator: true);

    // Dismiss the current dialog (fare calculator)
    Navigator.of(context).pop();

    showDialog(
      context: parentNavigator.context, // Use the parent context to show the new dialog
      barrierDismissible: false,
      builder: (context) => PaymentMethodDialog(
        onPaymentConfirmed: () {
          // This is now called with the correct context after PaymentMethodDialog dismisses itself
          parentNavigator.pushReplacementNamed('/trip_started');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(widget.isFullScreen)
            const SizedBox(height: 20),
          if(!widget.isFullScreen) ...[
             const Text("Calculate Fare First", style: TextStyle(fontWeight: FontWeight.bold, color: nagcarlanGreen, fontSize: 22)),
             const SizedBox(height: 8),
             Text("Select your route to estimate the cost.", style: TextStyle(color: Colors.grey[600])),
             const SizedBox(height: 24),
          ],
          _buildDropdown("From:", locations, fromLocation, (val) => setState(() { fromLocation = val!; _calculateFare();})),
          const SizedBox(height: 12),
          _buildDropdown("To:", locations, toLocation, (val) => setState(() { toLocation = val!; _calculateFare();})),
          const Divider(height: 32),
          _buildDropdown("Passenger:", passengerTypes, passengerType, (val) => setState(() { passengerType = val!; _calculateFare();})),
          const SizedBox(height: 12),
          _buildDropdown("Trip:", tripTypes, tripType, (val) => setState(() { tripType = val!; _calculateFare();})),
          const SizedBox(height: 24),
          Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: nagcarlanGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text("TOTAL FARE", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(fare, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                     if (passengerType != "Normal") ...[
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: nagcarlanGold.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8)
                            ),
                            child: const Text("20% Discount Applied", style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold, fontSize: 12))
                        )
                    ]
                  ],
                ),
              ),
          if(!widget.isFullScreen) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions_car, size: 18),
                  onPressed: isCalculated ? _showPaymentDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nagcarlanGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  ),
                  label: const Text("Confirm & Start"),
                ),
              ],
            ),
          ]
        ],
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        appBar: AppBar(title: const Text("Fare Matrix")),
        body: Container(
            decoration: nagcarlanGradient,
            padding: const EdgeInsets.all(20),
            child: content
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: content,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
