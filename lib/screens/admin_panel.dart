import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> stats = {};
  List<dynamic> pendingDoctors = [];
  List<dynamic> allDoctors = [];
  List<dynamic> allOwners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getAdminStats(),
      ApiService.getPendingDoctors(),
      ApiService.getAllDoctors(),
      ApiService.getAllPetOwners(),
    ]);
    if (mounted) {
      setState(() {
        stats = (results[0] as Map<String, dynamic>?) ?? {};
        pendingDoctors = results[1] as List<dynamic>;
        allDoctors = results[2] as List<dynamic>;
        allOwners = results[3] as List<dynamic>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  title: const Text(
                    "Admin Panel",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_outlined, color: Colors.white),
                      onPressed: () async {
                        Session.currentUser = null;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          "assets/images/alec-favale-Ivzo69e18nk-unsplash.jpg",
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.4),
                                AppTheme.primaryColor.withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                        // Glassmorphism admin badge
                        Positioned(
                          bottom: 60,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text("Super Admin", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: AppTheme.secondaryColor,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        text: "Pending (${stats['pendingDoctors'] ?? pendingDoctors.length})",
                        icon: const Icon(Icons.pending_outlined, size: 16),
                      ),
                      const Tab(
                        text: "All Doctors",
                        icon: Icon(Icons.medical_services_outlined, size: 16),
                      ),
                      const Tab(
                        text: "Pet Owners",
                        icon: Icon(Icons.pets_outlined, size: 16),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatsRow(),
                      _buildCredentialsCard(),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTab(),
                  _buildAllDoctorsTab(),
                  _buildOwnersTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildCredentialsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

  Widget _buildStatsRow() {
    final items = [
      {
        'label': 'Doctors',
        'value': '${stats['totalDoctors'] ?? 0}',
        'icon': Icons.medical_services,
        'color': AppTheme.doctorPrimary,
      },
      {
        'label': 'Pending',
        'value': '${stats['pendingDoctors'] ?? 0}',
        'icon': Icons.hourglass_empty,
        'color': Colors.orange,
      },
      {
        'label': 'Owners',
        'value': '${stats['totalPetOwners'] ?? 0}',
        'icon': Icons.pets,
        'color': AppTheme.farmerPrimary,
      },
      {
        'label': 'Bookings',
        'value': '${stats['totalBookings'] ?? 0}',
        'icon': Icons.calendar_today,
        'color': Colors.blue,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: items.map((item) {
          final color = item['color'] as Color;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'] as IconData, color: color, size: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(item['value']!.toString(),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  Text(item['label']!.toString(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (pendingDoctors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
            SizedBox(height: 16),
            Text("No pending verifications!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingDoctors.length,
        itemBuilder: (context, i) => _DoctorVerificationCard(
          doctor: pendingDoctors[i],
          onAction: _loadAll,
        ),
      ),
    );
  }

  Widget _buildAllDoctorsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allDoctors.length,
        itemBuilder: (context, i) {
          final d = allDoctors[i];
          final status = d['verificationStatus'] ?? 'PENDING';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: AppTheme.doctorPrimary.withOpacity(0.1),
                child: const Icon(Icons.medical_services, color: AppTheme.doctorPrimary),
              ),
              title: Text(d['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(d['email'] ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              trailing: _statusChip(status),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOwnersTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allOwners.length,
        itemBuilder: (context, i) {
          final o = allOwners[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: AppTheme.farmerPrimary.withOpacity(0.1),
                child: const Icon(Icons.pets, color: AppTheme.farmerPrimary),
              ),
              title: Text(o['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(o['email'] ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              trailing: Text(o['phone'] ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          );
        },
      ),
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

// Doctor Verification Card
class _DoctorVerificationCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onAction;

  const _DoctorVerificationCard({required this.doctor, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.doctorPrimary.withOpacity(0.1),
                  child: const Icon(Icons.medical_services, color: AppTheme.doctorPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(doctor['email'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("PENDING",
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (doctor['licenseNumber'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: AppTheme.doctorPrimary),
                    const SizedBox(width: 8),
                    Text("License: ${doctor['licenseNumber']}",
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text("Reject"),
                    onPressed: () => _showRejectDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text("Approve"),
                    onPressed: () => _approveDoctor(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveDoctor(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Approve Doctor"),
        content: Text("Approve ${doctor['name']}? They will be notified."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, minimumSize: const Size(80, 36)),
            child: const Text("Approve"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.verifyDoctor(doctor['id'], 'APPROVED');
      onAction();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${doctor['name']} approved ✅"),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Doctor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Reason for rejecting ${doctor['name']}:"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: "e.g., License number invalid",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, minimumSize: const Size(80, 36)),
            child: const Text("Reject"),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ApiService.verifyDoctor(doctor['id'], 'REJECTED', reason: result);
      onAction();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${doctor['name']} rejected"),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
