import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import 'register_screen.dart';
import 'farmer_screen.dart';
import 'service_provider_dashboard.dart';
import 'admin_panel.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/language_switcher.dart';
import 'otp_verification_screen.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  String role = "Pet Owner";  // F2: was "Farmer"
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(80)),
              ),
              child: Stack(
                children: [
                  // Language switcher top right
                  const Positioned(
                    top: 50,
                    right: 16,
                    child: LanguageSwitcher(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20)
                            ],
                          ),
                          child: const Icon(Icons.pets,
                              size: 60, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 20),
                        Text(l.animalCare,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(fontSize: 32)),
                        Text(l.tagline,
                            style: const TextStyle(
                                color: Colors.grey, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.signIn,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(l.accessAccount,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _roleTab("Pet Owner", "Pet Owner"),    // F2: was l.farmer / "Farmer"
                        _roleTab("Doctor / Vet", "Doctor"),    // F2: was l.serviceProvider / "Service Provider"
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: l.email,
                      prefixIcon:
                          const Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: l.password,
                      prefixIcon:
                          const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => isPasswordVisible = !isPasswordVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(l.continueBtn),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.newHere,
                          style: const TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: Text(l.createAccount,
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleTab(String label, String value) {
    bool isSelected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context)!;
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fillAllFields)));
      return;
    }
    setState(() => isLoading = true);
    final user = await ApiService.login(
        emailController.text, passwordController.text);
    setState(() => isLoading = false);
    if (user != null) {
      // F8: Admin routing
      if (user['role'] == "Admin") {
        Session.currentUser = user;
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminPanel()));
        }
        return;
      }

      // F2: Updated role check: "Pet Owner" instead of "Farmer"
      if (user['role'] == "Pet Owner" || user['role'] == "Farmer") {
        Session.currentUser = user;
        NotificationService.getTokenAndSave();
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const FarmerScreen()));
        }
      } else {
        // Doctor MFA
        setState(() => isLoading = true);

        final isMfaVerified = await Session.isMfaVerified(emailController.text);

        if (isMfaVerified) {
          if (mounted) setState(() => isLoading = false);
          Session.currentUser = user;
          NotificationService.getTokenAndSave();
          if (mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ServiceProviderDashboard()));
          }
          return;
        }

        final otpSent = await ApiService.sendOtp(emailController.text, "LOGIN");
        if (mounted) setState(() => isLoading = false);

        if (otpSent) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  email: emailController.text,
                  type: "LOGIN",
                  onVerified: () async {
                    await Session.setMfaVerified(emailController.text);
                    Session.currentUser = user;
                    NotificationService.getTokenAndSave();
                    if (mounted) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ServiceProviderDashboard()));
                    }
                  },
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("MFA Verification Failed. Please try again.")));
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.invalidCredentials)));
      }
    }
  }
}
