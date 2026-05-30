import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';
import '../utils/transitions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _data = [
    OnboardingData(
      title: "Find a Vet Near You",
      description: "Search and discover verified veterinary doctors in your district with real-time availability.",
      icon: Icons.map_outlined,
      color: Colors.blue,
      imagePath: "assets/images/dog.jpg",
    ),
    OnboardingData(
      title: "Book in Seconds",
      description: "Schedule consultations, home visits, or clinic appointments with instant confirmation.",
      icon: Icons.event_available_outlined,
      color: Colors.green,
      imagePath: "assets/images/cat.jpg",
    ),
    OnboardingData(
      title: "Track Pet Health",
      description: "Keep a digital record of vaccinations and get timely reminders for upcoming shots.",
      icon: Icons.vaccines_outlined,
      color: Colors.orange,
      imagePath: "assets/images/dogesh.jpg",
    ),
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, createSlideRoute(const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _data.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _buildPage(_data[index]);
            },
          ),
          // Bottom nav area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _data.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _data.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    child: Text(
                      _currentPage == _data.length - 1 ? "Get Started 🐾" : "Next →",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Skip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Stack(
      children: [
        // Full background image
        Positioned.fill(
          child: Image.asset(data.imagePath, fit: BoxFit.cover),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  data.color.withOpacity(0.55),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
        ),
        // Center content
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 48),
                // Glassmorphism content card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String imagePath;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.imagePath,
  });
}
