-- Supabase Data Migration Script (PostgreSQL)
-- Run this in the Supabase SQL Editor to populate your database with realistic data

-- 1. Seed Service Providers (Doctors)
INSERT INTO service_provider (name, email, password, role, specialization, clinic_name, phone, district, latitude, longitude, avg_rating, is_available, consultation_fee)
VALUES 
('Dr. Rajesh Patil', 'rajesh@example.com', 'pass123', 'Service Provider', 'Livestock Specialist', 'Patil Veterinary Clinic', '9876543210', 'Pune', 18.5204, 73.8567, 4.8, true, 500.0),
('Dr. Sneha Kulkarni', 'sneha@example.com', 'pass123', 'Service Provider', 'Poultry Expert', 'City Pet & Farm Care', '9876543211', 'Mumbai', 19.0760, 72.8777, 4.5, true, 450.0),
('Govt. Vet Center', 'govt@vet.in', 'pass123', 'Service Provider', 'General Veterinary', 'Municipal Veterinary Hospital', '020-2567890', 'Pune', 18.5308, 73.8474, 4.2, true, 0.0),
('Animal Relief NGO', 'info@animalrelief.org', 'pass123', 'Service Provider', 'Emergency Care', 'Relief Center', '1800-123-456', 'Pune', 18.5089, 73.9259, 4.9, true, 100.0),
('Dr. Amit Shinde', 'amit@example.com', 'pass123', 'Service Provider', 'Surgery Specialist', 'Shinde Animal Hospital', '9876543212', 'Nagpur', 21.1458, 79.0882, 4.7, true, 600.0);

-- 2. Seed Vaccination Records for demo
INSERT INTO vaccination_records (animal_name, vaccine_name, date_given, next_due_date, status, farmer_email)
VALUES 
('Laxmi (Cow)', 'FMD Vaccine', CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE + INTERVAL '170 days', 'COMPLETED', 'farmer@example.com'),
('Moti (Dog)', 'Rabies', CURRENT_DATE - INTERVAL '60 days', CURRENT_DATE + INTERVAL '305 days', 'COMPLETED', 'farmer@example.com'),
('Rani (Goat)', 'PPR Vaccine', CURRENT_DATE + INTERVAL '5 days', CURRENT_DATE + INTERVAL '185 days', 'PENDING', 'farmer@example.com');

-- 3. Seed Sample Bookings
INSERT INTO bookings (farmer_email, provider_email, service_type, appointment_time, status, created_at)
VALUES 
('farmer@example.com', 'rajesh@example.com', 'Regular Checkup', '2026-05-05 10:00:00', 'ACCEPTED', NOW()),
('farmer@example.com', 'sneha@example.com', 'Emergency Help', '2026-05-02 14:30:00', 'PENDING', NOW()),
('user@example.com', 'rajesh@example.com', 'Vaccination', '2026-05-10 11:00:00', 'ACCEPTED', NOW());

-- 4. Seed Consultation Notes (Chat & Medical)
INSERT INTO consultation_notes (booking_id, sender_role, sender_name, content, note_type, created_at)
VALUES 
(1, 'Service Provider', 'Dr. Rajesh Patil', 'Hello, how is the cow doing today?', 'MESSAGE', NOW()),
(1, 'Farmer', 'Farmer John', 'She is much better, but still has a slight limp.', 'MESSAGE', NOW()),
(1, 'Service Provider', 'Dr. Rajesh Patil', 'Paracetamol 500mg — 1 tablet daily', 'MEDICATION', NOW()),
(1, 'Service Provider', 'Dr. Rajesh Patil', 'Consultation Fee: ₹500', 'CHARGE', NOW());

-- 5. Seed Super Admin User (admin@pawcare.com / admin123)
-- The backend service automatically upgrades plain-text passwords to BCrypt on first login
INSERT INTO service_provider (name, email, password, role, is_available, verification_status)
VALUES ('Super Admin', 'admin@pawcare.com', 'admin123', 'Admin', true, 'APPROVED');

