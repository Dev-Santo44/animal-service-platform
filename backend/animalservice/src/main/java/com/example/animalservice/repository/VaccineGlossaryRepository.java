package com.example.animalservice.repository;

import com.example.animalservice.model.VaccineGlossary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VaccineGlossaryRepository extends JpaRepository<VaccineGlossary, Long> {
    List<VaccineGlossary> findByTermContainingIgnoreCase(String term);
}
