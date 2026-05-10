package com.example.animalservice.service;

import com.example.animalservice.model.Payment;
import com.example.animalservice.model.Withdrawal;
import com.example.animalservice.repository.PaymentRepository;
import com.example.animalservice.repository.WithdrawalRepository;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.logging.Logger;

@Service
public class PaymentService {

    private static final Logger log = Logger.getLogger(PaymentService.class.getName());
    private static final double PLATFORM_FEE_PERCENT = 10.0;

    @Value("${razorpay.key.id}")
    private String keyId;

    @Value("${razorpay.key.secret}")
    private String keySecret;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private WithdrawalRepository withdrawalRepository;

    // ─── 1. Create Razorpay Order (Online payment) ───────────────────────────
    public Map<String, Object> createRazorpayOrder(int bookingId, double amount,
                                                    String ownerEmail, String providerEmail) {
        Map<String, Object> result = new HashMap<>();
        try {
            RazorpayClient client = new RazorpayClient(keyId, keySecret);

            JSONObject options = new JSONObject();
            // Razorpay expects amount in paise (1 INR = 100 paise)
            options.put("amount", (int) (amount * 100));
            options.put("currency", "INR");
            options.put("receipt", "booking_" + bookingId);
            options.put("notes", new JSONObject()
                    .put("bookingId", bookingId)
                    .put("ownerEmail", ownerEmail)
                    .put("providerEmail", providerEmail));

            Order order = client.orders.create(options);
            String orderId = order.get("id").toString();

            // Save pending payment record
            Payment payment = new Payment();
            payment.setBookingId(bookingId);
            payment.setOwnerEmail(ownerEmail);
            payment.setProviderEmail(providerEmail);
            payment.setAmount(amount);
            payment.setMethod("ONLINE");
            payment.setStatus("PENDING");
            payment.setRazorpayOrderId(orderId);
            paymentRepository.save(payment);

            result.put("orderId", orderId);
            result.put("amount", (int) (amount * 100));
            result.put("currency", "INR");
            result.put("keyId", keyId);
            result.put("success", true);

        } catch (RazorpayException e) {
            log.severe("Razorpay order creation failed: " + e.getMessage());
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        return result;
    }

    // ─── 2. Verify Razorpay Payment Signature ────────────────────────────────
    public Map<String, Object> verifyAndConfirmPayment(String razorpayOrderId,
                                                        String razorpayPaymentId,
                                                        String razorpaySignature) {
        Map<String, Object> result = new HashMap<>();
        try {
            String payload = razorpayOrderId + "|" + razorpayPaymentId;
            String generatedSignature = hmacSha256(payload, keySecret);

            if (generatedSignature.equals(razorpaySignature)) {
                // Update payment record
                paymentRepository.findByRazorpayOrderId(razorpayOrderId).ifPresent(payment -> {
                    payment.setRazorpayPaymentId(razorpayPaymentId);
                    payment.setRazorpaySignature(razorpaySignature);
                    payment.setStatus("PAID");
                    paymentRepository.save(payment);
                });
                result.put("success", true);
                result.put("message", "Payment verified successfully");
            } else {
                result.put("success", false);
                result.put("message", "Invalid payment signature");
            }
        } catch (Exception e) {
            log.severe("Signature verification error: " + e.getMessage());
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        return result;
    }

    // ─── 3. Record Cash Payment ───────────────────────────────────────────────
    public Payment recordCashPayment(int bookingId, double amount,
                                      String ownerEmail, String providerEmail) {
        Payment payment = new Payment();
        payment.setBookingId(bookingId);
        payment.setOwnerEmail(ownerEmail);
        payment.setProviderEmail(providerEmail);
        payment.setAmount(amount);
        payment.setMethod("CASH");
        payment.setStatus("PAID");
        return paymentRepository.save(payment);
    }

    // ─── 4. Get Doctor Total Earnings ────────────────────────────────────────
    public Map<String, Object> getProviderEarnings(String providerEmail) {
        double totalEarned = paymentRepository.sumEarningsByProvider(providerEmail);
        double totalWithdrawn = withdrawalRepository.sumWithdrawnByProvider(providerEmail);
        double platformFee = totalEarned * (PLATFORM_FEE_PERCENT / 100.0);
        double netEarnings = totalEarned - platformFee;
        double availableBalance = netEarnings - totalWithdrawn;

        List<Payment> payments = paymentRepository.findByProviderEmailOrderByCreatedAtDesc(providerEmail);
        List<Withdrawal> withdrawals = withdrawalRepository.findByProviderEmailOrderByCreatedAtDesc(providerEmail);

        Map<String, Object> result = new HashMap<>();
        result.put("totalEarned", totalEarned);
        result.put("platformFee", platformFee);
        result.put("netEarnings", netEarnings);
        result.put("totalWithdrawn", totalWithdrawn);
        result.put("availableBalance", Math.max(availableBalance, 0));
        result.put("payments", payments);
        result.put("withdrawals", withdrawals);
        return result;
    }

    // ─── 5. Get Farmer Payment History ───────────────────────────────────────
    public List<Payment> getOwnerPaymentHistory(String ownerEmail) {
        return paymentRepository.findByOwnerEmailOrderByCreatedAtDesc(ownerEmail);
    }

    // ─── 6. Initiate Doctor Withdrawal via Razorpay Payout ───────────────────
    public Map<String, Object> initiateWithdrawal(String providerEmail, String upiId, double amount) {
        Map<String, Object> result = new HashMap<>();

        // Validate available balance
        double totalEarned = paymentRepository.sumEarningsByProvider(providerEmail);
        double platformFee = totalEarned * (PLATFORM_FEE_PERCENT / 100.0);
        double netEarnings = totalEarned - platformFee;
        double totalWithdrawn = withdrawalRepository.sumWithdrawnByProvider(providerEmail);
        double availableBalance = netEarnings - totalWithdrawn;

        if (amount > availableBalance) {
            result.put("success", false);
            result.put("message", "Insufficient balance. Available: ₹" + String.format("%.2f", availableBalance));
            return result;
        }

        // Save withdrawal record first
        Withdrawal withdrawal = new Withdrawal();
        withdrawal.setProviderEmail(providerEmail);
        withdrawal.setAmount(amount);
        withdrawal.setUpiId(upiId);
        withdrawal.setStatus("PENDING");

        try {
            // Razorpay Payout API call
            // NOTE: Requires X-Razorpay-Account header for linked account payouts
            // For standard payouts, use Razorpay RazorpayClient payout API
            RazorpayClient client = new RazorpayClient(keyId, keySecret);

            JSONObject payoutRequest = new JSONObject();
            payoutRequest.put("account_number", "YOUR_RAZORPAY_ACCOUNT_NUMBER"); // Set in .env ideally
            payoutRequest.put("amount", (int) (amount * 100)); // in paise
            payoutRequest.put("currency", "INR");
            payoutRequest.put("mode", "UPI");
            payoutRequest.put("purpose", "payout");
            payoutRequest.put("queue_if_low_balance", true);

            JSONObject fund_account = new JSONObject();
            fund_account.put("account_type", "vpa");
            fund_account.put("vpa", new JSONObject().put("address", upiId));

            JSONObject contact = new JSONObject();
            contact.put("name", providerEmail);
            contact.put("type", "vendor");
            fund_account.put("contact", contact);
            payoutRequest.put("fund_account", fund_account);

            // Attempt the payout via manual HTTP call (Standard SDK lacks Payouts field)
            String payoutId = "";
            try {
                payoutId = callRazorpayPayoutApi(payoutRequest);
            } catch (Exception apiEx) {
                log.warning("RazorpayX API call failed: " + apiEx.getMessage());
                throw apiEx;
            }

            withdrawal.setRazorpayPayoutId(payoutId);
            withdrawal.setStatus("PROCESSED");
            withdrawalRepository.save(withdrawal);

            result.put("success", true);
            result.put("payoutId", payoutId);
            result.put("message", "Withdrawal of ₹" + String.format("%.2f", amount) + " initiated to " + upiId);

        } catch (Exception e) {
            // If Razorpay payout fails (e.g., account not enabled for payouts),
            // we still record the withdrawal as PENDING for manual processing
            log.warning("Razorpay payout failed, recording as PENDING: " + e.getMessage());
            withdrawal.setStatus("PENDING");
            withdrawal.setFailureReason(e.getMessage());
            withdrawalRepository.save(withdrawal);

            result.put("success", true); // Still acknowledged to user
            result.put("message", "Withdrawal request of ₹" + String.format("%.2f", amount) +
                    " submitted. Payment will be sent to " + upiId + " within 24 hours.");
            result.put("pending", true);
        }

        return result;
    }

    // ─── Helper: Manual RazorpayX Payout API Call ───────────────────────────
    private String callRazorpayPayoutApi(JSONObject request) throws Exception {
        URL url = new URL("https://api.razorpay.com/v1/payouts");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        
        // Basic Auth
        String auth = keyId + ":" + keySecret;
        String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes(StandardCharsets.UTF_8));
        conn.setRequestProperty("Authorization", "Basic " + encodedAuth);
        
        conn.setDoOutput(true);
        conn.getOutputStream().write(request.toString().getBytes(StandardCharsets.UTF_8));
        
        int responseCode = conn.getResponseCode();
        if (responseCode >= 200 && responseCode < 300) {
            Scanner s = new Scanner(conn.getInputStream()).useDelimiter("\\A");
            String responseBody = s.hasNext() ? s.next() : "";
            JSONObject json = new JSONObject(responseBody);
            return json.optString("id", "manual_payout");
        } else {
            Scanner s = new Scanner(conn.getErrorStream()).useDelimiter("\\A");
            String errorBody = s.hasNext() ? s.next() : "";
            throw new RuntimeException("Payout failed with code " + responseCode + ": " + errorBody);
        }
    }

    // ─── Helper: HMAC-SHA256 Signature ───────────────────────────────────────
    private String hmacSha256(String data, String secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        SecretKeySpec secretKeySpec = new SecretKeySpec(
                secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        mac.init(secretKeySpec);
        byte[] hash = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return HexFormat.of().formatHex(hash);
    }
}
