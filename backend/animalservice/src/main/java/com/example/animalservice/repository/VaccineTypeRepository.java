package com.example.animalservice.repository;

import com.example.animalservice.model.VaccineType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface VaccineTypeRepository extends JpaRepository<VaccineType, Long> {
    List<VaccineType> findByTargetSpeciesContaining(String species);
}

