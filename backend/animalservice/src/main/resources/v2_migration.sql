-- SQL Migration for Animal Service Platform v2.0

-- 1. Global Rename Roles
UPDATE users SET role = 'Pet Owner' WHERE role = 'Farmer';
UPDATE users SET role = 'Doctor' WHERE role = 'Service Provider';
UPDATE service_providers SET role = 'Doctor' WHERE role = 'Service Provider';

-- 2. Add ServiceProvider Verification Columns
ALTER TABLE service_providers ADD COLUMN license_number VARCHAR(255);
ALTER TABLE service_providers ADD COLUMN license_file_url VARCHAR(255);
ALTER TABLE service_providers ADD COLUMN verification_status VARCHAR(20) DEFAULT 'PENDING';
ALTER TABLE service_providers ADD COLUMN rejection_reason TEXT;

-- 3. Add Booking Visit Type Columns
ALTER TABLE bookings ADD COLUMN visit_type VARCHAR(20) DEFAULT 'IN_HOSPITAL';
ALTER TABLE bookings ADD COLUMN visit_address VARCHAR(255);
ALTER TABLE bookings ADD COLUMN visit_city VARCHAR(100);
ALTER TABLE bookings ADD COLUMN visit_pincode VARCHAR(20);

-- 4. Expand VaccineType Columns
ALTER TABLE vaccine_types ADD COLUMN target_disease VARCHAR(255);
ALTER TABLE vaccine_types ADD COLUMN target_species VARCHAR(255);
ALTER TABLE vaccine_types ADD COLUMN schedule VARCHAR(255);
ALTER TABLE vaccine_types ADD COLUMN dosage VARCHAR(255);
ALTER TABLE vaccine_types ADD COLUMN side_effects VARCHAR(255);
ALTER TABLE vaccine_types ADD COLUMN description TEXT;
ALTER TABLE vaccine_types ADD COLUMN manufacturer VARCHAR(255);

-- 5. Insert Admin Account (UPSERT to fix legacy plain-text passwords)
INSERT INTO service_provider (name, email, password, role, verification_status) 
VALUES ('Admin', 'admin@animalcare.com', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.TVu4ATA', 'Admin', 'APPROVED')
ON CONFLICT (email) DO UPDATE SET password = EXCLUDED.password, verification_status = 'APPROVED';
