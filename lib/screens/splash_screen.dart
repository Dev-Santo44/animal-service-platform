import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/session.dart';
import '../services/api_service.dart';
import '../utils/transitions.dart';
import 'home_page.dart';
import 'farmer_screen.dart';
import 'service_provider_dashboard.dart';
import 'admin_panel.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    // F4: Animation duration + logic delay
    await Future.delayed(const Duration(seconds: 3));
    
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_role');
    final onboardingShown = prefs.getBool('onboarding_shown') ?? false;

    if (!mounted) return;

    if (email == null || role == null) {
      Navigator.pushReplacement(context, createSlideRoute(const HomePage()));
      return;
    }

    try {
      final user = await ApiService.getProviderProfile(email);
      if (user != null && mounted) {
        await Session.saveUser(user);
        Widget destination;
        if (role == 'Admin') {
          destination = const AdminPanel();
        } else if (role == 'Doctor' || role == 'Service Provider') {
          destination = const ServiceProviderDashboard();
        } else {
          destination = const FarmerScreen();
        }
        Navigator.pushReplacement(context, createSlideRoute(destination));
        return;
      }
    } catch (e) {
      debugPrint("Session check error: $e");
    }

    // Fallback to HomePage
    if (mounted) {
      Navigator.pushReplacement(context, createSlideRoute(const HomePage()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/splash.png", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.pets,
                        size: 80, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    l.splashIntegrated,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                  ),
                  Text(
                    l.splashAnimalService,
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(color: Colors.white, fontSize: 40),
                  ),
                  Text(
                    l.splashPlatform,
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(color: Colors.white, fontSize: 40),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      l.splashSmartWelfare,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
