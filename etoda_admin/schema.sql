-- 1. SETUP & CLEANUP
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;

-- Wipe existing data if tables exist
SET session_replication_role = 'replica';
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.complaints CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.trip_logs CASCADE;
DROP TABLE IF EXISTS public.qr_codes CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.admins CASCADE;
DROP TABLE IF EXISTS public.fare_matrix CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
SET session_replication_role = 'origin';

-- 2. TABLE CREATION
CREATE TABLE public.admins (
    admin_id SERIAL PRIMARY KEY,
    username character varying(50) NOT NULL UNIQUE,
    password_hash character varying(255) NOT NULL,
    full_name character varying(100),
    email character varying(150),
    created_at timestamp without time zone DEFAULT now()
);

CREATE TABLE public.users (
    user_id SERIAL PRIMARY KEY,
    username character varying(50) NOT NULL UNIQUE,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    phone_number character varying(20),
    email character varying(150),
    password_hash character varying(255) NOT NULL,
    status character varying(20) DEFAULT 'Active',
    created_at timestamp without time zone DEFAULT now(),
    profile_pic text
);

CREATE TABLE public.drivers (
    id SERIAL PRIMARY KEY,
    username character varying(50) UNIQUE,
    password_hash character varying(255),
    is_active boolean DEFAULT true,
    status character varying(20) DEFAULT 'Active',
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    contact character varying(20),
    email character varying(150),
    driver_code character varying(10) NOT NULL UNIQUE,
    franchise character varying(20) NOT NULL UNIQUE,
    body_no character varying(20),
    plate_number character varying(20),
    license_no character varying(30),
    association character varying(100) DEFAULT 'Nagcarlan TODA',
    created_at timestamp without time zone DEFAULT now(),
    profile_pic text,
    name text GENERATED ALWAYS AS (TRIM(BOTH FROM (first_name || ' ' || COALESCE(middle_name || ' ', '') || last_name))) STORED
);

CREATE TABLE public.qr_codes (
    id SERIAL PRIMARY KEY,
    driver_id integer REFERENCES public.drivers(id) ON DELETE CASCADE,
    franchise character varying(20) NOT NULL,
    qr_id character varying(60) NOT NULL UNIQUE,
    status character varying(20) DEFAULT 'Active',
    issued_at timestamp without time zone DEFAULT now()
);

CREATE TABLE public.fare_matrix (
    id SERIAL PRIMARY KEY,
    origin character varying(100) NOT NULL,
    destination character varying(100) NOT NULL,
    base_fare numeric(8,2) NOT NULL,
    discounted_fare numeric(8,2),
    night_fare numeric(8,2),
    special_fare numeric(8,2),
    created_at timestamp without time zone DEFAULT now(),
    UNIQUE(origin, destination)
);

CREATE TABLE public.payments (
    id SERIAL PRIMARY KEY,
    ref_code character varying(15) NOT NULL UNIQUE,
    passenger_id integer REFERENCES public.users(user_id),
    driver_id integer REFERENCES public.drivers(id),
    route character varying(200),
    amount numeric(8,2) NOT NULL,
    method character varying(20) DEFAULT 'Cash',
    status character varying(20) DEFAULT 'Pending',
    paid_at timestamp without time zone DEFAULT now()
);

CREATE TABLE public.complaints (
    id SERIAL PRIMARY KEY,
    report_code character varying(15) NOT NULL UNIQUE,
    passenger_id integer REFERENCES public.users(user_id),
    driver_id integer REFERENCES public.drivers(id),
    violation_type character varying(50),
    firebase_id character varying(30),
    admin_notes text,
    status character varying(20) DEFAULT 'Pending',
    reported_at timestamp without time zone DEFAULT now(),
    resolved_at timestamp without time zone
);

CREATE TABLE public.trip_logs (
    id SERIAL PRIMARY KEY,
    trip_code character varying(15) NOT NULL UNIQUE,
    passenger_id integer REFERENCES public.users(user_id),
    driver_id integer REFERENCES public.drivers(id),
    route character varying(200),
    fare_amount numeric(8,2),
    payment_method character varying(20),
    duration_min integer,
    started_at timestamp without time zone DEFAULT now()
);

CREATE TABLE public.audit_logs (
    id SERIAL PRIMARY KEY,
    action character varying(30) NOT NULL,
    entity character varying(50) NOT NULL,
    entity_id character varying(50),
    detail text,
    performed_by character varying(100) DEFAULT 'Admin',
    created_at timestamp without time zone DEFAULT now()
);

