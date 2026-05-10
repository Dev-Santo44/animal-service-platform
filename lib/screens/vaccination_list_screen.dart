import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'add_vaccination_screen.dart';

class VaccinationListScreen extends StatefulWidget {
  const VaccinationListScreen({super.key});

  @override
  State<VaccinationListScreen> createState() => _VaccinationListScreenState();
}

class _VaccinationListScreenState extends State<VaccinationListScreen> {
  List records = [];
  bool isLoading = true;
  String _filterStatus = 'All';  // F6: Filter
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<String> _filterOptions = ['All', 'Upcoming', 'Overdue', 'Completed'];

  List get _filteredRecords {
    return records.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          (r['vaccineName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (r['animalName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_filterStatus == 'All') return true;
      final status = _getBadgeStatus(r['nextDueDate']);
      return status == _filterStatus.toUpperCase();
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadRecords();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void loadRecords() async {
    final user = Session.currentUser;
    if (user != null) {
      final data = await ApiService.getFarmerVaccinations(user['email']);
      if (mounted) {
        setState(() {
          records = data;
          isLoading = false;
        });
      }
    }
  }

  String _getBadgeStatus(String? dueDateStr) {
    if (dueDateStr == null || dueDateStr.isEmpty) return "COMPLETED";
    try {
      DateTime dueDate = DateTime.parse(dueDateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      
      if (dueDate.isBefore(today)) return "OVERDUE";
      if (dueDate.difference(today).inDays <= 7) return "DUE SOON";
    } catch (e) {
      return "COMPLETED";
    }
    return "UPCOMING";
  }

  Color _getBadgeColor(String status) {
    switch (status) {
      case "OVERDUE": return Colors.red;
      case "DUE SOON": return Colors.orange;
      case "UPCOMING": return Colors.blue;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = Session.currentUser;
    final isDoctor = user?['role'] == 'Doctor' || user?['role'] == 'Service Provider';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l.vaccinationTracking),
        actions: [
          if (!isDoctor)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddVaccinationScreen()));
                loadRecords();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // F6: Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Search by animal or vaccine...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
                // F6: Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((option) {
                        final isSelected = _filterStatus == option;
                        Color chipColor;
                        switch (option) {
                          case 'Overdue': chipColor = Colors.red; break;
                          case 'Upcoming': chipColor = Colors.orange; break;
                          case 'Completed': chipColor = Colors.green; break;
                          default: chipColor = AppTheme.primaryColor;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _filterStatus = option),
                            selectedColor: chipColor.withOpacity(0.15),
                            checkmarkColor: chipColor,
                            labelStyle: TextStyle(
                              color: isSelected ? chipColor : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Record count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${_filteredRecords.length} records",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.vaccines_outlined,
                                  size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(l.noRecordsYet,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            return _buildVaccineCard(_filteredRecords[index], l);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: !isDoctor
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AddVaccinationScreen()));
                loadRecords();
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    int overdue = records.where((r) => _getBadgeStatus(r['nextDueDate']) == "OVERDUE").length;
    int dueSoon = records.where((r) => _getBadgeStatus(r['nextDueDate']) == "DUE SOON").length;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _headerStat(overdue.toString(), "OVERDUE", Colors.red),
          _headerStat(dueSoon.toString(), "DUE SOON", Colors.orange),
          _headerStat(records.length.toString(), "TOTAL", Colors.blue),
        ],
      ),
    );
  }

  Widget _headerStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVaccineCard(Map r, AppLocalizations l) {
    String status = _getBadgeStatus(r['nextDueDate']);
    Color color = _getBadgeColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r['animalName'] ?? "Animal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(r['vaccineName'] ?? "Vaccine", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                    const Divider(height: 24),
                    Row(
                      children: [
                        _infoItem(Icons.calendar_today, "Given", r['dateGiven'] ?? "N/A"),
                        const Spacer(),
                        _infoItem(Icons.event_repeat, "Next Due", r['nextDueDate'] ?? "Not Set"),
                      ],
                    ),
                    if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(r['notes'], style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vaccines_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(l.noRecordsYet, style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }
}
