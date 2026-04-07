import 'dart:async';
import 'package:etoda_nagcarlan/widgets/payment_method_dialog.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/constants.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

class FareCalculatorDialog extends StatefulWidget {
  final bool isFullScreen;
  final Map<String, dynamic> driverData;

  const FareCalculatorDialog({
    super.key, 
    this.isFullScreen = false, 
    required this.driverData,
  });

  @override
  State<FareCalculatorDialog> createState() => _FareCalculatorDialogState();
}

class _FareCalculatorDialogState extends State<FareCalculatorDialog> {
  final ApiService _apiService = ApiService();
  
  final List<String> passengers = ["Regular", "Student", "Senior Citizen", "PWD"];
  final List<String> tripTypes = ["Regular Trip", "Special Trip"];
  
  String selectedPassenger = "Regular";
  String selectedTrip = "Regular Trip";
  String? fromLocation;
  String? toLocation;
  
  List<String> _allLocations = [];
  List<dynamic> _fares = [];
  bool _isLoading = true;
  double fare = 0.00;
  double discountAmount = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final fareData = await _apiService.fetchFares();
      final Set<String> locs = {};
      for (var f in fareData) {
        if (f['origin'] != null) locs.add(f['origin'].toString());
        if (f['destination'] != null) locs.add(f['destination'].toString());
      }
      
      if (mounted) {
        setState(() {
          _fares = fareData;
          _allLocations = locs.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load fares: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateFare() {
    if (fromLocation == null || toLocation == null) {
      setState(() {
        fare = 0.00;
        discountAmount = 0.0;
      });
      return;
    }

    Map<String, dynamic>? routeFare;
    for (var f in _fares) {
      if ((f['origin'] == fromLocation && f['destination'] == toLocation) ||
          (f['origin'] == toLocation && f['destination'] == fromLocation)) {
        routeFare = f;
        break;
      }
    }

    if (routeFare == null) {
      setState(() {
        fare = 0.00;
        discountAmount = 0.0;
      });
      return;
    }

    double finalFare = 0.0;
    double currentDiscount = 0.0;

    if (selectedTrip == "Special Trip") {
      finalFare = (routeFare['special_fare'] as num).toDouble();
      currentDiscount = 0.0;
    } else {
      if (selectedPassenger == "Regular") {
        finalFare = (routeFare['base_fare'] as num).toDouble();
        currentDiscount = 0.0;
      } else {
        finalFare = (routeFare['discounted_fare'] as num).toDouble();
        double base = (routeFare['base_fare'] as num).toDouble();
        currentDiscount = base - finalFare;
      }
    }

    setState(() {
      fare = finalFare;
      discountAmount = currentDiscount;
    });
  }

  Future<void> _handlePayment() async {
    if (fare <= 0) return;
    
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    
    // We don't pop FareCalculatorDialog yet. 
    // We show PaymentMethodDialog on top of it.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (paymentDialogContext) => PaymentMethodDialog(
        fare: fare,
        passengerType: selectedPassenger,
        tripType: selectedTrip,
        driverData: {
          ...widget.driverData,
          'from_location': fromLocation,
          'to_location': toLocation,
        },
        onPaymentConfirmed: () {
          // 1. Pop the FareCalculatorDialog (which is underneath)
          // Since the PaymentMethodDialog has already popped itself (and its loading dialog) 
          // in its own confirm logic, we use the 'context' of FareCalculatorDialog here.
          Navigator.of(context).pop();

          // 2. Navigate to Trip Started Screen and remove the Profile Screen
          // This replaces '/driver_profile_scanned' with '/trip_started'
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/trip_started',
            ModalRoute.withName('/passenger_home'),
            arguments: {
              'passenger_id': widget.driverData['passenger_id'],
              'driver_id': widget.driverData['driver_id'],
            },
          );
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: nagcarlanGreen))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: nagcarlanGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calculate_rounded, color: nagcarlanGreen),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Fare Calculator",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildLabel("Pick-up Point"),
                  _buildSearchableDropdown(fromLocation, (val) {
                    setState(() => fromLocation = val);
                    _calculateFare();
                  }),

                  const SizedBox(height: 16),

                  _buildLabel("Drop-off Destination"),
                  _buildSearchableDropdown(toLocation, (val) {
                    setState(() => toLocation = val);
                    _calculateFare();
                  }),

                  const SizedBox(height: 16),

                  _buildLabel("Passenger Category"),
                  _buildDropdown(passengers, selectedPassenger, (val) {
                    setState(() => selectedPassenger = val!);
                    _calculateFare();
                  }),
                  
                  const SizedBox(height: 16),
                  
                  _buildLabel("Type of Trip"),
                  _buildDropdown(tripTypes, selectedTrip, (val) {
                    setState(() => selectedTrip = val!);
                    _calculateFare();
                  }),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "TOTAL FARE",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₱${fare.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: nagcarlanGreen),
                        ),
                        
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (selectedTrip == "Special Trip")
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.yellow.shade700.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    "Special Trip",
                                    style: TextStyle(color: Colors.yellow.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            if (discountAmount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.yellow.shade700.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    "Discounted (₱${discountAmount.toStringAsFixed(0)} Off)",
                                    style: TextStyle(color: Colors.yellow.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || fare <= 0) ? null : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nagcarlanGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text("Confirm & Pay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchableDropdown(String? selectedValue, ValueChanged<String?> onChanged) {
    return Autocomplete<String>(
      optionsBuilder: (v) => v.text == '' ? _allLocations : _allLocations.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
      onSelected: onChanged,
      fieldViewBuilder: (ctx, ctrl, node, onSubmit) {
        if (selectedValue != null && ctrl.text == "") ctrl.text = selectedValue;
        return TextFormField(
          controller: ctrl,
          focusNode: node,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: "Search location...",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        );
      },
    );
  }
}
