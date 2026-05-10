package com.example.animalservice.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "bookings")
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "farmer_email")
    private String ownerEmail;
    private String providerEmail;
    private String serviceType;
    private String status;
    private String appointmentTime;
    private String appointmentDate;

    // New fields for provider history
    @Column(columnDefinition = "TEXT")
    private String treatmentNotes;
    private String outcome;
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Getters & Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getOwnerEmail() { return ownerEmail; }
    public void setOwnerEmail(String ownerEmail) { this.ownerEmail = ownerEmail; }

    public String getProviderEmail() { return providerEmail; }
    public void setProviderEmail(String providerEmail) { this.providerEmail = providerEmail; }

    public String getServiceType() { return serviceType; }
    public void setServiceType(String serviceType) { this.serviceType = serviceType; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAppointmentTime() { return appointmentTime; }
    public void setAppointmentTime(String appointmentTime) { this.appointmentTime = appointmentTime; }

    public String getAppointmentDate() { return appointmentDate; }
    public void setAppointmentDate(String appointmentDate) { this.appointmentDate = appointmentDate; }

    public String getTreatmentNotes() { return treatmentNotes; }
    public void setTreatmentNotes(String treatmentNotes) { this.treatmentNotes = treatmentNotes; }

    public String getOutcome() { return outcome; }
    public void setOutcome(String outcome) { this.outcome = outcome; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    // Feature 7 — Visit Type (v2.0)
    private String visitType = "IN_HOSPITAL"; // HOME_VISIT or IN_HOSPITAL
    private String visitAddress;
    private String visitCity;
    private String visitPincode;

    public String getVisitType() { return visitType; }
    public void setVisitType(String visitType) { this.visitType = visitType; }

    public String getVisitAddress() { return visitAddress; }
    public void setVisitAddress(String visitAddress) { this.visitAddress = visitAddress; }

    public String getVisitCity() { return visitCity; }
    public void setVisitCity(String visitCity) { this.visitCity = visitCity; }

    public String getVisitPincode() { return visitPincode; }
    public void setVisitPincode(String visitPincode) { this.visitPincode = visitPincode; }
}

