import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_switcher.dart';
import '../widgets/dashboard_widgets.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'consultation_detail_screen.dart';
import 'provider_schedule_tab.dart';
import 'package:url_launcher/url_launcher.dart';
import 'medical_history_screen.dart';
import 'earnings_screen.dart';
import 'forum_screen.dart';

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() => _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ProviderHomeTab(),
    ProviderScheduleTab(),
    MapScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: AppTheme.doctorPrimary.withOpacity(0.1),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard, color: AppTheme.doctorPrimary),
              label: l.dashboard),
          NavigationDestination(
              icon: const Icon(Icons.event_outlined),
              selectedIcon: const Icon(Icons.event, color: AppTheme.doctorPrimary),
              label: l.schedule),
          NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map, color: AppTheme.doctorPrimary),
              label: l.map),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person, color: AppTheme.doctorPrimary),
              label: l.profile),
        ],
      ),
    );
  }
}

class ProviderHomeTab extends StatefulWidget {
  const ProviderHomeTab({super.key});

  @override
  State<ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<ProviderHomeTab> {
  List bookings = [];
  Map stats = {"total": 0, "pending": 0, "accepted": 0, "rejected": 0};
  Map? providerProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final user = Session.currentUser;
    final email = user?['email'];
    final bData = email != null ? await ApiService.getProviderBookings(email) : await ApiService.getAllBookings();
    final sData = await ApiService.getBookingStats(email: email);
    final pData = email != null ? await ApiService.getProviderProfile(email) : null;
    if (mounted) {
      setState(() {
        bookings = bData;
        stats = sData;
        providerProfile = pData;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = Session.currentUser;
    final verificationStatus = user?['verificationStatus'] ?? 'APPROVED';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => loadData(),
        child: CustomScrollView(
          slivers: [
            // F1: Verification status banner
            if (verificationStatus == 'PENDING')
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "⏳ Your license is under review. You cannot accept bookings yet.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (verificationStatus == 'REJECTED')
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "❌ Verification failed: ${user?['rejectionReason'] ?? 'Contact support'}.",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Doctor Portal", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.doctorPrimary)),
                        const LanguageSwitcher(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AnimatedGreetingCard(
                      name: user?['name']?.split(' ')[0] ?? 'Doctor',
                      color: AppTheme.doctorPrimary,
                      subtitle: "Check your appointments and manage patient records.",
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(l),
                    const SizedBox(height: 32),
                    
                    // --- RECENT APPOINTMENTS (Moved Up) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recent Appointments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                             context.findAncestorStateOfType<_ServiceProviderDashboardState>()?.setState(() {
                              context.findAncestorStateOfType<_ServiceProviderDashboardState>()?._currentIndex = 1;
                            });
                          },
                          child: const Text("View Schedule", style: TextStyle(color: AppTheme.doctorPrimary, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (bookings.isEmpty)
                      const Center(child: Text("No appointments found", style: TextStyle(color: Colors.grey)))
                    else
                      Column(
                        children: bookings.map((b) => _buildBookingCard(b)).toList(),
                      ),
                    
                    const SizedBox(height: 32),

                    // --- PROFESSIONAL TOOLS (Moved Down) ---
                    const Text("Professional Tools", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6, // Smaller box size
                      children: [
                        DashboardTile(
                          title: "Today's Appointments",
                          icon: Icons.calendar_today,
                          color: AppTheme.doctorPrimary,
                          onTap: () {
                            // Find the parent ServiceProviderDashboard state to change tab
                            context.findAncestorStateOfType<_ServiceProviderDashboardState>()?.setState(() {
                              context.findAncestorStateOfType<_ServiceProviderDashboardState>()?._currentIndex = 1;
                            });
                          },
                        ),
                        DashboardTile(
                          title: "Patient Records",
                          icon: Icons.folder_shared,
                          color: Colors.teal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalHistoryScreen())),
                        ),
                        DashboardTile(
                          title: "My Availability",
                          icon: Icons.access_time,
                          color: Colors.orange,
                          onTap: () {
                             context.findAncestorStateOfType<_ServiceProviderDashboardState>()?.setState(() {
                              context.findAncestorStateOfType<_ServiceProviderDashboardState>()?._currentIndex = 1;
                            });
                          },
                        ),
                        DashboardTile(
                          title: "My Ratings",
                          icon: Icons.star,
                          color: Colors.amber,
                          onTap: () {
                             context.findAncestorStateOfType<_ServiceProviderDashboardState>()?.setState(() {
                              context.findAncestorStateOfType<_ServiceProviderDashboardState>()?._currentIndex = 3;
                            });
                          },
                        ),
                        DashboardTile(
                          title: "Q&A Forum",
                          icon: Icons.forum,
                          color: Colors.purple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumScreen())),
                        ),
                        DashboardTile(
                          title: "Earnings",
                          icon: Icons.payments,
                          color: Colors.green,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map b) {
    bool isPending = b['status'] == "PENDING";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.doctorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: AppTheme.doctorPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['serviceType'] ?? "Consultation", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(b['ownerEmail'] ?? "Owner", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    // F7: Visit type indicator
                    Row(children: [
                      Icon(
                        b['visitType'] == 'HOME_VISIT' ? Icons.home : Icons.local_hospital,
                        size: 13,
                        color: b['visitType'] == 'HOME_VISIT' ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        b['visitType'] == 'HOME_VISIT' ? "Home Visit" : "In-Hospital",
                        style: TextStyle(
                          fontSize: 11,
                          color: b['visitType'] == 'HOME_VISIT' ? Colors.green : Colors.blue,
                        ),
                      ),
                    ]),
                    if (b['visitType'] == 'HOME_VISIT' && b['visitAddress'] != null)
                      Text(
                        "📍 ${b['visitAddress']}, ${b['visitCity'] ?? ''} - ${b['visitPincode'] ?? ''}",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(b['appointmentDate'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(b['status'] ?? "PENDING", 
                    style: TextStyle(
                      color: b['status'] == "ACCEPTED" ? Colors.green : (b['status'] == "REJECTED" ? Colors.red : Colors.orange), 
                      fontWeight: FontWeight.bold, 
                      fontSize: 10
                    )
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConsultationDetailScreen(booking: b))),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(b['id'], "REJECTED"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Reject", style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(b['id'], "ACCEPTED"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Accept", style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _updateStatus(int id, String status) async {
    final user = Session.currentUser;
    final email = user?['email'];
    await ApiService.updateBookingStatus(id, status, providerEmail: email);
    loadData();
  }

  Widget _buildStatsRow(AppLocalizations l) {
    return Row(
      children: [
        _statItem(stats['pending'].toString(), "Pending", Colors.orange, () {
           context.findAncestorStateOfType<_ServiceProviderDashboardState>()?.setState(() {
            context.findAncestorStateOfType<_ServiceProviderDashboardState>()?._currentIndex = 1;
          });
        }),
        const SizedBox(width: 12),
        _statItem(stats['accepted'].toString(), "Active", Colors.green, () {
           context.findAncestorStateOfType<_ServiceProviderDashboardState>()?.setState(() {
            context.findAncestorStateOfType<_ServiceProviderDashboardState>()?._currentIndex = 1;
          });
        }),
        const SizedBox(width: 12),
        _statItem(providerProfile?['avgRating']?.toString() ?? "0.0", "Rating", Colors.amber, () {
           context.findAncestorStateOfType<_ServiceProviderDashboardState>()?.setState(() {
            context.findAncestorStateOfType<_ServiceProviderDashboardState>()?._currentIndex = 3;
          });
        }),
      ],
    );
  }

  Widget _statItem(String value, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
