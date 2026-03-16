-- eTODA v3 PostgreSQL Schema
-- Run: psql -U postgres -d etoda_db -f schema.sql

DROP TABLE IF EXISTS audit_logs     CASCADE;
DROP TABLE IF EXISTS trip_logs      CASCADE;
DROP TABLE IF EXISTS complaints     CASCADE;
DROP TABLE IF EXISTS payments       CASCADE;
DROP TABLE IF EXISTS fare_matrix    CASCADE;
DROP TABLE IF EXISTS qr_codes       CASCADE;
DROP TABLE IF EXISTS passengers     CASCADE;
-- mobile/auth tables
DROP TABLE IF EXISTS users          CASCADE;
DROP TABLE IF EXISTS drivers        CASCADE;

CREATE TABLE drivers (
  id SERIAL PRIMARY KEY,
  -- LOGIN / PROFILE FIELDS (mobile app)
  username VARCHAR(50) UNIQUE,
  password_hash VARCHAR(255),
  first_name VARCHAR(50),
  middle_name VARCHAR(50),
  last_name VARCHAR(50),
  phone_number VARCHAR(20),
  email VARCHAR(150),
  plate_number VARCHAR(20),
  body_number VARCHAR(20),
  is_active BOOLEAN DEFAULT TRUE,

  -- ADMIN PANEL FIELDS
  driver_code VARCHAR(10) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  franchise VARCHAR(20) UNIQUE NOT NULL,
  body_no VARCHAR(10),
  contact VARCHAR(20),
  license_no VARCHAR(30),
  association VARCHAR(100) DEFAULT 'Nagcarlan TODA',
  status VARCHAR(20) DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE qr_codes (
  id SERIAL PRIMARY KEY,
  driver_id INT REFERENCES drivers(id) ON DELETE CASCADE,
  franchise VARCHAR(20) NOT NULL,
  qr_id VARCHAR(60) UNIQUE NOT NULL,
  status VARCHAR(20) DEFAULT 'Active',
  issued_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  middle_name VARCHAR(50),
  last_name VARCHAR(50) NOT NULL,
  phone_number VARCHAR(20),
  email VARCHAR(150),
  password_hash VARCHAR(255) NOT NULL,
  status VARCHAR(20) DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT NOW()
);

-- old passengers table removed; the mobile app now uses users
-- CREATE TABLE passengers (
--   id SERIAL PRIMARY KEY,
--   passenger_code VARCHAR(10) UNIQUE NOT NULL,
--   name VARCHAR(100),
--   email VARCHAR(150),
--   session_type VARCHAR(20) DEFAULT 'Registered',
--   status VARCHAR(20) DEFAULT 'Active',
--   registered_at TIMESTAMP DEFAULT NOW()
-- );

CREATE TABLE fare_matrix (
  id SERIAL PRIMARY KEY,
  origin VARCHAR(100) NOT NULL,
  destination VARCHAR(100) NOT NULL,
  base_fare NUMERIC(8,2) NOT NULL,
  discounted_fare NUMERIC(8,2),
  night_fare NUMERIC(8,2),
  special_fare NUMERIC(8,2),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(origin, destination)
);

CREATE TABLE payments (
  id SERIAL PRIMARY KEY,
  ref_code VARCHAR(15) UNIQUE NOT NULL,
  passenger_id INT REFERENCES users(user_id),
  driver_id INT REFERENCES drivers(id),
  route VARCHAR(200),
  amount NUMERIC(8,2) NOT NULL,
  method VARCHAR(20) DEFAULT 'Cash',
  status VARCHAR(20) DEFAULT 'Pending',
  paid_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE complaints (
  id SERIAL PRIMARY KEY,
  report_code VARCHAR(15) UNIQUE NOT NULL,
  passenger_id INT REFERENCES users(user_id),
  driver_id INT REFERENCES drivers(id),
  violation_type VARCHAR(50),
  firebase_id VARCHAR(30),
  admin_notes TEXT,
  status VARCHAR(20) DEFAULT 'Pending',
  reported_at TIMESTAMP DEFAULT NOW(),
  resolved_at TIMESTAMP
);

CREATE TABLE trip_logs (
  id SERIAL PRIMARY KEY,
  trip_code VARCHAR(15) UNIQUE NOT NULL,
  passenger_id INT REFERENCES users(user_id),
  driver_id INT REFERENCES drivers(id),
  route VARCHAR(200),
  fare_amount NUMERIC(8,2),
  payment_method VARCHAR(20),
  duration_min INT,
  started_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE audit_logs (
  id SERIAL PRIMARY KEY,
  action VARCHAR(30) NOT NULL,
  entity VARCHAR(50) NOT NULL,
  entity_id VARCHAR(50),
  detail TEXT,
  performed_by VARCHAR(100) DEFAULT 'Admin',
  created_at TIMESTAMP DEFAULT NOW()
);

-- ── SEED DATA ────────────────────────────────────────────────────

INSERT INTO drivers (driver_code,name,franchise,body_no,contact,license_no,association,status) VALUES
  ('D-001','Juan A. Dela Cruz','NVC-001A','01','09123456789','NAG-123456','Nagcarlan TODA','Active'),
  ('D-002','Maria S. Reyes','NVC-002B','02','09987654321','NAG-654321','Nagcarlan TODA','Inactive'),
  ('D-003','Pedro M. Santos','NVC-003C','03','09112233445','NAG-789012','Nagcarlan TODA','Active'),
  ('D-004','Roberto C. Lim','NVC-004D','04','09223344556','NAG-321098','Nagcarlan TODA','Active'),
  ('D-005','Elena T. Garcia','NVC-005E','05','09334455667','NAG-456789','Nagcarlan TODA','Active');


-- give the initial mobile driver accounts simple credentials for testing
UPDATE drivers SET username='juan1', password_hash='pass123' WHERE driver_code='D-001';
UPDATE drivers SET username='maria1', password_hash='pass123' WHERE driver_code='D-002';

INSERT INTO qr_codes (driver_id,franchise,qr_id,status) VALUES
  (1,'NVC-001A','QR-AES-NVC001A-7d3f','Active'),
  (2,'NVC-002B','QR-AES-NVC002B-9a1c','Inactive'),
  (3,'NVC-003C','QR-AES-NVC003C-2b8e','Active'),
  (4,'NVC-004D','QR-AES-NVC004D-4c9a','Active'),
  (5,'NVC-005E','QR-AES-NVC005E-1e7b','Active');

-- passenger seeds removed; sample mobile users above cover the same purpose

-- seed sample mobile user accounts for login
INSERT INTO users (username,first_name,last_name,phone_number,email,password_hash) VALUES
  ('pass1','Maria','Lopez','09123456789','maria@example.com','secret'),
  ('pass2','Jose','Santos','09112223344','jose@example.com','secret');

INSERT INTO fare_matrix (origin,destination,base_fare,discounted_fare,night_fare,special_fare) VALUES
  ('Poblacion','Talangan',15.00,12.00,17.25,45.00),
  ('Poblacion','Malinao',20.00,16.00,23.00,60.00),
  ('Poblacion','Oobi',40.00,32.00,46.00,120.00),
  ('Poblacion','Banago',25.00,20.00,28.75,75.00),
  ('Oobi','Talangan',30.00,24.00,34.50,90.00);

INSERT INTO payments (ref_code,passenger_id,driver_id,route,amount,method,status) VALUES
  ('TXN-2834',1,1,'Poblacion to Talangan',15.00,'GCash','Settled'),
  ('TXN-2831',2,4,'Talangan to Poblacion',15.00,'Cash','Settled');

INSERT INTO complaints (report_code,passenger_id,driver_id,violation_type,firebase_id,status) VALUES
  ('R-001',1,1,'Overcharging','FB-RPT-77821','Pending'),
  ('R-004',2,4,'Unauthorized Route Deviation','FB-RPT-77102','Pending');

INSERT INTO trip_logs (trip_code,passenger_id,driver_id,route,fare_amount,payment_method,duration_min) VALUES
  ('TR-5230',1,1,'Poblacion to Talangan',15.00,'GCash',12),
  ('TR-5229',2,3,'Poblacion to Oobi',40.00,'Maya',28);

INSERT INTO audit_logs (action,entity,entity_id,detail,performed_by) VALUES
  ('ENROLL','Driver','D-001','Enrolled Juan A. Dela Cruz (NVC-001A)','Admin'),
  ('ENROLL','Driver','D-002','Enrolled Maria S. Reyes (NVC-002B)','Admin'),
  ('ENROLL','Driver','D-003','Enrolled Pedro M. Santos (NVC-003C)','Admin'),
  ('UPDATE','Driver','D-002','Maria S. Reyes status → Inactive','Admin'),
  ('CREATE','Fare','1','Poblacion → Talangan base ₱15.00','Admin'),
  ('UPDATE','Complaint','R-003','Status → Resolved','Admin'),
  ('REVOKE','QRCode','NVC-002B','QR status → Inactive','Admin');

SELECT 'eTODA v3 database ready!' AS message;
