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
    @Autowired private VaccineGlossaryRepository glossaryRepo;

    @GetMapping("/species")
    public List<AnimalSpecies> getSpecies() { return speciesRepo.findAll(); }

    @GetMapping("/vaccines")
    public List<VaccineType> getVaccines(
            @RequestParam(required = false) String species,
            @RequestParam(required = false) String coreStatus) {

        if (species != null && coreStatus != null) {
            return vaccineRepo.findBySpeciesAndCoreStatus(species, coreStatus);
        } else if (species != null) {
            return vaccineRepo.findBySpecies(species);
        } else if (coreStatus != null) {
            return vaccineRepo.findByCoreStatus(coreStatus);
        }
        return vaccineRepo.findAll();
    }

    @GetMapping("/glossary")
    public List<VaccineGlossary> getGlossary(
            @RequestParam(required = false) String search) {
        if (search != null && !search.isBlank()) {
            return glossaryRepo.findByTermContainingIgnoreCase(search);
        }
        return glossaryRepo.findAll();
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

        // Clear old incomplete vaccine records (they'll be replaced by full seed)
        // Only if we haven't seeded the full set yet
        if (vaccineRepo.count() < 28) {
            vaccineRepo.deleteAll();
            vaccineRepo.saveAll(List.of(

                // ── CROSS-SPECIES ──────────────────────────────────────────────────────
                new VaccineType(
                    "Rabies vaccine",
                    "Rabies",
                    "Dogs, Cats, Horses, Cattle, Pigs, Rabbits, Exotic, Wildlife",
                    "Core", true,
                    "Rabies lyssavirus",
                    "RNA virus – Lyssavirus, Rhabdoviridae",
                    "Stimulates virus-neutralising antibodies via killed/inactivated or recombinant canarypox-vector vaccine; prevents viral replication in neural tissue.",
                    "100% fatal once clinical signs appear. Primary zoonotic risk — dogs responsible for 99% of human cases worldwide. Legally mandated in most countries.",
                    "All warm-blooded animals; dogs are main reservoir for human transmission.",
                    "First dose at 12–16 weeks; booster at 1 year; then every 1–3 years.",
                    "1–3 years (product/regulation dependent)",
                    "Subcutaneous (SC) or intramuscular (IM) injection",
                    "Mild soreness at injection site, low-grade fever, lethargy 1–2 days. Rare: hypersensitivity.",
                    "Legally mandated for dogs in most countries; required for cats and horses in many jurisdictions."
                ),

                // ── DOGS ──────────────────────────────────────────────────────────────
                new VaccineType(
                    "Canine distemper vaccine (CDV)",
                    "Canine distemper",
                    "Dogs, Wildlife, Exotic carnivores",
                    "Core", false,
                    "Canine morbillivirus",
                    "RNA virus – Paramyxoviridae",
                    "Modified live virus (MLV) or recombinant vaccine; generates cell-mediated and humoral immunity against viral envelope proteins.",
                    "Highly contagious multi-systemic disease (respiratory, GI, nervous system). Case fatality up to 80% in unvaccinated puppies.",
                    "Dogs, ferrets, foxes, wolves, lions, seals — nearly all carnivores.",
                    "Puppies: 6–8, 10–12, 14–16 weeks. Booster at 1 year, then every 3 years.",
                    "3 years after complete series + booster",
                    "Subcutaneous injection (part of DA2PP/DHPPi combo)",
                    "Mild fever, lethargy, anorexia. Rare: vaccine-induced distemper in immunocompromised animals.",
                    "Highly recommended; legally mandated in some jurisdictions."
                ),

                new VaccineType(
                    "Canine parvovirus vaccine (CPV-2)",
                    "Canine parvoviral enteritis",
                    "Dogs",
                    "Core", false,
                    "Canine parvovirus type 2",
                    "ssDNA virus – Parvoviridae",
                    "MLV vaccine produces robust humoral immunity targeting VP2 capsid protein; neutralising antibodies prevent viral entry into intestinal crypt cells.",
                    "Mortality up to 91% in untreated puppies. Severe haemorrhagic gastroenteritis and bone marrow suppression. Virus persists in environment for months.",
                    "All dogs, especially unvaccinated puppies 6 weeks–6 months; also wolves, coyotes.",
                    "Puppies: 6–8, 10–12, 14–16 weeks. Booster at 1 year, then every 3 years.",
                    "3+ years with full series",
                    "Subcutaneous injection (combined in DA2PP)",
                    "Mild GI upset; rarely post-vaccination diarrhoea.",
                    "Strongly recommended; considered essential worldwide."
                ),

                new VaccineType(
                    "Canine hepatitis vaccine (CAV-2)",
                    "Infectious canine hepatitis",
                    "Dogs",
                    "Core", false,
                    "Canine adenovirus type 1",
                    "dsDNA virus – Adenoviridae",
                    "Cross-protective CAV-2 vaccine stimulates antibodies against CAV-1; prevents viral replication in hepatocytes and endothelial cells.",
                    "Can cause severe liver failure, corneal oedema ('blue eye'), haemorrhage and death. Vaccine provides lifelong protection in many dogs.",
                    "Dogs, foxes, wolves, bears.",
                    "Same puppy series as distemper/parvo (included in DA2PP combo).",
                    "3+ years",
                    "Subcutaneous injection",
                    "Rare: transient 'blue eye' (corneal oedema) with CAV-1; CAV-2 avoids this.",
                    "Core — included in standard combination vaccines."
                ),

                new VaccineType(
                    "Leptospirosis vaccine",
                    "Leptospirosis",
                    "Dogs, Cattle, Pigs, Horses",
                    "Non-core", true,
                    "Leptospira interrogans",
                    "Spirochete bacterium – multiple serovars",
                    "Bacterin (killed whole-cell) vaccine; produces serovar-specific antibody response. Modern 4-way vaccines cover serovars Canicola, Icterohaemorrhagiae, Grippotyphosa, Pomona.",
                    "Causes kidney/liver failure and pulmonary haemorrhage. Highly zoonotic via contaminated water/urine. Common in tropical/subtropical regions. Rats are main reservoir.",
                    "Dogs with outdoor/water exposure; livestock; humans.",
                    "Initial 2-dose series 3–4 weeks apart. Annual booster required.",
                    "12 months — must be given annually",
                    "Subcutaneous injection",
                    "More likely to cause vaccine reactions than core vaccines; hypersensitivity possible.",
                    "Non-core; recommended based on lifestyle/geography risk."
                ),

                new VaccineType(
                    "Bordetella (kennel cough) vaccine",
                    "Infectious tracheobronchitis (kennel cough)",
                    "Dogs, Cats",
                    "Non-core", false,
                    "Bordetella bronchiseptica ± canine parainfluenza virus",
                    "Gram-negative bacterium ± RNA paramyxovirus",
                    "Mucosal intranasal live attenuated or injectable killed bacterin; intranasal generates local IgA at respiratory mucosa within 72 hours — faster than injectable.",
                    "Highly contagious respiratory disease spread by aerosol. Common in kennels, shelters, dog parks. Rarely fatal but causes prolonged cough.",
                    "Dogs in social/high-density environments. Cats in shelters. Humans rarely (immunocompromised).",
                    "Intranasal: single dose ≥72 hours before exposure. Injectable: 2 doses + annual booster.",
                    "12 months (some intranasal products effective 6 months)",
                    "Intranasal drops (preferred for speed) or subcutaneous injection",
                    "Intranasal: transient coughing/sneezing post-vaccination.",
                    "Required by most kennels, groomers, and doggy daycares."
                ),

                new VaccineType(
                    "Canine influenza vaccine (CIV)",
                    "Canine influenza (dog flu)",
                    "Dogs",
                    "Non-core", false,
                    "Canine influenza virus H3N8 and H3N2",
                    "RNA virus – Orthomyxoviridae",
                    "Bivalent killed virus vaccine covering both H3N8 (equine origin) and H3N2 (avian origin) strains; reduces severity and viral shedding.",
                    "Highly contagious respiratory disease in dogs. Two distinct strains circulate. H3N2 has crossed to cats. Does not currently infect humans significantly.",
                    "Dogs in high-density environments (kennels, shows, daycares). Cats potentially (H3N2).",
                    "2-dose primary series 2–4 weeks apart; annual booster.",
                    "12 months",
                    "Subcutaneous injection",
                    "Mild injection site reaction; transient lethargy.",
                    "Non-core; recommended for at-risk dogs in endemic regions."
                ),

                new VaccineType(
                    "Rattlesnake vaccine (dog)",
                    "Crotalus atrox venom toxicosis",
                    "Dogs",
                    "Non-core", false,
                    "Crotalus atrox venom",
                    "Complex of enzymes, cytotoxins and haemotoxins — not an infectious pathogen",
                    "Killed venom antigen vaccine; generates antibodies against venom components; reduces severity of envenomation — not a replacement for antivenom.",
                    "Snake bites common in dogs in western USA. Can cause severe tissue necrosis, coagulopathy, death. Vaccine reduces severity and buys time to reach veterinary care.",
                    "Dogs in western USA rattlesnake habitats. Cats anecdotally less responsive.",
                    "2-dose primary series 4 weeks apart; annual booster before snake season.",
                    "12 months",
                    "Subcutaneous injection",
                    "Injection site swelling; not a substitute for emergency antivenom treatment.",
                    "Non-core; lifestyle vaccine for at-risk dogs."
                ),

                // ── CATS ──────────────────────────────────────────────────────────────
                new VaccineType(
                    "Feline panleukopenia vaccine (FPV)",
                    "Feline panleukopenia (feline parvovirus)",
                    "Cats, Exotic felids",
                    "Core", false,
                    "Feline parvovirus",
                    "ssDNA virus – Parvoviridae",
                    "MLV or killed vaccine; induces neutralising antibodies against VP2 capsid protein; prevents destruction of bone marrow stem cells and intestinal crypts.",
                    "Mortality can reach 90% in kittens. Causes severe leukopenia, GI signs, and cerebellar hypoplasia in neonates.",
                    "All cats, all felids (lions, tigers, leopards), mink, raccoons.",
                    "Kittens: 6–8, 10–12, 14–16 weeks. 1-year booster, then every 3 years.",
                    "3 years after complete series",
                    "Subcutaneous injection (part of FVRCP combo)",
                    "Mild lethargy and fever; MLV contraindicated in pregnant queens.",
                    "Core — universally recommended."
                ),

                new VaccineType(
                    "Feline herpesvirus + calicivirus vaccine (FHV-1/FCV)",
                    "Feline upper respiratory disease",
                    "Cats",
                    "Core", false,
                    "Feline herpesvirus type 1 + Feline calicivirus",
                    "dsDNA (FHV-1) + ssRNA (FCV) – Herpesviridae / Caliciviridae",
                    "Combined vaccine induces humoral immunity; reduces severity and duration. FHV-1 causes lifelong latent infection with stress-induced recurrence.",
                    "Major cause of feline URI — conjunctivitis, nasal discharge, oral ulcers. Common in multi-cat households and shelters.",
                    "All cats, especially those in multi-cat households or shelters.",
                    "Kittens: 6–8, 10–12, 14–16 weeks. Annual or 3-year booster (FVRCP combo).",
                    "1–3 years depending on product and lifestyle",
                    "SC injection; intranasal products available",
                    "Intranasal: mild sneezing; injectable: mild soreness.",
                    "Core."
                ),

                new VaccineType(
                    "Feline leukemia virus vaccine (FeLV)",
                    "Feline leukemia",
                    "Cats",
                    "Non-core", false,
                    "Feline leukemia virus",
                    "ssRNA retrovirus – Retroviridae",
                    "Recombinant or inactivated subunit vaccine targeting FeLV envelope glycoprotein (gp70) to induce virus-neutralising antibodies.",
                    "Leading cause of cancer-related death in cats. Causes immunosuppression, lymphoma, anaemia. Transmitted via saliva/close contact.",
                    "Outdoor/indoor-outdoor cats, multi-cat households, kittens (most susceptible).",
                    "2-dose primary series 3–4 weeks apart from 8 weeks old; annual booster.",
                    "1 year — annual boosters required",
                    "Subcutaneous injection — left rear leg (tumour tracking protocol)",
                    "Vaccine-associated sarcoma (rare ~1:10,000). Injection site inflammation.",
                    "Non-core; recommended for at-risk cats."
                ),

                new VaccineType(
                    "Feline immunodeficiency virus vaccine (FIV)",
                    "Feline immunodeficiency (feline AIDS)",
                    "Cats",
                    "Non-core", false,
                    "Feline immunodeficiency virus",
                    "ssRNA lentivirus – Retroviridae",
                    "Dual-subtype killed whole-virus vaccine targeting multiple FIV clades; generates humoral and cell-mediated immunity; cross-subtype protection variable.",
                    "Progressive T-cell depletion leading to AIDS-like immunodeficiency; opportunistic infections and cancer. No cure. Transmitted by bite wounds.",
                    "All cats; especially intact male outdoor cats. Bite-wound transmission only.",
                    "3-dose primary series at 3-week intervals from 8 weeks old; annual booster.",
                    "12 months",
                    "Subcutaneous injection",
                    "Vaccination causes positive ELISA test — interferes with FIV antibody diagnostics.",
                    "Non-core. Limited availability; withdrawn in some markets."
                ),

                // ── CATTLE ────────────────────────────────────────────────────────────
                new VaccineType(
                    "Foot-and-mouth disease vaccine (FMD)",
                    "Foot-and-mouth disease",
                    "Cattle, Sheep, Pigs, Horses",
                    "Core", true,
                    "Foot-and-mouth disease virus",
                    "ssRNA virus – Aphthovirus, Picornaviridae (7 serotypes: A, O, C, SAT1, SAT2, SAT3, Asia1)",
                    "Inactivated (BEI-treated) oil-adjuvanted vaccine; generates neutralising antibodies; must match circulating serotype.",
                    "Economically devastating; causes fever and vesicles on hooves/mouth/teats. Spreads extremely rapidly. Major trade restriction trigger.",
                    "Cloven-hoofed animals: cattle, pigs, sheep, goats, deer, buffalo. Rare human cases.",
                    "Annual vaccination in endemic regions; emergency vaccination in outbreaks.",
                    "4–6 months — bi-annual or annual boosters required",
                    "Intramuscular injection",
                    "Injection site swelling; anaphylaxis rare.",
                    "Mandatory in endemic countries; banned in FMD-free zones (USA, Australia, UK)."
                ),

                new VaccineType(
                    "Bovine respiratory disease vaccines (IBR/BVD/PI3/BRSV)",
                    "Bovine respiratory disease complex (shipping fever)",
                    "Cattle",
                    "Core", false,
                    "BoHV-1 (IBR), BVD pestivirus, PI3, BRSV",
                    "Multiple RNA/DNA viruses – combination vaccines",
                    "MLV or killed combination vaccines target surface antigens of each virus; reduce viral shedding and severity. BVD vaccines prevent persistent infection (PI) in calves.",
                    "Leading cause of morbidity/mortality in feedlot cattle. BVD causes immunosuppression and reproductive failure. Costs billions annually.",
                    "Cattle of all ages, especially calves and feedlot animals; bison.",
                    "Calves: pre-weaning + booster at weaning/shipping. Annual boosters for cows.",
                    "6–12 months depending on product",
                    "Subcutaneous or intramuscular injection",
                    "Mild fever, reduced milk production transiently. MLV: do not use in pregnant cows.",
                    "Widely recommended; some components required in commercial programs."
                ),

                new VaccineType(
                    "Brucellosis vaccine (RB51 / S19)",
                    "Brucellosis (undulant fever)",
                    "Cattle, Sheep",
                    "Core", true,
                    "Brucella abortus / B. melitensis",
                    "Intracellular bacterium – Brucellaceae",
                    "Live attenuated strain (RB51 or S19) vaccine; stimulates cell-mediated immunity; reduces shedding and abortion storms.",
                    "Causes reproductive failure (abortions, retained placentas) in livestock. Highly zoonotic — causes Malta fever in humans via raw milk or direct contact.",
                    "Cattle, bison, elk (wildlife reservoirs). Sheep and goats. Humans.",
                    "Heifers: one dose at 4–12 months. Not given to adult cattle routinely.",
                    "Lifelong protection in most animals after single dose",
                    "Subcutaneous injection by licensed veterinarians only",
                    "RB51 is rifampin-resistant — strict handling protocols required for human safety.",
                    "USDA-mandated calfhood vaccination in many US states. Part of national eradication programs."
                ),

                new VaccineType(
                    "Clostridial disease vaccines (livestock)",
                    "Blackleg, pulpy kidney, enterotoxaemia, black disease, tetanus",
                    "Cattle, Sheep, Goats",
                    "Core", false,
                    "Multiple Clostridium spp. (C. chauvoei, C. perfringens C & D, C. haemolyticum, C. novyi, C. tetani)",
                    "Gram-positive spore-forming bacteria – Clostridiaceae",
                    "Bacterin-toxoid combination generating antitoxin antibodies against exotoxins (epsilon, beta, alpha toxins). Multi-way formulations protect against 7–8 diseases simultaneously.",
                    "Sudden death syndromes — animals often found dead without warning. Grain overeating, lush pasture trigger disease. Economically devastating in sheep and cattle.",
                    "Cattle, sheep, goats. Some species affect horses. Humans: C. perfringens food poisoning.",
                    "Lambs/calves: 2-dose primary + annual booster. Ewes/cows: booster 4–6 weeks pre-lambing/calving for maternal immunity transfer.",
                    "12 months",
                    "Subcutaneous injection",
                    "Local swelling (up to 10 cm in sheep); anaphylaxis rare.",
                    "Core globally for sheep and cattle production."
                ),

                new VaccineType(
                    "Anthrax vaccine (livestock / wildlife)",
                    "Anthrax",
                    "Cattle, Sheep, Horses, Wildlife",
                    "Core", true,
                    "Bacillus anthracis",
                    "Gram-positive spore-forming aerobic bacterium – Bacillaceae",
                    "Sterne-strain live spore vaccine; induces antibodies against protective antigen (PA) component of anthrax toxin complex.",
                    "Causes peracute-to-acute fatal septicaemia. Spores persist in soil for decades. Highly zoonotic — cutaneous, pulmonary, and GI anthrax in humans. Bioterrorism concern.",
                    "Grazing animals (cattle, sheep, horses, bison) in endemic soil zones. Humans via contact/inhalation.",
                    "Annual vaccination 2–4 weeks before at-risk season in endemic areas.",
                    "12 months",
                    "Subcutaneous injection; must not be given with antibiotics",
                    "Local swelling; systemic reactions possible. Sterne strain mildly virulent.",
                    "Required in endemic areas. Regulated biological — veterinarian administration only."
                ),

                // ── HORSES ────────────────────────────────────────────────────────────
                new VaccineType(
                    "Equine influenza vaccine",
                    "Equine influenza",
                    "Horses",
                    "Core", false,
                    "Equine influenza virus H3N8 and H7N7",
                    "RNA virus – Orthomyxoviridae",
                    "Inactivated whole-virus or subunit (hemagglutinin-based) vaccine; generates antibodies to H and N surface proteins; reduces viral shedding and severity.",
                    "Highly contagious via aerosol; can shut down racing/competition yards entirely. Strains drift, requiring updated vaccines periodically.",
                    "All horses, donkeys, mules. Performance horses at highest risk.",
                    "Primary 2-dose series 4–6 weeks apart. Booster at 6 months, then every 6–12 months.",
                    "6–12 months (competition horses every 6 months)",
                    "Intramuscular injection; intranasal MLV available",
                    "Mild swelling/stiffness at injection site; transient fever.",
                    "Required for many equine competitions worldwide (FEI regulations)."
                ),

                new VaccineType(
                    "Tetanus toxoid (equine / livestock)",
                    "Tetanus (lockjaw)",
                    "Horses, Cattle, Sheep, Dogs, Cats",
                    "Core", false,
                    "Clostridium tetani",
                    "Gram-positive spore-forming bacterium – Clostridiaceae",
                    "Formalin-inactivated toxoid; generates antitoxin antibodies (IgG) that neutralise tetanospasmin before it binds irreversibly to neural tissue.",
                    "Near 100% fatal in horses once signs appear. Entry through wounds, castration sites, hoof injuries. Horses uniquely susceptible.",
                    "Horses most susceptible. All mammals at risk after wound contamination. Humans also affected.",
                    "2-dose primary series 4–6 weeks apart; annual booster; wound booster if >6 months since last dose.",
                    "12 months routine; immediate wound booster if injury occurs",
                    "Intramuscular injection",
                    "Local swelling, stiffness; anaphylaxis very rare.",
                    "Core for horses worldwide. Included in multi-way equine vaccines."
                ),

                new VaccineType(
                    "West Nile virus vaccine (equine)",
                    "West Nile virus encephalitis",
                    "Horses, Exotic animals",
                    "Core", true,
                    "West Nile virus",
                    "ssRNA flavivirus – Flaviviridae (mosquito-borne)",
                    "Killed virus or recombinant canarypox-vectored vaccine (ALVAC) targeting WNV envelope protein; prevents viral neuroinvasion causing encephalitis.",
                    "Causes fatal neurological disease (encephalomyelitis) in horses. Birds are reservoir hosts; mosquito-borne. Zoonotic risk to humans.",
                    "Horses. Humans (via mosquitoes). Birds (corvids especially). Some reptiles.",
                    "2-dose primary 4–6 weeks apart; annual booster before mosquito season.",
                    "12 months",
                    "Intramuscular injection",
                    "Mild injection site swelling; fever.",
                    "Core in WNV-endemic areas (USA, Europe, Middle East, Africa)."
                ),

                // ── POULTRY ───────────────────────────────────────────────────────────
                new VaccineType(
                    "Newcastle disease vaccine (NDV)",
                    "Newcastle disease (fowl pest)",
                    "Poultry, Chickens, Turkeys, Ducks",
                    "Core", true,
                    "Avian paramyxovirus type 1 (APMV-1)",
                    "RNA virus – Paramyxoviridae (lentogenic/mesogenic/velogenic pathotypes)",
                    "Live attenuated (La Sota, B1, VG/GA strains) or inactivated oil-emulsion vaccines; mucosal IgA + systemic antibodies block attachment at respiratory/GI epithelium.",
                    "Velogenic ND is OIE-listed. Kills up to 100% of susceptible flocks within days. Causes respiratory, nervous, and GI signs. Huge economic impact.",
                    "Chickens, turkeys, ducks, geese, ostriches, pet birds, wild birds.",
                    "Broilers: eye-drop/drinking water day 1 + spray/IM day 14–21. Layers: boosters every 8–12 weeks.",
                    "8–12 weeks (live vaccines); 4–6 months (killed oil-emulsion)",
                    "Eye drop, intranasal, drinking water (live); IM/SC (killed)",
                    "Live vaccines: mild respiratory reaction (snicking, sneezing).",
                    "Mandatory in most countries; emergency vaccination in outbreaks."
                ),

                new VaccineType(
                    "Avian influenza vaccine (AI / H5N1)",
                    "Avian influenza (bird flu)",
                    "Poultry, Exotic birds, Wildlife",
                    "Core", true,
                    "Influenza A virus subtypes H5 and H7 (HPAI)",
                    "RNA virus – Orthomyxoviridae",
                    "Inactivated whole-virus or recombinant (HVT-vector / fowlpox-vector) vaccines targeting H5/H7 hemagglutinin; reduce mortality and shedding.",
                    "HPAI strains cause up to 100% mortality in poultry. H5N1 is zoonotic with pandemic potential. Global health security concern. Also infecting mammals (seals, foxes, cattle).",
                    "All domestic and wild birds. Humans (especially poultry workers). Mammals including seals, foxes, cattle.",
                    "Varies by country and outbreak risk; usually 2 doses + boosters. Emergency ring vaccination during outbreaks.",
                    "4–6 months",
                    "Intramuscular injection (inactivated); wing-web stab (fowlpox-vectored)",
                    "Mild; injection site reactions.",
                    "Banned in some countries (DIVA strategy); mandated in endemic zones (China, Egypt, Vietnam)."
                ),

                new VaccineType(
                    "Infectious bursal disease vaccine (IBD / Gumboro)",
                    "Gumboro disease",
                    "Poultry, Chickens",
                    "Core", false,
                    "Infectious bursal disease virus (IBDV)",
                    "dsRNA virus – Birnaviridae",
                    "Live attenuated (intermediate/intermediate-plus strains) or immune complex vaccines; target VP2 capsid protein; protect the Bursa of Fabricius (critical B-cell organ in chicks).",
                    "Destroys bursa in young chicks causing profound immunosuppression; increases susceptibility to all secondary infections and reduces vaccine responses.",
                    "Chickens 3–6 weeks old primarily; layer flocks and broilers worldwide.",
                    "Broilers: 1–2 doses via drinking water at 14–21 days. Breeders: oil-emulsion boosters for maternal antibody transfer.",
                    "Maternal antibodies protect chicks 2–3 weeks; live vaccine gives 8–10 weeks",
                    "Drinking water (live); SC/IM (killed or immune complex)",
                    "High intermediate strains: transient bursal damage.",
                    "Standard in all commercial poultry production."
                ),

                new VaccineType(
                    "Marek's disease vaccine (MDV)",
                    "Marek's disease",
                    "Poultry, Chickens",
                    "Core", false,
                    "Gallid alphaherpesvirus 2 (MDV-1)",
                    "dsDNA virus – Herpesviridae",
                    "Turkey herpesvirus (HVT) or serotype 2/3 vaccines given in ovo or at hatch; induce cell-mediated immunity; prevent tumour formation (not infection/shedding).",
                    "Causes T-cell lymphoma, paralysis, and death. One of the first oncogenic viruses controlled by vaccination. Without vaccination nearly 100% of commercial chickens would develop tumours.",
                    "Chickens exclusively. Devastating to commercial layer and broiler flocks.",
                    "Single dose at hatch (in ovo at day 18 or SC at hatch day).",
                    "Lifelong — single dose",
                    "In ovo injection or subcutaneous at day of hatch",
                    "Minimal when properly handled.",
                    "Universal in commercial poultry — administered to virtually all commercial chickens."
                ),

                // ── PIGS ──────────────────────────────────────────────────────────────
                new VaccineType(
                    "Erysipelas vaccine (pig)",
                    "Swine erysipelas",
                    "Pigs, Turkeys",
                    "Core", true,
                    "Erysipelothrix rhusiopathiae",
                    "Gram-positive bacterium – Erysipelotrichaceae",
                    "Live attenuated or inactivated bacterin; generates antibodies against surface virulence factors; prevents septicaemia, diamond skin disease, endocarditis and arthritis.",
                    "Common cause of sudden death, arthritis, and endocarditis in pigs. Zoonotic — causes erysipeloid skin infection in humans (butchers, fishermen, veterinarians).",
                    "Pigs of all ages. Turkeys. Humans via direct contact with infected animals.",
                    "Sows: 2-dose primary + boosters before farrowing. Grow-finish: 8 weeks + booster 4 weeks later.",
                    "6 months — sows require pre-farrowing boosters",
                    "Intramuscular or oral (water administration for some live vaccines)",
                    "Mild injection site reactions; transient fever.",
                    "Routine in swine production worldwide."
                ),

                new VaccineType(
                    "Porcine circovirus vaccine (PCV2)",
                    "Porcine circovirus-associated disease (PCVAD)",
                    "Pigs",
                    "Core", false,
                    "Porcine circovirus type 2 (PCV2)",
                    "ssDNA virus – Circoviridae",
                    "Subunit vaccine (Cap protein) or chimeric virus vaccine; generates antibodies against PCV2 capsid; prevents systemic disease and wasting.",
                    "Causes post-weaning multisystemic wasting syndrome (PMWS), reproductive failure, respiratory disease. One of the most economically significant swine diseases worldwide.",
                    "All pigs; most severe in 5–15 week olds. Also causes reproductive failure in gilts/sows.",
                    "Single or 2-dose series in piglets at 3 weeks; sows at farrowing.",
                    "Full grow-finish period with single dose in many products",
                    "Intramuscular injection",
                    "Transient swelling; rare hypersensitivity.",
                    "Universally adopted in commercial swine production worldwide."
                ),

                // ── RABBITS ───────────────────────────────────────────────────────────
                new VaccineType(
                    "Myxomatosis + RHD vaccine (rabbit)",
                    "Myxomatosis + Rabbit haemorrhagic disease",
                    "Rabbits",
                    "Core", false,
                    "Myxoma virus + RHDV2",
                    "Poxvirus (DNA) + Calicivirus (ssRNA)",
                    "Combination attenuated myxoma vector expressing RHDV2 antigens; generates immunity to both diseases simultaneously in a single injection.",
                    "Both diseases are rapidly fatal. RHD found dead with no prior signs; myxomatosis causes massive swelling and death. Spread by insects and contaminated surfaces.",
                    "All domestic and wild rabbits (Oryctolagus cuniculus). RHDV2 also affects hares.",
                    "Single dose from 5 weeks old; annual booster.",
                    "12 months",
                    "Subcutaneous injection",
                    "Mild lumps at injection site; rare lethargy.",
                    "Core for domestic rabbits in Europe. RHDV2 vaccines available by special licence in USA/Australia."
                ),

                // ── WILDLIFE ──────────────────────────────────────────────────────────
                new VaccineType(
                    "Oral wildlife rabies vaccine (ORV)",
                    "Rabies in wildlife",
                    "Wildlife",
                    "Core", true,
                    "Rabies lyssavirus",
                    "RNA virus – Lyssavirus, Rhabdoviridae",
                    "Recombinant vaccinia-rabies glycoprotein (V-RG) bait vaccine; eaten by wildlife; virus-like particles in tonsil/gut mucosa stimulate immunity. Delivered in flavoured baits airdropped over large areas.",
                    "Rabies eradication in wildlife impossible via trapping/injection. Oral baiting programs eliminated raccoon, fox, and coyote rabies from large regions of USA and Europe.",
                    "Raccoons, foxes, coyotes, skunks, bats (target species vary by bait type).",
                    "Aerial bait distribution 1–2 times per year in target zones.",
                    "12 months (maintained via annual bait drops)",
                    "Oral — eaten as wildlife bait (flavoured fishmeal polymer sachet)",
                    "Safe for non-target animals; humans should avoid direct contact with crushed bait.",
                    "Government wildlife management programs (USDA APHIS, European national programs)."
                )

            ));
        }

        if (glossaryRepo.count() == 0) {
            seedGlossary();
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
        return "Vaccine dataset and Maharashtra lookups seeded successfully!";
    }

    private void seedGlossary() {
        glossaryRepo.saveAll(List.of(
            new VaccineGlossary("Core vaccine",
                "A vaccine recommended for all animals of a given species regardless of lifestyle or location, due to the severity, contagiousness, or zoonotic nature of the disease."),
            new VaccineGlossary("Non-core vaccine",
                "A vaccine recommended only for animals at specific risk based on geographic location, lifestyle, or exposure history."),
            new VaccineGlossary("Zoonotic disease",
                "A disease transmissible from animals to humans under natural conditions. Vaccination of animals reduces the risk of human infection."),
            new VaccineGlossary("MLV (Modified Live Virus)",
                "A vaccine containing a live but weakened (attenuated) pathogen that replicates in the host, generating strong, long-lasting immunity. Contraindicated in some pregnant or immunocompromised animals."),
            new VaccineGlossary("Killed / Inactivated vaccine",
                "A vaccine containing pathogens that have been chemically or physically inactivated. Generally safer but may require adjuvants and more frequent boosters."),
            new VaccineGlossary("Recombinant vaccine",
                "A vaccine produced using genetic engineering; only specific antigens of the pathogen are included. Examples: canarypox-vectored rabies, FeLV recombinant vaccines."),
            new VaccineGlossary("Bacterin",
                "A killed bacterial vaccine preparation used to prevent bacterial diseases (e.g., leptospirosis, brucellosis)."),
            new VaccineGlossary("Toxoid",
                "A vaccine made from inactivated bacterial toxin (e.g., tetanus toxoid, clostridial toxoids); generates antitoxin antibody response."),
            new VaccineGlossary("Adjuvant",
                "A substance added to a vaccine to enhance the immune response (e.g., aluminium salts, oil emulsions). May increase injection site reactions."),
            new VaccineGlossary("Serovar",
                "A distinct variant of a microorganism (e.g., Leptospira, Salmonella) based on its surface antigens. Vaccines must match circulating serovars for protection."),
            new VaccineGlossary("Maternal antibody",
                "Antibodies transferred from a vaccinated mother to offspring via colostrum (first milk) or placenta; provides short-term passive protection to neonates."),
            new VaccineGlossary("Booster dose",
                "A subsequent dose of vaccine administered after the primary series to maintain protective immunity."),
            new VaccineGlossary("Primary series",
                "The initial set of doses given to an unvaccinated animal to establish baseline immunity (often 2–3 doses)."),
            new VaccineGlossary("In ovo vaccination",
                "Vaccine delivered directly into the egg at day 18 of incubation for poultry; used for Marek's disease vaccine to provide day-of-hatch immunity."),
            new VaccineGlossary("DIVA (Differentiating Infected from Vaccinated Animals)",
                "A strategy using marker vaccines and companion diagnostic tests to distinguish vaccinated from naturally infected animals; used in FMD and AI control programs."),
            new VaccineGlossary("OIE / WOAH",
                "World Organisation for Animal Health — the international body that sets standards for animal disease surveillance and control. OIE-listed diseases are of major international significance."),
            new VaccineGlossary("IgA",
                "Immunoglobulin A — the primary antibody class in mucosal secretions (respiratory, GI tract). Intranasal vaccines specifically stimulate local IgA responses at the infection site."),
            new VaccineGlossary("IgG",
                "Immunoglobulin G — the main antibody class in blood; provides systemic protection; transferred from mother to offspring via colostrum."),
            new VaccineGlossary("Cell-mediated immunity",
                "Immune response involving T lymphocytes rather than antibodies; essential for defence against intracellular pathogens (e.g., brucellosis, FIV, Marek's disease)."),
            new VaccineGlossary("Humoral immunity",
                "Antibody-based immune response produced by B lymphocytes; primary mechanism of protection against extracellular pathogens and toxins."),
            new VaccineGlossary("Vaccine-associated sarcoma (VAS)",
                "A rare, aggressive tumour arising at injection sites in cats, associated with certain adjuvanted vaccines (FeLV, rabies). Risk: ~1 in 10,000."),
            new VaccineGlossary("Ring vaccination",
                "Emergency strategy of vaccinating all susceptible animals in a ring around an outbreak to create a buffer zone; used in FMD and AI outbreaks."),
            new VaccineGlossary("Bait vaccination (ORV)",
                "Oral vaccine delivered in baits distributed by hand or aircraft over wildlife habitats to vaccinate free-ranging animals (e.g., oral rabies vaccine for wildlife)."),
            new VaccineGlossary("Endemic region",
                "A geographic area where a disease is permanently present in the population (e.g., anthrax in certain African and Asian soils; FMD in Asia, Africa, Middle East)."),
            new VaccineGlossary("Seroconversion",
                "Development of detectable antibodies in an animal's blood following vaccination or natural infection; confirms immune response.")
        ));
    }
}
