import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../models/vaccine_type.dart';

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

  // F5 — Species & Vaccine dropdowns
  String? _selectedSpecies;
  VaccineTypeModel? _selectedVaccine;
  List<String> _speciesList = ['Cow', 'Buffalo', 'Goat', 'Sheep', 'Dog', 'Cat', 'Chicken', 'Turkey'];
  List<VaccineTypeModel> _vaccines = [];
  bool _loadingVaccines = false;

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
    final species = await ApiService.getSpecies();
    if (mounted) setState(() => _speciesList = species.isNotEmpty ? species : _speciesList);
  }

  Future<void> _onSpeciesChanged(String? species) async {
    if (species == null) return;
    setState(() {
      _selectedSpecies = species;
      _selectedVaccine = null;
      _loadingVaccines = true;
    });
    final vaccines = await ApiService.getVaccines(species: species);
    if (mounted) {
      setState(() {
        _vaccines = vaccines;
        _loadingVaccines = false;
      });
    }
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

  // F5 — Learn More modal
  void _showVaccineDetails(VaccineTypeModel vaccine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.vaccines, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(vaccine.name,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _infoRow(Icons.bug_report_outlined, "Target Disease", vaccine.targetDisease),
                _infoRow(Icons.pets, "Species", vaccine.targetSpecies.replaceAll(',', ', ')),
                _infoRow(Icons.repeat, "Schedule", vaccine.schedule),
                _infoRow(Icons.science_outlined, "Dosage", vaccine.dosage),
                _infoRow(Icons.warning_amber_outlined, "Side Effects", vaccine.sideEffects),
                _infoRow(Icons.business, "Manufacturer", vaccine.manufacturer),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("About",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(vaccine.description,
                          style: const TextStyle(color: Colors.black87, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
      appBar: AppBar(title: Text(l.addVaccination)),
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

                    // F5: Step 1 — Species selector
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSpecies,
                        decoration: const InputDecoration(
                          labelText: "Animal Species",
                          prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryColor),
                        ),
                        hint: const Text("Select species"),
                        items: _speciesList.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        )).toList(),
                        onChanged: _onSpeciesChanged,
                        validator: (v) => v == null ? "Please select species" : null,
                      ),
                    ),

                    // F5: Step 2 — Vaccine selector (populated after species)
                    if (_selectedSpecies != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _loadingVaccines
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<VaccineTypeModel>(
                                value: _selectedVaccine,
                                decoration: const InputDecoration(
                                  labelText: "Vaccine",
                                  prefixIcon: Icon(Icons.vaccines_outlined, color: AppTheme.primaryColor),
                                ),
                                hint: const Text("Select vaccine"),
                                items: _vaccines.map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v.name),
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
