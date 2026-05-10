package com.example.animalservice.repository;

import com.example.animalservice.model.VaccineType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VaccineTypeRepository extends JpaRepository<VaccineType, Long> {

    /**
     * Filter vaccines by species — case-insensitive contains check on targetAnimals.
     * Example: findBySpecies("Dog") returns all vaccines where targetAnimals contains "Dog".
     */
    @Query("SELECT v FROM VaccineType v WHERE LOWER(v.targetAnimals) LIKE LOWER(CONCAT('%', :species, '%'))")
    List<VaccineType> findBySpecies(@Param("species") String species);

    /**
     * Filter vaccines by core status ("Core" or "Non-core").
     */
    List<VaccineType> findByCoreStatus(String coreStatus);

    /**
     * Filter by both species and core status.
     */
    @Query("SELECT v FROM VaccineType v WHERE LOWER(v.targetAnimals) LIKE LOWER(CONCAT('%', :species, '%')) AND v.coreStatus = :coreStatus")
    List<VaccineType> findBySpeciesAndCoreStatus(@Param("species") String species, @Param("coreStatus") String coreStatus);

    /**
     * Get only zoonotic vaccines — for displaying risk warnings.
     */
    List<VaccineType> findByIsZoonotic(Boolean isZoonotic);
}
