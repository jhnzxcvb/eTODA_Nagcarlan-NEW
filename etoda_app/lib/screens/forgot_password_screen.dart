import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _contactNumber;
  String? _role;
  int? _userId;

  String _maskPhoneNumber(String? phone) {
    if (phone == null || phone.length < 3) return "*******";
    String lastThree = phone.substring(phone.length - 3);
    return "*" * (phone.length - 3) + lastThree;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : nagcarlanGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _findUser() async {
    if (_usernameController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/forgot-password/find-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _usernameController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _contactNumber = data['phone_number'];
          _role = data['role'];
          _userId = data['id'];
        });
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      } else {
        _showSnackBar("Username not found.");
      }
    } catch (e) {
      _showSnackBar("Connection error.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (_otpController.text == "123456") {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _showSnackBar("Invalid OTP. Try 123456.");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty) {
      _showSnackBar("Please enter a new password.");
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showSnackBar("Password must be at least 6 characters long.");
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/forgot-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': _userId,
          'role': _role,
          'new_password': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Password reset successful!", isError: false);
        Navigator.pop(context);
      } else {
        _showSnackBar("Failed to reset password.");
      }
    } catch (e) {
      _showSnackBar("Connection error.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Account Recovery", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: nagcarlanWhite,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepContainer(_buildUsernameStep()),
                    _buildStepContainer(_buildOTPStep()),
                    _buildStepContainer(_buildResetStep()),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: BrandingFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: child,
    );
  }

  Widget _buildUsernameStep() {
    return Column(
      children: [
        const Icon(Icons.person_search_rounded, size: 100, color: nagcarlanYellow),
        const SizedBox(height: 32),
        const Text(
          "Find Your Account",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: nagcarlanYellow),
        ),
        const SizedBox(height: 12),
        const Text(
          "Enter your username and we'll help you recover your account access.",
          textAlign: TextAlign.center,
          style: TextStyle(color: nagcarlanWhite, height: 1.5),
        ),
        const SizedBox(height: 40),
        _buildInputField(
          controller: _usernameController,
          label: "Username",
          icon: Icons.person_outline,
          hint: "e.g. juan_dela_cruz",
        ),
        const SizedBox(height: 40),
        _buildActionButton("NEXT", _findUser),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_rounded, size: 100, color: nagcarlanYellow),
        const SizedBox(height: 32),
        const Text(
          "Verify Identity",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: nagcarlanYellow),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: nagcarlanWhite, height: 1.5, fontSize: 16),
            children: [
              const TextSpan(text: "We sent a 6-digit OTP to your registered phone number ending in "),
              TextSpan(
                text: _maskPhoneNumber(_contactNumber),
                style: const TextStyle(fontWeight: FontWeight.bold, color: nagcarlanYellow),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildInputField(
          controller: _otpController,
          label: "OTP Code",
          icon: Icons.lock_clock_outlined,
          hint: "Enter 6-digit code",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 40),
        _buildActionButton("VERIFY CODE", _verifyOTP),
        TextButton(
          onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
          child: const Text("Not your account? Go back", style: TextStyle(color: Colors.white70)),
        )
      ],
    );
  }

  Widget _buildResetStep() {
    return Column(
      children: [
        const Icon(Icons.published_with_changes_rounded, size: 100, color: nagcarlanYellow),
        const SizedBox(height: 32),
        const Text(
          "Create New Password",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: nagcarlanYellow),
        ),
        const SizedBox(height: 12),
        const Text(
          "Almost done! Please choose a strong password for your account.",
          textAlign: TextAlign.center,
          style: TextStyle(color: nagcarlanWhite, height: 1.5),
        ),
        const SizedBox(height: 40),
        _buildInputField(
          controller: _newPasswordController,
          label: "New Password",
          icon: Icons.lock_outline,
          obscureText: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _confirmPasswordController,
          label: "Confirm New Password",
          icon: Icons.check_circle_outline,
          obscureText: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 40),
        _buildActionButton("RESET PASSWORD", _resetPassword),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: nagcarlanWhite, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: nagcarlanGreen, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: nagcarlanGreen, size: 22),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                    onPressed: onToggle,
                  )
                : null,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: nagcarlanWhite.withOpacity(0.9),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: nagcarlanYellow, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: nagcarlanYellow))
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nagcarlanYellow,
                foregroundColor: nagcarlanGreen,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: onPressed,
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
    );
  }
}
