package com.example.animalservice.service;

import com.example.animalservice.model.VaccinationRecord;
import com.example.animalservice.repository.VaccinationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class ScheduledTaskService {

    @Autowired
    private VaccinationRepository vaccinationRepository;

    @Autowired
    private NotificationService notificationService;

    // Run every day at 8:00 AM
    @Scheduled(cron = "0 0 8 * * *")
    public void sendVaccinationReminders() {
        LocalDate tomorrow = LocalDate.now().plusDays(1);
        List<VaccinationRecord> records = vaccinationRepository.findByNextDueDateBefore(tomorrow.plusDays(1));
        
        for (VaccinationRecord record : records) {
            if (record.getNextDueDate().equals(tomorrow)) {
                notificationService.sendToUser(
                    record.getOwnerEmail(),
                    "Vaccination Reminder",
                    "Reminder: " + record.getAnimalName() + " is due for " + record.getVaccineName() + " tomorrow."
                );
            }
        }
    }
}
