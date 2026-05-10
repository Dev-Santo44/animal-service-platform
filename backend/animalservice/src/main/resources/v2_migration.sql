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
-- (Updated for Animal_Vaccination_Dataset integration)
-- Ensure existing columns are converted to TEXT for long scientific data
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vaccine_types' AND column_name='schedule') THEN
    ALTER TABLE vaccine_types ALTER COLUMN schedule TYPE TEXT;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vaccine_types' AND column_name='side_effects') THEN
    ALTER TABLE vaccine_types ALTER COLUMN side_effects TYPE TEXT;
  END IF;
END $$;

ALTER TABLE vaccine_types 
  ADD COLUMN IF NOT EXISTS disease_prevented    TEXT,
  ADD COLUMN IF NOT EXISTS target_animals       TEXT,
  ADD COLUMN IF NOT EXISTS core_status          VARCHAR(20)  DEFAULT 'Non-core',
  ADD COLUMN IF NOT EXISTS is_zoonotic          BOOLEAN      DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS pathogen_name        TEXT,
  ADD COLUMN IF NOT EXISTS pathogen_type        TEXT,
  ADD COLUMN IF NOT EXISTS mechanism_of_action  TEXT,
  ADD COLUMN IF NOT EXISTS why_vaccinate        TEXT,
  ADD COLUMN IF NOT EXISTS who_is_affected      TEXT,
  ADD COLUMN IF NOT EXISTS immunity_duration    TEXT,
  ADD COLUMN IF NOT EXISTS route_of_admin       TEXT,
  ADD COLUMN IF NOT EXISTS legal_status         TEXT;

-- 5. Create Vaccine Glossary Table
CREATE TABLE IF NOT EXISTS vaccine_glossary (
  id          BIGSERIAL PRIMARY KEY,
  term        VARCHAR(100) NOT NULL,
  definition  TEXT         NOT NULL
);


-- 6. Add Species Tag Index for Fast Filtering
CREATE INDEX IF NOT EXISTS idx_vaccine_target_animals
  ON vaccine_types USING gin(to_tsvector('english', COALESCE(target_animals, '')));

-- 7. Ensure Admin account exists with BCrypt password
INSERT INTO service_providers (name, email, password, role, verification_status)
VALUES ('Admin', 'admin@animalcare.com', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.TVu4ATA', 'Admin', 'APPROVED')
ON CONFLICT (email) DO UPDATE SET 
  password = EXCLUDED.password, 
  verification_status = 'APPROVED';


