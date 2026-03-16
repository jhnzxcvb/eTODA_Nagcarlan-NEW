--
-- PostgreSQL database dump
--

\restrict PWuFjFT8ZxW7YpdMs6B6IOtXTjXi16fiUmgyVOMa2efkQM6dLnpL4EEDTKe1JXQ

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-03-16 15:09:21

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 226 (class 1259 OID 24798)
-- Name: admins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admins (
    admin_id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(100),
    email character varying(150),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.admins OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 24797)
-- Name: admins_admin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admins_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admins_admin_id_seq OWNER TO postgres;

--
-- TOC entry 5150 (class 0 OID 0)
-- Dependencies: 225
-- Name: admins_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admins_admin_id_seq OWNED BY public.admins.admin_id;


--
-- TOC entry 236 (class 1259 OID 24899)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    action character varying(30) NOT NULL,
    entity character varying(50) NOT NULL,
    entity_id character varying(50),
    detail text,
    performed_by character varying(100) DEFAULT 'Admin'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 24898)
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO postgres;

--
-- TOC entry 5151 (class 0 OID 0)
-- Dependencies: 235
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- TOC entry 232 (class 1259 OID 24852)
-- Name: complaints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.complaints (
    id integer NOT NULL,
    report_code character varying(15) NOT NULL,
    passenger_id integer,
    driver_id integer,
    violation_type character varying(50),
    firebase_id character varying(30),
    admin_notes text,
    status character varying(20) DEFAULT 'Pending'::character varying,
    reported_at timestamp without time zone DEFAULT now(),
    resolved_at timestamp without time zone
);


ALTER TABLE public.complaints OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 24851)
-- Name: complaints_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.complaints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.complaints_id_seq OWNER TO postgres;

--
-- TOC entry 5152 (class 0 OID 0)
-- Dependencies: 231
-- Name: complaints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.complaints_id_seq OWNED BY public.complaints.id;


--
-- TOC entry 220 (class 1259 OID 24738)
-- Name: drivers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drivers (
    id integer NOT NULL,
    username character varying(50),
    password_hash character varying(255),
    first_name character varying(50),
    middle_name character varying(50),
    last_name character varying(50),
    phone_number character varying(20),
    email character varying(150),
    plate_number character varying(20),
    body_number character varying(20),
    is_active boolean DEFAULT true,
    driver_code character varying(10) NOT NULL,
    name character varying(100) NOT NULL,
    franchise character varying(20) NOT NULL,
    body_no character varying(10),
    contact character varying(20),
    license_no character varying(30),
    association character varying(100) DEFAULT 'Nagcarlan TODA'::character varying,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.drivers OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 24737)
-- Name: drivers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.drivers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.drivers_id_seq OWNER TO postgres;

--
-- TOC entry 5153 (class 0 OID 0)
-- Dependencies: 219
-- Name: drivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.drivers_id_seq OWNED BY public.drivers.id;


--
-- TOC entry 228 (class 1259 OID 24813)
-- Name: fare_matrix; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fare_matrix (
    id integer NOT NULL,
    origin character varying(100) NOT NULL,
    destination character varying(100) NOT NULL,
    base_fare numeric(8,2) NOT NULL,
    discounted_fare numeric(8,2),
    night_fare numeric(8,2),
    special_fare numeric(8,2),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.fare_matrix OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 24812)
-- Name: fare_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fare_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fare_matrix_id_seq OWNER TO postgres;

--
-- TOC entry 5154 (class 0 OID 0)
-- Dependencies: 227
-- Name: fare_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fare_matrix_id_seq OWNED BY public.fare_matrix.id;


--
-- TOC entry 238 (class 1259 OID 24914)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    type character varying(50),
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 24913)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- TOC entry 5155 (class 0 OID 0)
-- Dependencies: 237
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 230 (class 1259 OID 24827)
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id integer NOT NULL,
    ref_code character varying(15) NOT NULL,
    passenger_id integer,
    driver_id integer,
    route character varying(200),
    amount numeric(8,2) NOT NULL,
    method character varying(20) DEFAULT 'Cash'::character varying,
    status character varying(20) DEFAULT 'Pending'::character varying,
    paid_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 24826)
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_id_seq OWNER TO postgres;

