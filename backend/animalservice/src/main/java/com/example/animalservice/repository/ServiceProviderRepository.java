package com.example.animalservice.repository;

import com.example.animalservice.model.ServiceProvider;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServiceProviderRepository extends JpaRepository<ServiceProvider, Integer> {

    ServiceProvider findByEmail(String email);

    List<ServiceProvider> findByDoctorType(String doctorType);

    List<ServiceProvider> findByDoctorTypeAndDistrict(String doctorType, String district);

    List<ServiceProvider> findByRole(String role);

    // Feature 1 & 8 — Admin verification
    List<ServiceProvider> findByRoleAndVerificationStatus(String role, String verificationStatus);

    long countByRole(String role);

    long countByRoleAndVerificationStatus(String role, String verificationStatus);
}