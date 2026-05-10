class VaccineType {
  final int id;
  final String name;
  final String? diseasePrevented;
  final String? targetAnimals;
  final String? coreStatus;
  final bool? isZoonotic;
  final String? pathogenName;
  final String? pathogenType;
  final String? mechanismOfAction;
  final String? whyVaccinate;
  final String? whoIsAffected;
  final String? schedule;
  final String? immunityDuration;
  final String? routeOfAdmin;
  final String? sideEffects;
  final String? legalStatus;

  const VaccineType({
    required this.id,
    required this.name,
    this.diseasePrevented,
    this.targetAnimals,
    this.coreStatus,
    this.isZoonotic,
    this.pathogenName,
    this.pathogenType,
    this.mechanismOfAction,
    this.whyVaccinate,
    this.whoIsAffected,
    this.schedule,
    this.immunityDuration,
    this.routeOfAdmin,
    this.sideEffects,
    this.legalStatus,
  });

  bool get isCore     => coreStatus?.toLowerCase() == 'core';
  bool get isZoonoticRisk => isZoonotic == true;

  factory VaccineType.fromJson(Map<String, dynamic> j) => VaccineType(
    id:                 j['id'] ?? 0,
    name:               j['name'] ?? '',
    diseasePrevented:   j['diseasePrevented'],
    targetAnimals:      j['targetAnimals'],
    coreStatus:         j['coreStatus'],
    isZoonotic:         j['isZoonotic'],
    pathogenName:       j['pathogenName'],
    pathogenType:       j['pathogenType'],
    mechanismOfAction:  j['mechanismOfAction'],
    whyVaccinate:       j['whyVaccinate'],
    whoIsAffected:      j['whoIsAffected'],
    schedule:           j['schedule'],
    immunityDuration:   j['immunityDuration'],
    routeOfAdmin:       j['routeOfAdmin'],
    sideEffects:        j['sideEffects'],
    legalStatus:        j['legalStatus'],
  );
}

class VaccineGlossaryTerm {
  final int id;
  final String term;
  final String definition;

  const VaccineGlossaryTerm({
    required this.id,
    required this.term,
    required this.definition,
  });

  factory VaccineGlossaryTerm.fromJson(Map<String, dynamic> j) =>
      VaccineGlossaryTerm(
        id:         j['id'] ?? 0,
        term:       j['term'] ?? '',
        definition: j['definition'] ?? '',
      );
}
