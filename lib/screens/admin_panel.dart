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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Admin Panel",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              text: "Pending (${stats['pendingDoctors'] ?? pendingDoctors.length})",
              icon: const Icon(Icons.pending_outlined, size: 18),
            ),
            Tab(
              text: "All Doctors",
              icon: const Icon(Icons.medical_services_outlined, size: 18),
            ),
            Tab(
              text: "Pet Owners",
              icon: const Icon(Icons.pets_outlined, size: 18),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats row
                _buildStatsRow(),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(),
                      _buildAllDoctorsTab(),
                      _buildOwnersTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsRow() {
    final items = [
      {
        'label': 'Total Doctors',
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
        'label': 'Pet Owners',
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: items.map((item) {
          final color = item['color'] as Color;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(item['icon'] as IconData, color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(item['value']!.toString(),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text(item['label']!.toString(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
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
