package com.example.animalservice.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.UUID;

@Service
public class StorageService {

    /**
     * Placeholder for Supabase Storage upload.
     * In a production environment, use Supabase Java SDK or REST API with your Service Key.
     */
    public String uploadLicense(MultipartFile file, String email) throws IOException {
        // For now, returning a mock URL as per Sprint 1 initial setup
        String fileName = UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
        return "https://mosatjxgsidunjvtpsku.supabase.co/storage/v1/object/public/licenses/" + fileName;
    }
}
