import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool isLoading = true;
  double totalEarned = 0;
  double platformFee = 0;
  double netEarnings = 0;
  double totalWithdrawn = 0;
  double availableBalance = 0;
  
  List<dynamic> payments = [];
  List<dynamic> withdrawals = [];

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    final user = Session.currentUser;
    if (user == null) return;

    try {
      final data = await ApiService.getProviderEarnings(user['email']);
      if (data != null && mounted) {
        setState(() {
          totalEarned = (data['totalEarned'] as num).toDouble();
          platformFee = (data['platformFee'] as num).toDouble();
          netEarnings = (data['netEarnings'] as num).toDouble();
          totalWithdrawn = (data['totalWithdrawn'] as num).toDouble();
          availableBalance = (data['availableBalance'] as num).toDouble();
          payments = data['payments'] as List<dynamic>;
          withdrawals = data['withdrawals'] as List<dynamic>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _withdrawDialog() async {
    final upiCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: availableBalance.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Withdraw Earnings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Available for withdrawal: ₹${availableBalance.toStringAsFixed(2)}", 
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: upiCtrl,
              decoration: const InputDecoration(
                labelText: "UPI ID",
                hintText: "example@upi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixText: "₹ ",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final upiId = upiCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;

              if (upiId.isEmpty || !upiId.contains('@')) {
                _showError("Please enter a valid UPI ID");
                return;
              }
              if (amount <= 0 || amount > availableBalance) {
                _showError("Invalid amount");
                return;
              }

              Navigator.pop(ctx);
              _initiateWithdrawal(upiId, amount);
            },
            child: const Text("Withdraw"),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateWithdrawal(String upiId, double amount) async {
    setState(() => isLoading = true);
    final user = Session.currentUser;
    if (user == null) return;

    try {
      final res = await ApiService.withdrawEarnings(user['email'], upiId, amount);
      if (res != null && res['success'] == true) {
        _showSuccess(res['message'] ?? "Withdrawal request submitted");
        _fetchEarnings();
      } else {
        _showError(res?['message'] ?? "Withdrawal failed");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("My Earnings"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchEarnings,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildEarningsHeader(),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Text("Earning History", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (payments.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text("No earnings recorded yet.", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTransactionCard(payments[index]),
                        childCount: payments.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Text("Withdrawal History", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (withdrawals.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text("No withdrawals yet.", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildWithdrawalCard(withdrawals[index]),
                        childCount: withdrawals.length,
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text("₹${availableBalance.toStringAsFixed(2)}", 
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat("Total Earned", "₹${totalEarned.toStringAsFixed(0)}"),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildHeaderStat("Withdrawn", "₹${totalWithdrawn.toStringAsFixed(0)}"),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: availableBalance > 10 ? _withdrawDialog : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              disabledBackgroundColor: Colors.white54,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Withdraw Earnings", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Payment from Owner", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(tx['ownerEmail'] ?? "No Email", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Method: ${tx['method']}", style: const TextStyle(color: Colors.blue, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("+₹${(tx['amount'] as num).toStringAsFixed(2)}", 
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text(tx['createdAt'].toString().split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(dynamic w) {
    final isProcessed = w['status'] == 'PROCESSED';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isProcessed ? Colors.blue : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isProcessed ? Icons.check : Icons.pending, color: isProcessed ? Colors.blue : Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Withdrawal to UPI", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(w['upiId'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Status: ${w['status']}", style: TextStyle(color: isProcessed ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("-₹${(w['amount'] as num).toStringAsFixed(2)}", 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              Text(w['createdAt'].toString().split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
