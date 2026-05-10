import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/vaccine_type.dart';
import '../services/session.dart';

class ApiService {
  static String get baseUrl {
    if (kReleaseMode) return "https://animal-service-platform.onrender.com/api";
    if (kIsWeb) return "http://localhost:8080/api";
    return "http://10.0.2.2:8080/api";
  }

  // 🔐 AUTH
  static Future<Map<String, String>> _getHeaders() async {
    final token = await Session.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final trimmedEmail = email.trim();
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/service-provider/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": trimmedEmail, "password": password}),
      );
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == "null") return null;
        final data = jsonDecode(body);
        await Session.saveUser(data);
        return data;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> register(
      String name, String email, String password, String phone, String role, {String? licenseNumber}) async {
    final trimmedEmail = email.trim();
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/service-provider/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": trimmedEmail,
          "password": password,
          "phone": phone,
          "role": role,
          "licenseNumber": licenseNumber,
          "verificationStatus": role == "Doctor" ? "PENDING" : "APPROVED",
        }),
      );
      if (response.statusCode == 200 && response.body != "null") return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Register error: $e");
    }
    return null;
  }

  static Future<bool> uploadLicense(String email, String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse("$baseUrl/service-provider/upload-license"));
      request.fields['email'] = email;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final token = await Session.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Upload license error: $e");
      return false;
    }
  }

  // 🛡️ OTP
  static Future<bool> sendOtp(String email, String type) async {
    final trimmedEmail = email.trim();
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/otp/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": trimmedEmail, "type": type}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Send OTP error: $e");
    }
    return false;
  }

  static Future<bool> verifyOtp(String email, String code, String type) async {
    final trimmedEmail = email.trim();
    try {
      debugPrint("🚀 Verifying OTP: $trimmedEmail, Code: $code, Type: $type");
      final response = await http.post(
        Uri.parse("$baseUrl/otp/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": trimmedEmail, "code": code, "type": type}),
      );
      debugPrint("📡 OTP Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["status"] == "SUCCESS";
      }
    } catch (e) {
      debugPrint("❌ Verify OTP error: $e");
    }
    return false;
  }

  // 🏥 PROVIDERS
  static Future<List<dynamic>> getAllProviders({String? type}) async {
    try {
      String url = "$baseUrl/service-provider/providers";
      if (type != null && type != "All") url += "?type=$type";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get providers error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getProvidersByType(String type) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/service-provider/providers/type/$type"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get providers by type error: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getProviderProfile(String email) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/service-provider/email/$email"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get provider profile error: $e");
    }
    return null;
  }

  static Future<bool> updateProviderProfile(Map<String, dynamic> provider) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/service-provider/update"), // Actually it's PUT in controller, let me check
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(provider),
      );
      // Wait, I used PutMapping in controller. Let me use PUT here.
      final responsePut = await http.put(
        Uri.parse("$baseUrl/service-provider/update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(provider),
      );
      return responsePut.statusCode == 200;
    } catch (e) {
      debugPrint("Update provider profile error: $e");
    }
    return false;
  }

  // 📅 BOOKINGS
  static Future<void> createBooking(
    String email,
    String serviceType, {
    String? providerEmail,
    String? date,
    String? time,
    String visitType = 'IN_HOSPITAL',
    String? visitAddress,
    String? visitCity,
    String? visitPincode,
  }) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/bookings/create"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "ownerEmail": email,
          "providerEmail": providerEmail,
          "serviceType": serviceType,
          "status": "PENDING",
          "appointmentDate": date ?? DateTime.now().toString().split(' ')[0],
          "appointmentTime": time ?? "09:00 AM",
          "visitType": visitType,
          if (visitAddress != null) "visitAddress": visitAddress,
          if (visitCity != null) "visitCity": visitCity,
          if (visitPincode != null) "visitPincode": visitPincode,
        }),
      );
    } catch (e) {
      debugPrint("Create booking error: $e");
    }
  }

  static Future<List<dynamic>> getFarmerBookings(String email) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/bookings/owner/$email"), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get bookings error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getAllBookings() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/bookings/all"), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get all bookings error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getProviderBookings(String email) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/bookings/provider/$email"), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get provider bookings error: $e");
    }
    return [];
  }

  static Future<void> updateBookingStatus(int id, String status, {String? providerEmail}) async {
    try {
      String url = "$baseUrl/bookings/update/$id/$status";
      if (providerEmail != null) url += "?providerEmail=$providerEmail";
      await http.put(Uri.parse(url), headers: await _getHeaders());
    } catch (e) {
      debugPrint("Update status error: $e");
    }
  }

  static Future<Map<String, dynamic>> getBookingStats({String? email}) async {
    try {
      String url = "$baseUrl/bookings/stats";
      if (email != null) url += "?email=$email";
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get stats error: $e");
    }
    return {"total": 0, "pending": 0, "accepted": 0, "rejected": 0};
  }

  // 💬 CONSULTATIONS (Interactions)
  static Future<bool> deleteBooking(int id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/bookings/delete/$id"), headers: await _getHeaders());
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete booking error: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getConsultationNotes(int bookingId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/consultations/notes/$bookingId"), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get notes error: $e");
    }
    return [];
  }

  static Future<void> addConsultationNote(
      int bookingId, String role, String name, String content, String type) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/consultations/note"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "bookingId": bookingId,
          "senderRole": role,
          "senderName": name,
          "content": content,
          "noteType": type
        }),
      );
    } catch (e) {
      debugPrint("Add note error: $e");
    }
  }

  static Future<void> updateAvailability(String email, bool status) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/service-provider/availability"),
        headers: await _getHeaders(),
        body: jsonEncode({"email": email, "isAvailable": status}),
      );
    } catch (e) {
      debugPrint("Update availability error: $e");
    }
  }

  // 🐾 ANIMALS
  static Future<List<dynamic>> getFarmerAnimals(String email) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/animals?ownerEmail=$email"), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get animals error: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addAnimal(Map<String, dynamic> animal) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/animals"),
        headers: await _getHeaders(),
        body: jsonEncode(animal),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Add animal error: $e");
    }
    return null;
  }

  static Future<List<dynamic>> getAnimalVaccinations(int animalId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/animals/$animalId/vaccinations"), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get animal vaccinations error: $e");
    }
    return [];
  }

  static Future<void> addAnimalVaccination(int animalId, Map<String, dynamic> record) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/animals/$animalId/vaccinations"),
        headers: await _getHeaders(),
        body: jsonEncode(record),
      );
    } catch (e) {
      debugPrint("Add animal vaccination error: $e");
    }
  }

  static Future<void> saveFcmToken(String email, String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: await _getHeaders(),
        body: jsonEncode({"email": email, "token": token}),
      );
    } catch (e) {
      debugPrint("Save FCM token error: $e");
    }
  }

  // 💉 VACCINATIONS (General)
  static Future<void> addVaccinationRecord({
    required String ownerEmail,
    required String animal,
    required String vaccine,
    String? dateGiven,
    String? nextDueDate,
    String? status,
    String? providerEmail,
    String? notes,
  }) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/vaccinations"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "ownerEmail": ownerEmail,
          "animalName": animal,
          "vaccineName": vaccine,
          "dateGiven": dateGiven,
          "nextDueDate": nextDueDate ?? (dateGiven != null ? DateTime.parse(dateGiven).add(const Duration(days: 180)).toString().split(' ')[0] : null),
          "status": status ?? "COMPLETED",
          "providerEmail": providerEmail,
          "notes": notes,
        }),
      );
    } catch (e) {
      debugPrint("Add vaccination error: $e");
    }
  }

  static Future<List<dynamic>> getFarmerVaccinations(String email) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/vaccinations/owner/$email"), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get vaccinations error: $e");
    }
    return [];
  }

  static Future<bool> submitReview(Map<String, dynamic> review) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reviews"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(review),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Submit review error: $e");
    }
    return false;
  }

  static Future<List<dynamic>> getProviderReviews(int providerId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/reviews/provider/$providerId"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get reviews error: $e");
    }
    return [];
  }

  // 🔍 LOOKUPS
  static Future<List<String>> getSpecies() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/lookup/species"));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).map((e) => e['name'].toString()).toList();
      }
    } catch (e) { debugPrint("Lookup error: $e"); }
    return ["Cow", "Buffalo", "Goat"];
  }

  static Future<bool> addSpecies(String name) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/lookup/species"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Add species error: $e");
    }
    return false;
  }

  static Future<List<VaccineTypeModel>> getVaccines({String? species}) async {
    try {
      String url = "$baseUrl/lookup/vaccines";
      if (species != null && species != 'All') url += "?species=$species";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .map((e) => VaccineTypeModel.fromJson(e))
            .toList();
      }
    } catch (e) { debugPrint("Lookup error: $e"); }
    return [];
  }

  static Future<List<String>> getServiceTypes() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/lookup/services"));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).map((e) => e['name'].toString()).toList();
      }
    } catch (e) { debugPrint("Lookup error: $e"); }
    return ["Consultation", "Vaccination"];
  }

  static Future<List<String>> getDistricts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/lookup/districts"));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).map((e) => e['name'].toString()).toList();
      }
    } catch (e) { debugPrint("Lookup error: $e"); }
    return ["Pune", "Mumbai", "Satara"];
  }

  // 💳 PAYMENTS
  static Future<Map<String, dynamic>?> createRazorpayOrder(int bookingId, double amount, String ownerEmail, String providerEmail) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/create-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bookingId": bookingId,
          "amount": amount,
          "ownerEmail": ownerEmail,
          "providerEmail": providerEmail
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Create order error: $e");
    }
    return null;
  }

  static Future<bool> verifyPayment(String orderId, String paymentId, String signature) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "razorpay_order_id": orderId,
          "razorpay_payment_id": paymentId,
          "razorpay_signature": signature
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["success"] == true;
      }
    } catch (e) {
      debugPrint("Verify payment error: $e");
    }
    return false;
  }

  static Future<bool> recordCashPayment(int bookingId, double amount, String ownerEmail, String providerEmail) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/cash"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bookingId": bookingId,
          "amount": amount,
          "ownerEmail": ownerEmail,
          "providerEmail": providerEmail
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Record cash payment error: $e");
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getProviderEarnings(String email) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/payments/earnings/$email"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Get earnings error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> withdrawEarnings(String email, String upiId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payments/withdraw"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "upiId": upiId,
          "amount": amount
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Withdraw earnings error: $e");
    }
    return null;
  }

  // 🛡️ ADMIN
  static Future<Map<String, dynamic>?> getAdminStats() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/stats"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { debugPrint("Admin stats error: $e"); }
    return null;
  }

  static Future<List<dynamic>> getPendingDoctors() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/pending-doctors"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { debugPrint("Pending doctors error: $e"); }
    return [];
  }

  static Future<List<dynamic>> getAllDoctors({String? status}) async {
    try {
      String url = "$baseUrl/admin/all-doctors";
      if (status != null) url += "?status=$status";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { debugPrint("All doctors error: $e"); }
    return [];
  }

  static Future<List<dynamic>> getAllPetOwners() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/all-owners"));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { debugPrint("All owners error: $e"); }
    return [];
  }

  static Future<bool> verifyDoctor(int id, String status, {String? reason}) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/verify-doctor/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status, if (reason != null) "reason": reason}),
      );
      return response.statusCode == 200;
    } catch (e) { debugPrint("Verify doctor error: $e"); }
    return false;
  }
}

