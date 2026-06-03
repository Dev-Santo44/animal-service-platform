import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:animal1/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'otp_verification_screen.dart';
import '../services/session.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final licenseController = TextEditingController(); 
  String role = "Pet Owner"; 
  bool isLoading = false;
  String? selectedFilePath;
  String? selectedFileName;
  Uint8List? selectedFileBytes;

  Future<void> _pickLicense() async {
    try {
      debugPrint("Initiating file picker...");
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        debugPrint("File picked: name=${file.name}, bytesLength=${file.bytes?.length}");
        setState(() {
          selectedFilePath = kIsWeb ? null : file.path;
          selectedFileName = file.name;
          selectedFileBytes = file.bytes;
        });
      } else {
        debugPrint("File picker returned null (user cancelled or browser blocked it).");
      }
    } catch (e, stackTrace) {
      debugPrint("Exception in _pickLicense: $e");
      debugPrint(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking file: $e")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bool isDoctor = role == "Doctor";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle top animal image background
          Positioned(
            top: 0, left: 0, right: 0,
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/dogesh.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.75),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(l.createAccount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                          )),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.joinUs,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l.joinUsSubtitle,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: l.fullName,
                  prefixIcon:
                      const Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) => v!.isEmpty ? l.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: l.email,
                  prefixIcon:
                      const Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) =>
                    v!.contains("@") ? null : l.invalidEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: l.phoneNumber,
                  prefixIcon:
                      const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: l.password,
                  prefixIcon:
                      const Icon(Icons.lock_outline, size: 20),
                ),
                validator: (v) =>
                    v!.length >= 6 ? null : l.minCharacters,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                      Icons.assignment_ind_outlined,
                      size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                      value: "Pet Owner",
                      child: Text("Pet Owner")),
                  DropdownMenuItem(
                      value: "Doctor",
                      child: Text("Doctor / Vet")),
                ],
                onChanged: (v) => setState(() => role = v!),
              ),
              if (isDoctor) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: licenseController,
                  decoration: const InputDecoration(
                    hintText: "Veterinary License Number",
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (v) => isDoctor && (v == null || v.isEmpty)
                      ? "License number required for doctors"
                      : null,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "⏳ Your account will be pending admin verification. You can log in but cannot accept bookings until approved.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickLicense,
                  icon: Icon(selectedFileName == null ? Icons.upload_file : Icons.check_circle, 
                        color: selectedFileName == null ? null : Colors.green),
                  label: Text(selectedFileName ?? "Upload License Copy (PDF/JPG)"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: selectedFileName == null ? Colors.grey.shade300 : Colors.green),
                  ),
                ),
                if (isDoctor && selectedFileName == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text("Please upload a license copy", style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l.signUp),
              ),
            ],
          ),
        ),
      ),  // SingleChildScrollView
    ),  // Expanded
  ],
),  // Column
          ),  // SafeArea
        ],  // Stack children
      ),  // Stack
    );
  }

  Future<void> _handleRegister() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (role == "Doctor" && selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your license copy")),
      );
      return;
    }

    setState(() => isLoading = true);

    // STEP 1: Send OTP
    final otpSent = await ApiService.sendOtp(emailController.text, "REGISTRATION");

    if (!mounted) return;
    setState(() => isLoading = false);

    if (otpSent) {
      // STEP 2: Navigate to OTP Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: emailController.text,
            type: "REGISTRATION",
            onVerified: () async {
              setState(() => isLoading = true);
              // STEP 3: Finalize Registration
              final result = await ApiService.register(
                nameController.text,
                emailController.text,
                passwordController.text,
                phoneController.text,
                role,
                licenseNumber: role == "Doctor" ? licenseController.text : null,
              );
              
              if (result != null && role == "Doctor" && selectedFileName != null) {
                // STEP 4: Upload License
                await ApiService.uploadLicense(
                  emailController.text,
                  filePath: selectedFilePath,
                  bytes: selectedFileBytes,
                  fileName: selectedFileName,
                );
              }

              if (mounted) {
                setState(() => isLoading = false);
                if (result != null) {
                  await Session.setMfaVerified(emailController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      role == "Doctor"
                          ? "Account created! Pending admin verification."
                          : l.accountCreated
                    )),
                  );
                  Navigator.pop(context); // Go back from OTP
                  Navigator.pop(context); // Go back from Register
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.registrationFailed)),
                  );
                }
              }
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send verification code. Please try again.")),
      );
    }
  }
}

