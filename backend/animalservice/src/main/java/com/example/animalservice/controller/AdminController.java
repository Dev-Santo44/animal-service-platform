package com.example.animalservice.controller;

import com.example.animalservice.model.*;
import com.example.animalservice.repository.*;
import com.example.animalservice.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    @Autowired private ServiceProviderRepository providerRepository;
    @Autowired private BookingRepository bookingRepository;
    @Autowired private NotificationService notificationService;
    @Autowired private PaymentRepository paymentRepository;
    @Autowired private VaccinationRepository vaccinationRepository;
    @Autowired private AnimalRepository animalRepository;
    @Autowired private ReviewRepository reviewRepository;

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

    // Enhanced platform statistics
    @GetMapping("/stats")
    public Map<String, Object> getStats() {
        double totalRevenue = Optional.ofNullable(paymentRepository.sumEarningsByProvider(null)).orElse(0.0);
        // Calculate total revenue from all paid payments
        double revenue = 0.0;
        try {
            List<Payment> allPayments = paymentRepository.findAll();
            for (Payment p : allPayments) {
                if ("PAID".equals(p.getStatus()) && p.getAmount() != null) {
                    revenue += p.getAmount();
                }
            }
        } catch (Exception e) {
            // fallback
        }

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalDoctors", providerRepository.countByRole("Doctor"));
        stats.put("pendingDoctors", providerRepository.countByRoleAndVerificationStatus("Doctor", "PENDING"));
        stats.put("approvedDoctors", providerRepository.countByRoleAndVerificationStatus("Doctor", "APPROVED"));
        stats.put("rejectedDoctors", providerRepository.countByRoleAndVerificationStatus("Doctor", "REJECTED"));
        stats.put("totalPetOwners", providerRepository.countByRole("Pet Owner"));
        stats.put("totalBookings", bookingRepository.count());
        stats.put("pendingBookings", bookingRepository.countByStatus("PENDING"));
        stats.put("acceptedBookings", bookingRepository.countByStatus("ACCEPTED"));
        stats.put("completedBookings", bookingRepository.countByStatus("COMPLETED"));
        stats.put("totalAnimals", animalRepository.count());
        stats.put("totalVaccinations", vaccinationRepository.count());
        stats.put("totalPayments", paymentRepository.count());
        stats.put("totalRevenue", revenue);
        stats.put("totalReviews", reviewRepository.count());
        return stats;
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

    // ── NEW ENDPOINTS ──────────────────────────────────────────

    // Get all bookings for admin view
    @GetMapping("/all-bookings")
    public List<Booking> getAllBookings() {
        return bookingRepository.findAll();
    }

    // Get all payments for admin view
    @GetMapping("/all-payments")
    public List<Payment> getAllPayments() {
        return paymentRepository.findAll();
    }

    // Get all vaccination records for admin view
    @GetMapping("/all-vaccinations")
    public List<VaccinationRecord> getAllVaccinations() {
        return vaccinationRepository.findAll();
    }

    // Get all animals for admin view
    @GetMapping("/all-animals")
    public List<Animal> getAllAnimals() {
        return animalRepository.findAll();
    }

    // Get all reviews for admin view
    @GetMapping("/all-reviews")
    public List<Review> getAllReviews() {
        return reviewRepository.findAll();
    }

    // Get doctor document info for review
    @GetMapping("/doctor/{id}/document")
    public Map<String, Object> getDoctorDocument(@PathVariable int id) {
        ServiceProvider doctor = providerRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Doctor not found"));

        Map<String, Object> docInfo = new LinkedHashMap<>();
        docInfo.put("id", doctor.getId());
        docInfo.put("name", doctor.getName());
        docInfo.put("email", doctor.getEmail());
        docInfo.put("phone", doctor.getPhone());
        docInfo.put("licenseNumber", doctor.getLicenseNumber());
        docInfo.put("licenseFileUrl", doctor.getLicenseFileUrl());
        docInfo.put("verificationStatus", doctor.getVerificationStatus());
        docInfo.put("rejectionReason", doctor.getRejectionReason());
        docInfo.put("specialization", doctor.getSpecialization());
        docInfo.put("clinicName", doctor.getClinicName());
        return docInfo;
    }
}
