package com.example.animalservice.repository;

import com.example.animalservice.model.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    List<Payment> findByBookingId(int bookingId);

    List<Payment> findByOwnerEmailOrderByCreatedAtDesc(String ownerEmail);

    List<Payment> findByProviderEmailAndStatusOrderByCreatedAtDesc(String providerEmail, String status);

    List<Payment> findByProviderEmailOrderByCreatedAtDesc(String providerEmail);

    Optional<Payment> findByRazorpayOrderId(String razorpayOrderId);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p WHERE p.providerEmail = :email AND p.status = 'PAID'")
    Double sumEarningsByProvider(@Param("email") String providerEmail);
}