--
-- TOC entry 5156 (class 0 OID 0)
-- Dependencies: 229
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- TOC entry 222 (class 1259 OID 24761)
-- Name: qr_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qr_codes (
    id integer NOT NULL,
    driver_id integer,
    franchise character varying(20) NOT NULL,
    qr_id character varying(60) NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    issued_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.qr_codes OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 24760)
-- Name: qr_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qr_codes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.qr_codes_id_seq OWNER TO postgres;

--
-- TOC entry 5157 (class 0 OID 0)
-- Dependencies: 221
-- Name: qr_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qr_codes_id_seq OWNED BY public.qr_codes.id;


--
-- TOC entry 234 (class 1259 OID 24877)
-- Name: trip_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trip_logs (
    id integer NOT NULL,
    trip_code character varying(15) NOT NULL,
    passenger_id integer,
    driver_id integer,
    route character varying(200),
    fare_amount numeric(8,2),
    payment_method character varying(20),
    duration_min integer,
    started_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.trip_logs OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 24876)
-- Name: trip_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trip_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trip_logs_id_seq OWNER TO postgres;

--
-- TOC entry 5158 (class 0 OID 0)
-- Dependencies: 233
-- Name: trip_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trip_logs_id_seq OWNED BY public.trip_logs.id;


--
-- TOC entry 224 (class 1259 OID 24780)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    phone_number character varying(20),
    email character varying(150),
    password_hash character varying(255) NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 24779)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;

--
-- TOC entry 5159 (class 0 OID 0)
-- Dependencies: 223
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- TOC entry 4912 (class 2604 OID 24801)
-- Name: admins admin_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins ALTER COLUMN admin_id SET DEFAULT nextval('public.admins_admin_id_seq'::regclass);


--
-- TOC entry 4925 (class 2604 OID 24902)
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- TOC entry 4920 (class 2604 OID 24855)
-- Name: complaints id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints ALTER COLUMN id SET DEFAULT nextval('public.complaints_id_seq'::regclass);


--
-- TOC entry 4901 (class 2604 OID 24741)
-- Name: drivers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers ALTER COLUMN id SET DEFAULT nextval('public.drivers_id_seq'::regclass);


--
-- TOC entry 4914 (class 2604 OID 24816)
-- Name: fare_matrix id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_matrix ALTER COLUMN id SET DEFAULT nextval('public.fare_matrix_id_seq'::regclass);


--
-- TOC entry 4928 (class 2604 OID 24917)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 4916 (class 2604 OID 24830)
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- TOC entry 4906 (class 2604 OID 24764)
-- Name: qr_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes ALTER COLUMN id SET DEFAULT nextval('public.qr_codes_id_seq'::regclass);


--
-- TOC entry 4923 (class 2604 OID 24880)
-- Name: trip_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs ALTER COLUMN id SET DEFAULT nextval('public.trip_logs_id_seq'::regclass);


--
-- TOC entry 4909 (class 2604 OID 24783)
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- TOC entry 5132 (class 0 OID 24798)
-- Dependencies: 226
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admins (admin_id, username, password_hash, full_name, email, created_at) FROM stdin;
1	admin	admin123	Portal Administrator	admin@example.com	2026-03-13 08:57:59.951705
3	admin 	admin123			2026-03-13 13:51:57.44213
\.


