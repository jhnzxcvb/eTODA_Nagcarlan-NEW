import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/constants.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';

enum PaymentMethod { cash, ewallet }
enum EWallet { gcash, maya, konek2card }

class PaymentMethodDialog extends StatefulWidget {
  final VoidCallback onPaymentConfirmed;
  final double fare;
  final String passengerType;
  final String tripType;
  final Map<String, dynamic> driverData;

  const PaymentMethodDialog({
    super.key,
    required this.onPaymentConfirmed,
    required this.fare,
    required this.passengerType,
    required this.tripType,
    required this.driverData,
  });

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  EWallet? _selectedEWallet;
  late final TextEditingController _contactController;
  final TextEditingController _accountController = TextEditingController();
  String _refCode = '';

  @override
  void initState() {
    super.initState();
    final contact = widget.driverData['contact_number']?.toString()
                 ?? widget.driverData['phone']?.toString()
                 ?? widget.driverData['contact']?.toString()
                 ?? widget.driverData['phone_number']?.toString()
                 ?? widget.driverData['mobile']?.toString()
                 ?? '';
    _contactController = TextEditingController(text: contact);
  }

  @override
  void dispose() {
    _contactController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _eWalletConfig(EWallet wallet) {
    switch (wallet) {
      case EWallet.gcash:
        return {'color': const Color(0xFF007DFF), 'label': 'G', 'name': 'GCash', 'hint': '09XX XXX XXXX'};
      case EWallet.maya:
        return {'color': const Color(0xFF00B140), 'label': 'M', 'name': 'Maya', 'hint': '09XX XXX XXXX'};
      case EWallet.konek2card:
        return {'color': const Color(0xFFFF6600), 'label': 'K', 'name': 'Konek2CARD', 'hint': 'Card/Account Number'};
    }
  }

  String get _methodLabel {
    if (_selectedMethod == PaymentMethod.cash) return 'Cash';
    return _eWalletConfig(_selectedEWallet!)['name'] as String;
  }

  void _showEWalletInputDialog() {
    _accountController.text = _contactController.text;
    final config = _eWalletConfig(_selectedEWallet!);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: config['color'] as Color,
                    radius: 20,
                    child: Text(config['label'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Text(config['name'] as String,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: nagcarlanGreen)),
                ],
              ),
              const SizedBox(height: 6),
              Text("Amount: ₱${widget.fare.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 18),
              Text("Driver's ${config['name']} Number",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextField(
                controller: _accountController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: config['hint'] as String,
                  prefixIcon: const Icon(Icons.phone_android, color: nagcarlanGreen),
                  helperText: "Auto-filled from driver profile. You may edit if needed.",
                  helperStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: nagcarlanGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: nagcarlanGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: nagcarlanGreen)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nagcarlanGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _runPaymentSteps();
                      },
                      child: const Text("Send Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runPaymentSteps() {
    final isCash = _selectedMethod == PaymentMethod.cash;
    final walletName = isCash ? '' : _methodLabel;

    final List<String> steps = isCash
        ? ["Processing cash payment...", "Recording transaction...", "Payment confirmed! ✓"]
        : [
            "Connecting to $walletName...",
            "Verifying account...",
            "Processing ₱${widget.fare.toStringAsFixed(2)}...",
            "Payment confirmed! ✓",
          ];

    int stepIndex = 0;
    final statusNotifier = ValueNotifier<String>(steps[0]);
    final isLastStep = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<String>(
        valueListenable: statusNotifier,
        builder: (_, status, __) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: isLastStep,
                  builder: (_, done, __) => done
                      ? const Icon(Icons.check_circle_rounded, color: nagcarlanGreen, size: 48)
                      : const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(nagcarlanGreen)),
                ),
                const SizedBox(height: 20),
                Text(status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );

    // Store the future to ensure we wait for it before showing the receipt
    final paymentFuture = _postPayment();

    Timer.periodic(const Duration(milliseconds: 900), (timer) {
      stepIndex++;
      if (stepIndex < steps.length) {
        statusNotifier.value = steps[stepIndex];
        if (stepIndex == steps.length - 1) isLastStep.value = true;
      } else {
        timer.cancel();
        
        // Ensure the API call is finished and successful before showing receipt
        paymentFuture.then((success) {
          if (success) {
            Future.delayed(const Duration(milliseconds: 600), () {
              Navigator.of(context).pop(); // Pop progress dialog
              Navigator.of(context).pop(); // Pop payment method dialog
              _showReceiptDialog();
            });
          } else {
            Navigator.of(context).pop(); // Pop progress dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to record payment. Please try again.")),
            );
          }
        });
      }
    });
  }

