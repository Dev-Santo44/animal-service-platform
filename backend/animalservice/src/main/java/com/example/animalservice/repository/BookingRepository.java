package com.example.animalservice.repository;

import com.example.animalservice.model.Booking;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookingRepository extends JpaRepository<Booking, Integer> {

    // Get bookings by owner email
    List<Booking> findByOwnerEmail(String ownerEmail);

    // Get bookings by provider email
    List<Booking> findByProviderEmail(String providerEmail);

    // Get bookings by status
    List<Booking> findByStatus(String status);

    // Count by status
    long countByStatus(String status);
}