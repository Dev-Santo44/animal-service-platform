import '../services/api_service.dart';
import '../models/vaccine_type.dart';

class LookupService {
  static final LookupService _instance = LookupService._internal();
  factory LookupService() => _instance;
  LookupService._internal();

  List<String> species = [];
  List<String> vaccines = [];
  List<String> services = [];
  List<String> districts = [];

  bool isLoaded = false;

  Future<void> initialize() async {
    final results = await Future.wait([
      ApiService.getSpecies(),
      ApiService.getVaccines(),
      ApiService.getServiceTypes(),
      ApiService.getDistricts(),
    ]);

    species = (results[0] as List).map((e) => e.toString()).toList();
    // results[1] is List<VaccineType>
    final vaccineModels = results[1] as List;
    vaccines = vaccineModels.map((e) {
      if (e is String) return e;
      if (e is VaccineType) return e.name;
      if (e is Map && e.containsKey('name')) return e['name'].toString();
      return e.toString();
    }).toList();

    services = (results[2] as List).map((e) => e.toString()).toList();
    districts = (results[3] as List).map((e) => e.toString()).toList();
    isLoaded = true;
  }
}

// Global instance for easy access
final lookup = LookupService();
