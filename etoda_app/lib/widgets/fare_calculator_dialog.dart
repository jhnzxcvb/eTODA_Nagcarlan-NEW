import 'dart:async';
import 'package:etoda_nagcarlan/widgets/payment_method_dialog.dart';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
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
  StreamSubscription? _wsSubscription;
  String? _currentRequestId;
  
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
  String? _passengerName;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
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
    if (fromLocation == null || toLocation == null) {
      _showSnackbar("Please select a pick-up and drop-off location.");
      return;
    }

    final String driverStatusRaw = widget.driverData['status']?.toString() ?? widget.driverData['driver_status']?.toString() ?? '';
    final String driverStatus = driverStatusRaw.toLowerCase().trim();
    final bool driverIsOnline = RegExp(r'\b(active|online|available)\b').hasMatch(driverStatus) ||
        widget.driverData['is_active']?.toString().toLowerCase() == 'true' ||
        widget.driverData['active'] == true ||
        widget.driverData['qr_status']?.toString().toLowerCase().trim() == 'active';

    if (!driverIsOnline) {
      _showSnackbar("Driver is currently offline. Please choose another driver or try again later.");
      return;
    }

    final int passengerId = (widget.driverData['passenger_id'] as num?)?.toInt() ?? 0;
    if (passengerId == 0) {
      _showSnackbar("Unable to determine passenger identity.");
      return;
    }

    if (_passengerName == null) {
      try {
        final pData = await _apiService.getPassengerById(passengerId);
        if (pData != null) {
          _passengerName = pData['name'] ?? 'Passenger';
        } else {
          _passengerName = 'Passenger';
        }
      } catch (e) {
        debugPrint('Failed to fetch passenger name: $e');
        _passengerName = 'Passenger';
      }
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final route = [fromLocation, toLocation]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(' → ');

    // Ensure socket is ready before sending request
    await _ensurePassengerSocket(passengerId);

    final result = await _apiService.createTripRequest({
      'passenger_id': passengerId,
      'driver_id': (widget.driverData['driver_id'] as num?)?.toInt() ?? 0,
      'passenger_name': _passengerName,
      'route': route,
      'fare': fare,
      'from_location': fromLocation,
      'to_location': toLocation,
    });

    if (!mounted) return;

    if (result['request_id'] == null) {
      _showSnackbar("Could not send request to driver. Please try again.");
      setState(() => _isProcessing = false);
      return;
    }

    _currentRequestId = result['request_id'].toString();
    // Start listening only after we have a valid request ID to match against
    _listenForApprovalResponse();
    setState(() => _isProcessing = false);
    _showWaitingApprovalDialog();
  }

  Future<void> _ensurePassengerSocket(int passengerId) async {
    if (ApiService.getWebSocketStream() == null) {
      await ApiService.connectPassengerWebSocket(passengerId.toString());
    }
  }

  void _listenForApprovalResponse() {
    _wsSubscription?.cancel();
    final wsStream = ApiService.getWebSocketStream();
    if (wsStream == null) return;

    _wsSubscription = wsStream.listen((message) {
      final event = message['event']?.toString();
      final request = message['request'] as Map<String, dynamic>?;
      
      // Ensure we match the request ID correctly (handling int vs String types)
      final incomingId = request?['request_id']?.toString();
      
      if (incomingId == null || incomingId != _currentRequestId) return;

      if (event == 'trip_approved') {
        _closeWaitingDialog();
        _showSnackbar("Driver accepted your request. Proceeding to payment.");
        _showPaymentDialog();
      } else if (event == 'trip_rejected') {
        _closeWaitingDialog();
        _showSnackbar("Driver rejected the request. Please try another driver.");
        if (mounted) setState(() => _isProcessing = false);
      }
    }, onError: (error) {
      debugPrint('Passenger WebSocket error: $error');
    });
  }

  void _showWaitingApprovalDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: nagcarlanWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Waiting for Driver Approval', style: TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: nagcarlanGreen),
            SizedBox(height: 16),
            Text(
              'Please wait while the driver reviews your trip request.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _currentRequestId = null;
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  void _closeWaitingDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showPaymentDialog() {
    if (!mounted) return;
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
          Navigator.of(context).pop();
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

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          color: nagcarlanWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                          color: nagcarlanGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calculate_rounded, color: nagcarlanGreen),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Fare Calculator",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, color: nagcarlanGreen),
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
                      color: Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "TOTAL FARE",
                          style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                                    color: nagcarlanYellow.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: nagcarlanYellow.withOpacity(0.5)),
                                  ),
                                  child: const Text(
                                    "Special Trip",
                                    style: TextStyle(color: Color(0xFF854D0E), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            if (discountAmount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: nagcarlanYellow.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: nagcarlanYellow.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    "Discounted (₱${discountAmount.toStringAsFixed(0)} Off)",
                                    style: const TextStyle(color: Color(0xFF854D0E), fontSize: 12, fontWeight: FontWeight.bold),
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
                          : const Text("Request Driver Approval", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: nagcarlanGreen),
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
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: ctrl,
          builder: (context, value, child) {
            return TextFormField(
              controller: ctrl,
              focusNode: node,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Search location...",
                hintStyle: const TextStyle(color: Colors.black26),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20, color: Colors.black38),
                        onPressed: () {
                          ctrl.clear();
                          onChanged(null);
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
