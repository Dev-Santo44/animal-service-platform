import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../models/vaccine_type.dart';
import '../constants/species_list.dart';
import 'vaccine_glossary_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AddVaccinationScreen extends StatefulWidget {
  final int? animalId;
  final String? animalName;

  const AddVaccinationScreen({super.key, this.animalId, this.animalName});

  @override
  State<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends State<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _animalController = TextEditingController();
  final TextEditingController _dateGivenController = TextEditingController();
  final TextEditingController _nextDueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  int? _selectedAnimalId;

  // F5 — Species & Vaccine dropdowns (Updated for Dataset Integration)
  String? _selectedSpecies;
  VaccineType? _selectedVaccine;
  List<VaccineType> _vaccines = [];
  bool _loadingVaccines = false;
  String _coreFilter = ''; // '', 'Core', 'Non-core'


  @override
  void initState() {
    super.initState();
    if (widget.animalName != null) {
      _animalController.text = widget.animalName!;
    }
    _selectedAnimalId = widget.animalId;
    _loadSpecies();
  }

  Future<void> _loadSpecies() async {
    // We use the static kSpeciesList now
  }


  Future<void> _onSpeciesChanged(String? species) async {
    if (species == null) return;
    setState(() {
      _selectedSpecies = species;
      _selectedVaccine = null;
    });
    _loadVaccines(species: species, coreStatus: _coreFilter);
  }

  Future<void> _loadVaccines({String species = '', String coreStatus = ''}) async {
    setState(() => _loadingVaccines = true);
    try {
      final vaccines = await ApiService.getVaccines(species: species, coreStatus: coreStatus);
      if (mounted) {
        setState(() {
          _vaccines = vaccines;
          _selectedVaccine = null;
          _loadingVaccines = false;
        });
      }
    } catch (_) { 
      if (mounted) setState(() => _loadingVaccines = false); 
    }
  }

  List<VaccineType> get _sortedVaccines {
    final core    = _vaccines.where((v) => v.isCore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    final nonCore = _vaccines.where((v) => !v.isCore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    return [...core, ...nonCore];
  }


  Future<void> _selectDate(BuildContext context, TextEditingController controller,
      {DateTime? firstDate, DateTime? lastDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toString().split(' ')[0];
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVaccine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a vaccine")));
      return;
    }

    setState(() => _isLoading = true);
    final user = Session.currentUser;

    final record = {
      "ownerEmail": user!['email'],
      "animalName": _animalController.text,
      "vaccineName": _selectedVaccine!.name,
      "dateGiven": _dateGivenController.text.isEmpty ? null : _dateGivenController.text,
      "nextDueDate": _nextDueController.text.isEmpty ? null : _nextDueController.text,
      "notes": _notesController.text,
      "status": _dateGivenController.text.isNotEmpty ? "COMPLETED" : "UPCOMING",
      "providerEmail": user['role'] == 'Doctor' ? user['email'] : null,
    };

    if (_selectedAnimalId != null) {
      await ApiService.addAnimalVaccination(_selectedAnimalId!, record);
    } else {
      await ApiService.addVaccinationRecord(
        ownerEmail: user['email'],
        animal: _animalController.text,
        vaccine: _selectedVaccine!.name,
        dateGiven: _dateGivenController.text,
        nextDueDate: _nextDueController.text,
        status: _dateGivenController.text.isNotEmpty ? "COMPLETED" : "UPCOMING",
        notes: _notesController.text,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  // F5 — Learn More modal (4-tab version)
  void _showVaccineDetails(VaccineType v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle bar
            Center(child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            )),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.vaccines, color: Color(0xFF2D6A4F), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  if (v.diseasePrevented != null)
                    Text(v.diseasePrevented!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ])),
                // Badges
                Column(children: [
                  _VaccineBadge(label: v.coreStatus ?? 'Unknown', isCore: v.isCore),
                  if (v.isZoonoticRisk) const SizedBox(height: 4),
                  if (v.isZoonoticRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('⚠️ Zoonotic', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Tabbed content
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(children: [
                  const TabBar(
                    labelColor: Color(0xFF2D6A4F),
                    indicatorColor: Color(0xFF2D6A4F),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Schedule'),
                      Tab(text: 'Science'),
                      Tab(text: 'Safety'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(children: [

                      // Tab 1 — OVERVIEW
                      _ModalScrollView(children: [
                        _InfoSection('Why Vaccinate', v.whyVaccinate),
                        _InfoSection('Who Is Affected', v.whoIsAffected),
                        _InfoSection('Target Animals', v.targetAnimals),
                        _InfoSection('Legal / Regulatory Status', v.legalStatus),
                      ]),

                      // Tab 2 — SCHEDULE
                      _ModalScrollView(children: [
                        _InfoSection('Vaccination Schedule', v.schedule),
                        _InfoSection('Duration of Immunity', v.immunityDuration),
                        _InfoSection('Route of Administration', v.routeOfAdmin),
                      ]),

                      // Tab 3 — SCIENCE
                      _ModalScrollView(children: [
                        _InfoSection('Pathogen', v.pathogenName),
                        _InfoSection('Pathogen Type', v.pathogenType),
                        _InfoSection('Mechanism of Action', v.mechanismOfAction),
                      ]),

                      // Tab 4 — SAFETY
                      _ModalScrollView(children: [
                        if (v.isZoonoticRisk)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'This is a zoonotic disease — it can be transmitted to humans. Vaccinating your animal also protects your family.',
                                  style: TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ]),
                          ),
                        _InfoSection('Side Effects', v.sideEffects),
                        _InfoSection('Legal Status', v.legalStatus),
                      ]),

                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }


  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.addVaccination),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Vaccination Glossary',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VaccineGlossaryScreen()),
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildTextField(
                        _animalController, l.animalName, Icons.pets_outlined,
                        enabled: widget.animalId == null),

                    // F5: Step 1 — Species selector (with emojis)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSpecies,
                        decoration: const InputDecoration(
                          labelText: "Animal Species",
                          prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryColor),
                        ),
                        hint: const Text("Select species"),
                        items: kSpeciesList.map((s) => DropdownMenuItem(
                          value: s['value'],
                          child: Row(children: [
                            Text(s['emoji']!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(s['label']!),
                          ]),
                        )).toList(),
                        onChanged: _onSpeciesChanged,
                        validator: (v) => v == null ? "Please select species" : null,
                      ),
                    ),

                    // F5: Step 2 — Vaccine selector (with filtering and badges)
                    if (_selectedSpecies != null) ...[
                      // Core / Non-core toggle filter
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          const Text('Show:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(width: 10),
                          _CoreFilterChip(
                            label: 'All', 
                            selected: _coreFilter == '', 
                            onTap: () { 
                              setState(() => _coreFilter = ''); 
                              _loadVaccines(species: _selectedSpecies!); 
                            }
                          ),
                          const SizedBox(width: 6),
                          _CoreFilterChip(
                            label: '✅ Core', 
                            selected: _coreFilter == 'Core', 
                            onTap: () { 
                              setState(() => _coreFilter = 'Core'); 
                              _loadVaccines(species: _selectedSpecies!, coreStatus: 'Core'); 
                            }
                          ),
                          const SizedBox(width: 6),
                          _CoreFilterChip(
                            label: '🔔 Non-core', 
                            selected: _coreFilter == 'Non-core', 
                            onTap: () { 
                              setState(() => _coreFilter = 'Non-core'); 
                              _loadVaccines(species: _selectedSpecies!, coreStatus: 'Non-core'); 
                            }
                          ),
                        ]),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _loadingVaccines
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<VaccineType>(
                                value: _selectedVaccine,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Vaccine",
                                  prefixIcon: Icon(Icons.vaccines_outlined, color: AppTheme.primaryColor),
                                ),
                                hint: const Text("Select vaccine"),
                                items: _sortedVaccines.map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Row(children: [
                                    // Core badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: v.isCore
                                            ? const Color(0xFF2D6A4F).withOpacity(0.15)
                                            : Colors.orange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        v.isCore ? 'Core' : 'Non-core',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: v.isCore ? const Color(0xFF2D6A4F) : Colors.orange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(v.name, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14)),
                                    ),
                                    // Zoonotic warning
                                    if (v.isZoonoticRisk)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.warning_amber, color: Colors.red, size: 14),
                                      ),
                                  ]),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedVaccine = v),
                                validator: (v) => v == null ? "Please select vaccine" : null,
                              ),
                      ),


                      // F5: Step 3 — Learn More button
                      if (_selectedVaccine != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextButton.icon(
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text("Learn More"),
                            onPressed: () => _showVaccineDetails(_selectedVaccine!),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerField(
                              _dateGivenController, l.dateGiven,
                              Icons.calendar_today, context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDatePickerField(
                              _nextDueController, l.nextDueDate,
                              Icons.event_repeat, context, isFuture: true),
                        ),
                      ],
                    ),

                    _buildTextField(_notesController, "Notes (Optional)",
                        Icons.note_alt_outlined, maxLines: 3),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(l.save,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, {bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildDatePickerField(TextEditingController controller, String label,
      IconData icon, BuildContext context, {bool isFuture = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onTap: () => _selectDate(context, controller,
          firstDate: isFuture ? DateTime.now() : DateTime(2000),
          lastDate: isFuture
              ? DateTime.now().add(const Duration(days: 365 * 5))
              : DateTime.now(),
        ),
      ),
    );
  }
}

// ── NEW HELPER WIDGETS ──────────────────────────────────────────────────────

class _CoreFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CoreFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D6A4F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF2D6A4F) : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, color: selected ? Colors.white : Colors.grey[700],
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoSection(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            color: Color(0xFF2D6A4F), letterSpacing: 0.8)),
        const SizedBox(height: 5),
        Text(value!, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.55)),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ]),
    );
  }
}

class _ModalScrollView extends StatelessWidget {
  final List<Widget> children;
  const _ModalScrollView({required this.children});
  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
}

class _VaccineBadge extends StatelessWidget {
  final String label;
  final bool isCore;
  const _VaccineBadge({required this.label, required this.isCore});
  @override
  Widget build(BuildContext context) {
    final color = isCore ? const Color(0xFF2D6A4F) : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

