
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';

enum PaymentMethod { cash, ewallet }
enum EWallet { gcash, maya, konek2card }

class PaymentMethodDialog extends StatefulWidget {
  final VoidCallback onPaymentConfirmed;

  const PaymentMethodDialog({super.key, required this.onPaymentConfirmed});

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  EWallet? _selectedEWallet;

  void _confirmAndProceed() {
    // Show a loading dialog for 3 seconds
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(nagcarlanGreen)),
                SizedBox(width: 24),
                Text("Confirming Payment...", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );

    // After 3 seconds, close all dialogs and proceed
    Timer(const Duration(seconds: 3), () {
      // Dismiss loading dialog
      Navigator.of(context).pop(); 
      // Dismiss self (PaymentMethodDialog)
      Navigator.of(context).pop(); 
      // Trigger the callback
      widget.onPaymentConfirmed();
    });
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
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: nagcarlanGreen),
            ),
            const SizedBox(height: 20),

            _buildPaymentOption(
              title: "Pay with Cash",
              value: PaymentMethod.cash,
              icon: Icons.money_outlined,
            ),
            
            _buildPaymentOption(
              title: "E-Wallet",
              value: PaymentMethod.ewallet,
              icon: Icons.account_balance_wallet_outlined,
            ),

            if (_selectedMethod == PaymentMethod.ewallet)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, top: 8.0, bottom: 8.0),
                child: Column(
                  children: [
                    _buildEWalletChoice(name: "GCash", value: EWallet.gcash),
                    _buildEWalletChoice(name: "Maya", value: EWallet.maya),
                    _buildEWalletChoice(name: "Konek2CARD", value: EWallet.konek2card),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nagcarlanGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_selectedMethod == PaymentMethod.cash || (_selectedMethod == PaymentMethod.ewallet && _selectedEWallet != null))
                  ? _confirmAndProceed
                  : null,
              child: const Text("CONFIRM PAYMENT", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({required String title, required PaymentMethod value, required IconData icon}) {
    return RadioListTile<PaymentMethod>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      groupValue: _selectedMethod,
      onChanged: (PaymentMethod? newValue) {
        setState(() {
          _selectedMethod = newValue!;
          if (_selectedMethod == PaymentMethod.cash) {
            _selectedEWallet = null;
          }
        });
      },
      secondary: Icon(icon, color: nagcarlanGreen),
      activeColor: nagcarlanGreen,
    );
  }

  Widget _buildEWalletChoice({required String name, required EWallet value}) {
    final placeholderLogo = CircleAvatar(backgroundColor: Colors.grey[200], child: Text(name[0], style: const TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold)));

    return RadioListTile<EWallet>(
      title: Text(name),
      value: value,
      groupValue: _selectedEWallet,
      onChanged: (EWallet? newValue) {
        setState(() {
          _selectedEWallet = newValue;
        });
      },
      secondary: SizedBox(width: 32, height: 32, child: placeholderLogo),
      activeColor: nagcarlanGreen,
    );
  }
}
