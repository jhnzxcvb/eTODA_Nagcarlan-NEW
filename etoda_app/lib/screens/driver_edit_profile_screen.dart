import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverEditProfileScreen extends StatefulWidget {
  const DriverEditProfileScreen({super.key});

  @override
  State<DriverEditProfileScreen> createState() => _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState extends State<DriverEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Revised controllers to match database fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  int? _driverId;

  @override
  void initState() {
    super.initState();
    // Rebuild when new password changes to update UI and validation
    _newPasswordController.addListener(_onPasswordFieldsChanged);
    // Rebuild when current password changes to enforce requirement on new password fields
    _currentPasswordController.addListener(_onPasswordFieldsChanged);
  }

  void _onPasswordFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_driverId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _driverId = args?['driver_id'];

      if (_driverId != null) {
        _fetchDriverData();
      } else {
        setState(() => _isLoading = false);
        _showError("Session expired. Please login again.");
      }
    }
  }

  Future<void> _fetchDriverData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/profile?role=driver&id=$_driverId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _middleNameController.text = data['middle_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _contactController.text = data['phone_number'] ?? '';
          _plateController.text = data['plate_number'] ?? '';
          _isLoading = false;
        });
      } else {
        _showError("Could not retrieve driver data.");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError("Connection error. Check your server.");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional check: New password must not be the same as the old one
    if (_newPasswordController.text.isNotEmpty && _newPasswordController.text == _currentPasswordController.text) {
      _showError("New password cannot be the same as the current password.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/driver/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': _driverId,
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone_number': _contactController.text.trim(),
          'plate_number': _plateController.text.trim(),
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Driver profile updated successfully!"),
                ],
              ),
              backgroundColor: nagcarlanGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else if (response.statusCode == 401) {
        _showError("Incorrect current password.");
      } else {
        _showError("Update failed. Server returned ${response.statusCode}");
      }
    } catch (e) {
      _showError("Connection error.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _plateController.dispose();
    _currentPasswordController.removeListener(_onPasswordFieldsChanged);
    _currentPasswordController.dispose();
    _newPasswordController.removeListener(_onPasswordFieldsChanged);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Driver Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: nagcarlanGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: nagcarlanGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: nagcarlanGreen))
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: _buildAvatar()),
                              const SizedBox(height: 32),
                              _buildSectionTitle("DRIVER INFORMATION"),
                              const SizedBox(height: 16),
                              _buildTextField(label: "First Name", controller: _firstNameController, icon: Icons.person_outline),
                              const SizedBox(height: 16),
                              _buildTextField(label: "Middle Name (Optional)", controller: _middleNameController, icon: Icons.person_outline, isOptional: true),
                              const SizedBox(height: 16),
                              _buildTextField(label: "Last Name", controller: _lastNameController, icon: Icons.person_outline),
                              const SizedBox(height: 16),
                              _buildTextField(label: "Contact Number", controller: _contactController, icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                              const SizedBox(height: 16),
                              _buildTextField(label: "Plate Number", controller: _plateController, icon: Icons.directions_car_outlined),
                              
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Divider(thickness: 1, color: Colors.black12),
                              ),

                              _buildSectionTitle("SECURITY"),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                label: _newPasswordController.text.isNotEmpty ? "Current Password (Required)" : "Current Password",
                                controller: _currentPasswordController,
                                obscureText: _obscureCurrent,
                                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                isRequired: _newPasswordController.text.isNotEmpty,
                                checkLength: false,
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                label: _currentPasswordController.text.isNotEmpty ? "New Password (Required)" : "New Password (Optional)",
                                controller: _newPasswordController,
                                obscureText: _obscureNew,
                                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                                isRequired: _currentPasswordController.text.isNotEmpty,
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                label: "Confirm New Password",
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                mustMatch: _newPasswordController.text,
                                isRequired: _currentPasswordController.text.isNotEmpty,
                              ),

                              const SizedBox(height: 40),
                              _buildSaveButton(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: BrandingFooter(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: nagcarlanGreen,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_outline_rounded, size: 70, color: Color(0xFFA5D6A7)),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: nagcarlanGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
        )
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, TextInputType keyboardType = TextInputType.text, bool isOptional = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        prefixIcon: Icon(icon, color: nagcarlanGreen, size: 22),
        filled: true,
        fillColor: Colors.white.withAlpha(230),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: nagcarlanGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      validator: (v) {
        if (!isOptional && (v == null || v.trim().isEmpty)) return "This field is required";
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    bool isRequired = false,
    String? mustMatch,
    bool checkLength = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: nagcarlanGreen, size: 22),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withAlpha(230),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: nagcarlanGreen, width: 1.5),
        ),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.isEmpty)) return "This field is required";
        if (checkLength && v != null && v.isNotEmpty && v.length < 6) return "Password must be at least 6 characters";
        if (mustMatch != null && v != mustMatch) return "Passwords do not match";
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: nagcarlanGreen.withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: _isSaving
          ? const Center(child: CircularProgressIndicator(color: nagcarlanGreen))
          : ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 22),
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: nagcarlanGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              label: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.8)),
            ),
    );
  }
}
