package com.example.animalservice.controller;

import com.example.animalservice.model.Booking;
import com.example.animalservice.service.BookingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/bookings")
@CrossOrigin(origins = "*")
public class BookingController {

    @Autowired
    private BookingService bookingService;

    @PostMapping("/create")
    public Booking createBooking(@RequestBody Booking booking) {
        return bookingService.createBooking(booking);
    }

    @GetMapping("/all")
    public List<Booking> getAllBookings() {
        return bookingService.getAllBookings();
    }

    @GetMapping("/owner/{email}")
    public List<Booking> getOwnerBookings(@PathVariable String email) {
        return bookingService.getFarmerBookings(email);
    }

    @GetMapping("/provider/{email}")
    public List<Booking> getProviderBookings(@PathVariable String email) {
        return bookingService.getProviderDashboardBookings(email);
    }

    @PutMapping("/update/{id}/{status}")
    public Booking updateStatus(
            @PathVariable int id, 
            @PathVariable String status,
            @RequestParam(required = false) String providerEmail) {
        return bookingService.updateStatus(id, status, providerEmail);
    }

    @GetMapping("/stats")
    public Map<String, Long> getStats(@RequestParam(required = false) String email) {
        if (email != null && !email.isEmpty()) {
            return bookingService.getProviderStats(email);
        }
        return bookingService.getStats();
    }

    @DeleteMapping("/delete/{id}")
    public void deleteBooking(@PathVariable int id) {
        bookingService.deleteBooking(id);
    }

    @GetMapping("/test")
    public String test() {
        return "BOOKING API WORKING";
    }
}