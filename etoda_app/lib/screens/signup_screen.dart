import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _showNotificationDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: nagcarlanGreen)),
          ),
        ],
      ),
    );
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessDialog(_usernameController.text.trim());
      } else {
        final error = jsonDecode(response.body);
        _showNotificationDialog(
          title: "Signup Failed",
          message: error['message'] ?? "An error occurred during registration.",
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }
    } catch (e) {
      _showNotificationDialog(
        title: "Connection Error",
        message: "Could not connect to the server. Please check your connection.",
        icon: Icons.wifi_off,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Registration Success"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your passenger account has been created successfully."),
            const SizedBox(height: 10),
            Text(
              "Username: $username",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: nagcarlanGreen),
            ),
            const SizedBox(height: 10),
            const Text("Please use this Username to log in to the application."),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nagcarlanGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("BACK TO LOGIN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: nagcarlanGreen,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: nagcarlanGreen),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Join the eTODA community as a passenger",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _usernameController,
                    label: "Username *",
                    icon: Icons.badge_outlined,
                    hintText: "Enter your username",
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Username is required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _firstNameController,
                    label: "First Name *",
                    icon: Icons.person_outline,
                    validator: (value) => value!.trim().isEmpty ? "First name is required" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _middleNameController,
                    label: "Middle Name (Optional)",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    label: "Last Name *",
                    icon: Icons.person_outline,
                    validator: (value) => value!.trim().isEmpty ? "Last name is required" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone Number *",
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    hintText: "e.g. 09123456789",
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Phone number is required";
                      if (value.length < 11) return "Enter a valid 11-digit phone number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: "Email Address *",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Email is required";
                      if (!value.contains("@")) return "Enter a valid email address";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: "Password *",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Password is required";
                      if (value.length < 6) return "Password must be at least 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: "Confirm Password *",
                    icon: Icons.lock_reset_outlined,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Confirm password is required";
                      if (value != _passwordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator(color: nagcarlanGreen)
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nagcarlanGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          onPressed: _handleSignup,
                          child: const Text("SIGN UP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Drivers must register through the eTODA administration office.",
                            style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: nagcarlanGreen),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: nagcarlanGreen, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
