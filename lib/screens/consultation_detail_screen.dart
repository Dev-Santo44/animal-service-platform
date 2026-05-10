import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import 'medical_history_screen.dart';
import 'receipt_screen.dart';
import 'rate_doctor_screen.dart';
import 'package:intl/intl.dart';
import '../services/razorpay_web_service.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final Map booking;
  const ConsultationDetailScreen({super.key, required this.booking});

  @override
  State<ConsultationDetailScreen> createState() => _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  List<Map> messages = [];
  List<Map> medications = [];
  List<Map> charges = [];
  double totalCharge = 0;
  bool isLoading = false;
  Timer? _timer;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map get _user => Session.currentUser ?? {};
  bool get _isDoctor => (_user['role'] ?? '') == 'Service Provider';
  int get _bookingId {
    final id = widget.booking['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '0') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
    // Poll for new messages/notes every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _loadNotes(isPolling: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes({bool isPolling = false}) async {
    if (_bookingId == 0) return;
    if (!isPolling) setState(() => isLoading = true);
    try {
      final notes = await ApiService.getConsultationNotes(_bookingId);
      if (!mounted) return;

      // If nothing changed, don't rebuild
      if (isPolling && notes.length == (messages.length + medications.length + charges.length)) return;

      final msgs = <Map>[];
      final meds = <Map>[];
      final chgs = <Map>[];
      double total = 0;
      for (final n in notes) {
        final note = Map<String, dynamic>.from(n);
        final type = note['noteType']?.toString() ?? '';
        if (type == 'MESSAGE') msgs.add(note);
        if (type == 'MEDICATION') meds.add(note);
        if (type == 'CHARGE') {
          chgs.add(note);
          final raw = note['content']?.toString() ?? '';
          final amt = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          total += amt;
        }
      }
      setState(() {
        messages = msgs;
        medications = meds;
        charges = chgs;
        totalCharge = total;
        if (!isPolling) isLoading = false;
      });
    } catch (e) {
      if (!isPolling && mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _user.isEmpty) return;
    final msg = <String, dynamic>{
      'senderName': _user['name'] ?? 'User',
      'senderRole': _user['role'] ?? '',
      'content': text,
      'noteType': 'MESSAGE',
      'time': TimeOfDay.now().format(context),
    };
    setState(() {
      messages.add(msg);
      _msgController.clear();
    });
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    await ApiService.addConsultationNote(
      _bookingId,
      _user['role'] ?? '',
      _user['name'] ?? 'User',
      text,
      'MESSAGE',
    );
  }

  Future<void> _addMedication() async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.prescribeMedication),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(hintText: AppLocalizations.of(context)!.medicineName)),
          const SizedBox(height: 12),
          TextField(controller: doseCtrl, decoration: InputDecoration(hintText: AppLocalizations.of(context)!.dosageInstructions)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final entry = '${nameCtrl.text} — ${doseCtrl.text}';
              if (mounted) {
                setState(() => medications.add({'content': entry, 'noteType': 'MEDICATION'}));
              }
              Navigator.pop(context);
              await ApiService.addConsultationNote(
                  _bookingId, _user['role'] ?? '', _user['name'] ?? '', entry, 'MEDICATION');
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _addCharge() async {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addCharge),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: descCtrl, decoration: InputDecoration(hintText: AppLocalizations.of(context)!.chargeDescriptionHint)),
          const SizedBox(height: 12),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: AppLocalizations.of(context)!.amount, prefixText: '₹ '),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt <= 0) return;
              final entry = '${descCtrl.text}: ₹${amt.toStringAsFixed(0)}';
              if (mounted) {
                setState(() {
                  charges.add({'content': entry, 'amount': amt, 'noteType': 'CHARGE'});
                  totalCharge += amt;
                });
              }
              Navigator.pop(context);
              await ApiService.addConsultationNote(
                  _bookingId, _user['role'] ?? '', _user['name'] ?? '', entry, 'CHARGE');
            },
            child: Text(AppLocalizations.of(context)!.addRecord),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog() async {
    final rated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RateDoctorScreen(booking: widget.booking)),
    );
    if (rated == true) {
      // Maybe disable the button or show a thank you
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Appointment?"),
        content: const Text("This will permanently remove this appointment and all its records. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoading = true);
              final success = await ApiService.deleteBooking(_bookingId);
              if (success && mounted) {
                Navigator.pop(context, true); // Go back to dashboard with 'true' to refresh
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment deleted successfully")));
              } else if (mounted) {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete appointment")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.booking['serviceType']?.toString() ?? AppLocalizations.of(context)!.consultation),
              Text(
                _isDoctor
                    ? '${AppLocalizations.of(context)!.patient}: ${widget.booking['ownerEmail'] ?? ''}'
                    : '${AppLocalizations.of(context)!.role}: ${widget.booking['status'] ?? ''}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            if (_isDoctor)
              IconButton(
                icon: const Icon(Icons.history, color: AppTheme.primaryColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MedicalHistoryScreen(ownerEmail: widget.booking['ownerEmail'])),
                ),
                tooltip: "Medical History",
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: "Delete Appointment",
              onPressed: () => _confirmDelete(context),
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryColor),
              tooltip: AppLocalizations.of(context)!.viewBillTooltip,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReceiptScreen(
                    booking: widget.booking,
                    medications: medications,
                    charges: charges,
                    totalCharge: totalCharge,
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: const Icon(Icons.chat_bubble_outline, size: 18), text: AppLocalizations.of(context)!.chat),
              Tab(icon: const Icon(Icons.medication_outlined, size: 18), text: AppLocalizations.of(context)!.medical),
              Tab(icon: const Icon(Icons.shield_outlined, size: 18), text: AppLocalizations.of(context)!.vaccination),
              Tab(icon: const Icon(Icons.healing_outlined, size: 18), text: AppLocalizations.of(context)!.firstAid),
            ],
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: TabBarView(
          children: [
            _chatTab(),
            _medicalTab(),
            _vaccinationTab(),
            _firstAidTab(),
          ],
        ),
      ),
    );
  }

  // ── VACCINATION ────────────────────────
  List _vaccinations = [];
  bool _loadingVaccines = false;

  Future<void> _loadVaccinations() async {
    final email = widget.booking['ownerEmail'];
    if (email == null) return;
    setState(() => _loadingVaccines = true);
    final data = await ApiService.getFarmerVaccinations(email);
    if (mounted) {
      setState(() {
        _vaccinations = data;
        _loadingVaccines = false;
      });
    }
  }

  Widget _vaccinationTab() {
    if (_vaccinations.isEmpty && !_loadingVaccines) {
      _loadVaccinations();
    }
    return Column(
      children: [
        Expanded(
          child: _loadingVaccines
              ? const Center(child: CircularProgressIndicator())
              : _vaccinations.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)!.noVaccinationHistory, style: TextStyle(color: Colors.grey.shade400)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vaccinations.length,
                      itemBuilder: (context, index) => _vaccineSmallCard(_vaccinations[index]),
                    ),
        ),
        if (_isDoctor)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton.icon(
                onPressed: _showAddVaccineDialog,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.recordVaccination),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _vaccineSmallCard(Map v) {
    bool isUpcoming = v['status'] == "UPCOMING";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUpcoming ? Colors.orange.withOpacity(0.3) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: isUpcoming ? Colors.orange : Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${v['animalName']} - ${v['vaccineName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  isUpcoming ? "${AppLocalizations.of(context)!.setReminder}: ${v['nextDueDate']}" : "${AppLocalizations.of(context)!.givenOn}: ${v['dateGiven']}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isUpcoming)
            const Icon(Icons.alarm, color: Colors.orange, size: 16),
        ],
      ),
    );
  }

  void _showAddVaccineDialog() {
    final animalCtrl = TextEditingController();
    final vaccineCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final nextDueCtrl = TextEditingController();
    String selectedStatus = "COMPLETED";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.newVaccination),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: [
                    DropdownMenuItem(value: "COMPLETED", child: Text(AppLocalizations.of(context)!.administeredToday)),
                    DropdownMenuItem(value: "UPCOMING", child: Text(AppLocalizations.of(context)!.setFutureReminder)),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.type),
                ),
                const SizedBox(height: 12),
                TextField(controller: animalCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.animalName)),
                const SizedBox(height: 12),
                TextField(controller: vaccineCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.vaccineName)),
                const SizedBox(height: 12),
                if (selectedStatus == "COMPLETED")
                  ListTile(
                    title: Text("${AppLocalizations.of(context)!.dateGiven} ${dateCtrl.text.isEmpty ? AppLocalizations.of(context)!.today : dateCtrl.text}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => dateCtrl.text = picked.toString().split(' ')[0]);
                      }
                    },
                  ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(selectedStatus == "UPCOMING" ? "${AppLocalizations.of(context)!.reminderDate} ${nextDueCtrl.text}" : "${AppLocalizations.of(context)!.nextDueDate} ${nextDueCtrl.text.isEmpty ? AppLocalizations.of(context)!.notSet : nextDueCtrl.text}"),
                  trailing: const Icon(Icons.alarm),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setDialogState(() => nextDueCtrl.text = picked.toString().split(' ')[0]);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (animalCtrl.text.isNotEmpty && vaccineCtrl.text.isNotEmpty) {
                  await ApiService.addVaccinationRecord(
                    ownerEmail: widget.booking['ownerEmail'],
                    animal: animalCtrl.text,
                    vaccine: vaccineCtrl.text,
                    status: selectedStatus,
                    dateGiven: selectedStatus == "COMPLETED" ? (dateCtrl.text.isEmpty ? DateTime.now().toString().split(' ')[0] : dateCtrl.text) : null,
                    nextDueDate: nextDueCtrl.text.isEmpty ? null : nextDueCtrl.text,
                    providerEmail: _user['email'],
                  );
                  Navigator.pop(context);
                  _loadVaccinations();
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  // ── CHAT ──────────────────────────────
  Widget _chatTab() {
    return Column(
      children: [
        if (!_isDoctor && totalCharge > 0) _paymentBanner(),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? _emptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final m = messages[i];
                        final isMe = (m['senderName']?.toString() ?? '') == (_user['name']?.toString() ?? '');
                        return _bubble(m, isMe);
                      },
                    ),
        ),
        _chatInput(),
      ],
    );
  }

  Widget _bubble(Map m, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              m['senderName']?.toString() ?? '',
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(m['content']?.toString() ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade200),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.noMessagesYet, style: TextStyle(color: Colors.grey.shade400)),
        Text(AppLocalizations.of(context)!.startConsultation, style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
      ]),
    );
  }

  Widget _chatInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.white,
        child: Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.typeMessage,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    );
  }

  // ── PAYMENT BANNER ────────────────────
  Widget _paymentBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade400]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.paymentDue, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text('₹${totalCharge.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
        TextButton(
          onPressed: _showPaymentSheet,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(AppLocalizations.of(context)!.payNow, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.completePayment, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${AppLocalizations.of(context)!.total}: ₹${totalCharge.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            _payOpt(
              Icons.account_balance,
              AppLocalizations.of(context)!.paymentOptionUPI,
              'Pay via UPI, Card, or Netbanking',
              onTap: () => _startRazorpayPayment(),
            ),
            const SizedBox(height: 10),
            _payOpt(
              Icons.currency_rupee,
              AppLocalizations.of(context)!.paymentOptionCash,
              AppLocalizations.of(context)!.confirmCashPaymentSmall,
              onTap: () => _confirmCashPayment(),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _startRazorpayPayment() async {
    Navigator.pop(context); // Close sheet
    setState(() => isLoading = true);

    try {
      final orderData = await ApiService.createRazorpayOrder(
        _bookingId,
        totalCharge,
        widget.booking['ownerEmail'],
        widget.booking['providerEmail'],
      );

      if (orderData != null && orderData['success'] == true) {
        RazorpayWebService.openCheckout(
          options: {
            'key': orderData['keyId'],
            'amount': orderData['amount'],
            'name': 'Animal Service Platform',
            'description': 'Consultation Fee',
            'order_id': orderData['orderId'],
            'prefill': {
              'email': widget.booking['ownerEmail'],
            },
          },
          onSuccess: (paymentId, orderId, signature) async {
            final verified = await ApiService.verifyPayment(orderId, paymentId, signature);
            if (verified) {
              _showSuccessSnackBar("Payment successful!");
              _loadNotes(); // Refresh to show updated charges if needed
            } else {
              _showErrorSnackBar("Payment verification failed.");
            }
          },
          onDismiss: () {
            setState(() => isLoading = false);
            _showErrorSnackBar("Payment cancelled.");
          },
        );
      } else {
        _showErrorSnackBar("Failed to create payment order.");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmCashPayment() async {
    Navigator.pop(context); // Close sheet
    setState(() => isLoading = true);

    try {
      final success = await ApiService.recordCashPayment(
        _bookingId,
        totalCharge,
        widget.booking['ownerEmail'],
        widget.booking['providerEmail'],
      );

      if (success) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.cashPaymentConfirmed);
        _loadNotes();
      } else {
        _showErrorSnackBar("Failed to record cash payment.");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _payOpt(IconData icon, String title, String sub, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ]),
      ),
    );
  }

  // ── MEDICAL ───────────────────────────
  Widget _medicalTab() {
    return Column(children: [
      if (_isDoctor && totalCharge > 0) _earningsBanner(),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (medications.isNotEmpty) ...[
            _sectionHead(AppLocalizations.of(context)!.medications, Icons.medication, Colors.blue),
            const SizedBox(height: 8),
            ...medications.map((m) => _noteCard(m['content']?.toString() ?? '', Icons.medication, Colors.blue)),
            const SizedBox(height: 20),
          ],
          if (charges.isNotEmpty) ...[
            _sectionHead(AppLocalizations.of(context)!.chargesFees, Icons.payments, Colors.orange),
            const SizedBox(height: 8),
            ...charges.map((c) => _noteCard(c['content']?.toString() ?? '', Icons.receipt_long, Colors.orange)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.25))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(AppLocalizations.of(context)!.total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('₹${totalCharge.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
              ]),
            ),
          ],
          if (medications.isEmpty && charges.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(child: Column(children: [
                Icon(Icons.medical_services_outlined, size: 52, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.noRecordsYet, style: TextStyle(color: Colors.grey.shade400)),
              ])),
            ),
          const SizedBox(height: 32),
          if (!_isDoctor)
            Center(
              child: OutlinedButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(Icons.star_outline),
                label: Text(AppLocalizations.of(context)!.rateYourDoctor),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ]),
      ),
      if (_isDoctor)
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context)!.prescribeMedication),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addCharge,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(AppLocalizations.of(context)!.addCharge),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
              ),
            ]),
          ),
        ),
    ]);
  }

  Widget _earningsBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your Earnings (via Platform)', style: TextStyle(color: Colors.white70, fontSize: 11)),
          Text('₹${(totalCharge * 0.90).toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('After 10% fee from ₹${totalCharge.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ])),
      ]),
    );
  }

  Widget _sectionHead(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
    ]);
  }

  Widget _noteCard(String content, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(content, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ── FIRST AID ─────────────────────────
  Widget _firstAidTab() {
    final tips = [
      _FAItem('Wound Cleaning', 'Rinse with clean water, apply antiseptic, bandage loosely.', Icons.healing, Colors.red),
      _FAItem('Heat Stroke', 'Move to shade, offer small sips of water, fan the animal.', Icons.thermostat, Colors.orange),
      _FAItem('Bloating / Gas', 'Keep animal walking slowly. Do NOT lay down. Call vet ASAP.', Icons.medical_services, Colors.purple),
      _FAItem('Fracture', 'Immobilize with a firm splint. Minimize all movement.', Icons.accessibility_new, Colors.blue),
      _FAItem('Snake Bite', 'Keep calm, restrict movement, rush to vet. No tourniquet.', Icons.warning_amber, Colors.red.shade900),
      _FAItem('Eye Infection', 'Flush with clean water. Cover loosely. Avoid sunlight.', Icons.visibility, Colors.teal),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.2))),
        child: const Row(children: [
          Icon(Icons.emergency, color: Colors.red, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text('For life-threatening emergencies, call a vet immediately!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
          ),
        ]),
      ),
      ...tips.map((t) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: t.color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(t.icon, color: t.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, style: TextStyle(fontWeight: FontWeight.bold, color: t.color)),
            const SizedBox(height: 4),
            Text(t.desc, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
          ])),
        ]),
      )),
    ]);
  }
}

class _FAItem {
  final String title, desc;
  final IconData icon;
  final Color color;
  const _FAItem(this.title, this.desc, this.icon, this.color);
}
