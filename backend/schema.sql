-- eTODA v3 PostgreSQL Schema
-- Run: psql -U postgres -d etoda_db -f schema.sql

DROP TABLE IF EXISTS audit_logs     CASCADE;
DROP TABLE IF EXISTS trip_logs      CASCADE;
DROP TABLE IF EXISTS complaints     CASCADE;
DROP TABLE IF EXISTS payments       CASCADE;
DROP TABLE IF EXISTS fare_matrix    CASCADE;
DROP TABLE IF EXISTS qr_codes       CASCADE;
DROP TABLE IF EXISTS passengers     CASCADE;
DROP TABLE IF EXISTS drivers        CASCADE;

CREATE TABLE drivers (
  id SERIAL PRIMARY KEY,
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

CREATE TABLE passengers (
  id SERIAL PRIMARY KEY,
  passenger_code VARCHAR(10) UNIQUE NOT NULL,
  name VARCHAR(100),
  email VARCHAR(150),
  session_type VARCHAR(20) DEFAULT 'Registered',
  status VARCHAR(20) DEFAULT 'Active',
  registered_at TIMESTAMP DEFAULT NOW()
);

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
  passenger_id INT REFERENCES passengers(id),
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
  passenger_id INT REFERENCES passengers(id),
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
  passenger_id INT REFERENCES passengers(id),
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

INSERT INTO qr_codes (driver_id,franchise,qr_id,status) VALUES
  (1,'NVC-001A','QR-AES-NVC001A-7d3f','Active'),
  (2,'NVC-002B','QR-AES-NVC002B-9a1c','Inactive'),
  (3,'NVC-003C','QR-AES-NVC003C-2b8e','Active'),
  (4,'NVC-004D','QR-AES-NVC004D-4c9a','Active'),
  (5,'NVC-005E','QR-AES-NVC005E-1e7b','Active');

INSERT INTO passengers (passenger_code,name,email,session_type,status) VALUES
  ('P-001','Maria Lopez','maria@email.com','Registered','Active'),
  ('P-002','Jose Santos','jose@email.com','Registered','Active'),
  ('P-003','Ana Reyes','ana@email.com','Registered','Active'),
  ('G-039','Guest User',NULL,'Guest','Temp Session');

INSERT INTO fare_matrix (origin,destination,base_fare,discounted_fare,night_fare,special_fare) VALUES
  ('Poblacion','Talangan',15.00,12.00,17.25,45.00),
  ('Poblacion','Malinao',20.00,16.00,23.00,60.00),
  ('Poblacion','Oobi',40.00,32.00,46.00,120.00),
  ('Poblacion','Banago',25.00,20.00,28.75,75.00),
  ('Oobi','Talangan',30.00,24.00,34.50,90.00);

INSERT INTO payments (ref_code,passenger_id,driver_id,route,amount,method,status) VALUES
  ('TXN-2834',1,1,'Poblacion to Talangan',15.00,'GCash','Settled'),
  ('TXN-2833',1,3,'Poblacion to Oobi',40.00,'Maya','Settled'),
  ('TXN-2832',4,5,'Poblacion to Banago',25.00,'Card','Pending'),
  ('TXN-2831',2,4,'Talangan to Poblacion',15.00,'Cash','Settled'),
  ('TXN-2830',3,2,'Malinao to Poblacion',20.00,'GCash','Settled');

INSERT INTO complaints (report_code,passenger_id,driver_id,violation_type,firebase_id,status) VALUES
  ('R-001',1,1,'Overcharging','FB-RPT-77821','Pending'),
  ('R-002',1,3,'Discourteous Behavior','FB-RPT-77634','Investigating'),
  ('R-003',4,2,'Reckless Driving','FB-RPT-77411','Resolved'),
  ('R-004',2,4,'Unauthorized Route Deviation','FB-RPT-77102','Pending');

INSERT INTO trip_logs (trip_code,passenger_id,driver_id,route,fare_amount,payment_method,duration_min) VALUES
  ('TR-5230',1,1,'Poblacion to Talangan',15.00,'GCash',12),
  ('TR-5229',2,3,'Poblacion to Oobi',40.00,'Maya',28),
  ('TR-5228',4,5,'Nagcarlan to Underground Cemetery',25.00,'Cash',8),
  ('TR-5227',4,4,'Talangan to Poblacion',15.00,'Cash',10),
  ('TR-5226',3,2,'Malinao to Poblacion',20.00,'GCash',15);

INSERT INTO audit_logs (action,entity,entity_id,detail,performed_by) VALUES
  ('ENROLL','Driver','D-001','Enrolled Juan A. Dela Cruz (NVC-001A)','Admin'),
  ('ENROLL','Driver','D-002','Enrolled Maria S. Reyes (NVC-002B)','Admin'),
  ('ENROLL','Driver','D-003','Enrolled Pedro M. Santos (NVC-003C)','Admin'),
  ('UPDATE','Driver','D-002','Maria S. Reyes status → Inactive','Admin'),
  ('CREATE','Fare','1','Poblacion → Talangan base ₱15.00','Admin'),
  ('UPDATE','Complaint','R-003','Status → Resolved','Admin'),
  ('REVOKE','QRCode','NVC-002B','QR status → Inactive','Admin');

SELECT 'eTODA v3 database ready!' AS message;