--
-- TOC entry 5142 (class 0 OID 24899)
-- Dependencies: 236
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, action, entity, entity_id, detail, performed_by, created_at) FROM stdin;
1	ENROLL	Driver	D-001	Enrolled Juan A. Dela Cruz (NVC-001A)	Admin	2026-03-13 08:57:59.951705
2	ENROLL	Driver	D-002	Enrolled Maria S. Reyes (NVC-002B)	Admin	2026-03-13 08:57:59.951705
3	ENROLL	Driver	D-003	Enrolled Pedro M. Santos (NVC-003C)	Admin	2026-03-13 08:57:59.951705
4	UPDATE	Driver	D-002	Maria S. Reyes status → Inactive	Admin	2026-03-13 08:57:59.951705
5	CREATE	Fare	1	Poblacion → Talangan base ₱15.00	Admin	2026-03-13 08:57:59.951705
6	UPDATE	Complaint	R-003	Status → Resolved	Admin	2026-03-13 08:57:59.951705
7	REVOKE	QRCode	NVC-002B	QR status → Inactive	Admin	2026-03-13 08:57:59.951705
8	RESTORE	QRCode	NVC-002B	QR regenerated with new AES key	Admin	2026-03-13 11:42:37.775591
9	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-03-13 11:42:50.056569
10	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-03-13 13:58:34.487214
11	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-03-13 13:58:41.685848
12	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-03-13 13:58:43.292435
13	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-03-13 13:58:48.803141
14	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-03-13 13:58:50.080041
15	UPDATE	Driver	1	Updated fields: username=$1, password_hash=$2, name=$3, franchise=$4, body_no=$5, contact=$6, license_no=$7, association=$8	Admin	2026-03-16 12:43:19.490296
16	UPDATE	Driver	1	Updated fields: status=$1	Admin	2026-03-16 12:44:00.599634
17	UPDATE	Driver	1	Updated fields: status=$1	Admin	2026-03-16 12:44:11.892905
18	UPDATE	Driver	1	Updated fields: status=$1	Admin	2026-03-16 12:44:16.240223
19	UPDATE	Driver	1	Updated fields: status=$1	Admin	2026-03-16 12:44:21.664961
20	UPDATE	Driver	5	Updated fields: status=$1	Admin	2026-03-16 12:57:16.736154
\.


--
-- TOC entry 5138 (class 0 OID 24852)
-- Dependencies: 232
-- Data for Name: complaints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.complaints (id, report_code, passenger_id, driver_id, violation_type, firebase_id, admin_notes, status, reported_at, resolved_at) FROM stdin;
1	R-001	1	1	Overcharging	FB-RPT-77821	\N	Pending	2026-03-13 08:57:59.951705	\N
2	R-004	2	4	Unauthorized Route Deviation	FB-RPT-77102	\N	Pending	2026-03-13 08:57:59.951705	\N
\.


--
-- TOC entry 5126 (class 0 OID 24738)
-- Dependencies: 220
-- Data for Name: drivers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.drivers (id, username, password_hash, first_name, middle_name, last_name, phone_number, email, plate_number, body_number, is_active, driver_code, name, franchise, body_no, contact, license_no, association, status, created_at) FROM stdin;
3	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	D-003	Pedro M. Santos	NVC-003C	03	09112233445	NAG-789012	Nagcarlan TODA	Active	2026-03-13 08:57:59.951705
4	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	D-004	Roberto C. Lim	NVC-004D	04	09223344556	NAG-321098	Nagcarlan TODA	Active	2026-03-13 08:57:59.951705
2	maria1	pass123	\N	\N	\N	\N	\N	\N	\N	t	D-002	Maria S. Reyes	NVC-002B	02	09987654321	NAG-654321	Nagcarlan TODA	Inactive	2026-03-13 08:57:59.951705
1	juan	123456	\N	\N	\N	\N	\N	\N	\N	t	D-001	Juan A. Dela Cruz	NVC-001A	01	09123456789	NAG-123456	Nagcarlan TODA	Active	2026-03-13 08:57:59.951705
5	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	D-005	Elena T. Garcia	NVC-005E	05	09334455667	NAG-456789	Nagcarlan TODA	Inactive	2026-03-13 08:57:59.951705
\.


--
-- TOC entry 5134 (class 0 OID 24813)
-- Dependencies: 228
-- Data for Name: fare_matrix; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fare_matrix (id, origin, destination, base_fare, discounted_fare, night_fare, special_fare, created_at) FROM stdin;
1	Poblacion	Talangan	15.00	12.00	17.25	45.00	2026-03-13 08:57:59.951705
2	Poblacion	Malinao	20.00	16.00	23.00	60.00	2026-03-13 08:57:59.951705
3	Poblacion	Oobi	40.00	32.00	46.00	120.00	2026-03-13 08:57:59.951705
4	Poblacion	Banago	25.00	20.00	28.75	75.00	2026-03-13 08:57:59.951705
5	Oobi	Talangan	30.00	24.00	34.50	90.00	2026-03-13 08:57:59.951705
\.


