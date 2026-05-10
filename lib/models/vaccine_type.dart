class VaccineTypeModel {
  final int id;
  final String name;
  final String targetDisease;
  final String targetSpecies;
  final String schedule;
  final String dosage;
  final String sideEffects;
  final String description;
  final String manufacturer;

  VaccineTypeModel({
    required this.id,
    required this.name,
    required this.targetDisease,
    required this.targetSpecies,
    required this.schedule,
    required this.dosage,
    required this.sideEffects,
    required this.description,
    required this.manufacturer,
  });

  factory VaccineTypeModel.fromJson(Map<String, dynamic> json) {
    return VaccineTypeModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      targetDisease: json['targetDisease'] ?? '',
      targetSpecies: json['targetSpecies'] ?? '',
      schedule: json['schedule'] ?? '',
      dosage: json['dosage'] ?? '',
      sideEffects: json['sideEffects'] ?? '',
      description: json['description'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetDisease': targetDisease,
    'targetSpecies': targetSpecies,
    'schedule': schedule,
    'dosage': dosage,
    'sideEffects': sideEffects,
    'description': description,
    'manufacturer': manufacturer,
  };
}
