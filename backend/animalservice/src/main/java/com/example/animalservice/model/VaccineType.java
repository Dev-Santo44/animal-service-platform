package com.example.animalservice.model;

import jakarta.persistence.*;

/**
 * Full vaccine dataset model.
 * Integrates all 15 columns from Animal_Vaccination_Dataset.xlsx Master Dataset sheet.
 * 28 vaccines seeded via LookupController.seedLookups().
 */
@Entity
@Table(name = "vaccine_types")
public class VaccineType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ── Core display fields ────────────────────────────────────────────────────
    /** Vaccine display name. e.g., "Rabies vaccine", "Canine distemper vaccine (CDV)" */
    private String name;

    /** Disease the vaccine prevents. e.g., "Rabies", "Canine distemper" */
    @Column(columnDefinition = "TEXT")
    private String diseasePrevented;

    /**
     * Comma-separated list of target animal species.
     * Used for dropdown filtering.
     * e.g., "Dogs, cats, horses, cattle"
     */
    @Column(columnDefinition = "TEXT")
    private String targetAnimals;

    /**
     * "Core" or "Non-core".
     * Core = recommended for ALL animals of this species.
     * Non-core = lifestyle/risk-based.
     */
    private String coreStatus;

    /**
     * Whether this disease is zoonotic (transmissible to humans).
     * true = show zoonotic warning badge in UI.
     */
    private Boolean isZoonotic;

    // ── Scientific / educational fields (shown in Learn More modal) ────────────
    /** e.g., "Rabies lyssavirus", "Canine parvovirus type 2" */
    @Column(columnDefinition = "TEXT")
    private String pathogenName;

    /** e.g., "RNA virus – Lyssavirus, Rhabdoviridae" */
    @Column(columnDefinition = "TEXT")
    private String pathogenType;

    /** How the vaccine works immunologically */
    @Column(columnDefinition = "TEXT")
    private String mechanismOfAction;

    /** Clinical justification — why vaccinate this animal */
    @Column(columnDefinition = "TEXT")
    private String whyVaccinate;

    /** Who/what species is at risk */
    @Column(columnDefinition = "TEXT")
    private String whoIsAffected;

    // ── Practical scheduling fields ────────────────────────────────────────────
    /** Full schedule text. e.g., "First dose at 12–16 weeks; booster at 1 year; then every 1–3 years." */
    @Column(columnDefinition = "TEXT")
    private String schedule;

    /** e.g., "1–3 years (product/regulation dependent)", "Lifelong — single dose" */
    @Column(columnDefinition = "TEXT")
    private String immunityDuration;

    /** Administration route. e.g., "Subcutaneous (SC) or intramuscular (IM) injection" */
    @Column(columnDefinition = "TEXT")
    private String routeOfAdmin;

    /** Known adverse effects. e.g., "Mild soreness at injection site, low-grade fever" */
    @Column(columnDefinition = "TEXT")
    private String sideEffects;

    /** Regulatory/legal requirement. e.g., "Legally mandated for dogs in most countries" */
    @Column(columnDefinition = "TEXT")
    private String legalStatus;

    // ── Constructors ───────────────────────────────────────────────────────────

    public VaccineType() {}

    /** Backward-compatible simple constructor */
    public VaccineType(String name) {
        this.name = name;
    }

    /** Full 15-field constructor for seeding */
    public VaccineType(
            String name, String diseasePrevented, String targetAnimals,
            String coreStatus, Boolean isZoonotic, String pathogenName,
            String pathogenType, String mechanismOfAction, String whyVaccinate,
            String whoIsAffected, String schedule, String immunityDuration,
            String routeOfAdmin, String sideEffects, String legalStatus) {
        this.name              = name;
        this.diseasePrevented  = diseasePrevented;
        this.targetAnimals     = targetAnimals;
        this.coreStatus        = coreStatus;
        this.isZoonotic        = isZoonotic;
        this.pathogenName      = pathogenName;
        this.pathogenType      = pathogenType;
        this.mechanismOfAction = mechanismOfAction;
        this.whyVaccinate      = whyVaccinate;
        this.whoIsAffected     = whoIsAffected;
        this.schedule          = schedule;
        this.immunityDuration  = immunityDuration;
        this.routeOfAdmin      = routeOfAdmin;
        this.sideEffects       = sideEffects;
        this.legalStatus       = legalStatus;
    }

    // ── Getters & Setters ──────────────────────────────────────────────────────
    public Long getId()                            { return id; }
    public void setId(Long id)                     { this.id = id; }
    public String getName()                        { return name; }
    public void setName(String name)               { this.name = name; }
    public String getDiseasePrevented()            { return diseasePrevented; }
    public void setDiseasePrevented(String v)      { this.diseasePrevented = v; }
    public String getTargetAnimals()               { return targetAnimals; }
    public void setTargetAnimals(String v)         { this.targetAnimals = v; }
    public String getCoreStatus()                  { return coreStatus; }
    public void setCoreStatus(String v)            { this.coreStatus = v; }
    public Boolean getIsZoonotic()                 { return isZoonotic; }
    public void setIsZoonotic(Boolean v)           { this.isZoonotic = v; }
    public String getPathogenName()                { return pathogenName; }
    public void setPathogenName(String v)          { this.pathogenName = v; }
    public String getPathogenType()                { return pathogenType; }
    public void setPathogenType(String v)          { this.pathogenType = v; }
    public String getMechanismOfAction()           { return mechanismOfAction; }
    public void setMechanismOfAction(String v)     { this.mechanismOfAction = v; }
    public String getWhyVaccinate()                { return whyVaccinate; }
    public void setWhyVaccinate(String v)          { this.whyVaccinate = v; }
    public String getWhoIsAffected()               { return whoIsAffected; }
    public void setWhoIsAffected(String v)         { this.whoIsAffected = v; }
    public String getSchedule()                    { return schedule; }
    public void setSchedule(String v)              { this.schedule = v; }
    public String getImmunityDuration()            { return immunityDuration; }
    public void setImmunityDuration(String v)      { this.immunityDuration = v; }
    public String getRouteOfAdmin()                { return routeOfAdmin; }
    public void setRouteOfAdmin(String v)          { this.routeOfAdmin = v; }
    public String getSideEffects()                 { return sideEffects; }
    public void setSideEffects(String v)           { this.sideEffects = v; }
    public String getLegalStatus()                 { return legalStatus; }
    public void setLegalStatus(String v)           { this.legalStatus = v; }
}
