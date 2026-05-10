package com.example.animalservice.controller;

import com.example.animalservice.model.Payment;
import com.example.animalservice.model.Withdrawal;
import com.example.animalservice.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@CrossOrigin(origins = "*")
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    @PostMapping("/create-order")
    public Map<String, Object> createOrder(@RequestBody Map<String, Object> payload) {
        int bookingId = (int) payload.get("bookingId");
        double amount = Double.parseDouble(payload.get("amount").toString());
        String ownerEmail = (String) payload.get("ownerEmail");
        String providerEmail = (String) payload.get("providerEmail");
        return paymentService.createRazorpayOrder(bookingId, amount, ownerEmail, providerEmail);
    }

    @PostMapping("/verify")
    public Map<String, Object> verifyPayment(@RequestBody Map<String, String> payload) {
        String orderId = payload.get("razorpay_order_id");
        String paymentId = payload.get("razorpay_payment_id");
        String signature = payload.get("razorpay_signature");
        return paymentService.verifyAndConfirmPayment(orderId, paymentId, signature);
    }

    @PostMapping("/cash")
    public Payment recordCash(@RequestBody Map<String, Object> payload) {
        int bookingId = (int) payload.get("bookingId");
        double amount = Double.parseDouble(payload.get("amount").toString());
        String ownerEmail = (String) payload.get("ownerEmail");
        String providerEmail = (String) payload.get("providerEmail");
        return paymentService.recordCashPayment(bookingId, amount, ownerEmail, providerEmail);
    }

    @GetMapping("/earnings/{email}")
    public Map<String, Object> getEarnings(@PathVariable String email) {
        return paymentService.getProviderEarnings(email);
    }

    @GetMapping("/history/{email}")
    public List<Payment> getHistory(@PathVariable String email) {
        return paymentService.getOwnerPaymentHistory(email);
    }

    @PostMapping("/withdraw")
    public Map<String, Object> withdraw(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.get("email");
        String upiId = (String) payload.get("upiId");
        double amount = Double.parseDouble(payload.get("amount").toString());
        return paymentService.initiateWithdrawal(email, upiId, amount);
    }
}
