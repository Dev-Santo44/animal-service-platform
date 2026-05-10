package com.example.animalservice.repository;

import com.example.animalservice.model.VaccinationRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface VaccinationRepository extends JpaRepository<VaccinationRecord, Integer> {

    List<VaccinationRecord> findByOwnerEmail(String ownerEmail);

    List<VaccinationRecord> findByAnimalId(int animalId);

    List<VaccinationRecord> findByNextDueDateBefore(LocalDate date);
}
