import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Admin bookings tab — displays all platform bookings with filter chips.
class AdminBookingsTab extends StatefulWidget {
  final List<dynamic> bookings;
  final VoidCallback onRefresh;

  const AdminBookingsTab({
    super.key,
    required this.bookings,
    required this.onRefresh,
  });

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  String _filter = 'ALL';

  List<dynamic> get _filteredBookings {
    if (_filter == 'ALL') return widget.bookings;
    return widget.bookings
        .where((b) => (b['status'] ?? '') == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Bookings",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    Text("${widget.bookings.length}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _miniStat("Pending",
                  widget.bookings.where((b) => b['status'] == 'PENDING').length,
                  Colors.orange),
              const SizedBox(width: 8),
              _miniStat("Accepted",
                  widget.bookings.where((b) => b['status'] == 'ACCEPTED').length,
                  Colors.green),
            ],
          ),
        ),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['ALL', 'PENDING', 'ACCEPTED', 'COMPLETED', 'REJECTED']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f,
                            style: TextStyle(
                                fontSize: 12,
                                color: _filter == f
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w600)),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                      ),
                    ))
                .toList(),
          ),
        ),
        // Bookings list
        Expanded(
          child: _filteredBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("No bookings found",
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredBookings.length,
                    itemBuilder: (context, i) {
                      final b = _filteredBookings[i];
                      return _BookingCard(booking: b);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text("$count",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'UNKNOWN';
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking #${booking['id'] ?? '-'}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(booking['serviceType'] ?? 'N/A',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(status,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _detailRow(Icons.person_outline, "Owner",
                      booking['ownerEmail'] ?? 'N/A'),
                  const SizedBox(height: 6),
                  _detailRow(Icons.medical_services_outlined, "Provider",
                      booking['providerEmail'] ?? 'Not assigned'),
                  if (booking['appointmentDate'] != null) ...[
                    const SizedBox(height: 6),
                    _detailRow(Icons.event_outlined, "Date",
                        "${booking['appointmentDate']} ${booking['appointmentTime'] ?? ''}"),
                  ],
                  if (booking['visitType'] != null) ...[
                    const SizedBox(height: 6),
                    _detailRow(
                        Icons.location_on_outlined,
                        "Type",
                        booking['visitType'] == 'HOME_VISIT'
                            ? 'Home Visit'
                            : 'In Hospital'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
