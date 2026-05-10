import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_switcher.dart';
import '../widgets/dashboard_widgets.dart';
import 'map_screen.dart';
import 'provider_list_screen.dart';
import 'vaccination_list_screen.dart';
import 'profile_screen.dart';
import 'pharmacy_screen.dart';
import 'consultation_detail_screen.dart';
import 'bookings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class FarmerScreen extends StatefulWidget {
  const FarmerScreen({super.key});

  @override
  State<FarmerScreen> createState() => _FarmerScreenState();
}

class _FarmerScreenState extends State<FarmerScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FarmerHomeTab(),
    ProviderListScreen(),
    VaccinationListScreen(),  // F6: Added Vaccinations tab
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
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        indicatorColor: AppTheme.farmerPrimary.withOpacity(0.1),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppTheme.farmerPrimary),
              label: l.home),
          NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people, color: AppTheme.farmerPrimary),
              label: l.doctors),
          NavigationDestination(
              icon: const Icon(Icons.vaccines_outlined),      // F6: Vaccinations nav
              selectedIcon: const Icon(Icons.vaccines, color: AppTheme.farmerPrimary),
              label: "Vaccinations"),
          NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map, color: AppTheme.farmerPrimary),
              label: l.map),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person, color: AppTheme.farmerPrimary),
              label: l.profile),
        ],
      ),
    );
  }
}

class FarmerHomeTab extends StatefulWidget {
  const FarmerHomeTab({super.key});

  @override
  State<FarmerHomeTab> createState() => _FarmerHomeTabState();
}

class _FarmerHomeTabState extends State<FarmerHomeTab> {
  List bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final user = Session.currentUser;
    if (user != null) {
      final bData = await ApiService.getFarmerBookings(user['email']);
      if (mounted) {
        setState(() {
          bookings = bData;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = Session.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => loadData(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pet Owner Portal", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.farmerPrimary)),  // F2
                        const LanguageSwitcher(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AnimatedGreetingCard(
                      name: user?['name']?.split(' ')[0] ?? 'Pet Owner',  // F2
                      color: AppTheme.farmerPrimary,
                      subtitle: "Manage your pets and book vet services with ease.",
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
                    
                    // --- OUR SERVICES ---
                    Text(l.ourServices, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.2,
                      children: [
                        DashboardTile(
                          title: l.consultation,
                          icon: Icons.medical_services,
                          color: AppTheme.farmerPrimary,
                          onTap: () => _handleServiceBooking("Consultation"),
                        ),
                        DashboardTile(
                          title: l.vaccination,
                          icon: Icons.vaccines,
                          color: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccinationListScreen())),
                        ),
                        DashboardTile(
                          title: l.emergency,
                          icon: Icons.emergency,
                          color: Colors.red,
                          onTap: () => _showEmergencySheet(context),
                        ),
                        DashboardTile(
                          title: "Find Vet on Map",
                          icon: Icons.map,
                          color: Colors.blue,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                        ),
                        DashboardTile(
                          title: "My Bookings",
                          icon: Icons.calendar_month,
                          color: Colors.teal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- RECENT APPOINTMENTS ---
                    if (bookings.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.recentAppointments, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                            child: const Text("View All", style: TextStyle(color: AppTheme.farmerPrimary, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Show all appointments
                      ...bookings.map((b) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConsultationDetailScreen(booking: b),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppTheme.farmerPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.calendar_today, color: AppTheme.farmerPrimary),
                            ),
                            title: Text(b['serviceType'] ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(b['providerEmail'] ?? 'Doctor Not Assigned Yet'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  b['status'] ?? 'UNKNOWN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: b['status'] == "PENDING"
                                        ? Colors.orange
                                        : b['status'] == "ACCEPTED"
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['appointmentTime'] != null 
                                    ? b['appointmentTime'].toString().contains('T') 
                                      ? b['appointmentTime'].toString().split('T')[1].substring(0, 5) // Show HH:mm
                                      : b['appointmentTime'].toString()
                                    : "10:30 AM", // Fallback for testing or missing time
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ] else ...[
                       const SizedBox(height: 8),
                       Text(l.noActiveAppointments, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ],
                    const SizedBox(height: 32),                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l) {
    return Row(
      children: [
        _statItem(bookings.length.toString(), "Bookings", Colors.orange),
        const SizedBox(width: 12),
        _statItem("0", "Vouchers", Colors.blue),
      ],
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Expanded(
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
    );
  }

  void _showEmergencySheet(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.emergencyContacts, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text(l.immediateHelp, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _emergencyItem(l.vetEmergencyHelpline, "1800-VET-HELP", Icons.phone),
            const SizedBox(height: 12),
            _emergencyItem(l.districtVetHospital, "011-2345-6789", Icons.local_hospital),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _emergencyItem(String title, String phone, IconData icon) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse("tel:$phone")),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            Text(phone, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _handleServiceBooking(String service) async {
    final l = AppLocalizations.of(context)!;
    final user = Session.currentUser;
    if (user == null) return;

    // F7: Pick Visit Type first
    String selectedVisitType = 'IN_HOSPITAL';
    String? visitAddress;
    String? visitCity;
    String? visitPincode;

    final visitTypeResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _VisitTypeDialog(),
    );
    if (visitTypeResult == null) return;
    selectedVisitType = visitTypeResult['type'];
    visitAddress = visitTypeResult['address'];
    visitCity = visitTypeResult['city'];
    visitPincode = visitTypeResult['pincode'];

    // 1. Pick Date
    if (!mounted) return;
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: "Select Appointment Date",
    );

    if (selectedDate == null) return;

    // 2. Pick Time
    if (!mounted) return;
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 30),
      helpText: "Select Appointment Time",
    );

    if (selectedTime == null) return;

    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final dateStr = selectedDate.toString().split(' ')[0];
    final timeStr = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}";

    await ApiService.createBooking(
      user['email'],
      service,
      date: dateStr,
      time: timeStr,
      visitType: selectedVisitType,
      visitAddress: visitAddress,
      visitCity: visitCity,
      visitPincode: visitPincode,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading
      loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.bookingRequestSent(service)), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// F7: Visit Type Selection Dialog
class _VisitTypeDialog extends StatefulWidget {
  @override
  State<_VisitTypeDialog> createState() => _VisitTypeDialogState();
}

class _VisitTypeDialogState extends State<_VisitTypeDialog> {
  String _visitType = 'IN_HOSPITAL';
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Visit Type'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'IN_HOSPITAL',
                    label: Text('In-Hospital'),
                    icon: Icon(Icons.local_hospital),
                  ),
                  ButtonSegment(
                    value: 'HOME_VISIT',
                    label: Text('Home Visit'),
                    icon: Icon(Icons.home),
                  ),
                ],
                selected: {_visitType},
                onSelectionChanged: (s) => setState(() => _visitType = s.first),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (v) => _visitType == 'HOME_VISIT' && (v == null || v.isEmpty)
                          ? 'Address required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        prefixIcon: Icon(Icons.pin_drop_outlined),
                      ),
                    ),
                  ],
                ),
                crossFadeState: _visitType == 'HOME_VISIT'
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'type': _visitType,
                'address': _visitType == 'HOME_VISIT' ? _addressCtrl.text : null,
                'city': _visitType == 'HOME_VISIT' ? _cityCtrl.text : null,
                'pincode': _visitType == 'HOME_VISIT' ? _pincodeCtrl.text : null,
              });
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