--
-- TOC entry 5144 (class 0 OID 24914)
-- Dependencies: 238
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, title, description, type, is_read, created_at) FROM stdin;
1	Test Notification	This is a test message.	complaint	f	2026-03-16 13:06:22.682512
\.


--
-- TOC entry 5136 (class 0 OID 24827)
-- Dependencies: 230
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, ref_code, passenger_id, driver_id, route, amount, method, status, paid_at) FROM stdin;
1	TXN-2834	1	1	Poblacion to Talangan	15.00	GCash	Settled	2026-03-13 08:57:59.951705
2	TXN-2831	2	4	Talangan to Poblacion	15.00	Cash	Settled	2026-03-13 08:57:59.951705
\.


--
-- TOC entry 5128 (class 0 OID 24761)
-- Dependencies: 222
-- Data for Name: qr_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.qr_codes (id, driver_id, franchise, qr_id, status, issued_at) FROM stdin;
3	3	NVC-003C	QR-AES-NVC003C-2b8e	Active	2026-03-13 08:57:59.951705
4	4	NVC-004D	QR-AES-NVC004D-4c9a	Active	2026-03-13 08:57:59.951705
5	5	NVC-005E	QR-AES-NVC005E-1e7b	Active	2026-03-13 08:57:59.951705
2	2	NVC-002B	QR-AES-NVC002B-90bc	Active	2026-03-13 08:57:59.951705
1	1	NVC-001A	QR-AES-NVC001A-c88d	Active	2026-03-13 08:57:59.951705
\.


--
-- TOC entry 5140 (class 0 OID 24877)
-- Dependencies: 234
-- Data for Name: trip_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trip_logs (id, trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at) FROM stdin;
1	TR-5230	1	1	Poblacion to Talangan	15.00	GCash	12	2026-03-13 08:57:59.951705
2	TR-5229	2	3	Poblacion to Oobi	40.00	Maya	28	2026-03-13 08:57:59.951705
\.


--
-- TOC entry 5130 (class 0 OID 24780)
-- Dependencies: 224
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, username, first_name, middle_name, last_name, phone_number, email, password_hash, status, created_at) FROM stdin;
1	pass1	Maria	\N	Lopez	09123456789	maria@example.com	secret	Active	2026-03-13 08:57:59.951705
2	pass2	Jose	\N	Santos	09112223344	jose@example.com	secret	Active	2026-03-13 08:57:59.951705
3	lebronjames	james		Smith	09494439017	lebronjames@gmail.com	123456	Active	2026-03-13 09:22:23.729036
4	drew	andrew	Panganiban	cauyan	09494439017	andrew.cauyan27@gmail.com	123456	Active	2026-03-13 10:49:04.204755
5	mackybao	macky		lucido	09494439018	macky@gmail.com	123456	Active	2026-03-16 11:36:00.910349
6	pat	patrick		furaque	09494439016	patrick@gmail.com	123456	Active	2026-03-16 12:58:19.252947
\.


--
-- TOC entry 5160 (class 0 OID 0)
-- Dependencies: 225
-- Name: admins_admin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admins_admin_id_seq', 3, true);


--
-- TOC entry 5161 (class 0 OID 0)
-- Dependencies: 235
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 20, true);


--
-- TOC entry 5162 (class 0 OID 0)
-- Dependencies: 231
-- Name: complaints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.complaints_id_seq', 6, true);


--
-- TOC entry 5163 (class 0 OID 0)
-- Dependencies: 219
-- Name: drivers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.drivers_id_seq', 5, true);


--
-- TOC entry 5164 (class 0 OID 0)
-- Dependencies: 227
-- Name: fare_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fare_matrix_id_seq', 5, true);


--
-- TOC entry 5165 (class 0 OID 0)
-- Dependencies: 237
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, true);


--
-- TOC entry 5166 (class 0 OID 0)
-- Dependencies: 229
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_id_seq', 2, true);


