import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _benefitsController;
  late AnimationController _stepsController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _benefitsFade;
  late Animation<double> _stepsFade;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _benefitsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _stepsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _headerFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _benefitsFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _benefitsController, curve: Curves.easeOut));
    _stepsFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _stepsController, curve: Curves.easeOut));

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _benefitsController.forward());
    Future.delayed(const Duration(milliseconds: 700), () => _stepsController.forward());
  }

  @override
  void dispose() {
    _headerController.dispose();
    _benefitsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO SECTION ──
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: _buildHeroSection(context),
              ),
            ),

            const SizedBox(height: 40),

            // ── BENEFITS SECTION ──
            FadeTransition(
              opacity: _benefitsFade,
              child: _buildBenefitsSection(context),
            ),

            const SizedBox(height: 40),

            // ── HOW IT WORKS ──
            FadeTransition(
              opacity: _stepsFade,
              child: _buildHowItWorksSection(context),
            ),

            const SizedBox(height: 40),

            // ── ANIMAL SHOWCASE ──
            _buildAnimalShowcase(context),

            const SizedBox(height: 40),

            // ── CTA BUTTONS ──
            _buildCtaSection(context),

            const SizedBox(height: 40),

            // ── FOOTER ──
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return SizedBox(
      height: 520,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "assets/images/dog.jpg",
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xCC1B5E20),
                    Color(0xAA2E7D32),
                    Color(0x881565C0),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Bottom fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFFF0F7F0)],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "PawCare",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Your Pet Deserves\nthe Best Care",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Connect with verified veterinary doctors, track vaccinations, and manage your pet's health — all in one place.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.6,
                      shadows: const [Shadow(blurRadius: 6, color: Colors.black38)],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _heroBadge(Icons.verified_user_outlined, "Verified Vets"),
                      _heroBadge(Icons.schedule_outlined, "24/7 Booking"),
                      _heroBadge(Icons.vaccines_outlined, "Vaccination Tracker"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.medical_services_outlined,
        'title': 'Book Consultations',
        'desc': 'Instantly book vet appointments at home or in-clinic.',
        'color': AppTheme.doctorPrimary,
        'image': 'assets/images/cat.jpg',
      },
      {
        'icon': Icons.vaccines_outlined,
        'title': 'Vaccination Tracker',
        'desc': 'Track vaccination schedules. Get reminders before due dates.',
        'color': Colors.orange,
        'image': 'assets/images/dog.jpg',
      },
      {
        'icon': Icons.map_outlined,
        'title': 'Find Nearby Vets',
        'desc': 'Discover government & private vets near you on the map.',
        'color': Colors.teal,
        'image': 'assets/images/dogesh.jpg',
      },
      {
        'icon': Icons.star_outline,
        'title': 'Trusted Reviews',
        'desc': 'Read community ratings before choosing a veterinarian.',
        'color': Colors.amber,
        'image': 'assets/images/alec-favale-Ivzo69e18nk-unsplash.jpg',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Why PawCare?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 4),
          Text("Everything your pet needs, in one app.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: benefits.length,
            itemBuilder: (context, i) {
              final b = benefits[i];
              final color = b['color'] as Color;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(b['image'] as String, fit: BoxFit.cover),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withOpacity(0.5),
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Icon(b['icon'] as IconData, color: Colors.white, size: 22),
                            ),
                            const Spacer(),
                            Text(b['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(b['desc'] as String,
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    final steps = [
      {
        'num': '1',
        'title': 'Create Your Account',
        'desc': 'Sign up as a Pet Owner or register as a verified Doctor.',
        'color': AppTheme.primaryColor,
      },
      {
        'num': '2',
        'title': 'Find & Book a Vet',
        'desc': 'Browse nearby vets or book a home visit in minutes.',
        'color': AppTheme.doctorPrimary,
      },
      {
        'num': '3',
        'title': 'Track Pet Health',
        'desc': 'Manage vaccinations, records, and consultation history.',
        'color': Colors.teal,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How It Works",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 4),
          Text("Get started in 3 simple steps.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final step = entry.value;
            final color = step['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Text(step['num']! as String,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step['title']! as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(step['desc']! as String,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 14),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnimalShowcase(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Happy Patients 🐾",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text("Animals we've helped care for",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _showcaseCard("assets/images/dog.jpg", "Buddy", "Labrador"),
              _showcaseCard("assets/images/cat.jpg", "Whiskers", "Persian Cat"),
              _showcaseCard("assets/images/dogesh.jpg", "Max", "German Shepherd"),
              _showcaseCard("assets/images/zdenek-machacek-OlKkCmToXEs-unsplash.jpg", "Wild", "Exotic Bird"),
              _showcaseCard("assets/images/alec-favale-Ivzo69e18nk-unsplash.jpg", "Daisy", "Farm Animal"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _showcaseCard(String imagePath, String name, String breed) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(breed, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 20),
                  SizedBox(width: 8),
                  Text("Login to Your Account",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text("Create Free Account",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFF0F7F0), Colors.grey.shade100],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                "PawCare — Animal Service Platform",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Connecting Pet Owners with Trusted Veterinary Care",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