CREATE TABLE public.notifications (
    id SERIAL PRIMARY KEY,
    title character varying(255) NOT NULL,
    description text,
    type character varying(50),
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);

-- 3. INSERT DATA
INSERT INTO public.admins (admin_id, username, password_hash, full_name, email, created_at) VALUES
(1, 'admin', 'admin123', 'Portal Administrator', 'admin@example.com', '2026-03-13 16:38:10.127763');

INSERT INTO public.users (user_id, username, first_name, middle_name, last_name, phone_number, email, password_hash, status, created_at, profile_pic) VALUES
(1, 'pass1', 'Maria', NULL, 'Lopez', '09123456789', 'maria@example.com', 'secret', 'Active', '2026-03-13 16:38:10.127763', NULL),
(2, 'pass2', 'Jose', NULL, 'Santos', '09112223344', 'jose@example.com', 'secret', 'Active', '2026-03-13 16:38:10.127763', NULL),
(3, 'kendricklamar', 'Maki', 'Bao', 'Dilaw', '09123456789', 'maki@gmail.com', '123456', 'Active', '2026-03-16 09:13:33.912015', NULL),
(4, 'andrewpogi', 'Andrew', '', 'Kawayan', '09123456789', 'andrew@wew.com', 'patinginngtiti', 'Active', '2026-03-16 14:25:33.885943', 'p_4_1773643119.jpg');

INSERT INTO public.drivers (id, username, password_hash, is_active, status, first_name, middle_name, last_name, contact, email, driver_code, franchise, body_no, plate_number, license_no, association, created_at, profile_pic) VALUES
(1, 'juan1', 'pass123', true, 'Active', 'Juan', 'A.', 'Dela Cruz', '09123456789', NULL, 'D-001', 'NVC-001A', '01', NULL, 'NAG-123456', 'Nagcarlan TODA', '2026-03-13 16:38:10.127763', NULL),
(2, 'maria1', 'pass123', true, 'Inactive', 'Maria', 'S.', 'Reyes', '09987654321', NULL, 'D-002', 'NVC-002B', '02', NULL, 'NAG-654321', 'Nagcarlan TODA', '2026-03-13 16:38:10.127763', NULL),
(3, NULL, NULL, true, 'Active', 'Pedro', 'M.', 'Santos', '09112233445', NULL, 'D-003', 'NVC-003C', '03', NULL, 'NAG-789012', 'Nagcarlan TODA', '2026-03-13 16:38:10.127763', NULL),
(4, NULL, NULL, true, 'Active', 'Roberto', 'C.', 'Lim', '09223344556', NULL, 'D-004', 'NVC-004D', '04', NULL, 'NAG-321098', 'Nagcarlan TODA', '2026-03-13 16:38:10.127763', NULL),
(5, NULL, NULL, true, 'Active', 'Elena', 'T.', 'Garcia', '09334455667', NULL, 'D-005', 'NVC-005E', '05', NULL, 'NAG-456789', 'Nagcarlan TODA', '2026-03-13 16:38:10.127763', NULL),
(6, 'mjsuniega', '123123', true, 'Active', 'Michael John', 'M.', 'Suniega', '09123456789', 'michael@example.com', 'D-006', 'NVC-006F', 'ABC-1234', 'ABC-1234', 'NAG-998877', 'Nagcarlan TODA', '2026-03-13 16:40:27.22025', NULL);

INSERT INTO public.qr_codes (id, driver_id, franchise, qr_id, status, issued_at) VALUES
(1, 1, 'NVC-001A', 'QR-AES-NVC001A-7d3f', 'Active', '2026-03-13 16:38:10.127763'),
(2, 2, 'NVC-002B', 'QR-AES-NVC002B-9a1c', 'Inactive', '2026-03-13 16:38:10.127763'),
(3, 3, 'NVC-003C', 'QR-AES-NVC003C-2b8e', 'Active', '2026-03-13 16:38:10.127763'),
(4, 4, 'NVC-004D', 'QR-AES-NVC004D-4c9a', 'Active', '2026-03-13 16:38:10.127763'),
(5, 5, 'NVC-005E', 'QR-AES-NVC005E-1e7b', 'Active', '2026-03-13 16:38:10.127763');

