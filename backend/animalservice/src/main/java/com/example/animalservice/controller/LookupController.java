package com.example.animalservice.controller;

import com.example.animalservice.model.*;
import com.example.animalservice.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/lookup")
@CrossOrigin(origins = "*")
public class LookupController {

    @Autowired private AnimalSpeciesRepository speciesRepo;
    @Autowired private VaccineTypeRepository vaccineRepo;
    @Autowired private ServiceTypeRepository serviceRepo;
    @Autowired private DistrictRepository districtRepo;

    @GetMapping("/species")
    public List<AnimalSpecies> getSpecies() { return speciesRepo.findAll(); }

    @GetMapping("/vaccines")
    public List<VaccineType> getVaccines(@RequestParam(required = false) String species) {
        if (species != null && !species.isBlank() && !species.equalsIgnoreCase("All")) {
            return vaccineRepo.findByTargetSpeciesContaining(species);
        }
        return vaccineRepo.findAll();
    }

    @GetMapping("/services")
    public List<ServiceType> getServices() { return serviceRepo.findAll(); }

    @GetMapping("/districts")
    public List<District> getDistricts() { return districtRepo.findAll(); }

    @PostMapping("/species")
    public AnimalSpecies addSpecies(@RequestBody AnimalSpecies species) {
        return speciesRepo.save(species);
    }

    @GetMapping("/seed")
    public String seedLookups() {
        if (speciesRepo.count() == 0) {
            speciesRepo.saveAll(List.of(
                new AnimalSpecies("Cow"), new AnimalSpecies("Buffalo"),
                new AnimalSpecies("Goat"), new AnimalSpecies("Sheep"),
                new AnimalSpecies("Chicken"), new AnimalSpecies("Dog"),
                new AnimalSpecies("Cat"), new AnimalSpecies("Turkey")
            ));
        }
        if (vaccineRepo.count() == 0) {
            vaccineRepo.saveAll(List.of(
                // Cattle & Livestock
                new VaccineType("FMD Vaccine", "Foot & Mouth Disease", "Cow,Buffalo,Goat,Sheep",
                    "Every 6 months", "2ml subcutaneous", "Mild swelling at injection site",
                    "Protects against all serotypes of Foot-and-Mouth Disease virus. Essential for livestock herd protection.", "IAH Bengaluru"),
                new VaccineType("Black Quarter (BQ)", "Black Quarter Clostridial Disease", "Cow,Buffalo",
                    "Annual", "1ml subcutaneous", "Rare fever",
                    "Prevents sudden death from clostridial myositis in young cattle.", "IVRI"),
                new VaccineType("Hemorrhagic Septicemia (HS)", "Pasteurellosis", "Cow,Buffalo",
                    "Annual (before monsoon)", "2ml subcutaneous", "Transient fever",
                    "Critical pre-monsoon vaccine for water buffaloes.", "MSD Animal Health"),
                new VaccineType("Brucellosis (S19)", "Brucellosis", "Cow,Buffalo",
                    "Once (3-8 months age)", "5ml subcutaneous", "None significant",
                    "One-time vaccine for female calves preventing reproductive failure.", "IVRI"),
                // Small Ruminants
                new VaccineType("PPR Vaccine", "Peste des Petits Ruminants", "Goat,Sheep",
                    "Every 3 years", "1ml subcutaneous", "Mild local reaction",
                    "Highly effective against the goat plague virus.", "IVRI"),
                new VaccineType("ET Vaccine", "Enterotoxaemia", "Goat,Sheep",
                    "Annual (booster every 6 months)", "2ml subcutaneous", "None significant",
                    "Prevents pulpy kidney disease in small ruminants.", "Indian Immunologicals"),
                // Dogs & Cats
                new VaccineType("Rabies", "Rabies", "Dog,Cat",
                    "Annual", "1ml intramuscular", "Mild lethargy for 1-2 days",
                    "Mandatory zoonotic disease prevention. Protects animals and humans.", "Zoetis"),
                new VaccineType("DHPPiL (5-in-1)", "Distemper, Hepatitis, Parvovirus, Parainfluenza, Leptospirosis", "Dog",
                    "Annual after puppy series", "1ml subcutaneous", "Mild fever possible",
                    "Core canine vaccine covering 5 major diseases.", "Nobivac"),
                new VaccineType("Feline 3-in-1 (FVRCP)", "Rhinotracheitis, Calicivirus, Panleukopenia", "Cat",
                    "Annual after kitten series", "1ml subcutaneous", "Mild lethargy",
                    "Core feline vaccine. Essential for all cats.", "Zoetis"),
                // Poultry
                new VaccineType("Newcastle Disease (ND)", "Newcastle Disease", "Chicken,Turkey",
                    "Every 2-3 months", "Eye drop / drinking water", "None",
                    "Prevents fatal respiratory and neurological disease in poultry.", "Venkys"),
                new VaccineType("Marek's Disease", "Marek's Disease", "Chicken",
                    "Day 1 of life (hatchery)", "0.2ml subcutaneous", "None",
                    "Given at hatchery. Prevents lymphoma in chickens.", "MSD Animal Health"),
                new VaccineType("Infectious Bronchitis (IB)", "Infectious Bronchitis", "Chicken",
                    "Every 8-10 weeks", "Eye drop / drinking water", "None",
                    "Protects respiratory tract in poultry flocks.", "Venkys")
            ));
        }
        if (serviceRepo.count() == 0) {
            serviceRepo.saveAll(List.of(
                new ServiceType("General Consultation"),
                new ServiceType("Vaccination"),
                new ServiceType("Artificial Insemination"),
                new ServiceType("Emergency Surgery"),
                new ServiceType("De-worming")
            ));
        }
        if (districtRepo.count() == 0) {
            districtRepo.saveAll(List.of(
                new District("Pune"), new District("Mumbai"),
                new District("Satara"), new District("Nagpur"),
                new District("Nashik"), new District("Aurangabad"),
                new District("Solapur"), new District("Kolhapur"),
                new District("Sangli"), new District("Ahmednagar")
            ));
        }
        return "Maharashtra-relevant lookups seeded successfully!";
    }
}
