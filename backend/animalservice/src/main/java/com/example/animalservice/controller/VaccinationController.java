package com.example.animalservice.controller;

import com.example.animalservice.model.VaccinationRecord;
import com.example.animalservice.service.VaccinationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vaccinations")
@CrossOrigin(origins = "*")
public class VaccinationController {

    @Autowired
    private VaccinationService vaccinationService;

    @PostMapping
    public VaccinationRecord addRecord(@RequestBody VaccinationRecord record) {
        return vaccinationService.addRecord(record);
    }

    @GetMapping("/owner/{email}")
    public List<VaccinationRecord> getByOwner(@PathVariable String email) {
        return vaccinationService.getByOwner(email);
    }

    @GetMapping("/animal/{animalId}")
    public List<VaccinationRecord> getByAnimal(@PathVariable int animalId) {
        return vaccinationService.getByAnimal(animalId);
    }

    @GetMapping("/reminders")
    public List<VaccinationRecord> getUpcomingReminders() {
        return vaccinationService.getUpcomingReminders();
    }
}