INSERT INTO public.fare_matrix (id, origin, destination, base_fare, discounted_fare, night_fare, special_fare, created_at) VALUES
(1, 'Poblacion', 'Talangan', 15.00, 12.00, 17.25, 45.00, '2026-03-13 16:38:10.127763'),
(2, 'Poblacion', 'Malinao', 20.00, 16.00, 23.00, 60.00, '2026-03-13 16:38:10.127763'),
(3, 'Poblacion', 'Oobi', 40.00, 32.00, 46.00, 120.00, '2026-03-13 16:38:10.127763'),
(4, 'Poblacion', 'Banago', 25.00, 20.00, 28.75, 75.00, '2026-03-13 16:38:10.127763'),
(5, 'Oobi', 'Talangan', 30.00, 24.00, 34.50, 90.00, '2026-03-13 16:38:10.127763');

INSERT INTO public.payments (id, ref_code, passenger_id, driver_id, route, amount, method, status, paid_at) VALUES
(1, 'TXN-2834', 1, 1, 'Poblacion to Talangan', 15.00, 'GCash', 'Settled', '2026-03-13 16:38:10.127763'),
(2, 'TXN-2831', 2, 4, 'Talangan to Poblacion', 15.00, 'Cash', 'Settled', '2026-03-13 16:38:10.127763');

INSERT INTO public.complaints (id, report_code, passenger_id, driver_id, violation_type, firebase_id, admin_notes, status, reported_at, resolved_at) VALUES
(1, 'R-001', 1, 1, 'Overcharging', 'FB-RPT-77821', NULL, 'Pending', '2026-03-13 16:38:10.127763', NULL),
(2, 'R-004', 2, 4, 'Unauthorized Route Deviation', 'FB-RPT-77102', NULL, 'Pending', '2026-03-13 16:38:10.127763', NULL);

INSERT INTO public.trip_logs (id, trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at) VALUES
(1, 'TR-5230', 1, 1, 'Poblacion to Talangan', 15.00, 'GCash', 12, '2026-03-13 16:38:10.127763'),
(2, 'TR-5229', 2, 3, 'Poblacion to Oobi', 40.00, 'Maya', 28, '2026-03-13 16:38:10.127763');

INSERT INTO public.audit_logs (id, action, entity, entity_id, detail, performed_by, created_at) VALUES
(1, 'ENROLL', 'Driver', 'D-001', 'Enrolled Juan A. Dela Cruz', 'Admin', '2026-03-13 16:38:10.127763'),
(2, 'ENROLL', 'Driver', 'D-002', 'Enrolled Maria S. Reyes', 'Admin', '2026-03-13 16:38:10.127763'),
(3, 'ENROLL', 'Driver', 'D-003', 'Enrolled Pedro M. Santos', 'Admin', '2026-03-13 16:38:10.127763'),
(4, 'UPDATE', 'Driver', 'D-002', 'Maria S. Reyes status → Inactive', 'Admin', '2026-03-13 16:38:10.127763'),
(5, 'CREATE', 'Fare', '1', 'Poblacion → Talangan base ₱15.00', 'Admin', '2026-03-13 16:38:10.127763'),
(6, 'UPDATE', 'Complaint', 'R-003', 'Status → Resolved', 'Admin', '2026-03-13 16:38:10.127763'),
(7, 'REVOKE', 'QRCode', 'NVC-002B', 'QR status → Inactive', 'Admin', '2026-03-13 16:38:10.127763'),
(8, 'UPDATE', 'Driver', '2', 'Updated fields: status=$1', 'Admin', '2026-03-16 10:14:52.551666'),
(17, 'UPDATE', 'Driver', '6', 'Profile updated', 'Admin', '2026-03-16 14:47:11.033199');

-- 4. SEQUENCE RESET (IMPORTANT)
SELECT setval('public.admins_admin_id_seq', (SELECT MAX(admin_id) FROM public.admins));
SELECT setval('public.users_user_id_seq', (SELECT MAX(user_id) FROM public.users));
SELECT setval('public.drivers_id_seq', (SELECT MAX(id) FROM public.drivers));
SELECT setval('public.qr_codes_id_seq', (SELECT MAX(id) FROM public.qr_codes));
SELECT setval('public.fare_matrix_id_seq', (SELECT MAX(id) FROM public.fare_matrix));
SELECT setval('public.payments_id_seq', (SELECT MAX(id) FROM public.payments));
SELECT setval('public.complaints_id_seq', (SELECT MAX(id) FROM public.complaints));
SELECT setval('public.trip_logs_id_seq', (SELECT MAX(id) FROM public.trip_logs));
SELECT setval('public.audit_logs_id_seq', (SELECT MAX(id) FROM public.audit_logs));
SELECT setval('public.notifications_id_seq', COALESCE((SELECT MAX(id) FROM public.notifications), 1), false);