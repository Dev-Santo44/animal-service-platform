package com.example.animalservice.controller;

import com.example.animalservice.model.ServiceProvider;
import com.example.animalservice.model.Booking;
import com.example.animalservice.service.ServiceProviderService;
import com.example.animalservice.service.BookingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.List;

@RestController
@RequestMapping("/api/service-provider")
@CrossOrigin(origins = "*")
public class ServiceProviderController {

    @Autowired
    private ServiceProviderService service;

    @Autowired
    private BookingService bookingService;

    @Autowired
    private com.example.animalservice.security.JwtUtil jwtUtil;

    @Autowired
    private com.example.animalservice.service.StorageService storageService;

    @PostMapping("/register")
    public ServiceProvider register(@RequestBody ServiceProvider provider) {
        return service.register(provider);
    }

    @PostMapping("/upload-license")
    public Map<String, String> uploadLicense(
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file,
            @RequestParam("email") String email) {
        try {
            String url = storageService.uploadLicense(file, email);
            ServiceProvider provider = service.findByEmail(email);
            if (provider != null) {
                provider.setLicenseFileUrl(url);
                service.save(provider);
                return Map.of("status", "SUCCESS", "url", url);
            }
            return Map.of("status", "ERROR", "message", "Doctor not found");
        } catch (Exception e) {
            return Map.of("status", "ERROR", "message", e.getMessage());
        }
    }

    @PostMapping("/login")
    public ServiceProvider login(@RequestBody ServiceProvider provider) {
        ServiceProvider user = service.login(provider.getEmail(), provider.getPassword());
        if (user != null) {
            String token = jwtUtil.generateToken(user.getEmail(), user.getRole());
            user.setToken(token);
            return user;
        }
        return null;
    }

    @GetMapping("/providers")
    public List<ServiceProvider> getAllProviders(@RequestParam(required = false) String type) {
        if (type != null && !type.equalsIgnoreCase("All")) {
            return service.getProvidersByType(type.toUpperCase());
        }
        return service.getAllProviders();
    }

    @GetMapping("/providers/{id}")
    public ServiceProvider getProviderById(@PathVariable int id) {
        return service.getProviderById(id).orElse(null);
    }

    @GetMapping("/providers/type/{type}")
    public List<ServiceProvider> getProvidersByType(@PathVariable String type) {
        return service.getProvidersByType(type);
    }

    @GetMapping("/providers/government")
    public List<ServiceProvider> getGovernmentProviders(
            @RequestParam(required = false) String district) {
        if (district != null && !district.isEmpty()) {
            return service.getGovernmentProvidersByDistrict(district);
        }
        return service.getProvidersByType("GOVERNMENT");
    }

    @PutMapping("/booking/update/{id}/{status}")
    public Booking updateStatus(
            @PathVariable int id, 
            @PathVariable String status,
            @RequestParam(required = false) String providerEmail) {
        return bookingService.updateStatus(id, status, providerEmail);
    }

    @GetMapping("/test")
    public String test() {
        return "API WORKING";
    }

    @GetMapping("/email/{email}")
    public ServiceProvider getProviderByEmail(@PathVariable String email) {
        return service.findByEmail(email);
    }

    @PutMapping("/update")
    public ServiceProvider updateProfile(@RequestBody ServiceProvider updatedProvider) {
        ServiceProvider existing = service.findByEmail(updatedProvider.getEmail());
        if (existing != null) {
            existing.setName(updatedProvider.getName());
            existing.setSpecialization(updatedProvider.getSpecialization());
            existing.setClinicName(updatedProvider.getClinicName());
            existing.setPhone(updatedProvider.getPhone());
            existing.setConsultationFee(updatedProvider.getConsultationFee());
            existing.setLatitude(updatedProvider.getLatitude());
            existing.setLongitude(updatedProvider.getLongitude());
            existing.setDoctorType(updatedProvider.getDoctorType());
            existing.setDescription(updatedProvider.getDescription());
            existing.setWorkingHours(updatedProvider.getWorkingHours());
            existing.setDistrict(updatedProvider.getDistrict());
            return service.save(existing);
        }
        return null;
    }

    @PutMapping("/availability")
    public ServiceProvider updateAvailability(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.get("email");
        boolean isAvailable = (boolean) payload.get("isAvailable");
        ServiceProvider provider = service.findByEmail(email);
        if (provider != null) {
            provider.setAvailable(isAvailable);
            return service.save(provider);
        }
        return null;
    }

    @GetMapping("/seed-diverse")
    public String seedDiverse() {
        String[] types = {"PRIVATE", "GOVERNMENT", "NGO"};
        String[] specializations = {"Bovine Specialist", "Small Animal Surgery", "Avian Expert"};
        String[] districts = {"Pune", "Mumbai", "Satara"};

        for (String type : types) {
            for (int i = 1; i <= 3; i++) {
                ServiceProvider p = new ServiceProvider();
                String name = "Dr. " + type.substring(0, 1) + type.substring(1).toLowerCase() + " " + i;
                p.setName(name);
                p.setEmail(type.toLowerCase() + i + "@example.com");
                p.setPassword("password");
                p.setRole("Service Provider");
                p.setDoctorType(type);
                p.setSpecialization(specializations[i-1]);
                p.setClinicName(type + " Clinic " + i);
                p.setConsultationFee(type.equals("GOVERNMENT") ? 0.0 : 500.0 * i);
                p.setDistrict(districts[i-1]);
                p.setLatitude(18.5 + (Math.random() * 0.5));
                p.setLongitude(73.8 + (Math.random() * 0.5));
                service.register(p);
            }
        }
        return "9 Diverse Vets Seeded (3 Private, 3 Govt, 3 NGO)!";
    }
}