  Future<bool> _postPayment() async {
    try {
      final route = [
        widget.driverData['from_location'],
        widget.driverData['to_location'],
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' → ');

      final body = {
        'passenger_id': (widget.driverData['passenger_id'] as num?)?.toInt() ?? 0,
        'driver_id': (widget.driverData['driver_id'] as num?)?.toInt() ?? 0,
        'passenger_name': widget.driverData['passenger_name'] ?? 'Passenger',
        'driver_name': widget.driverData['full_name'] ?? 'Driver',
        'route': route.isNotEmpty ? route : "Body #${widget.driverData['body_no'] ?? 'N/A'}",
        'amount': widget.fare,
        'method': _methodLabel,
        'status': 'Paid',
        'passenger_type': widget.passengerType,
        'trip_type': widget.tripType,
        'ewallet_account': _selectedMethod == PaymentMethod.ewallet
            ? _accountController.text.trim()
            : '',
        'contact_number': _contactController.text.trim(),
      };

      final result = await ApiService().post('/api/payments', body);
      
      // ApiService.post unwraps the "data" object from the backend response.
      // Check if we received a reference code, which indicates a successful DB save.
      if (result.containsKey('ref_code')) {
        _refCode = result['ref_code'].toString();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Payment POST error: $e');
      return false;
    }
  }

  void _showReceiptDialog() {
    final now = DateTime.now();
    final timeLabel =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} "
        "${now.month}/${now.day}/${now.year}";
    final displayRef = _refCode.isNotEmpty
        ? _refCode
        : DateTime.now().millisecondsSinceEpoch.toString().substring(6);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: nagcarlanGreen, size: 60),
              const SizedBox(height: 12),
              const Text("Payment Successful!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: nagcarlanGreen)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              _receiptRow("Amount Paid", "₱${widget.fare.toStringAsFixed(2)}"),
              _receiptRow("Method", _methodLabel),
              if (_selectedMethod == PaymentMethod.ewallet)
                _receiptRow("Account No.", _accountController.text.trim()),
              _receiptRow("Passenger Type", widget.passengerType),
              _receiptRow("Trip Type", widget.tripType),
              _receiptRow("Reference No.", displayRef),
              _receiptRow("Date & Time", timeLabel),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nagcarlanGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onPaymentConfirmed();
                  },
                  child: const Text("DONE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirmAndProceed() {
    if (_selectedMethod == PaymentMethod.ewallet) {
      _showEWalletInputDialog();
    } else {
      _runPaymentSteps();
    }
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
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: nagcarlanGreen)),
            const SizedBox(height: 8),
            Text("Amount to Pay: ₱${widget.fare.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            _buildPaymentOption(
                title: "Pay with Cash", value: PaymentMethod.cash, icon: Icons.money_outlined),
            _buildPaymentOption(
                title: "E-Wallet", value: PaymentMethod.ewallet, icon: Icons.account_balance_wallet_outlined),
            if (_selectedMethod == PaymentMethod.ewallet)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, top: 8.0, bottom: 8.0),
                child: Column(children: [
                  _buildEWalletChoice(wallet: EWallet.gcash),
                  _buildEWalletChoice(wallet: EWallet.maya),
                  _buildEWalletChoice(wallet: EWallet.konek2card),
                ]),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nagcarlanGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_selectedMethod == PaymentMethod.cash ||
                      (_selectedMethod == PaymentMethod.ewallet && _selectedEWallet != null))
                  ? _confirmAndProceed
                  : null,
              child: const Text("CONFIRM PAYMENT",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
      {required String title, required PaymentMethod value, required IconData icon}) {
    return RadioListTile<PaymentMethod>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      groupValue: _selectedMethod,
      onChanged: (v) => setState(() {
        _selectedMethod = v!;
        if (_selectedMethod == PaymentMethod.cash) _selectedEWallet = null;
      }),
      secondary: Icon(icon, color: nagcarlanGreen),
      activeColor: nagcarlanGreen,
    );
  }

  Widget _buildEWalletChoice({required EWallet wallet}) {
    final config = _eWalletConfig(wallet);
    return RadioListTile<EWallet>(
      title: Text(config['name'] as String),
      value: wallet,
      groupValue: _selectedEWallet,
      onChanged: (v) => setState(() => _selectedEWallet = v),
      secondary: CircleAvatar(
        backgroundColor: config['color'] as Color,
        radius: 16,
        child: Text(config['label'] as String,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      activeColor: nagcarlanGreen,
    );
  }
}