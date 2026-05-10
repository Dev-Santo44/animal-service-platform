package com.example.animalservice.model;

import jakarta.persistence.*;

/**
 * Stores the 25 veterinary vaccination glossary terms
 * from Animal_Vaccination_Dataset.xlsx Glossary & Notes sheet.
 */
@Entity
@Table(name = "vaccine_glossary")
public class VaccineGlossary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String term;

    @Column(columnDefinition = "TEXT")
    private String definition;

    public VaccineGlossary() {}

    public VaccineGlossary(String term, String definition) {
        this.term = term;
        this.definition = definition;
    }

    public Long getId()                    { return id; }
    public void setId(Long id)             { this.id = id; }
    public String getTerm()                { return term; }
    public void setTerm(String term)       { this.term = term; }
    public String getDefinition()          { return definition; }
    public void setDefinition(String def)  { this.definition = def; }
}
