import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Admin payments tab — displays all platform payments with revenue summary.
class AdminPaymentsTab extends StatelessWidget {
  final List<dynamic> payments;
  final VoidCallback onRefresh;

  const AdminPaymentsTab({
    super.key,
    required this.payments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    double totalRevenue = 0;
    int paidCount = 0;
    int pendingCount = 0;
    int cashCount = 0;
    int onlineCount = 0;

    for (final p in payments) {
      final amount = (p['amount'] ?? 0).toDouble();
      final status = p['status'] ?? '';
      final method = p['method'] ?? '';
      if (status == 'PAID') {
        totalRevenue += amount;
        paidCount++;
      } else {
        pendingCount++;
      }
      if (method == 'CASH') {
        cashCount++;
      } else if (method == 'ONLINE') {
        onlineCount++;
      }
    }

    return Column(
      children: [
        // Revenue summary
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade700,
                Colors.orange.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Revenue",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text("₹${totalRevenue.toStringAsFixed(0)}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem("Total", "${payments.length}", Icons.receipt),
                    _divider(),
                    _summaryItem("Paid", "$paidCount", Icons.check_circle),
                    _divider(),
                    _summaryItem(
                        "Pending", "$pendingCount", Icons.hourglass_empty),
                    _divider(),
                    _summaryItem("Cash", "$cashCount", Icons.money),
                    _divider(),
                    _summaryItem("Online", "$onlineCount", Icons.credit_card),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Payments list
        Expanded(
          child: payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("No payments found",
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: payments.length,
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      return _PaymentCard(payment: p);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.2),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final status = payment['status'] ?? 'UNKNOWN';
    final method = payment['method'] ?? 'N/A';
    final amount = (payment['amount'] ?? 0).toDouble();
    final isPaid = status == 'PAID';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPaid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPaid
                    ? Icons.check_circle_outline
                    : Icons.hourglass_empty,
                color: isPaid ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Booking #${payment['bookingId'] ?? '-'}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    "${payment['ownerEmail'] ?? '—'} → ${payment['providerEmail'] ?? '—'}",
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: method == 'CASH'
                              ? Colors.teal.withOpacity(0.1)
                              : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              method == 'CASH'
                                  ? Icons.money
                                  : Icons.credit_card,
                              size: 10,
                              color: method == 'CASH'
                                  ? Colors.teal
                                  : Colors.purple,
                            ),
                            const SizedBox(width: 3),
                            Text(method,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: method == 'CASH'
                                        ? Colors.teal
                                        : Colors.purple)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? Colors.green
                                    : Colors.orange)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text("₹${amount.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPaid
                        ? Colors.green.shade700
                        : Colors.orange.shade700)),
          ],
        ),
      ),
    );
  }
}
