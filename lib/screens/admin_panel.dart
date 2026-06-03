import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'doctor_document_dialog.dart';
import 'admin_bookings_tab.dart';
import 'admin_payments_tab.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  Map<String, dynamic> stats = {};
  List<dynamic> pendingDoctors = [];
  List<dynamic> allDoctors = [];
  List<dynamic> allOwners = [];
  List<dynamic> bookings = [];
  List<dynamic> payments = [];
  List<dynamic> vaccinations = [];
  List<dynamic> animals = [];
  List<dynamic> reviews = [];
  bool _loading = true;

  final List<String> _pageTitles = [
    "Dashboard",
    "Doctors",
    "Pet Owners",
    "Bookings",
    "Payments",
    "Vaccinations",
  ];

  final List<IconData> _pageIcons = [
    Icons.dashboard_outlined,
    Icons.medical_services_outlined,
    Icons.people_outline,
    Icons.calendar_month_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.vaccines_outlined,
  ];

  String _doctorFilter = 'PENDING';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getAdminStats(),
        ApiService.getPendingDoctors(),
        ApiService.getAllDoctors(),
        ApiService.getAllPetOwners(),
        ApiService.getAdminBookings(),
        ApiService.getAdminPayments(),
        ApiService.getAdminVaccinations(),
        ApiService.getAdminAnimals(),
        ApiService.getAdminReviews(),
      ]);
      if (mounted) {
        setState(() {
          stats = (results[0] as Map<String, dynamic>?) ?? {};
          pendingDoctors = results[1] as List<dynamic>;
          allDoctors = results[2] as List<dynamic>;
          allOwners = results[3] as List<dynamic>;
          bookings = results[4] as List<dynamic>;
          payments = results[5] as List<dynamic>;
          vaccinations = results[6] as List<dynamic>;
          animals = results[7] as List<dynamic>;
          reviews = results[8] as List<dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading admin data: $e");
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading admin data: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    Session.currentUser = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              title: Text(_pageTitles[_selectedIndex]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAll,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                ),
              ],
            ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (isDesktop) _buildSidebar(),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppTheme.primaryColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "PawCare Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "Control Panel",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: List.generate(_pageTitles.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.white.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Icon(
                        _pageIcons[index],
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                      title: Text(
                        _pageTitles[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PawCare",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      "Admin Portal",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: List.generate(_pageTitles.length, (index) {
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.white.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      _pageIcons[index],
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    title: Text(
                      _pageTitles[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              }),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Super Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "admin@pawcare.com",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardSection();
      case 1:
        return _buildDoctorsSection();
      case 2:
        return _buildOwnersSection();
      case 3:
        return AdminBookingsTab(
          bookings: bookings,
          onRefresh: _loadAll,
        );
      case 4:
        return AdminPaymentsTab(
          payments: payments,
          onRefresh: _loadAll,
        );
      case 5:
        return _buildVaccinationsSection();
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  Widget _buildDashboardSection() {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    final totalDoctors = stats['totalDoctors'] ?? allDoctors.length;
    final pendingDocsCount = stats['pendingDoctors'] ?? pendingDoctors.length;
    final totalOwners = stats['totalPetOwners'] ?? allOwners.length;
    final totalBookings = stats['totalBookings'] ?? bookings.length;
    final totalAnimals = stats['totalAnimals'] ?? animals.length;
    final totalVaccinations = stats['totalVaccinations'] ?? vaccinations.length;
    final totalPayments = stats['totalPayments'] ?? payments.length;
    final double rawRevenue = (stats['totalRevenue'] ?? 0.0).toDouble();
    final totalRevenue = "₹${rawRevenue.toStringAsFixed(0)}";

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Super Admin Dashboard",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: isDesktop ? 28 : 22,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Monitor and manage pawcare platform data",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                if (isDesktop)
                  ElevatedButton.icon(
                    onPressed: _loadAll,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Refresh Data"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(140, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isDesktop ? 1.7 : 1.4,
              children: [
                _buildStatCard("Total Doctors", "$totalDoctors", Icons.medical_services_outlined, AppTheme.doctorPrimary),
                _buildStatCard("Pending Doctors", "$pendingDocsCount", Icons.pending_actions_outlined, Colors.orange),
                _buildStatCard("Pet Owners", "$totalOwners", Icons.people_outline, AppTheme.farmerPrimary),
                _buildStatCard("Total Bookings", "$totalBookings", Icons.calendar_month_outlined, Colors.blue),
                _buildStatCard("Total Animals", "$totalAnimals", Icons.pets_outlined, Colors.purple),
                _buildStatCard("Vaccinations", "$totalVaccinations", Icons.vaccines_outlined, Colors.indigo),
                _buildStatCard("Total Payments", "$totalPayments", Icons.payment_outlined, Colors.amber),
                _buildStatCard("Total Revenue", totalRevenue, Icons.monetization_on_outlined, Colors.teal),
              ],
            ),
            const SizedBox(height: 24),
            
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildCredentialsCard(),
                        const SizedBox(height: 20),
                        _buildRecentReviewsSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildAnimalsSummarySection(),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildCredentialsCard(),
                  const SizedBox(height: 16),
                  _buildRecentReviewsSection(),
                  const SizedBox(height: 16),
                  _buildAnimalsSummarySection(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.08), AppTheme.doctorPrimary.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.key_rounded, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Admin Credentials",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("admin@pawcare.com",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("admin123",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text("Active",
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.rate_review_outlined, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Recent Reviews",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Text(
                "Total: ${reviews.length}",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 24),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No reviews submitted yet.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length > 5 ? 5 : reviews.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final r = reviews[index];
                final rating = r['rating'] ?? 5;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r['reviewerName'] ?? 'Anonymous Owner',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => Icon(
                              Icons.star,
                              size: 14,
                              color: starIndex < rating ? Colors.amber : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r['comment'] ?? 'No comment provided',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${r['ownerEmail'] ?? ''} → ${r['providerEmail'] ?? ''}",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnimalsSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pets_outlined, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Registered Pets",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Text(
                "Total: ${animals.length}",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 24),
          if (animals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No animals registered yet.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: animals.length > 5 ? 5 : animals.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final a = animals[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.purple.shade50,
                      child: Text(
                        (a['name'] ?? 'P').toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['name'] ?? 'Unknown Pet',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "${a['species'] ?? ''} • ${a['breed'] ?? 'Unknown Breed'}",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: a['healthStatus'] == 'HEALTHY' || a['healthStatus'] == 'Healthy'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (a['healthStatus'] ?? 'Unknown').toString().toUpperCase(),
                        style: TextStyle(
                          color: a['healthStatus'] == 'HEALTHY' || a['healthStatus'] == 'Healthy'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection() {
    List<dynamic> filteredDocs;
    if (_doctorFilter == 'ALL') {
      filteredDocs = allDoctors;
    } else {
      filteredDocs = allDoctors.where((d) => (d['verificationStatus'] ?? 'PENDING') == _doctorFilter).toList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Doctor Accounts",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 4),
                  Text("Verify licenses and manage veterinary accounts", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Text(
                "Found: ${filteredDocs.length}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: ['PENDING', 'APPROVED', 'REJECTED', 'ALL'].map((f) {
              final count = f == 'PENDING'
                  ? pendingDoctors.length
                  : f == 'APPROVED'
                      ? allDoctors.where((d) => d['verificationStatus'] == 'APPROVED').length
                      : f == 'REJECTED'
                          ? allDoctors.where((d) => d['verificationStatus'] == 'REJECTED').length
                          : allDoctors.length;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text("$f ($count)", style: TextStyle(color: _doctorFilter == f ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                  selected: _doctorFilter == f,
                  onSelected: (_) => setState(() => _doctorFilter = f),
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filteredDocs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("No doctors found for '$_doctorFilter'", style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, i) {
                      final d = filteredDocs[i];
                      final status = d['verificationStatus'] ?? 'PENDING';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.doctorPrimary.withOpacity(0.1),
                                    child: const Icon(Icons.medical_services, color: AppTheme.doctorPrimary, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(d['name'] ?? 'Unknown Doctor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text(d['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  _statusChip(status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.grey.shade100, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("License No:", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                        Text(d['licenseNumber'] ?? 'Not provided', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.rate_review, size: 14),
                                    label: Text(status == 'PENDING' ? "Verify & Action" : "View Document"),
                                    onPressed: () => _viewDoctorDocument(d),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: status == 'PENDING' ? Colors.orange.shade700 : AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(140, 36),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _viewDoctorDocument(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DoctorDocumentDialog(
        doctor: doctor,
        onAction: _loadAll,
      ),
    );
  }

  Widget _buildOwnersSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pet Owners",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text("Registered platform users who own animals", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Text(
                "Total: ${allOwners.length}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: allOwners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("No pet owners registered.", style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: allOwners.length,
                    itemBuilder: (context, i) {
                      final o = allOwners[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.farmerPrimary.withOpacity(0.1),
                            radius: 22,
                            child: const Icon(Icons.person, color: AppTheme.farmerPrimary),
                          ),
                          title: Text(o['name'] ?? 'Unknown Owner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(o['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(o['phone'] ?? 'No phone number', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVaccinationsSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vaccination Records",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 4),
                  Text("All recorded animal vaccinations", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Text(
                "Total: ${vaccinations.length}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: vaccinations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vaccines_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("No vaccination records found.", style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: vaccinations.length,
                    itemBuilder: (context, i) {
                      final v = vaccinations[i];
                      final status = (v['status'] ?? 'UPCOMING').toString().toUpperCase();
                      Color statusColor;
                      switch (status) {
                        case 'COMPLETED':
                          statusColor = Colors.green;
                          break;
                        case 'OVERDUE':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.blue;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.vaccines_outlined, color: statusColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(v['vaccineName'] ?? 'Unknown Vaccine', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          Text("For: ${v['animalName'] ?? 'Unknown Animal'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    _vaccineDetailRow(Icons.person_outline, "Owner", v['ownerEmail'] ?? 'N/A'),
                                    const SizedBox(height: 6),
                                    _vaccineDetailRow(Icons.medical_services_outlined, "Provider", v['providerEmail'] ?? 'N/A'),
                                    const SizedBox(height: 6),
                                    _vaccineDetailRow(Icons.calendar_today_outlined, "Given Date", v['dateGiven'] ?? 'N/A'),
                                    if (v['nextDueDate'] != null) ...[
                                      const SizedBox(height: 6),
                                      _vaccineDetailRow(Icons.event_outlined, "Next Due", v['nextDueDate']),
                                    ],
                                    if (v['notes'] != null && (v['notes'] as String).isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _vaccineDetailRow(Icons.notes, "Notes", v['notes']),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _vaccineDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 75,
          child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Chip(
      label: Text(status,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
