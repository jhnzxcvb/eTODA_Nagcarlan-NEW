import 'dart:io';
import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class PassengerEditProfileScreen extends StatefulWidget {
  const PassengerEditProfileScreen({super.key});

  @override
  State<PassengerEditProfileScreen> createState() => _PassengerEditProfileScreenState();
}

class _PassengerEditProfileScreenState extends State<PassengerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int? _userId;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onPasswordFieldsChanged);
    _currentPasswordController.addListener(_onPasswordFieldsChanged);
  }

  void _onPasswordFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userId = args?['user_id'];

      if (_userId != null) {
        _fetchPassengerData();
      } else {
        setState(() => _isLoading = false);
        _showError("Session error: ID not found.");
      }
    }
  }

  Future<void> _fetchPassengerData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/profile?role=passenger&id=$_userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _middleNameController.text = data['middle_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _contactController.text = data['phone_number'] ?? '';
          _emailController.text = data['email'] ?? '';
          _avatarUrl = data['profile_pic'];
          _isLoading = false;
        });
      } else {
        _showError("Failed to load profile.");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError("Connection error.");
      setState(() => _isLoading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Image Source",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: nagcarlanGreen),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nagcarlanGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: nagcarlanGreen, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError("Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}.");
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text.isNotEmpty &&
        _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _currentPasswordController.text) {
      _showError("New password cannot be the same as the current password.");
      return;
    }

    setState(() => _isSaving = true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/passenger/update-profile'),
      );

      request.fields['user_id'] = _userId.toString();
      request.fields['first_name'] = _firstNameController.text.trim();
      request.fields['middle_name'] = _middleNameController.text.trim();
      request.fields['last_name'] = _lastNameController.text.trim();
      request.fields['phone_number'] = _contactController.text.trim();
      request.fields['email'] = _emailController.text.trim();

      if (_currentPasswordController.text.isNotEmpty) {
        request.fields['current_password'] = _currentPasswordController.text;
        request.fields['new_password'] = _newPasswordController.text;
      }

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          _imageFile!.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint("Server Response: ${response.body}");
        final errorData = jsonDecode(response.body);
        _showError(errorData['error'] ?? "Update failed.");
      }
    } catch (e) {
      _showError("Connection error. Please try again.");
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
    _emailController.dispose();
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
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: nagcarlanWhite,
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
                        _buildSectionTitle("PERSONAL INFORMATION"),
                        const SizedBox(height: 16),
                        _buildTextField(label: "First Name", controller: _firstNameController, icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField(label: "Middle Name (Optional)", controller: _middleNameController, icon: Icons.person_outline, isOptional: true),
                        const SizedBox(height: 16),
                        _buildTextField(label: "Last Name", controller: _lastNameController, icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField(label: "Contact Number", controller: _contactController, icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildTextField(label: "Email Address (Optional)", controller: _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, isOptional: true),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Divider(thickness: 1, color: Colors.black12),
                        ),

                        _buildSectionTitle("SECURITY"),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          label: "Current Password",
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          isRequired: false,
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
    ImageProvider avatarImage;
    if (_imageFile != null) {
      avatarImage = FileImage(_imageFile!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage('${ApiService.baseUrl}/uploads/$_avatarUrl');
    } else {
      avatarImage = const AssetImage('assets/images/default_avatar.png');
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: avatarImage,
              child: (_imageFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                  ? const Icon(Icons.person_outline_rounded, size: 70, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: nagcarlanGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          ),
        )
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, TextInputType keyboardType = TextInputType.text, bool isOptional = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        prefixIcon: Icon(icon, color: nagcarlanGreen, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: nagcarlanGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      validator: (v) {
        if (!isOptional && (v == null || v.trim().isEmpty)) return "This field is required";
        if (keyboardType == TextInputType.emailAddress && v != null && v.isNotEmpty && !v.contains('@')) return "Enter a valid email address";
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
      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: nagcarlanGreen, size: 22),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: nagcarlanGreen, width: 2),
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
            color: Colors.black.withOpacity(0.05),
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
