package com.example.animalservice.model;

import jakarta.persistence.*;

@Entity
@Table(name = "vaccine_types")
public class VaccineType {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String targetDisease;
    private String targetSpecies;      // Cow, Dog, Cat, Goat, Poultry, All
    private String schedule;           // e.g., "Every 6 months"
    private String dosage;             // e.g., "2ml intramuscular"
    private String sideEffects;
    @Column(columnDefinition = "TEXT")
    private String description;
    private String manufacturer;

    public VaccineType() {}

    public VaccineType(String name) { this.name = name; }

    public VaccineType(String name, String targetDisease, String targetSpecies,
                       String schedule, String dosage, String sideEffects,
                       String description, String manufacturer) {
        this.name = name;
        this.targetDisease = targetDisease;
        this.targetSpecies = targetSpecies;
        this.schedule = schedule;
        this.dosage = dosage;
        this.sideEffects = sideEffects;
        this.description = description;
        this.manufacturer = manufacturer;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getTargetDisease() { return targetDisease; }
    public void setTargetDisease(String targetDisease) { this.targetDisease = targetDisease; }
    public String getTargetSpecies() { return targetSpecies; }
    public void setTargetSpecies(String targetSpecies) { this.targetSpecies = targetSpecies; }
    public String getSchedule() { return schedule; }
    public void setSchedule(String schedule) { this.schedule = schedule; }
    public String getDosage() { return dosage; }
    public void setDosage(String dosage) { this.dosage = dosage; }
    public String getSideEffects() { return sideEffects; }
    public void setSideEffects(String sideEffects) { this.sideEffects = sideEffects; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getManufacturer() { return manufacturer; }
    public void setManufacturer(String manufacturer) { this.manufacturer = manufacturer; }
}

