package com.example.animalservice.service;

import com.example.animalservice.model.ServiceProvider;
import com.example.animalservice.repository.ServiceProviderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.logging.Logger;

import java.util.List;
import java.util.Optional;

@Service
public class ServiceProviderService {
    private static final Logger log = Logger.getLogger(ServiceProviderService.class.getName());

    @Autowired
    private ServiceProviderRepository repository;

    @Autowired
    private org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder passwordEncoder;

    public ServiceProvider register(ServiceProvider provider) {
        // Hash password before saving
        provider.setPassword(passwordEncoder.encode(provider.getPassword()));
        return repository.save(provider);
    }

    public ServiceProvider login(String email, String password) {
        ServiceProvider user = repository.findByEmail(email);
        if (user == null) return null;

        // 1. Try BCrypt Match (Standard)
        if (passwordEncoder.matches(password, user.getPassword())) {
            return user;
        }

        // 2. Legacy Migration: Try Plain Text Match (Only if DB entry isn't BCrypt yet)
        if (password.equals(user.getPassword())) {
            // Auto-repair: Hash the password now for future logins
            user.setPassword(passwordEncoder.encode(password));
            repository.save(user);
            log.info("Legacy user migrated to BCrypt: " + email);
            return user;
        }

        return null;
    }

    public List<ServiceProvider> getAllProviders() {
        return repository.findByRole("Service Provider");
    }

    public Optional<ServiceProvider> getProviderById(int id) {
        return repository.findById(id);
    }

    public List<ServiceProvider> getProvidersByType(String doctorType) {
        return repository.findByDoctorType(doctorType);
    }

    public List<ServiceProvider> getGovernmentProvidersByDistrict(String district) {
        return repository.findByDoctorTypeAndDistrict("GOVERNMENT", district);
    }

    public ServiceProvider updateProvider(ServiceProvider provider) {
        return repository.save(provider);
    }

    public ServiceProvider findByEmail(String email) {
        return repository.findByEmail(email);
    }

    public ServiceProvider save(ServiceProvider provider) {
        return repository.save(provider);
    }
}