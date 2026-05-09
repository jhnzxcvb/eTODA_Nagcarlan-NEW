import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart'; 
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});


  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

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
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: nagcarlanGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    setState(() => _isLoading = true);

    if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) {
      final remaining = _lockoutEndTime!.difference(DateTime.now());
      _showNotificationDialog(
        title: "Account Locked",
        message: "Too many incorrect attempts. Please try again in ${remaining.inMinutes + 1} minutes.",
        icon: Icons.timer_outlined,
        color: Colors.redAccent,
      );
      setState(() => _isLoading = false);
      return;
    }

    // Ensure a clean state before attempting a new login
    ApiService.resetSession();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _failedAttempts = 0;
        _lockoutEndTime = null;

        String role = data['role'] ?? 'passenger';
        if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver_home', arguments: data);
        } else if (role == 'admin') {
          _showNotificationDialog(
            title: "Admin Login",
            message: "Please use the web-based admin portal to sign in.",
            icon: Icons.admin_panel_settings,
            color: nagcarlanGreen,
          );
        } else {
          Navigator.pushReplacementNamed(context, '/passenger_home', arguments: data);
        }
      } else if (response.statusCode == 401) {
        _failedAttempts++;
        String message = "The username or password you entered is incorrect.";
        
        if (_failedAttempts >= 5) {
          _lockoutEndTime = DateTime.now().add(const Duration(minutes: 15));
          message = "You have reached the limit of 5 incorrect attempts. Your account is locked for 15 minutes.";
        } else {
          int attemptsLeft = 5 - _failedAttempts;
          message += "\n\nAttempts left: $attemptsLeft";
        }

        _showNotificationDialog(
          title: _failedAttempts >= 5 ? "Account Locked" : "Login Failed",
          message: message,
          icon: _failedAttempts >= 5 ? Icons.lock_clock_outlined : Icons.lock_outline,
          color: Colors.redAccent,
        );
      } else {
        if (!mounted) return;
        _showNotificationDialog(
          title: "Error",
          message: "Something went wrong. Please try again later.",
          icon: Icons.error_outline,
          color: Colors.orange,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showNotificationDialog(
        title: "Connection Error",
        message: "Unable to connect to the eTODA server.",
        icon: Icons.cloud_off_outlined,
        color: Colors.blueGrey,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGuestLogin() {
    Navigator.pushReplacementNamed(
      context, 
      '/passenger_home', 
      arguments: {
        'role': 'passenger',
        'first_name': 'Guest',
        'is_guest': true,
      }
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: nagcarlanWhite),
          onPressed: () => Navigator.pop(context),
        ),
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
                  const SizedBox(height: 20),
                  // Logo / Icon Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: nagcarlanWhite.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.account_circle, size: 80, color: nagcarlanGreen),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "eTODA Nagcarlan",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: nagcarlanYellow),
                  ),
                  const Text(
                    "Login to your account",
                    style: TextStyle(color: nagcarlanWhite, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: _inputDecoration(Icons.person_outline, hint: "Username"),
                    validator: (v) => v!.isEmpty ? "Please enter your username" : null,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(Icons.lock_outline, hint: "Password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: nagcarlanGreen),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Please enter your password" : null,
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: nagcarlanWhite, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Login Button
                  _isLoading
                      ? const CircularProgressIndicator(color: nagcarlanYellow)
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nagcarlanYellow,
                      foregroundColor: nagcarlanGreen,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    onPressed: _handleLogin,
                    child: const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 20),

                  // --- OR DIVIDER ---
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1, color: Colors.white30)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR", style: TextStyle(color: nagcarlanWhite, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(child: Divider(thickness: 1, color: Colors.white30)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Guest Login Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: nagcarlanWhite, width: 1.5),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _handleGuestLogin,
                    icon: const Icon(Icons.person_outline, color: nagcarlanWhite),
                    label: const Text(
                      "CONTINUE AS GUEST", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: nagcarlanWhite)
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Signup Link for Passengers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have a passenger account?", style: TextStyle(color: nagcarlanWhite)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(color: nagcarlanYellow, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Drivers: Please contact the eTODA Admin office if you cannot access your account.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white60, fontStyle: FontStyle.italic),
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

  InputDecoration _inputDecoration(IconData icon, {String? hint}) {
    return InputDecoration(
      filled: true,
      fillColor: nagcarlanWhite.withValues(alpha: 0.9),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: nagcarlanGreen),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), // Line 176
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: nagcarlanYellow, width: 2),
      ),
    );
  }
}
