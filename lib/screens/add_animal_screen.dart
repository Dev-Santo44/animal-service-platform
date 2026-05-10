import 'package:flutter/material.dart';
import 'package:animal1/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../services/lookup_service.dart';
import '../theme/app_theme.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();
  final newSpeciesController = TextEditingController();
  String? selectedSpecies;
  bool isLoading = false;
  bool isAddingNewSpecies = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Animal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Animal Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.farmerPrimary)),
              const SizedBox(height: 24),
              _buildTextField(nameController, "Animal Name", Icons.badge_outlined),
              
              const Text("Species", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.farmerPrimary)),
              const SizedBox(height: 8),
              if (!isAddingNewSpecies)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSpecies,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.pets, color: AppTheme.farmerPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: lookup.species.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => selectedSpecies = val),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.farmerPrimary),
                      onPressed: () => setState(() => isAddingNewSpecies = true),
                      tooltip: "Add New Species",
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(newSpeciesController, "Enter New Species (e.g. Rabbit)", Icons.add),
                    ),
                    IconButton(
                      icon: const Icon(Icons.list, color: AppTheme.farmerPrimary),
                      onPressed: () => setState(() => isAddingNewSpecies = false),
                      tooltip: "Select from List",
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              
              _buildTextField(breedController, "Breed (Optional)", Icons.category_outlined),
              _buildTextField(ageController, "Age (Years)", Icons.calendar_month_outlined, keyboardType: TextInputType.number),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveAnimal,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Animal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.farmerPrimary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final user = Session.currentUser;
    String? species = selectedSpecies;
    
    if (isAddingNewSpecies && newSpeciesController.text.isNotEmpty) {
      final success = await ApiService.addSpecies(newSpeciesController.text);
      if (success) {
        species = newSpeciesController.text;
        // Update local lookup list
        if (!lookup.species.contains(species)) {
          lookup.species.add(species);
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add new species")));
        }
        return;
      }
    }

    final success = await ApiService.addAnimal({
      "ownerEmail": user!['email'],
      "name": nameController.text,
      "species": species,
      "breed": breedController.text,
      "age": int.tryParse(ageController.text) ?? 0,
    });

    if (mounted) {
      setState(() => isLoading = false);
      if (success != null) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save animal")));
      }
    }
  }
}