--
-- TOC entry 5167 (class 0 OID 0)
-- Dependencies: 221
-- Name: qr_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.qr_codes_id_seq', 5, true);


--
-- TOC entry 5168 (class 0 OID 0)
-- Dependencies: 233
-- Name: trip_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.trip_logs_id_seq', 2, true);


--
-- TOC entry 5169 (class 0 OID 0)
-- Dependencies: 223
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 6, true);


--
-- TOC entry 4948 (class 2606 OID 24809)
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (admin_id);


--
-- TOC entry 4950 (class 2606 OID 24811)
-- Name: admins admins_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_username_key UNIQUE (username);


--
-- TOC entry 4968 (class 2606 OID 24911)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4960 (class 2606 OID 24863)
-- Name: complaints complaints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_pkey PRIMARY KEY (id);


--
-- TOC entry 4962 (class 2606 OID 24865)
-- Name: complaints complaints_report_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_report_code_key UNIQUE (report_code);


--
-- TOC entry 4932 (class 2606 OID 24757)
-- Name: drivers drivers_driver_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_driver_code_key UNIQUE (driver_code);


--
-- TOC entry 4934 (class 2606 OID 24759)
-- Name: drivers drivers_franchise_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_franchise_key UNIQUE (franchise);


--
-- TOC entry 4936 (class 2606 OID 24753)
-- Name: drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- TOC entry 4938 (class 2606 OID 24755)
-- Name: drivers drivers_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_username_key UNIQUE (username);


--
-- TOC entry 4952 (class 2606 OID 24825)
-- Name: fare_matrix fare_matrix_origin_destination_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_matrix
    ADD CONSTRAINT fare_matrix_origin_destination_key UNIQUE (origin, destination);


--
-- TOC entry 4954 (class 2606 OID 24823)
-- Name: fare_matrix fare_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_matrix
    ADD CONSTRAINT fare_matrix_pkey PRIMARY KEY (id);


--
-- TOC entry 4970 (class 2606 OID 24925)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4956 (class 2606 OID 24838)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- TOC entry 4958 (class 2606 OID 24840)
-- Name: payments payments_ref_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_ref_code_key UNIQUE (ref_code);


--
-- TOC entry 4940 (class 2606 OID 24771)
-- Name: qr_codes qr_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT qr_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 4942 (class 2606 OID 24773)
-- Name: qr_codes qr_codes_qr_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT qr_codes_qr_id_key UNIQUE (qr_id);


--
-- TOC entry 4964 (class 2606 OID 24885)
-- Name: trip_logs trip_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4966 (class 2606 OID 24887)
-- Name: trip_logs trip_logs_trip_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_trip_code_key UNIQUE (trip_code);


--
-- TOC entry 4944 (class 2606 OID 24794)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4946 (class 2606 OID 24796)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 4974 (class 2606 OID 24871)
-- Name: complaints complaints_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- TOC entry 4975 (class 2606 OID 24866)
-- Name: complaints complaints_passenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_passenger_id_fkey FOREIGN KEY (passenger_id) REFERENCES public.users(user_id);


--
-- TOC entry 4972 (class 2606 OID 24846)
-- Name: payments payments_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- TOC entry 4973 (class 2606 OID 24841)
-- Name: payments payments_passenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_passenger_id_fkey FOREIGN KEY (passenger_id) REFERENCES public.users(user_id);


--
-- TOC entry 4971 (class 2606 OID 24774)
-- Name: qr_codes qr_codes_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT qr_codes_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE;


--
-- TOC entry 4976 (class 2606 OID 24893)
-- Name: trip_logs trip_logs_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- TOC entry 4977 (class 2606 OID 24888)
-- Name: trip_logs trip_logs_passenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_passenger_id_fkey FOREIGN KEY (passenger_id) REFERENCES public.users(user_id);


-- Completed on 2026-03-16 15:09:21

--
-- PostgreSQL database dump complete
--

\unrestrict PWuFjFT8ZxW7YpdMs6B6IOtXTjXi16fiUmgyVOMa2efkQM6dLnpL4EEDTKe1JXQ

