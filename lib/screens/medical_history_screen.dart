import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'consultation_detail_screen.dart';
import '../services/session.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String? ownerEmail;
  const MedicalHistoryScreen({super.key, this.ownerEmail});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = Session.currentUser;
    final email = widget.ownerEmail ?? user?['email'];
    if (email == null) return;

    List data;
    if (widget.ownerEmail != null || user?['role'] == "Farmer") {
      data = await ApiService.getFarmerBookings(email);
    } else {
      data = await ApiService.getProviderBookings(email);
    }

    setState(() {
      history = data.reversed.toList(); // Newest first
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text("Medical History"),
            Text(widget.ownerEmail ?? Session.currentUser?['email'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) => _historyCard(history[index]),
                ),
    );
  }

  Widget _historyCard(Map b) {
    Color statusColor = b['status'] == "COMPLETED" ? Colors.green : Colors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      borderOnForeground: true,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConsultationDetailScreen(booking: b)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(b['appointmentDate'] ?? "Date Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(b['status'], style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(b['serviceType'] ?? "General Consultation", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              const Divider(height: 24),
              if (b['treatmentNotes'] != null && b['treatmentNotes'].toString().isNotEmpty) ...[
                const Text("Notes & Medications:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(b['treatmentNotes'], style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ] else
                const Text("No treatment notes recorded", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Text("View Details →", style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noPastAppointments, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
