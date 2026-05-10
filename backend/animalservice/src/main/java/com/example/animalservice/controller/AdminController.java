package com.example.animalservice.controller;

import com.example.animalservice.model.ServiceProvider;
import com.example.animalservice.repository.BookingRepository;
import com.example.animalservice.repository.ServiceProviderRepository;
import com.example.animalservice.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    @Autowired private ServiceProviderRepository providerRepository;
    @Autowired private BookingRepository bookingRepository;
    @Autowired private NotificationService notificationService;

    // Get all pending doctors
    @GetMapping("/pending-doctors")
    public List<ServiceProvider> getPendingDoctors() {
        return providerRepository.findByRoleAndVerificationStatus("Doctor", "PENDING");
    }

    // Approve or reject a doctor
    @PutMapping("/verify-doctor/{id}")
    public ServiceProvider verifyDoctor(@PathVariable int id, @RequestBody Map<String, String> payload) {
        String status = payload.get("status");   // "APPROVED" or "REJECTED"
        String reason = payload.get("reason");    // optional rejection reason

        ServiceProvider doctor = providerRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Doctor not found"));
        doctor.setVerificationStatus(status);
        if ("REJECTED".equals(status)) doctor.setRejectionReason(reason);
        providerRepository.save(doctor);

        // Notify doctor
        String title = "APPROVED".equals(status) ? "Account Approved ✅" : "Account Rejected ❌";
        String body = "APPROVED".equals(status)
            ? "Your veterinary license has been verified. You can now accept bookings!"
            : "Your license verification failed: " + reason;
        notificationService.sendToUser(doctor.getEmail(), title, body);

        return doctor;
    }

    // Platform statistics
    @GetMapping("/stats")
    public Map<String, Object> getStats() {
        return Map.of(
            "totalDoctors",    providerRepository.countByRole("Doctor"),
            "pendingDoctors",  providerRepository.countByRoleAndVerificationStatus("Doctor", "PENDING"),
            "approvedDoctors", providerRepository.countByRoleAndVerificationStatus("Doctor", "APPROVED"),
            "totalPetOwners",  providerRepository.countByRole("Pet Owner"),
            "totalBookings",   bookingRepository.count(),
            "pendingBookings", bookingRepository.countByStatus("PENDING"),
            "acceptedBookings",bookingRepository.countByStatus("ACCEPTED")
        );
    }

    // Get all doctors (with optional status filter)
    @GetMapping("/all-doctors")
    public List<ServiceProvider> getAllDoctors(@RequestParam(required = false) String status) {
        if (status != null) return providerRepository.findByRoleAndVerificationStatus("Doctor", status);
        return providerRepository.findByRole("Doctor");
    }

    // Get all pet owners
    @GetMapping("/all-owners")
    public List<ServiceProvider> getAllOwners() {
        return providerRepository.findByRole("Pet Owner");
    }
}
