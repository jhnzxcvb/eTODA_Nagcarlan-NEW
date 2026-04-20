--
-- PostgreSQL database dump
--

\restrict VM27KyYq7yzYwhEc4WAjvDr43AkZ5TIZa2cPBYd116d3XaYazSNpDOxSdkE9zRG

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-04-15 11:50:06

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
-- TOC entry 220 (class 1259 OID 24979)
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
-- TOC entry 219 (class 1259 OID 24978)
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
-- TOC entry 5184 (class 0 OID 0)
-- Dependencies: 219
-- Name: admins_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admins_admin_id_seq OWNED BY public.admins.admin_id;


--
-- TOC entry 236 (class 1259 OID 25142)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    action character varying(30) NOT NULL,
    entity character varying(50) NOT NULL,
    entity_id character varying(50) NOT NULL,
    detail text,
    performed_by character varying(100),
    created_at timestamp without time zone DEFAULT now(),
    actor_type character varying(20) DEFAULT 'Admin'::character varying NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 25141)
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
-- TOC entry 5185 (class 0 OID 0)
-- Dependencies: 235
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- TOC entry 232 (class 1259 OID 25095)
-- Name: complaints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.complaints (
    id integer NOT NULL,
    report_code character varying(15) NOT NULL,
    passenger_id integer,
    driver_id integer,
    violation_type character varying(50),
    details character varying(30),
    admin_notes text,
    status character varying(20) DEFAULT 'Open'::character varying,
    reported_at timestamp without time zone DEFAULT now(),
    resolved_at timestamp without time zone
);


ALTER TABLE public.complaints OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 25094)
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
-- TOC entry 5186 (class 0 OID 0)
-- Dependencies: 231
-- Name: complaints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.complaints_id_seq OWNED BY public.complaints.id;


--
-- TOC entry 224 (class 1259 OID 25012)
-- Name: drivers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drivers (
    id integer NOT NULL,
    username character varying(50),
    password_hash character varying(255),
    is_active boolean DEFAULT true,
    status character varying(20) DEFAULT 'Active'::character varying,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    contact character varying(20),
    email character varying(150),
    driver_code character varying(10) NOT NULL,
    franchise character varying(20) NOT NULL,
    body_no character varying(20),
    plate_number character varying(20),
    license_no character varying(30),
    association character varying(100) DEFAULT 'Nagcarlan TODA'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    profile_pic text,
    name text GENERATED ALWAYS AS (TRIM(BOTH FROM ((((first_name)::text || ' '::text) || COALESCE(((middle_name)::text || ' '::text), ''::text)) || (last_name)::text))) STORED
);


ALTER TABLE public.drivers OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 25011)
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
-- TOC entry 5187 (class 0 OID 0)
-- Dependencies: 223
-- Name: drivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.drivers_id_seq OWNED BY public.drivers.id;


--
-- TOC entry 228 (class 1259 OID 25056)
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
    created_at timestamp without time zone DEFAULT now(),
    association text DEFAULT 'General'::text NOT NULL
);


ALTER TABLE public.fare_matrix OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 25055)
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
-- TOC entry 5188 (class 0 OID 0)
-- Dependencies: 227
-- Name: fare_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fare_matrix_id_seq OWNED BY public.fare_matrix.id;


--
-- TOC entry 238 (class 1259 OID 25156)
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
-- TOC entry 237 (class 1259 OID 25155)
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
-- TOC entry 5189 (class 0 OID 0)
-- Dependencies: 237
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 230 (class 1259 OID 25070)
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
    paid_at timestamp without time zone DEFAULT now(),
    passenger_type text DEFAULT ''::text,
    trip_type text DEFAULT ''::text,
    ewallet_account text DEFAULT ''::text,
    contact_number text DEFAULT ''::text
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 25069)
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
-- TOC entry 5190 (class 0 OID 0)
-- Dependencies: 229
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- TOC entry 226 (class 1259 OID 25037)
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
-- TOC entry 225 (class 1259 OID 25036)
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
-- TOC entry 5191 (class 0 OID 0)
-- Dependencies: 225
-- Name: qr_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qr_codes_id_seq OWNED BY public.qr_codes.id;


--
-- TOC entry 242 (class 1259 OID 25216)
-- Name: ratings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ratings (
    id integer NOT NULL,
    passenger_id integer,
    driver_id integer,
    rating integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT ratings_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.ratings OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 25215)
-- Name: ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ratings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ratings_id_seq OWNER TO postgres;

--
-- TOC entry 5192 (class 0 OID 0)
-- Dependencies: 241
-- Name: ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ratings_id_seq OWNED BY public.ratings.id;


--
-- TOC entry 240 (class 1259 OID 25184)
-- Name: toda_stations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.toda_stations (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    lat numeric(10,6) NOT NULL,
    lng numeric(10,6) NOT NULL,
    logo text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    color character varying(10) DEFAULT '#16a34a'::character varying
);


ALTER TABLE public.toda_stations OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 25183)
-- Name: toda_stations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.toda_stations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.toda_stations_id_seq OWNER TO postgres;

--
-- TOC entry 5193 (class 0 OID 0)
-- Dependencies: 239
-- Name: toda_stations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.toda_stations_id_seq OWNED BY public.toda_stations.id;


--
-- TOC entry 234 (class 1259 OID 25120)
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
    started_at timestamp without time zone DEFAULT now(),
    status character varying(20) DEFAULT 'ongoing'::character varying,
    ended_at timestamp without time zone
);


ALTER TABLE public.trip_logs OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 25119)
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
-- TOC entry 5194 (class 0 OID 0)
-- Dependencies: 233
-- Name: trip_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trip_logs_id_seq OWNED BY public.trip_logs.id;


--
-- TOC entry 222 (class 1259 OID 24994)
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
    created_at timestamp without time zone DEFAULT now(),
    profile_pic text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 24993)
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
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 221
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- TOC entry 4911 (class 2604 OID 24982)
-- Name: admins admin_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins ALTER COLUMN admin_id SET DEFAULT nextval('public.admins_admin_id_seq'::regclass);


--
-- TOC entry 4942 (class 2604 OID 25145)
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 25098)
-- Name: complaints id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints ALTER COLUMN id SET DEFAULT nextval('public.complaints_id_seq'::regclass);


--
-- TOC entry 4916 (class 2604 OID 25015)
-- Name: drivers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers ALTER COLUMN id SET DEFAULT nextval('public.drivers_id_seq'::regclass);


--
-- TOC entry 4925 (class 2604 OID 25059)
-- Name: fare_matrix id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_matrix ALTER COLUMN id SET DEFAULT nextval('public.fare_matrix_id_seq'::regclass);


--
-- TOC entry 4945 (class 2604 OID 25159)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 4928 (class 2604 OID 25073)
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- TOC entry 4922 (class 2604 OID 25040)
-- Name: qr_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes ALTER COLUMN id SET DEFAULT nextval('public.qr_codes_id_seq'::regclass);


--
-- TOC entry 4951 (class 2604 OID 25219)
-- Name: ratings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings ALTER COLUMN id SET DEFAULT nextval('public.ratings_id_seq'::regclass);


--
-- TOC entry 4948 (class 2604 OID 25187)
-- Name: toda_stations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.toda_stations ALTER COLUMN id SET DEFAULT nextval('public.toda_stations_id_seq'::regclass);


--
-- TOC entry 4939 (class 2604 OID 25123)
-- Name: trip_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs ALTER COLUMN id SET DEFAULT nextval('public.trip_logs_id_seq'::regclass);


--
-- TOC entry 4913 (class 2604 OID 24997)
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- TOC entry 5156 (class 0 OID 24979)
-- Dependencies: 220
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admins (admin_id, username, password_hash, full_name, email, created_at) FROM stdin;
1	admin	admin123	Portal Administrator	admin@example.com	2026-03-13 16:38:10.127763
\.


--
-- TOC entry 5172 (class 0 OID 25142)
-- Dependencies: 236
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, action, entity, entity_id, detail, performed_by, created_at, actor_type) FROM stdin;
1	ENROLL	Driver	D-001	Enrolled Juan A. Dela Cruz	Admin	2026-03-13 16:38:10.127763	Admin
2	ENROLL	Driver	D-002	Enrolled Maria S. Reyes	Admin	2026-03-13 16:38:10.127763	Admin
3	ENROLL	Driver	D-003	Enrolled Pedro M. Santos	Admin	2026-03-13 16:38:10.127763	Admin
4	UPDATE	Driver	D-002	Maria S. Reyes status → Inactive	Admin	2026-03-13 16:38:10.127763	Admin
5	CREATE	Fare	1	Poblacion → Talangan base ₱15.00	Admin	2026-03-13 16:38:10.127763	Admin
6	UPDATE	Complaint	R-003	Status → Resolved	Admin	2026-03-13 16:38:10.127763	Admin
7	REVOKE	QRCode	NVC-002B	QR status → Inactive	Admin	2026-03-13 16:38:10.127763	Admin
8	UPDATE	Driver	2	Updated fields: status=$1	Admin	2026-03-16 10:14:52.551666	Admin
17	UPDATE	Driver	6	Profile updated	Admin	2026-03-16 14:47:11.033199	Admin
18	UPDATE	Driver	6	Updated fields: username=$1, name=$2, franchise=$3, body_no=$4, contact=$5, license_no=$6	Admin	2026-03-24 09:16:11.598465	Admin
19	UPDATE	Driver	2	Updated fields: status=$1	Admin	2026-03-24 09:28:19.540784	Admin
20	DELETE	Driver	D-006	Removed driver Michael John M. Suniega	Admin	2026-03-24 09:28:45.593393	Admin
21	UPDATE	Driver	3	Updated fields: username=$1, first_name=$2, middle_name=$3, last_name=$4, franchise=$5, body_no=$6, contact=$7, license_no=$8, association=$9, plate_number=$10	Admin	2026-03-24 10:15:42.326451	Admin
22	UPDATE	Driver	4	Updated fields: username=$1, first_name=$2, middle_name=$3, last_name=$4, franchise=$5, body_no=$6, contact=$7, license_no=$8, association=$9, plate_number=$10	Admin	2026-03-24 10:15:52.101965	Admin
23	UPDATE	Driver	5	Updated fields: username=$1, first_name=$2, middle_name=$3, last_name=$4, franchise=$5, body_no=$6, contact=$7, license_no=$8, association=$9, plate_number=$10	Admin	2026-03-24 10:16:01.4387	Admin
24	ENROLL	Driver	D-006	Enrolled Andrew  Cauyan (NVC-00F2)	Admin	2026-03-24 10:17:01.475754	Admin
25	UPDATE	Complaint	R-004	Status → Resolved	Admin	2026-03-24 10:45:49.409406	Admin
26	UPDATE	Complaint	R-004	Status → Open	Admin	2026-03-24 10:45:56.252349	Admin
27	UPDATE	Complaint	R-001	Status → Open	Admin	2026-03-24 10:45:59.403102	Admin
28	UPDATE	Complaint	R-004	Status → In Progress	Admin	2026-03-24 10:46:07.594018	Admin
29	UPDATE	Complaint	R-004	Status → Open	Admin	2026-03-24 10:46:10.228047	Admin
30	RESTORE	QRCode	NVC-002B	QR regenerated with new AES key	Admin	2026-03-24 11:20:12.00251	Admin
31	DELETE	Driver	D-004	Removed driver Roberto Lim	Admin	2026-03-25 08:54:07.877916	Admin
32	UPDATE	Driver	1	Updated driver details	Admin	2026-03-25 10:17:28.578509	Admin
33	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-03-25 10:30:08.290527	Admin
34	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-03-25 10:31:10.361379	Admin
35	UPDATE	Driver	1	Updated driver details	Admin	2026-03-25 10:31:19.235877	Admin
36	UPDATE	Driver	1	Updated driver details	Admin	2026-03-25 10:53:26.74281	Admin
37	CREATE	Fare	1	Poblacion → Talangan base ₱15.00	Admin	2026-03-25 13:44:31.229202	Admin
38	CREATE	Fare	2	Poblacion → Malinao base ₱20.00	Admin	2026-03-25 13:44:31.243815	Admin
39	CREATE	Fare	3	Poblacion → Oobi base ₱40.00	Admin	2026-03-25 13:44:31.25194	Admin
40	CREATE	Fare	4	Poblacion → Banago base ₱25.00	Admin	2026-03-25 13:44:31.257699	Admin
41	CREATE	Fare	5	Oobi → Talangan base ₱30.00	Admin	2026-03-25 13:44:31.262783	Admin
42	CREATE	Fare	11	Poblacion → San Felix base ₱35.00	Admin	2026-03-25 13:44:31.268489	Admin
43	CREATE	Fare	12	Poblacion → Bukal base ₱45.00	Admin	2026-03-25 13:44:31.27352	Admin
44	CREATE	Fare	13	Oobi → Malinao base ₱20.00	Admin	2026-03-25 13:44:31.278681	Admin
45	CREATE	Fare	14	San Felix → Talangan base ₱25.00	Admin	2026-03-25 13:44:31.283409	Admin
46	CREATE	Fare	15	Bukal → Poblacion base ₱45.00	Admin	2026-03-25 13:44:31.288352	Admin
47	DELETE	Fare	15	Deleted Bukal → Poblacion	Admin	2026-03-25 13:47:01.995274	Admin
48	DELETE	Fare	5	Deleted Oobi → Talangan	Admin	2026-03-25 13:47:02.005868	Admin
49	DELETE	Fare	13	Deleted Oobi → Malinao	Admin	2026-03-25 13:47:02.011976	Admin
50	DELETE	Fare	1	Deleted Poblacion → Talangan	Admin	2026-03-25 13:47:02.018836	Admin
51	DELETE	Fare	2	Deleted Poblacion → Malinao	Admin	2026-03-25 13:47:02.024288	Admin
52	DELETE	Fare	3	Deleted Poblacion → Oobi	Admin	2026-03-25 13:47:02.029621	Admin
53	DELETE	Fare	4	Deleted Poblacion → Banago	Admin	2026-03-25 13:47:02.035115	Admin
54	DELETE	Fare	11	Deleted Poblacion → San Felix	Admin	2026-03-25 13:47:02.040381	Admin
55	DELETE	Fare	12	Deleted Poblacion → Bukal	Admin	2026-03-25 13:47:02.045898	Admin
56	DELETE	Fare	14	Deleted San Felix → Talangan	Admin	2026-03-25 13:47:02.051344	Admin
57	CREATE	Fare	16	Poblacion → Talangan base ₱15.00	Admin	2026-03-25 13:47:15.013421	Admin
58	CREATE	Fare	17	Poblacion → Malinao base ₱20.00	Admin	2026-03-25 13:47:15.021365	Admin
59	CREATE	Fare	18	Poblacion → Oobi base ₱40.00	Admin	2026-03-25 13:47:15.025601	Admin
60	CREATE	Fare	19	Poblacion → Banago base ₱25.00	Admin	2026-03-25 13:47:15.029569	Admin
61	CREATE	Fare	20	Oobi → Talangan base ₱30.00	Admin	2026-03-25 13:47:15.033984	Admin
62	CREATE	Fare	21	Poblacion → San Felix base ₱35.00	Admin	2026-03-25 13:47:15.038831	Admin
63	CREATE	Fare	22	Poblacion → Bukal base ₱45.00	Admin	2026-03-25 13:47:15.042745	Admin
64	CREATE	Fare	23	Oobi → Malinao base ₱20.00	Admin	2026-03-25 13:47:15.046657	Admin
65	CREATE	Fare	24	San Felix → Talangan base ₱25.00	Admin	2026-03-25 13:47:15.050963	Admin
66	CREATE	Fare	25	Bukal → Poblacion base ₱45.00	Admin	2026-03-25 13:47:15.055555	Admin
67	CREATE	Complaint	C-003	New report filed	Admin	2026-03-25 14:37:07.153569	Admin
68	CREATE	Complaint	C-004	New report filed	Admin	2026-03-25 14:39:43.889945	Admin
69	UPDATE	Complaint	25	Status updated to Resolved	Admin	2026-03-25 15:59:30.509593	Admin
70	UPDATE	Complaint	25	Status updated to Open	Admin	2026-03-25 15:59:35.623841	Admin
71	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-03-31 22:38:08.751589	Admin
72	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-03-31 22:38:11.972606	Admin
73	CREATE	Complaint	C-001	New report filed	Admin	2026-03-31 22:45:17.481719	Admin
74	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-04-01 08:37:15.268617	Admin
75	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-04-01 08:37:16.968313	Admin
76	DELETE	Fare	25	Deleted Bukal → Poblacion	Admin	2026-04-01 08:59:23.886262	Admin
77	DELETE	Fare	20	Deleted Oobi → Talangan	Admin	2026-04-01 08:59:23.898312	Admin
78	DELETE	Fare	23	Deleted Oobi → Malinao	Admin	2026-04-01 08:59:23.906959	Admin
79	DELETE	Fare	16	Deleted Poblacion → Talangan	Admin	2026-04-01 08:59:23.917194	Admin
80	DELETE	Fare	17	Deleted Poblacion → Malinao	Admin	2026-04-01 08:59:23.924432	Admin
81	DELETE	Fare	18	Deleted Poblacion → Oobi	Admin	2026-04-01 08:59:23.933273	Admin
82	DELETE	Fare	19	Deleted Poblacion → Banago	Admin	2026-04-01 08:59:23.943369	Admin
83	DELETE	Fare	21	Deleted Poblacion → San Felix	Admin	2026-04-01 08:59:23.953331	Admin
84	DELETE	Fare	22	Deleted Poblacion → Bukal	Admin	2026-04-01 08:59:23.96359	Admin
85	DELETE	Fare	24	Deleted San Felix → Talangan	Admin	2026-04-01 08:59:23.97228	Admin
86	CREATE	Fare	26	Balinacon → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:03:04.439596	Admin
87	CREATE	Fare	27	Balinacon → Sinipian base ₱20.00	Admin	2026-04-01 09:03:04.448763	Admin
88	CREATE	Fare	28	Balinacon → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 09:03:04.455325	Admin
89	CREATE	Fare	29	Balinacon → Malinao base ₱25.00	Admin	2026-04-01 09:03:04.461907	Admin
90	CREATE	Fare	30	Balinacon → Upland LMES (School) base ₱30.00	Admin	2026-04-01 09:03:04.471196	Admin
91	CREATE	Fare	31	Balinacon → Sil. Lazaan base ₱35.00	Admin	2026-04-01 09:03:04.47813	Admin
92	CREATE	Fare	32	Balinacon → Kan. Lazaan base ₱40.00	Admin	2026-04-01 09:03:04.482991	Admin
93	CREATE	Fare	33	Balinacon → Sil. Lazaan (Tower) base ₱45.00	Admin	2026-04-01 09:03:04.492996	Admin
94	CREATE	Fare	34	Balinacon → Kan. Lazaan (Barod) base ₱55.00	Admin	2026-04-01 09:03:04.499706	Admin
95	CREATE	Fare	35	Balinacon → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:03:04.505907	Admin
96	CREATE	Fare	36	Balinacon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:03:04.513728	Admin
97	CREATE	Fare	37	Balinacon → Sil. Lazaan (Dulo) base ₱60.00	Admin	2026-04-01 09:03:04.520342	Admin
98	CREATE	Fare	38	Balinacon → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:03:04.525876	Admin
99	CREATE	Fare	39	Balinacon → Kan. Lazaan (St. Bartolome) base ₱70.00	Admin	2026-04-01 09:03:04.532766	Admin
100	CREATE	Fare	40	Balimbing - 1 Ahon → Balinacon base ₱20.00	Admin	2026-04-01 09:03:04.537718	Admin
101	CREATE	Fare	41	Balimbing - 1 Ahon → Sinipian base ₱20.00	Admin	2026-04-01 09:03:04.542767	Admin
102	CREATE	Fare	42	Balimbing - 1 Ahon → Balimbing - 2 Ahon base ₱20.00	Admin	2026-04-01 09:03:04.54866	Admin
103	CREATE	Fare	43	Balimbing - 1 Ahon → Malinao base ₱20.00	Admin	2026-04-01 09:03:04.553001	Admin
104	CREATE	Fare	44	Balimbing - 1 Ahon → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:03:04.559056	Admin
105	CREATE	Fare	45	Balimbing - 1 Ahon → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:03:04.567793	Admin
106	CREATE	Fare	46	Balimbing - 1 Ahon → Kan. Lazaan base ₱35.00	Admin	2026-04-01 09:03:04.57347	Admin
107	CREATE	Fare	47	Balimbing - 1 Ahon → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 09:03:04.579377	Admin
108	CREATE	Fare	48	Balimbing - 1 Ahon → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 09:03:04.583724	Admin
109	CREATE	Fare	49	Balimbing - 1 Ahon → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:03:04.58843	Admin
110	CREATE	Fare	50	Balimbing - 1 Ahon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:03:04.593741	Admin
111	CREATE	Fare	51	Balimbing - 1 Ahon → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 09:03:04.598572	Admin
112	CREATE	Fare	52	Balimbing - 1 Ahon → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 09:03:04.603058	Admin
113	CREATE	Fare	53	Balimbing - 1 Ahon → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:03:04.608207	Admin
114	CREATE	Fare	54	Sinipian → Balinacon base ₱20.00	Admin	2026-04-01 09:03:04.614843	Admin
115	CREATE	Fare	55	Sinipian → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:03:04.620381	Admin
116	CREATE	Fare	56	Sinipian → Balimbing - 2 Ahon base ₱20.00	Admin	2026-04-01 09:03:04.625208	Admin
117	CREATE	Fare	57	Sinipian → Malinao base ₱20.00	Admin	2026-04-01 09:03:04.6303	Admin
118	CREATE	Fare	58	Sinipian → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:03:04.634898	Admin
119	CREATE	Fare	59	Sinipian → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:03:04.639823	Admin
120	CREATE	Fare	60	Sinipian → Kan. Lazaan base ₱35.00	Admin	2026-04-01 09:03:04.645295	Admin
121	CREATE	Fare	61	Sinipian → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 09:03:04.65012	Admin
122	CREATE	Fare	62	Sinipian → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 09:03:04.655004	Admin
123	CREATE	Fare	63	Sinipian → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:03:04.659752	Admin
124	CREATE	Fare	64	Sinipian → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:03:04.664921	Admin
125	CREATE	Fare	65	Sinipian → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 09:03:04.66962	Admin
126	CREATE	Fare	66	Sinipian → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 09:03:04.674126	Admin
127	CREATE	Fare	67	Sinipian → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:03:04.680177	Admin
128	CREATE	Fare	68	Balimbing - 2 Ahon → Balinacon base ₱20.00	Admin	2026-04-01 09:03:04.685568	Admin
129	CREATE	Fare	69	Balimbing - 2 Ahon → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:03:04.690668	Admin
130	CREATE	Fare	70	Balimbing - 2 Ahon → Sinipian base ₱20.00	Admin	2026-04-01 09:03:04.69778	Admin
131	CREATE	Fare	71	Balimbing - 2 Ahon → Malinao base ₱20.00	Admin	2026-04-01 09:03:04.703091	Admin
132	CREATE	Fare	72	Balimbing - 2 Ahon → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:03:04.712326	Admin
133	CREATE	Fare	73	Balimbing - 2 Ahon → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:03:04.718967	Admin
134	CREATE	Fare	74	Balimbing - 2 Ahon → Kan. Lazaan base ₱35.00	Admin	2026-04-01 09:03:04.724857	Admin
135	CREATE	Fare	75	Balimbing - 2 Ahon → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 09:03:04.731009	Admin
136	CREATE	Fare	76	Balimbing - 2 Ahon → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 09:03:04.736663	Admin
137	CREATE	Fare	77	Balimbing - 2 Ahon → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:03:04.741562	Admin
138	CREATE	Fare	78	Balimbing - 2 Ahon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:03:04.747734	Admin
139	CREATE	Fare	79	Balimbing - 2 Ahon → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 09:03:04.752394	Admin
140	CREATE	Fare	80	Balimbing - 2 Ahon → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:03:04.758031	Admin
141	CREATE	Fare	81	Balimbing - 2 Ahon → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:03:04.764045	Admin
142	CREATE	Fare	82	Malinao → Balinacon base ₱20.00	Admin	2026-04-01 09:03:04.768845	Admin
143	CREATE	Fare	83	Malinao → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:03:04.773465	Admin
144	CREATE	Fare	84	Malinao → Sinipian base ₱20.00	Admin	2026-04-01 09:03:04.77966	Admin
145	CREATE	Fare	85	Malinao → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 09:03:04.786082	Admin
146	CREATE	Fare	86	Malinao → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:03:04.790626	Admin
147	CREATE	Fare	87	Malinao → Sil. Lazaan base ₱25.00	Admin	2026-04-01 09:03:04.797095	Admin
148	CREATE	Fare	88	Malinao → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:03:04.802522	Admin
149	CREATE	Fare	89	Malinao → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 09:03:04.808603	Admin
150	CREATE	Fare	90	Malinao → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 09:03:04.813764	Admin
151	CREATE	Fare	91	Malinao → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:03:04.818472	Admin
152	CREATE	Fare	92	Malinao → Kan. Lazaan (Ilaya) base ₱45.00	Admin	2026-04-01 09:03:04.822967	Admin
153	CREATE	Fare	93	Malinao → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:03:04.828605	Admin
154	CREATE	Fare	94	Malinao → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 09:03:04.832985	Admin
155	CREATE	Fare	95	Malinao → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:03:04.838148	Admin
156	CREATE	Fare	96	Upland LMES (School) → Balinacon base ₱25.00	Admin	2026-04-01 09:03:04.842831	Admin
157	CREATE	Fare	97	Upland LMES (School) → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:03:04.84761	Admin
158	CREATE	Fare	98	Upland LMES (School) → Sinipian base ₱20.00	Admin	2026-04-01 09:03:04.852776	Admin
159	CREATE	Fare	99	Upland LMES (School) → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 09:03:04.857801	Admin
160	CREATE	Fare	100	Upland LMES (School) → Malinao base ₱20.00	Admin	2026-04-01 09:03:04.862644	Admin
161	CREATE	Fare	101	Upland LMES (School) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:03:04.867361	Admin
162	CREATE	Fare	102	Upland LMES (School) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:03:04.87155	Admin
163	CREATE	Fare	103	Upland LMES (School) → Sil. Lazaan (Tower) base ₱30.00	Admin	2026-04-01 09:03:04.876832	Admin
164	CREATE	Fare	104	Upland LMES (School) → Kan. Lazaan (Barod) base ₱35.00	Admin	2026-04-01 09:03:04.881446	Admin
165	CREATE	Fare	105	Upland LMES (School) → Sil. Lazaan (Ilaya) base ₱35.00	Admin	2026-04-01 09:03:04.887649	Admin
166	CREATE	Fare	106	Upland LMES (School) → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:03:04.893384	Admin
167	CREATE	Fare	107	Upland LMES (School) → Sil. Lazaan (Dulo) base ₱45.00	Admin	2026-04-01 09:03:04.898027	Admin
168	CREATE	Fare	108	Upland LMES (School) → Kan. Lazaan (Siriaco) base ₱45.00	Admin	2026-04-01 09:03:04.902738	Admin
169	CREATE	Fare	109	Upland LMES (School) → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:03:04.908123	Admin
170	CREATE	Fare	110	Sil. Lazaan → Balinacon base ₱30.00	Admin	2026-04-01 09:03:04.913837	Admin
171	CREATE	Fare	111	Sil. Lazaan → Balimbing - 1 Ahon base ₱25.00	Admin	2026-04-01 09:03:04.919069	Admin
172	CREATE	Fare	112	Sil. Lazaan → Sinipian base ₱25.00	Admin	2026-04-01 09:03:04.923636	Admin
173	CREATE	Fare	113	Sil. Lazaan → Balimbing - 2 Ahon base ₱30.00	Admin	2026-04-01 09:03:04.930084	Admin
174	CREATE	Fare	114	Sil. Lazaan → Malinao base ₱20.00	Admin	2026-04-01 09:03:04.934842	Admin
175	CREATE	Fare	115	Sil. Lazaan → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:03:04.939717	Admin
176	CREATE	Fare	116	Sil. Lazaan → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:03:04.944316	Admin
177	CREATE	Fare	117	Sil. Lazaan → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 09:03:04.949103	Admin
178	CREATE	Fare	118	Sil. Lazaan → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 09:03:04.953475	Admin
179	CREATE	Fare	119	Sil. Lazaan → Sil. Lazaan (Ilaya) base ₱35.00	Admin	2026-04-01 09:03:04.959251	Admin
180	CREATE	Fare	120	Sil. Lazaan → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:03:04.964667	Admin
181	CREATE	Fare	121	Sil. Lazaan → Sil. Lazaan (Dulo) base ₱40.00	Admin	2026-04-01 09:03:04.969661	Admin
182	CREATE	Fare	122	Sil. Lazaan → Kan. Lazaan (Siriaco) base ₱45.00	Admin	2026-04-01 09:03:04.974549	Admin
183	CREATE	Fare	123	Sil. Lazaan → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:03:04.979622	Admin
184	CREATE	Fare	124	Kan. Lazaan → Balinacon base ₱30.00	Admin	2026-04-01 09:03:04.983933	Admin
185	CREATE	Fare	125	Kan. Lazaan → Balimbing - 1 Ahon base ₱25.00	Admin	2026-04-01 09:03:04.988933	Admin
186	CREATE	Fare	126	Kan. Lazaan → Sinipian base ₱25.00	Admin	2026-04-01 09:03:04.994139	Admin
187	CREATE	Fare	127	Kan. Lazaan → Balimbing - 2 Ahon base ₱30.00	Admin	2026-04-01 09:03:04.99929	Admin
188	CREATE	Fare	128	Kan. Lazaan → Malinao base ₱25.00	Admin	2026-04-01 09:03:05.003679	Admin
189	CREATE	Fare	129	Kan. Lazaan → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:03:05.008969	Admin
190	CREATE	Fare	130	Kan. Lazaan → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:03:05.014103	Admin
191	CREATE	Fare	131	Kan. Lazaan → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 09:03:05.018904	Admin
192	CREATE	Fare	132	Kan. Lazaan → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 09:03:05.02405	Admin
193	CREATE	Fare	133	Kan. Lazaan → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:03:05.02987	Admin
194	CREATE	Fare	134	Kan. Lazaan → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:03:05.034643	Admin
195	CREATE	Fare	135	Kan. Lazaan → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:03:05.040155	Admin
196	CREATE	Fare	136	Kan. Lazaan → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 09:03:05.046551	Admin
197	CREATE	Fare	137	Kan. Lazaan → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:03:05.051104	Admin
198	CREATE	Fare	138	Sil. Lazaan (Tower) → Balinacon base ₱35.00	Admin	2026-04-01 09:03:05.055723	Admin
199	CREATE	Fare	139	Sil. Lazaan (Tower) → Balimbing - 1 Ahon base ₱30.00	Admin	2026-04-01 09:03:05.060427	Admin
200	CREATE	Fare	140	Sil. Lazaan (Tower) → Sinipian base ₱30.00	Admin	2026-04-01 09:03:05.06549	Admin
201	CREATE	Fare	141	Sil. Lazaan (Tower) → Balimbing - 2 Ahon base ₱35.00	Admin	2026-04-01 09:03:05.07023	Admin
202	CREATE	Fare	142	Sil. Lazaan (Tower) → Malinao base ₱25.00	Admin	2026-04-01 09:03:05.076048	Admin
203	CREATE	Fare	143	Sil. Lazaan (Tower) → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:03:05.080916	Admin
204	CREATE	Fare	144	Sil. Lazaan (Tower) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:03:05.0867	Admin
205	CREATE	Fare	145	Sil. Lazaan (Tower) → Kan. Lazaan base ₱40.00	Admin	2026-04-01 09:03:05.091454	Admin
206	CREATE	Fare	146	Sil. Lazaan (Tower) → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 09:03:05.097054	Admin
207	CREATE	Fare	147	Sil. Lazaan (Tower) → Sil. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:03:05.101754	Admin
208	CREATE	Fare	148	Sil. Lazaan (Tower) → Kan. Lazaan (Ilaya) base ₱45.00	Admin	2026-04-01 09:03:05.106744	Admin
209	CREATE	Fare	149	Sil. Lazaan (Tower) → Sil. Lazaan (Dulo) base ₱30.00	Admin	2026-04-01 09:03:05.111955	Admin
210	CREATE	Fare	150	Sil. Lazaan (Tower) → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 09:03:05.117279	Admin
211	CREATE	Fare	151	Sil. Lazaan (Tower) → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:03:05.121712	Admin
212	CREATE	Fare	152	Kan. Lazaan (Barod) → Balinacon base ₱40.00	Admin	2026-04-01 09:03:05.127468	Admin
213	CREATE	Fare	153	Kan. Lazaan (Barod) → Balimbing - 1 Ahon base ₱30.00	Admin	2026-04-01 09:03:05.132309	Admin
214	CREATE	Fare	154	Kan. Lazaan (Barod) → Sinipian base ₱30.00	Admin	2026-04-01 09:03:05.136893	Admin
215	CREATE	Fare	155	Kan. Lazaan (Barod) → Balimbing - 2 Ahon base ₱35.00	Admin	2026-04-01 09:03:05.141772	Admin
216	CREATE	Fare	156	Kan. Lazaan (Barod) → Malinao base ₱30.00	Admin	2026-04-01 09:03:05.147376	Admin
217	CREATE	Fare	157	Kan. Lazaan (Barod) → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:03:05.151948	Admin
218	CREATE	Fare	158	Kan. Lazaan (Barod) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:03:05.157371	Admin
219	CREATE	Fare	159	Kan. Lazaan (Barod) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:03:05.1625	Admin
220	CREATE	Fare	160	Kan. Lazaan (Barod) → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 09:03:05.167251	Admin
221	CREATE	Fare	161	Kan. Lazaan (Barod) → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:03:05.17274	Admin
222	CREATE	Fare	162	Kan. Lazaan (Barod) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:03:05.179938	Admin
223	CREATE	Fare	163	Kan. Lazaan (Barod) → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:03:05.184508	Admin
224	CREATE	Fare	164	Kan. Lazaan (Barod) → Kan. Lazaan (Siriaco) base ₱35.00	Admin	2026-04-01 09:03:05.188962	Admin
225	CREATE	Fare	165	Kan. Lazaan (Barod) → Kan. Lazaan (St. Bartolome) base ₱45.00	Admin	2026-04-01 09:03:05.194087	Admin
226	CREATE	Fare	166	Sil. Lazaan (Ilaya) → Balinacon base ₱40.00	Admin	2026-04-01 09:03:05.199359	Admin
227	CREATE	Fare	167	Sil. Lazaan (Ilaya) → Balimbing - 1 Ahon base ₱35.00	Admin	2026-04-01 09:03:05.203897	Admin
228	CREATE	Fare	168	Sil. Lazaan (Ilaya) → Sinipian base ₱35.00	Admin	2026-04-01 09:03:05.211091	Admin
229	CREATE	Fare	169	Sil. Lazaan (Ilaya) → Balimbing - 2 Ahon base ₱40.00	Admin	2026-04-01 09:03:05.216318	Admin
230	CREATE	Fare	170	Sil. Lazaan (Ilaya) → Malinao base ₱30.00	Admin	2026-04-01 09:03:05.22058	Admin
231	CREATE	Fare	171	Sil. Lazaan (Ilaya) → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:03:05.22737	Admin
232	CREATE	Fare	172	Sil. Lazaan (Ilaya) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:03:05.232279	Admin
233	CREATE	Fare	173	Sil. Lazaan (Ilaya) → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:03:05.237883	Admin
234	CREATE	Fare	174	Sil. Lazaan (Ilaya) → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 09:03:05.243056	Admin
235	CREATE	Fare	175	Sil. Lazaan (Ilaya) → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 09:03:05.248006	Admin
236	CREATE	Fare	176	Sil. Lazaan (Ilaya) → Kan. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:03:05.252557	Admin
237	CREATE	Fare	177	Sil. Lazaan (Ilaya) → Sil. Lazaan (Dulo) base ₱30.00	Admin	2026-04-01 09:03:05.257708	Admin
238	CREATE	Fare	178	Sil. Lazaan (Ilaya) → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:03:05.263107	Admin
239	CREATE	Fare	179	Sil. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome) base ₱65.00	Admin	2026-04-01 09:03:05.267601	Admin
240	CREATE	Fare	180	Kan. Lazaan (Ilaya) → Balinacon base ₱40.00	Admin	2026-04-01 09:03:05.271843	Admin
241	CREATE	Fare	181	Kan. Lazaan (Ilaya) → Balimbing - 1 Ahon base ₱35.00	Admin	2026-04-01 09:03:05.278131	Admin
242	CREATE	Fare	182	Kan. Lazaan (Ilaya) → Sinipian base ₱35.00	Admin	2026-04-01 09:03:05.284182	Admin
243	CREATE	Fare	183	Kan. Lazaan (Ilaya) → Balimbing - 2 Ahon base ₱40.00	Admin	2026-04-01 09:03:05.290257	Admin
244	CREATE	Fare	184	Kan. Lazaan (Ilaya) → Malinao base ₱30.00	Admin	2026-04-01 09:03:05.295617	Admin
245	CREATE	Fare	185	Kan. Lazaan (Ilaya) → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:03:05.300746	Admin
246	CREATE	Fare	186	Kan. Lazaan (Ilaya) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:03:05.305991	Admin
247	CREATE	Fare	187	Kan. Lazaan (Ilaya) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:03:05.311405	Admin
248	CREATE	Fare	188	Kan. Lazaan (Ilaya) → Sil. Lazaan (Tower) base ₱45.00	Admin	2026-04-01 09:03:05.31629	Admin
249	CREATE	Fare	189	Kan. Lazaan (Ilaya) → Kan. Lazaan (Barod) base ₱20.00	Admin	2026-04-01 09:03:05.321213	Admin
250	CREATE	Fare	190	Kan. Lazaan (Ilaya) → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:03:05.326179	Admin
251	CREATE	Fare	191	Kan. Lazaan (Ilaya) → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:03:05.331195	Admin
252	CREATE	Fare	192	Kan. Lazaan (Ilaya) → Kan. Lazaan (Siriaco) base ₱25.00	Admin	2026-04-01 09:03:05.336493	Admin
253	CREATE	Fare	193	Kan. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome) base ₱30.00	Admin	2026-04-01 09:03:05.344342	Admin
254	CREATE	Fare	194	Sil. Lazaan (Dulo) → Balinacon base ₱50.00	Admin	2026-04-01 09:03:05.369793	Admin
255	CREATE	Fare	195	Sil. Lazaan (Dulo) → Balimbing - 1 Ahon base ₱45.00	Admin	2026-04-01 09:03:05.375364	Admin
256	CREATE	Fare	196	Sil. Lazaan (Dulo) → Sinipian base ₱45.00	Admin	2026-04-01 09:03:05.380371	Admin
257	CREATE	Fare	197	Sil. Lazaan (Dulo) → Balimbing - 2 Ahon base ₱45.00	Admin	2026-04-01 09:03:05.386502	Admin
258	CREATE	Fare	198	Sil. Lazaan (Dulo) → Malinao base ₱40.00	Admin	2026-04-01 09:03:05.391084	Admin
259	CREATE	Fare	199	Sil. Lazaan (Dulo) → Upland LMES (School) base ₱30.00	Admin	2026-04-01 09:03:05.396992	Admin
260	CREATE	Fare	200	Sil. Lazaan (Dulo) → Sil. Lazaan base ₱25.00	Admin	2026-04-01 09:03:05.401477	Admin
261	CREATE	Fare	201	Sil. Lazaan (Dulo) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:03:05.406045	Admin
262	CREATE	Fare	202	Sil. Lazaan (Dulo) → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 09:03:05.411382	Admin
263	CREATE	Fare	203	Sil. Lazaan (Dulo) → Kan. Lazaan (Barod) base ₱55.00	Admin	2026-04-01 09:03:05.416764	Admin
264	CREATE	Fare	204	Sil. Lazaan (Dulo) → Sil. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:03:05.42146	Admin
265	CREATE	Fare	205	Sil. Lazaan (Dulo) → Kan. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:03:05.426784	Admin
266	CREATE	Fare	206	Sil. Lazaan (Dulo) → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:03:05.431587	Admin
267	CREATE	Fare	207	Sil. Lazaan (Dulo) → Kan. Lazaan (St. Bartolome) base ₱70.00	Admin	2026-04-01 09:03:05.436752	Admin
268	CREATE	Fare	208	Kan. Lazaan (Siriaco) → Balinacon base ₱50.00	Admin	2026-04-01 09:03:05.441481	Admin
269	CREATE	Fare	209	Kan. Lazaan (Siriaco) → Balimbing - 1 Ahon base ₱45.00	Admin	2026-04-01 09:03:05.446653	Admin
270	CREATE	Fare	210	Kan. Lazaan (Siriaco) → Sinipian base ₱45.00	Admin	2026-04-01 09:03:05.451076	Admin
271	CREATE	Fare	211	Kan. Lazaan (Siriaco) → Balimbing - 2 Ahon base ₱45.00	Admin	2026-04-01 09:03:05.456232	Admin
272	CREATE	Fare	212	Kan. Lazaan (Siriaco) → Malinao base ₱40.00	Admin	2026-04-01 09:03:05.461102	Admin
273	CREATE	Fare	213	Kan. Lazaan (Siriaco) → Upland LMES (School) base ₱30.00	Admin	2026-04-01 09:03:05.466184	Admin
274	CREATE	Fare	214	Kan. Lazaan (Siriaco) → Sil. Lazaan base ₱25.00	Admin	2026-04-01 09:03:05.470991	Admin
275	CREATE	Fare	215	Kan. Lazaan (Siriaco) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:03:05.476717	Admin
276	CREATE	Fare	216	Kan. Lazaan (Siriaco) → Sil. Lazaan (Tower) base ₱55.00	Admin	2026-04-01 09:03:05.481366	Admin
277	CREATE	Fare	217	Kan. Lazaan (Siriaco) → Kan. Lazaan (Barod) base ₱20.00	Admin	2026-04-01 09:03:05.485916	Admin
278	CREATE	Fare	218	Kan. Lazaan (Siriaco) → Sil. Lazaan (Ilaya) base ₱60.00	Admin	2026-04-01 09:03:05.490413	Admin
279	CREATE	Fare	219	Kan. Lazaan (Siriaco) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:03:05.49633	Admin
280	CREATE	Fare	220	Kan. Lazaan (Siriaco) → Sil. Lazaan (Dulo) base ₱60.00	Admin	2026-04-01 09:03:05.500909	Admin
281	CREATE	Fare	221	Kan. Lazaan (Siriaco) → Kan. Lazaan (St. Bartolome) base ₱30.00	Admin	2026-04-01 09:03:05.505665	Admin
282	CREATE	Fare	222	Kan. Lazaan (St. Bartolome) → Balinacon base ₱55.00	Admin	2026-04-01 09:03:05.510582	Admin
283	CREATE	Fare	223	Kan. Lazaan (St. Bartolome) → Balimbing - 1 Ahon base ₱50.00	Admin	2026-04-01 09:03:05.515556	Admin
284	CREATE	Fare	224	Kan. Lazaan (St. Bartolome) → Sinipian base ₱50.00	Admin	2026-04-01 09:03:05.520318	Admin
285	CREATE	Fare	225	Kan. Lazaan (St. Bartolome) → Balimbing - 2 Ahon base ₱50.00	Admin	2026-04-01 09:03:05.525163	Admin
286	CREATE	Fare	226	Kan. Lazaan (St. Bartolome) → Malinao base ₱40.00	Admin	2026-04-01 09:03:05.530362	Admin
287	CREATE	Fare	227	Kan. Lazaan (St. Bartolome) → Upland LMES (School) base ₱36.00	Admin	2026-04-01 09:03:05.535058	Admin
288	CREATE	Fare	228	Kan. Lazaan (St. Bartolome) → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:03:05.53997	Admin
289	CREATE	Fare	229	Kan. Lazaan (St. Bartolome) → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:03:05.545651	Admin
290	CREATE	Fare	230	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Tower) base ₱60.00	Admin	2026-04-01 09:03:05.551142	Admin
291	CREATE	Fare	231	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 09:03:05.555999	Admin
292	CREATE	Fare	232	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:03:05.561239	Admin
293	CREATE	Fare	233	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:03:05.5658	Admin
294	CREATE	Fare	234	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Dulo) base ₱20.00	Admin	2026-04-01 09:03:05.570547	Admin
295	CREATE	Fare	235	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 09:03:05.575513	Admin
296	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-04-01 09:05:35.939597	Admin
297	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-04-01 09:05:39.013415	Admin
298	DELETE	Fare	40	Deleted Balimbing - 1 Ahon → Balinacon	Admin	2026-04-01 09:28:06.791722	Admin
299	DELETE	Fare	41	Deleted Balimbing - 1 Ahon → Sinipian	Admin	2026-04-01 09:28:06.841432	Admin
300	DELETE	Fare	42	Deleted Balimbing - 1 Ahon → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:06.851084	Admin
301	DELETE	Fare	43	Deleted Balimbing - 1 Ahon → Malinao	Admin	2026-04-01 09:28:06.85858	Admin
302	DELETE	Fare	44	Deleted Balimbing - 1 Ahon → Upland LMES (School)	Admin	2026-04-01 09:28:06.868651	Admin
303	DELETE	Fare	45	Deleted Balimbing - 1 Ahon → Sil. Lazaan	Admin	2026-04-01 09:28:06.876976	Admin
304	DELETE	Fare	46	Deleted Balimbing - 1 Ahon → Kan. Lazaan	Admin	2026-04-01 09:28:06.88471	Admin
305	DELETE	Fare	47	Deleted Balimbing - 1 Ahon → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:06.893744	Admin
306	DELETE	Fare	48	Deleted Balimbing - 1 Ahon → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:06.903598	Admin
307	DELETE	Fare	49	Deleted Balimbing - 1 Ahon → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:06.911244	Admin
308	DELETE	Fare	50	Deleted Balimbing - 1 Ahon → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:06.918701	Admin
309	DELETE	Fare	51	Deleted Balimbing - 1 Ahon → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:06.926624	Admin
310	DELETE	Fare	52	Deleted Balimbing - 1 Ahon → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:06.935394	Admin
311	DELETE	Fare	53	Deleted Balimbing - 1 Ahon → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:06.943972	Admin
312	DELETE	Fare	68	Deleted Balimbing - 2 Ahon → Balinacon	Admin	2026-04-01 09:28:06.952613	Admin
313	DELETE	Fare	69	Deleted Balimbing - 2 Ahon → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:06.960828	Admin
314	DELETE	Fare	70	Deleted Balimbing - 2 Ahon → Sinipian	Admin	2026-04-01 09:28:06.968904	Admin
315	DELETE	Fare	71	Deleted Balimbing - 2 Ahon → Malinao	Admin	2026-04-01 09:28:06.978519	Admin
316	DELETE	Fare	72	Deleted Balimbing - 2 Ahon → Upland LMES (School)	Admin	2026-04-01 09:28:06.987325	Admin
317	DELETE	Fare	73	Deleted Balimbing - 2 Ahon → Sil. Lazaan	Admin	2026-04-01 09:28:06.996418	Admin
318	DELETE	Fare	74	Deleted Balimbing - 2 Ahon → Kan. Lazaan	Admin	2026-04-01 09:28:07.003408	Admin
319	DELETE	Fare	75	Deleted Balimbing - 2 Ahon → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.011868	Admin
320	DELETE	Fare	76	Deleted Balimbing - 2 Ahon → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:07.019153	Admin
321	DELETE	Fare	77	Deleted Balimbing - 2 Ahon → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.027934	Admin
322	DELETE	Fare	78	Deleted Balimbing - 2 Ahon → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.036608	Admin
323	DELETE	Fare	79	Deleted Balimbing - 2 Ahon → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.045433	Admin
324	DELETE	Fare	80	Deleted Balimbing - 2 Ahon → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:07.05297	Admin
325	DELETE	Fare	81	Deleted Balimbing - 2 Ahon → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:07.060323	Admin
326	DELETE	Fare	26	Deleted Balinacon → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.067478	Admin
327	DELETE	Fare	27	Deleted Balinacon → Sinipian	Admin	2026-04-01 09:28:07.075632	Admin
328	DELETE	Fare	28	Deleted Balinacon → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.083792	Admin
329	DELETE	Fare	29	Deleted Balinacon → Malinao	Admin	2026-04-01 09:28:07.094765	Admin
330	DELETE	Fare	30	Deleted Balinacon → Upland LMES (School)	Admin	2026-04-01 09:28:07.101435	Admin
331	DELETE	Fare	31	Deleted Balinacon → Sil. Lazaan	Admin	2026-04-01 09:28:07.111104	Admin
332	DELETE	Fare	32	Deleted Balinacon → Kan. Lazaan	Admin	2026-04-01 09:28:07.119357	Admin
333	DELETE	Fare	33	Deleted Balinacon → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.130691	Admin
334	DELETE	Fare	34	Deleted Balinacon → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:07.141441	Admin
335	DELETE	Fare	35	Deleted Balinacon → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.150833	Admin
336	DELETE	Fare	36	Deleted Balinacon → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.158503	Admin
337	DELETE	Fare	37	Deleted Balinacon → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.167371	Admin
338	DELETE	Fare	38	Deleted Balinacon → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:07.176193	Admin
339	DELETE	Fare	39	Deleted Balinacon → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:07.185967	Admin
340	DELETE	Fare	124	Deleted Kan. Lazaan → Balinacon	Admin	2026-04-01 09:28:07.19479	Admin
341	DELETE	Fare	125	Deleted Kan. Lazaan → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.204569	Admin
342	DELETE	Fare	126	Deleted Kan. Lazaan → Sinipian	Admin	2026-04-01 09:28:07.213938	Admin
343	DELETE	Fare	127	Deleted Kan. Lazaan → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.222007	Admin
344	DELETE	Fare	128	Deleted Kan. Lazaan → Malinao	Admin	2026-04-01 09:28:07.231083	Admin
345	DELETE	Fare	129	Deleted Kan. Lazaan → Upland LMES (School)	Admin	2026-04-01 09:28:07.239437	Admin
346	DELETE	Fare	130	Deleted Kan. Lazaan → Sil. Lazaan	Admin	2026-04-01 09:28:07.247519	Admin
347	DELETE	Fare	131	Deleted Kan. Lazaan → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.257535	Admin
348	DELETE	Fare	132	Deleted Kan. Lazaan → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:07.265274	Admin
349	DELETE	Fare	133	Deleted Kan. Lazaan → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.273932	Admin
350	DELETE	Fare	134	Deleted Kan. Lazaan → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.281676	Admin
351	DELETE	Fare	135	Deleted Kan. Lazaan → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.291166	Admin
352	DELETE	Fare	136	Deleted Kan. Lazaan → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:07.300187	Admin
353	DELETE	Fare	137	Deleted Kan. Lazaan → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:07.309485	Admin
354	DELETE	Fare	152	Deleted Kan. Lazaan (Barod) → Balinacon	Admin	2026-04-01 09:28:07.317718	Admin
355	DELETE	Fare	153	Deleted Kan. Lazaan (Barod) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.327768	Admin
356	DELETE	Fare	154	Deleted Kan. Lazaan (Barod) → Sinipian	Admin	2026-04-01 09:28:07.335577	Admin
357	DELETE	Fare	155	Deleted Kan. Lazaan (Barod) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.343073	Admin
358	DELETE	Fare	156	Deleted Kan. Lazaan (Barod) → Malinao	Admin	2026-04-01 09:28:07.35087	Admin
359	DELETE	Fare	157	Deleted Kan. Lazaan (Barod) → Upland LMES (School)	Admin	2026-04-01 09:28:07.360866	Admin
360	DELETE	Fare	158	Deleted Kan. Lazaan (Barod) → Sil. Lazaan	Admin	2026-04-01 09:28:07.369211	Admin
361	DELETE	Fare	159	Deleted Kan. Lazaan (Barod) → Kan. Lazaan	Admin	2026-04-01 09:28:07.376986	Admin
362	DELETE	Fare	160	Deleted Kan. Lazaan (Barod) → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.386415	Admin
363	DELETE	Fare	161	Deleted Kan. Lazaan (Barod) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.395313	Admin
364	DELETE	Fare	162	Deleted Kan. Lazaan (Barod) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.405542	Admin
365	DELETE	Fare	163	Deleted Kan. Lazaan (Barod) → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.413785	Admin
366	DELETE	Fare	164	Deleted Kan. Lazaan (Barod) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:07.422271	Admin
367	DELETE	Fare	165	Deleted Kan. Lazaan (Barod) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:07.430795	Admin
368	DELETE	Fare	180	Deleted Kan. Lazaan (Ilaya) → Balinacon	Admin	2026-04-01 09:28:07.438763	Admin
369	DELETE	Fare	181	Deleted Kan. Lazaan (Ilaya) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.45	Admin
370	DELETE	Fare	182	Deleted Kan. Lazaan (Ilaya) → Sinipian	Admin	2026-04-01 09:28:07.460523	Admin
371	DELETE	Fare	183	Deleted Kan. Lazaan (Ilaya) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.469247	Admin
372	DELETE	Fare	184	Deleted Kan. Lazaan (Ilaya) → Malinao	Admin	2026-04-01 09:28:07.47779	Admin
373	DELETE	Fare	185	Deleted Kan. Lazaan (Ilaya) → Upland LMES (School)	Admin	2026-04-01 09:28:07.484984	Admin
374	DELETE	Fare	186	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan	Admin	2026-04-01 09:28:07.492812	Admin
375	DELETE	Fare	187	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan	Admin	2026-04-01 09:28:07.499727	Admin
376	DELETE	Fare	188	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.509016	Admin
377	DELETE	Fare	189	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:07.517221	Admin
378	DELETE	Fare	190	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.52627	Admin
379	DELETE	Fare	191	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.536176	Admin
380	DELETE	Fare	192	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:07.546065	Admin
381	DELETE	Fare	193	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:07.552856	Admin
382	DELETE	Fare	208	Deleted Kan. Lazaan (Siriaco) → Balinacon	Admin	2026-04-01 09:28:07.561911	Admin
383	DELETE	Fare	209	Deleted Kan. Lazaan (Siriaco) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.570267	Admin
384	DELETE	Fare	210	Deleted Kan. Lazaan (Siriaco) → Sinipian	Admin	2026-04-01 09:28:07.581063	Admin
385	DELETE	Fare	211	Deleted Kan. Lazaan (Siriaco) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.591976	Admin
386	DELETE	Fare	212	Deleted Kan. Lazaan (Siriaco) → Malinao	Admin	2026-04-01 09:28:07.599643	Admin
387	DELETE	Fare	213	Deleted Kan. Lazaan (Siriaco) → Upland LMES (School)	Admin	2026-04-01 09:28:07.607675	Admin
388	DELETE	Fare	214	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan	Admin	2026-04-01 09:28:07.615267	Admin
389	DELETE	Fare	215	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan	Admin	2026-04-01 09:28:07.62502	Admin
390	DELETE	Fare	216	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.633619	Admin
391	DELETE	Fare	217	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:07.643208	Admin
392	DELETE	Fare	218	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.65104	Admin
393	DELETE	Fare	219	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.658023	Admin
394	DELETE	Fare	220	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.667433	Admin
395	DELETE	Fare	221	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:07.67631	Admin
396	DELETE	Fare	222	Deleted Kan. Lazaan (St. Bartolome) → Balinacon	Admin	2026-04-01 09:28:07.686962	Admin
397	DELETE	Fare	223	Deleted Kan. Lazaan (St. Bartolome) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.696235	Admin
398	DELETE	Fare	224	Deleted Kan. Lazaan (St. Bartolome) → Sinipian	Admin	2026-04-01 09:28:07.708294	Admin
399	DELETE	Fare	225	Deleted Kan. Lazaan (St. Bartolome) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.716332	Admin
400	DELETE	Fare	226	Deleted Kan. Lazaan (St. Bartolome) → Malinao	Admin	2026-04-01 09:28:07.726501	Admin
401	DELETE	Fare	227	Deleted Kan. Lazaan (St. Bartolome) → Upland LMES (School)	Admin	2026-04-01 09:28:07.735523	Admin
402	DELETE	Fare	228	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan	Admin	2026-04-01 09:28:07.743764	Admin
403	DELETE	Fare	229	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan	Admin	2026-04-01 09:28:07.754534	Admin
404	DELETE	Fare	230	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.762615	Admin
405	DELETE	Fare	231	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:07.770401	Admin
406	DELETE	Fare	232	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.780694	Admin
407	DELETE	Fare	233	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.78885	Admin
408	DELETE	Fare	234	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.799492	Admin
409	DELETE	Fare	235	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:07.809499	Admin
410	DELETE	Fare	82	Deleted Malinao → Balinacon	Admin	2026-04-01 09:28:07.821769	Admin
411	DELETE	Fare	83	Deleted Malinao → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.830382	Admin
412	DELETE	Fare	84	Deleted Malinao → Sinipian	Admin	2026-04-01 09:28:07.838876	Admin
413	DELETE	Fare	85	Deleted Malinao → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.849798	Admin
414	DELETE	Fare	86	Deleted Malinao → Upland LMES (School)	Admin	2026-04-01 09:28:07.859502	Admin
415	DELETE	Fare	87	Deleted Malinao → Sil. Lazaan	Admin	2026-04-01 09:28:07.869016	Admin
416	DELETE	Fare	88	Deleted Malinao → Kan. Lazaan	Admin	2026-04-01 09:28:07.876467	Admin
417	DELETE	Fare	89	Deleted Malinao → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:07.889247	Admin
418	DELETE	Fare	90	Deleted Malinao → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:07.897525	Admin
419	DELETE	Fare	91	Deleted Malinao → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.90675	Admin
420	DELETE	Fare	92	Deleted Malinao → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:07.916407	Admin
421	DELETE	Fare	93	Deleted Malinao → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:07.925608	Admin
422	DELETE	Fare	94	Deleted Malinao → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:07.933658	Admin
423	DELETE	Fare	95	Deleted Malinao → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:07.942225	Admin
424	DELETE	Fare	110	Deleted Sil. Lazaan → Balinacon	Admin	2026-04-01 09:28:07.95213	Admin
425	DELETE	Fare	111	Deleted Sil. Lazaan → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:07.96044	Admin
426	DELETE	Fare	112	Deleted Sil. Lazaan → Sinipian	Admin	2026-04-01 09:28:07.970365	Admin
427	DELETE	Fare	113	Deleted Sil. Lazaan → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:07.979286	Admin
428	DELETE	Fare	114	Deleted Sil. Lazaan → Malinao	Admin	2026-04-01 09:28:07.987643	Admin
429	DELETE	Fare	115	Deleted Sil. Lazaan → Upland LMES (School)	Admin	2026-04-01 09:28:07.998223	Admin
430	DELETE	Fare	116	Deleted Sil. Lazaan → Kan. Lazaan	Admin	2026-04-01 09:28:08.008134	Admin
431	DELETE	Fare	117	Deleted Sil. Lazaan → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:08.015928	Admin
432	DELETE	Fare	118	Deleted Sil. Lazaan → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:08.0251	Admin
433	DELETE	Fare	119	Deleted Sil. Lazaan → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.033281	Admin
434	DELETE	Fare	120	Deleted Sil. Lazaan → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.041668	Admin
435	DELETE	Fare	121	Deleted Sil. Lazaan → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:08.049835	Admin
436	DELETE	Fare	122	Deleted Sil. Lazaan → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:08.060007	Admin
437	DELETE	Fare	123	Deleted Sil. Lazaan → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:08.068369	Admin
438	DELETE	Fare	194	Deleted Sil. Lazaan (Dulo) → Balinacon	Admin	2026-04-01 09:28:08.078053	Admin
439	DELETE	Fare	195	Deleted Sil. Lazaan (Dulo) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:08.090116	Admin
440	DELETE	Fare	196	Deleted Sil. Lazaan (Dulo) → Sinipian	Admin	2026-04-01 09:28:08.099696	Admin
441	DELETE	Fare	197	Deleted Sil. Lazaan (Dulo) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:08.107869	Admin
442	DELETE	Fare	198	Deleted Sil. Lazaan (Dulo) → Malinao	Admin	2026-04-01 09:28:08.115704	Admin
443	DELETE	Fare	199	Deleted Sil. Lazaan (Dulo) → Upland LMES (School)	Admin	2026-04-01 09:28:08.123971	Admin
444	DELETE	Fare	200	Deleted Sil. Lazaan (Dulo) → Sil. Lazaan	Admin	2026-04-01 09:28:08.133406	Admin
445	DELETE	Fare	201	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan	Admin	2026-04-01 09:28:08.14213	Admin
446	DELETE	Fare	202	Deleted Sil. Lazaan (Dulo) → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:08.151916	Admin
447	DELETE	Fare	203	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:08.161385	Admin
448	DELETE	Fare	204	Deleted Sil. Lazaan (Dulo) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.169918	Admin
449	DELETE	Fare	205	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.179454	Admin
450	DELETE	Fare	206	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:08.186905	Admin
451	DELETE	Fare	207	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:08.196408	Admin
452	DELETE	Fare	166	Deleted Sil. Lazaan (Ilaya) → Balinacon	Admin	2026-04-01 09:28:08.204406	Admin
453	DELETE	Fare	167	Deleted Sil. Lazaan (Ilaya) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:08.213147	Admin
454	DELETE	Fare	168	Deleted Sil. Lazaan (Ilaya) → Sinipian	Admin	2026-04-01 09:28:08.220824	Admin
455	DELETE	Fare	169	Deleted Sil. Lazaan (Ilaya) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:08.232394	Admin
456	DELETE	Fare	170	Deleted Sil. Lazaan (Ilaya) → Malinao	Admin	2026-04-01 09:28:08.24111	Admin
457	DELETE	Fare	171	Deleted Sil. Lazaan (Ilaya) → Upland LMES (School)	Admin	2026-04-01 09:28:08.250149	Admin
458	DELETE	Fare	172	Deleted Sil. Lazaan (Ilaya) → Sil. Lazaan	Admin	2026-04-01 09:28:08.263535	Admin
459	DELETE	Fare	173	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan	Admin	2026-04-01 09:28:08.273238	Admin
460	DELETE	Fare	174	Deleted Sil. Lazaan (Ilaya) → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:08.285307	Admin
461	DELETE	Fare	175	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:08.295118	Admin
462	DELETE	Fare	176	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.303287	Admin
463	DELETE	Fare	177	Deleted Sil. Lazaan (Ilaya) → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:08.314232	Admin
464	DELETE	Fare	178	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:08.323226	Admin
465	DELETE	Fare	179	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:08.331767	Admin
466	DELETE	Fare	138	Deleted Sil. Lazaan (Tower) → Balinacon	Admin	2026-04-01 09:28:08.341835	Admin
467	DELETE	Fare	139	Deleted Sil. Lazaan (Tower) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:08.349757	Admin
468	DELETE	Fare	140	Deleted Sil. Lazaan (Tower) → Sinipian	Admin	2026-04-01 09:28:08.360647	Admin
469	DELETE	Fare	141	Deleted Sil. Lazaan (Tower) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:08.368548	Admin
470	DELETE	Fare	142	Deleted Sil. Lazaan (Tower) → Malinao	Admin	2026-04-01 09:28:08.377723	Admin
471	DELETE	Fare	143	Deleted Sil. Lazaan (Tower) → Upland LMES (School)	Admin	2026-04-01 09:28:08.386189	Admin
472	DELETE	Fare	144	Deleted Sil. Lazaan (Tower) → Sil. Lazaan	Admin	2026-04-01 09:28:08.395101	Admin
473	DELETE	Fare	145	Deleted Sil. Lazaan (Tower) → Kan. Lazaan	Admin	2026-04-01 09:28:08.404764	Admin
474	DELETE	Fare	146	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:08.415832	Admin
475	DELETE	Fare	147	Deleted Sil. Lazaan (Tower) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.425291	Admin
476	DELETE	Fare	148	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.432944	Admin
477	DELETE	Fare	149	Deleted Sil. Lazaan (Tower) → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:08.443894	Admin
478	DELETE	Fare	150	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:08.453	Admin
479	DELETE	Fare	151	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:08.460539	Admin
480	DELETE	Fare	54	Deleted Sinipian → Balinacon	Admin	2026-04-01 09:28:08.470183	Admin
481	DELETE	Fare	55	Deleted Sinipian → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:08.480116	Admin
482	DELETE	Fare	56	Deleted Sinipian → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:08.488033	Admin
483	DELETE	Fare	57	Deleted Sinipian → Malinao	Admin	2026-04-01 09:28:08.496228	Admin
484	DELETE	Fare	58	Deleted Sinipian → Upland LMES (School)	Admin	2026-04-01 09:28:08.503382	Admin
485	DELETE	Fare	59	Deleted Sinipian → Sil. Lazaan	Admin	2026-04-01 09:28:08.510988	Admin
486	DELETE	Fare	60	Deleted Sinipian → Kan. Lazaan	Admin	2026-04-01 09:28:08.520518	Admin
487	DELETE	Fare	61	Deleted Sinipian → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:08.530955	Admin
488	DELETE	Fare	62	Deleted Sinipian → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:08.541891	Admin
489	DELETE	Fare	63	Deleted Sinipian → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.550505	Admin
490	DELETE	Fare	64	Deleted Sinipian → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.558712	Admin
491	DELETE	Fare	65	Deleted Sinipian → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:08.566859	Admin
492	DELETE	Fare	66	Deleted Sinipian → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:08.575953	Admin
493	DELETE	Fare	67	Deleted Sinipian → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:08.585393	Admin
494	DELETE	Fare	96	Deleted Upland LMES (School) → Balinacon	Admin	2026-04-01 09:28:08.593791	Admin
495	DELETE	Fare	97	Deleted Upland LMES (School) → Balimbing - 1 Ahon	Admin	2026-04-01 09:28:08.602052	Admin
496	DELETE	Fare	98	Deleted Upland LMES (School) → Sinipian	Admin	2026-04-01 09:28:08.611033	Admin
497	DELETE	Fare	99	Deleted Upland LMES (School) → Balimbing - 2 Ahon	Admin	2026-04-01 09:28:08.619737	Admin
498	DELETE	Fare	100	Deleted Upland LMES (School) → Malinao	Admin	2026-04-01 09:28:08.630589	Admin
499	DELETE	Fare	101	Deleted Upland LMES (School) → Sil. Lazaan	Admin	2026-04-01 09:28:08.639877	Admin
500	DELETE	Fare	102	Deleted Upland LMES (School) → Kan. Lazaan	Admin	2026-04-01 09:28:08.647044	Admin
501	DELETE	Fare	103	Deleted Upland LMES (School) → Sil. Lazaan (Tower)	Admin	2026-04-01 09:28:08.657789	Admin
502	DELETE	Fare	104	Deleted Upland LMES (School) → Kan. Lazaan (Barod)	Admin	2026-04-01 09:28:08.668	Admin
503	DELETE	Fare	105	Deleted Upland LMES (School) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.675561	Admin
504	DELETE	Fare	106	Deleted Upland LMES (School) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 09:28:08.683202	Admin
505	DELETE	Fare	107	Deleted Upland LMES (School) → Sil. Lazaan (Dulo)	Admin	2026-04-01 09:28:08.69126	Admin
506	DELETE	Fare	108	Deleted Upland LMES (School) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 09:28:08.698794	Admin
507	DELETE	Fare	109	Deleted Upland LMES (School) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 09:28:08.709945	Admin
508	CREATE	Fare	236	Balinacon → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:28:30.026148	Admin
509	CREATE	Fare	237	Balinacon → Sinipian base ₱20.00	Admin	2026-04-01 09:28:30.053173	Admin
510	CREATE	Fare	238	Balinacon → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 09:28:30.059536	Admin
511	CREATE	Fare	239	Balinacon → Malinao base ₱25.00	Admin	2026-04-01 09:28:30.065175	Admin
512	CREATE	Fare	240	Balinacon → Upland LMES (School) base ₱30.00	Admin	2026-04-01 09:28:30.072193	Admin
513	CREATE	Fare	241	Balinacon → Sil. Lazaan base ₱35.00	Admin	2026-04-01 09:28:30.081669	Admin
514	CREATE	Fare	242	Balinacon → Kan. Lazaan base ₱40.00	Admin	2026-04-01 09:28:30.08755	Admin
515	CREATE	Fare	243	Balinacon → Sil. Lazaan (Tower) base ₱45.00	Admin	2026-04-01 09:28:30.094138	Admin
516	CREATE	Fare	244	Balinacon → Kan. Lazaan (Barod) base ₱55.00	Admin	2026-04-01 09:28:30.100377	Admin
517	CREATE	Fare	245	Balinacon → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:28:30.106281	Admin
518	CREATE	Fare	246	Balinacon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:28:30.114578	Admin
519	CREATE	Fare	247	Balinacon → Sil. Lazaan (Dulo) base ₱60.00	Admin	2026-04-01 09:28:30.121466	Admin
520	CREATE	Fare	248	Balinacon → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:28:30.131066	Admin
521	CREATE	Fare	249	Balinacon → Kan. Lazaan (St. Bartolome) base ₱70.00	Admin	2026-04-01 09:28:30.137035	Admin
522	CREATE	Fare	250	Balimbing - 1 Ahon → Balinacon base ₱20.00	Admin	2026-04-01 09:28:30.144566	Admin
523	CREATE	Fare	251	Balimbing - 1 Ahon → Sinipian base ₱20.00	Admin	2026-04-01 09:28:30.150066	Admin
524	CREATE	Fare	252	Balimbing - 1 Ahon → Balimbing - 2 Ahon base ₱20.00	Admin	2026-04-01 09:28:30.155309	Admin
525	CREATE	Fare	253	Balimbing - 1 Ahon → Malinao base ₱20.00	Admin	2026-04-01 09:28:30.162725	Admin
526	CREATE	Fare	254	Balimbing - 1 Ahon → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:28:30.168732	Admin
527	CREATE	Fare	255	Balimbing - 1 Ahon → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:28:30.175018	Admin
528	CREATE	Fare	256	Balimbing - 1 Ahon → Kan. Lazaan base ₱35.00	Admin	2026-04-01 09:28:30.18108	Admin
529	CREATE	Fare	257	Balimbing - 1 Ahon → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 09:28:30.186286	Admin
530	CREATE	Fare	258	Balimbing - 1 Ahon → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 09:28:30.191815	Admin
531	CREATE	Fare	259	Balimbing - 1 Ahon → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:28:30.197307	Admin
532	CREATE	Fare	260	Balimbing - 1 Ahon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:28:30.202995	Admin
533	CREATE	Fare	261	Balimbing - 1 Ahon → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 09:28:30.209008	Admin
534	CREATE	Fare	262	Balimbing - 1 Ahon → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 09:28:30.214447	Admin
535	CREATE	Fare	263	Balimbing - 1 Ahon → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:28:30.219644	Admin
536	CREATE	Fare	264	Sinipian → Balinacon base ₱20.00	Admin	2026-04-01 09:28:30.22581	Admin
537	CREATE	Fare	265	Sinipian → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:28:30.231337	Admin
538	CREATE	Fare	266	Sinipian → Balimbing - 2 Ahon base ₱20.00	Admin	2026-04-01 09:28:30.236659	Admin
539	CREATE	Fare	267	Sinipian → Malinao base ₱20.00	Admin	2026-04-01 09:28:30.242168	Admin
540	CREATE	Fare	268	Sinipian → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:28:30.248146	Admin
541	CREATE	Fare	269	Sinipian → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:28:30.254069	Admin
542	CREATE	Fare	270	Sinipian → Kan. Lazaan base ₱35.00	Admin	2026-04-01 09:28:30.260777	Admin
543	CREATE	Fare	271	Sinipian → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 09:28:30.2675	Admin
544	CREATE	Fare	272	Sinipian → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 09:28:30.274207	Admin
545	CREATE	Fare	273	Sinipian → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:28:30.280795	Admin
546	CREATE	Fare	274	Sinipian → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:28:30.286765	Admin
547	CREATE	Fare	275	Sinipian → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 09:28:30.292863	Admin
548	CREATE	Fare	276	Sinipian → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 09:28:30.298326	Admin
549	CREATE	Fare	277	Sinipian → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:28:30.30345	Admin
550	CREATE	Fare	278	Balimbing - 2 Ahon → Balinacon base ₱20.00	Admin	2026-04-01 09:28:30.309943	Admin
551	CREATE	Fare	279	Balimbing - 2 Ahon → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:28:30.314998	Admin
552	CREATE	Fare	280	Balimbing - 2 Ahon → Sinipian base ₱20.00	Admin	2026-04-01 09:28:30.319689	Admin
553	CREATE	Fare	281	Balimbing - 2 Ahon → Malinao base ₱20.00	Admin	2026-04-01 09:28:30.325679	Admin
554	CREATE	Fare	282	Balimbing - 2 Ahon → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:28:30.331197	Admin
555	CREATE	Fare	283	Balimbing - 2 Ahon → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:28:30.336761	Admin
556	CREATE	Fare	284	Balimbing - 2 Ahon → Kan. Lazaan base ₱35.00	Admin	2026-04-01 09:28:30.342735	Admin
557	CREATE	Fare	285	Balimbing - 2 Ahon → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 09:28:30.348771	Admin
558	CREATE	Fare	286	Balimbing - 2 Ahon → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 09:28:30.355263	Admin
559	CREATE	Fare	287	Balimbing - 2 Ahon → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:28:30.362178	Admin
560	CREATE	Fare	288	Balimbing - 2 Ahon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:28:30.371056	Admin
561	CREATE	Fare	289	Balimbing - 2 Ahon → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 09:28:30.378747	Admin
562	CREATE	Fare	290	Balimbing - 2 Ahon → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:28:30.384365	Admin
563	CREATE	Fare	291	Balimbing - 2 Ahon → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:28:30.39128	Admin
564	CREATE	Fare	292	Malinao → Balinacon base ₱20.00	Admin	2026-04-01 09:28:30.398701	Admin
565	CREATE	Fare	293	Malinao → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:28:30.408381	Admin
566	CREATE	Fare	294	Malinao → Sinipian base ₱20.00	Admin	2026-04-01 09:28:30.418791	Admin
567	CREATE	Fare	295	Malinao → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 09:28:30.427018	Admin
568	CREATE	Fare	296	Malinao → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:28:30.43305	Admin
569	CREATE	Fare	297	Malinao → Sil. Lazaan base ₱25.00	Admin	2026-04-01 09:28:30.439312	Admin
570	CREATE	Fare	298	Malinao → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:28:30.445679	Admin
571	CREATE	Fare	299	Malinao → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 09:28:30.45145	Admin
572	CREATE	Fare	300	Malinao → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 09:28:30.45709	Admin
573	CREATE	Fare	301	Malinao → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:28:30.46248	Admin
574	CREATE	Fare	302	Malinao → Kan. Lazaan (Ilaya) base ₱45.00	Admin	2026-04-01 09:28:30.469084	Admin
575	CREATE	Fare	303	Malinao → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:28:30.474908	Admin
576	CREATE	Fare	304	Malinao → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 09:28:30.480205	Admin
577	CREATE	Fare	305	Malinao → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:28:30.48705	Admin
578	CREATE	Fare	306	Upland LMES (School) → Balinacon base ₱25.00	Admin	2026-04-01 09:28:30.493694	Admin
579	CREATE	Fare	307	Upland LMES (School) → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 09:28:30.499793	Admin
580	CREATE	Fare	308	Upland LMES (School) → Sinipian base ₱20.00	Admin	2026-04-01 09:28:30.506892	Admin
581	CREATE	Fare	309	Upland LMES (School) → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 09:28:30.51348	Admin
582	CREATE	Fare	310	Upland LMES (School) → Malinao base ₱20.00	Admin	2026-04-01 09:28:30.519825	Admin
583	CREATE	Fare	311	Upland LMES (School) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:28:30.526069	Admin
584	CREATE	Fare	312	Upland LMES (School) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:28:30.53231	Admin
585	CREATE	Fare	313	Upland LMES (School) → Sil. Lazaan (Tower) base ₱30.00	Admin	2026-04-01 09:28:30.538031	Admin
586	CREATE	Fare	314	Upland LMES (School) → Kan. Lazaan (Barod) base ₱35.00	Admin	2026-04-01 09:28:30.544491	Admin
587	CREATE	Fare	315	Upland LMES (School) → Sil. Lazaan (Ilaya) base ₱35.00	Admin	2026-04-01 09:28:30.550264	Admin
588	CREATE	Fare	316	Upland LMES (School) → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:28:30.555687	Admin
589	CREATE	Fare	317	Upland LMES (School) → Sil. Lazaan (Dulo) base ₱45.00	Admin	2026-04-01 09:28:30.561387	Admin
590	CREATE	Fare	318	Upland LMES (School) → Kan. Lazaan (Siriaco) base ₱45.00	Admin	2026-04-01 09:28:30.566812	Admin
591	CREATE	Fare	319	Upland LMES (School) → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:28:30.575074	Admin
592	CREATE	Fare	320	Sil. Lazaan → Balinacon base ₱30.00	Admin	2026-04-01 09:28:30.58198	Admin
593	CREATE	Fare	321	Sil. Lazaan → Balimbing - 1 Ahon base ₱25.00	Admin	2026-04-01 09:28:30.588181	Admin
594	CREATE	Fare	322	Sil. Lazaan → Sinipian base ₱25.00	Admin	2026-04-01 09:28:30.595612	Admin
595	CREATE	Fare	323	Sil. Lazaan → Balimbing - 2 Ahon base ₱30.00	Admin	2026-04-01 09:28:30.601379	Admin
596	CREATE	Fare	324	Sil. Lazaan → Malinao base ₱20.00	Admin	2026-04-01 09:28:30.60711	Admin
597	CREATE	Fare	325	Sil. Lazaan → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:28:30.613123	Admin
598	CREATE	Fare	326	Sil. Lazaan → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:28:30.619063	Admin
599	CREATE	Fare	327	Sil. Lazaan → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 09:28:30.626919	Admin
600	CREATE	Fare	328	Sil. Lazaan → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 09:28:30.634123	Admin
601	CREATE	Fare	329	Sil. Lazaan → Sil. Lazaan (Ilaya) base ₱35.00	Admin	2026-04-01 09:28:30.640902	Admin
602	CREATE	Fare	330	Sil. Lazaan → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:28:30.647446	Admin
603	CREATE	Fare	331	Sil. Lazaan → Sil. Lazaan (Dulo) base ₱40.00	Admin	2026-04-01 09:28:30.653241	Admin
604	CREATE	Fare	332	Sil. Lazaan → Kan. Lazaan (Siriaco) base ₱45.00	Admin	2026-04-01 09:28:30.659806	Admin
605	CREATE	Fare	333	Sil. Lazaan → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:28:30.666109	Admin
606	CREATE	Fare	334	Kan. Lazaan → Balinacon base ₱30.00	Admin	2026-04-01 09:28:30.672638	Admin
607	CREATE	Fare	335	Kan. Lazaan → Balimbing - 1 Ahon base ₱25.00	Admin	2026-04-01 09:28:30.679361	Admin
608	CREATE	Fare	336	Kan. Lazaan → Sinipian base ₱25.00	Admin	2026-04-01 09:28:30.68673	Admin
609	CREATE	Fare	337	Kan. Lazaan → Balimbing - 2 Ahon base ₱30.00	Admin	2026-04-01 09:28:30.693821	Admin
610	CREATE	Fare	338	Kan. Lazaan → Malinao base ₱25.00	Admin	2026-04-01 09:28:30.700692	Admin
611	CREATE	Fare	339	Kan. Lazaan → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:28:30.712066	Admin
612	CREATE	Fare	340	Kan. Lazaan → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:28:30.718031	Admin
613	CREATE	Fare	341	Kan. Lazaan → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 09:28:30.724973	Admin
614	CREATE	Fare	342	Kan. Lazaan → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 09:28:30.73244	Admin
615	CREATE	Fare	343	Kan. Lazaan → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:28:30.738755	Admin
616	CREATE	Fare	344	Kan. Lazaan → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:28:30.745164	Admin
617	CREATE	Fare	345	Kan. Lazaan → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:28:30.750613	Admin
618	CREATE	Fare	346	Kan. Lazaan → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 09:28:30.756141	Admin
619	CREATE	Fare	347	Kan. Lazaan → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 09:28:30.762826	Admin
620	CREATE	Fare	348	Sil. Lazaan (Tower) → Balinacon base ₱35.00	Admin	2026-04-01 09:28:30.77019	Admin
621	CREATE	Fare	349	Sil. Lazaan (Tower) → Balimbing - 1 Ahon base ₱30.00	Admin	2026-04-01 09:28:30.776574	Admin
622	CREATE	Fare	350	Sil. Lazaan (Tower) → Sinipian base ₱30.00	Admin	2026-04-01 09:28:30.781973	Admin
623	CREATE	Fare	351	Sil. Lazaan (Tower) → Balimbing - 2 Ahon base ₱35.00	Admin	2026-04-01 09:28:30.787527	Admin
624	CREATE	Fare	352	Sil. Lazaan (Tower) → Malinao base ₱25.00	Admin	2026-04-01 09:28:30.793288	Admin
625	CREATE	Fare	353	Sil. Lazaan (Tower) → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:28:30.799605	Admin
626	CREATE	Fare	354	Sil. Lazaan (Tower) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:28:30.809223	Admin
627	CREATE	Fare	355	Sil. Lazaan (Tower) → Kan. Lazaan base ₱40.00	Admin	2026-04-01 09:28:30.815887	Admin
628	CREATE	Fare	356	Sil. Lazaan (Tower) → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 09:28:30.82403	Admin
629	CREATE	Fare	357	Sil. Lazaan (Tower) → Sil. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:28:30.830477	Admin
630	CREATE	Fare	358	Sil. Lazaan (Tower) → Kan. Lazaan (Ilaya) base ₱45.00	Admin	2026-04-01 09:28:30.835941	Admin
631	CREATE	Fare	359	Sil. Lazaan (Tower) → Sil. Lazaan (Dulo) base ₱30.00	Admin	2026-04-01 09:28:30.842024	Admin
632	CREATE	Fare	360	Sil. Lazaan (Tower) → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 09:28:30.847717	Admin
633	CREATE	Fare	361	Sil. Lazaan (Tower) → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 09:28:30.853502	Admin
634	CREATE	Fare	362	Kan. Lazaan (Barod) → Balinacon base ₱40.00	Admin	2026-04-01 09:28:30.859639	Admin
635	CREATE	Fare	363	Kan. Lazaan (Barod) → Balimbing - 1 Ahon base ₱30.00	Admin	2026-04-01 09:28:30.865063	Admin
636	CREATE	Fare	364	Kan. Lazaan (Barod) → Sinipian base ₱30.00	Admin	2026-04-01 09:28:30.871386	Admin
637	CREATE	Fare	365	Kan. Lazaan (Barod) → Balimbing - 2 Ahon base ₱35.00	Admin	2026-04-01 09:28:30.877456	Admin
638	CREATE	Fare	366	Kan. Lazaan (Barod) → Malinao base ₱30.00	Admin	2026-04-01 09:28:30.883354	Admin
639	CREATE	Fare	367	Kan. Lazaan (Barod) → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:28:30.891321	Admin
640	CREATE	Fare	368	Kan. Lazaan (Barod) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:28:30.897603	Admin
641	CREATE	Fare	369	Kan. Lazaan (Barod) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:28:30.903298	Admin
642	CREATE	Fare	370	Kan. Lazaan (Barod) → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 09:28:30.910074	Admin
643	CREATE	Fare	371	Kan. Lazaan (Barod) → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 09:28:30.915825	Admin
644	CREATE	Fare	372	Kan. Lazaan (Barod) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:28:30.921617	Admin
645	CREATE	Fare	373	Kan. Lazaan (Barod) → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:28:30.92849	Admin
646	CREATE	Fare	374	Kan. Lazaan (Barod) → Kan. Lazaan (Siriaco) base ₱35.00	Admin	2026-04-01 09:28:30.93381	Admin
647	CREATE	Fare	375	Kan. Lazaan (Barod) → Kan. Lazaan (St. Bartolome) base ₱45.00	Admin	2026-04-01 09:28:30.939162	Admin
648	CREATE	Fare	376	Sil. Lazaan (Ilaya) → Balinacon base ₱40.00	Admin	2026-04-01 09:28:30.944607	Admin
649	CREATE	Fare	377	Sil. Lazaan (Ilaya) → Balimbing - 1 Ahon base ₱35.00	Admin	2026-04-01 09:28:30.950772	Admin
650	CREATE	Fare	378	Sil. Lazaan (Ilaya) → Sinipian base ₱35.00	Admin	2026-04-01 09:28:30.956458	Admin
651	CREATE	Fare	379	Sil. Lazaan (Ilaya) → Balimbing - 2 Ahon base ₱40.00	Admin	2026-04-01 09:28:30.961953	Admin
652	CREATE	Fare	380	Sil. Lazaan (Ilaya) → Malinao base ₱30.00	Admin	2026-04-01 09:28:30.967381	Admin
653	CREATE	Fare	381	Sil. Lazaan (Ilaya) → Upland LMES (School) base ₱20.00	Admin	2026-04-01 09:28:30.973963	Admin
654	CREATE	Fare	382	Sil. Lazaan (Ilaya) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:28:30.980201	Admin
655	CREATE	Fare	383	Sil. Lazaan (Ilaya) → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:28:30.986018	Admin
656	CREATE	Fare	384	Sil. Lazaan (Ilaya) → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 09:28:30.993076	Admin
657	CREATE	Fare	385	Sil. Lazaan (Ilaya) → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 09:28:30.998754	Admin
658	CREATE	Fare	386	Sil. Lazaan (Ilaya) → Kan. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:28:31.004904	Admin
659	CREATE	Fare	387	Sil. Lazaan (Ilaya) → Sil. Lazaan (Dulo) base ₱30.00	Admin	2026-04-01 09:28:31.01113	Admin
660	CREATE	Fare	388	Sil. Lazaan (Ilaya) → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:28:31.017202	Admin
661	CREATE	Fare	389	Sil. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome) base ₱65.00	Admin	2026-04-01 09:28:31.022699	Admin
662	CREATE	Fare	390	Kan. Lazaan (Ilaya) → Balinacon base ₱40.00	Admin	2026-04-01 09:28:31.029192	Admin
663	CREATE	Fare	391	Kan. Lazaan (Ilaya) → Balimbing - 1 Ahon base ₱35.00	Admin	2026-04-01 09:28:31.035582	Admin
664	CREATE	Fare	392	Kan. Lazaan (Ilaya) → Sinipian base ₱35.00	Admin	2026-04-01 09:28:31.043037	Admin
665	CREATE	Fare	393	Kan. Lazaan (Ilaya) → Balimbing - 2 Ahon base ₱40.00	Admin	2026-04-01 09:28:31.048567	Admin
666	CREATE	Fare	394	Kan. Lazaan (Ilaya) → Malinao base ₱30.00	Admin	2026-04-01 09:28:31.054127	Admin
667	CREATE	Fare	395	Kan. Lazaan (Ilaya) → Upland LMES (School) base ₱25.00	Admin	2026-04-01 09:28:31.059996	Admin
668	CREATE	Fare	396	Kan. Lazaan (Ilaya) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 09:28:31.065419	Admin
669	CREATE	Fare	397	Kan. Lazaan (Ilaya) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:28:31.070809	Admin
670	CREATE	Fare	398	Kan. Lazaan (Ilaya) → Sil. Lazaan (Tower) base ₱45.00	Admin	2026-04-01 09:28:31.077206	Admin
671	CREATE	Fare	399	Kan. Lazaan (Ilaya) → Kan. Lazaan (Barod) base ₱20.00	Admin	2026-04-01 09:28:31.087885	Admin
672	CREATE	Fare	400	Kan. Lazaan (Ilaya) → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:28:31.09753	Admin
673	CREATE	Fare	401	Kan. Lazaan (Ilaya) → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 09:28:31.105441	Admin
674	CREATE	Fare	402	Kan. Lazaan (Ilaya) → Kan. Lazaan (Siriaco) base ₱25.00	Admin	2026-04-01 09:28:31.116266	Admin
675	CREATE	Fare	403	Kan. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome) base ₱30.00	Admin	2026-04-01 09:28:31.124978	Admin
676	CREATE	Fare	404	Sil. Lazaan (Dulo) → Balinacon base ₱50.00	Admin	2026-04-01 09:28:31.132057	Admin
677	CREATE	Fare	405	Sil. Lazaan (Dulo) → Balimbing - 1 Ahon base ₱45.00	Admin	2026-04-01 09:28:31.138504	Admin
678	CREATE	Fare	406	Sil. Lazaan (Dulo) → Sinipian base ₱45.00	Admin	2026-04-01 09:28:31.146185	Admin
679	CREATE	Fare	407	Sil. Lazaan (Dulo) → Balimbing - 2 Ahon base ₱45.00	Admin	2026-04-01 09:28:31.151349	Admin
680	CREATE	Fare	408	Sil. Lazaan (Dulo) → Malinao base ₱40.00	Admin	2026-04-01 09:28:31.157013	Admin
681	CREATE	Fare	409	Sil. Lazaan (Dulo) → Upland LMES (School) base ₱30.00	Admin	2026-04-01 09:28:31.162606	Admin
682	CREATE	Fare	410	Sil. Lazaan (Dulo) → Sil. Lazaan base ₱25.00	Admin	2026-04-01 09:28:31.167996	Admin
683	CREATE	Fare	411	Sil. Lazaan (Dulo) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:28:31.173374	Admin
684	CREATE	Fare	412	Sil. Lazaan (Dulo) → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 09:28:31.180363	Admin
685	CREATE	Fare	413	Sil. Lazaan (Dulo) → Kan. Lazaan (Barod) base ₱55.00	Admin	2026-04-01 09:28:31.18654	Admin
686	CREATE	Fare	414	Sil. Lazaan (Dulo) → Sil. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:28:31.192593	Admin
687	CREATE	Fare	415	Sil. Lazaan (Dulo) → Kan. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 09:28:31.198292	Admin
688	CREATE	Fare	416	Sil. Lazaan (Dulo) → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 09:28:31.203673	Admin
689	CREATE	Fare	417	Sil. Lazaan (Dulo) → Kan. Lazaan (St. Bartolome) base ₱70.00	Admin	2026-04-01 09:28:31.210029	Admin
690	CREATE	Fare	418	Kan. Lazaan (Siriaco) → Balinacon base ₱50.00	Admin	2026-04-01 09:28:31.215518	Admin
691	CREATE	Fare	419	Kan. Lazaan (Siriaco) → Balimbing - 1 Ahon base ₱45.00	Admin	2026-04-01 09:28:31.221171	Admin
692	CREATE	Fare	420	Kan. Lazaan (Siriaco) → Sinipian base ₱45.00	Admin	2026-04-01 09:28:31.22711	Admin
693	CREATE	Fare	421	Kan. Lazaan (Siriaco) → Balimbing - 2 Ahon base ₱45.00	Admin	2026-04-01 09:28:31.232614	Admin
694	CREATE	Fare	422	Kan. Lazaan (Siriaco) → Malinao base ₱40.00	Admin	2026-04-01 09:28:31.238058	Admin
695	CREATE	Fare	423	Kan. Lazaan (Siriaco) → Upland LMES (School) base ₱30.00	Admin	2026-04-01 09:28:31.244277	Admin
696	CREATE	Fare	424	Kan. Lazaan (Siriaco) → Sil. Lazaan base ₱25.00	Admin	2026-04-01 09:28:31.249905	Admin
697	CREATE	Fare	425	Kan. Lazaan (Siriaco) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 09:28:31.255263	Admin
698	CREATE	Fare	426	Kan. Lazaan (Siriaco) → Sil. Lazaan (Tower) base ₱55.00	Admin	2026-04-01 09:28:31.261548	Admin
699	CREATE	Fare	427	Kan. Lazaan (Siriaco) → Kan. Lazaan (Barod) base ₱20.00	Admin	2026-04-01 09:28:31.266882	Admin
700	CREATE	Fare	428	Kan. Lazaan (Siriaco) → Sil. Lazaan (Ilaya) base ₱60.00	Admin	2026-04-01 09:28:31.272431	Admin
701	CREATE	Fare	429	Kan. Lazaan (Siriaco) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:28:31.278467	Admin
702	CREATE	Fare	430	Kan. Lazaan (Siriaco) → Sil. Lazaan (Dulo) base ₱60.00	Admin	2026-04-01 09:28:31.283883	Admin
703	CREATE	Fare	431	Kan. Lazaan (Siriaco) → Kan. Lazaan (St. Bartolome) base ₱30.00	Admin	2026-04-01 09:28:31.289351	Admin
704	CREATE	Fare	432	Kan. Lazaan (St. Bartolome) → Balinacon base ₱55.00	Admin	2026-04-01 09:28:31.295604	Admin
705	CREATE	Fare	433	Kan. Lazaan (St. Bartolome) → Balimbing - 1 Ahon base ₱50.00	Admin	2026-04-01 09:28:31.301325	Admin
706	CREATE	Fare	434	Kan. Lazaan (St. Bartolome) → Sinipian base ₱50.00	Admin	2026-04-01 09:28:31.307433	Admin
707	CREATE	Fare	435	Kan. Lazaan (St. Bartolome) → Balimbing - 2 Ahon base ₱50.00	Admin	2026-04-01 09:28:31.312912	Admin
708	CREATE	Fare	436	Kan. Lazaan (St. Bartolome) → Malinao base ₱40.00	Admin	2026-04-01 09:28:31.318775	Admin
709	CREATE	Fare	437	Kan. Lazaan (St. Bartolome) → Upland LMES (School) base ₱36.00	Admin	2026-04-01 09:28:31.324839	Admin
710	CREATE	Fare	438	Kan. Lazaan (St. Bartolome) → Sil. Lazaan base ₱30.00	Admin	2026-04-01 09:28:31.330806	Admin
711	CREATE	Fare	439	Kan. Lazaan (St. Bartolome) → Kan. Lazaan base ₱30.00	Admin	2026-04-01 09:28:31.336292	Admin
712	CREATE	Fare	440	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Tower) base ₱60.00	Admin	2026-04-01 09:28:31.341822	Admin
713	CREATE	Fare	441	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 09:28:31.347906	Admin
714	CREATE	Fare	442	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 09:28:31.353581	Admin
715	CREATE	Fare	443	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 09:28:31.359363	Admin
716	CREATE	Fare	444	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Dulo) base ₱20.00	Admin	2026-04-01 09:28:31.366143	Admin
717	CREATE	Fare	445	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 09:28:31.371915	Admin
718	UPDATE	Passenger	3	Updated passenger: Maki 	Admin	2026-04-01 10:24:18.866442	Admin
719	UPDATE	Passenger	3	Updated passenger: Maki Lucido	Admin	2026-04-01 10:24:33.410481	Admin
720	UPDATE	Passenger	4	Updated passenger: Andrew Cauyan	Admin	2026-04-01 10:24:46.559754	Admin
721	UPDATE	Driver	2	Updated driver details	Admin	2026-04-01 10:25:13.841655	Admin
722	UPDATE	Driver	2	Updated driver details	Admin	2026-04-01 10:25:17.992846	Admin
723	DELETE	Fare	250	Deleted Balimbing - 1 Ahon → Balinacon	Admin	2026-04-01 13:01:15.388833	Admin
724	DELETE	Fare	251	Deleted Balimbing - 1 Ahon → Sinipian	Admin	2026-04-01 13:01:15.401022	Admin
725	DELETE	Fare	252	Deleted Balimbing - 1 Ahon → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:15.406763	Admin
726	DELETE	Fare	253	Deleted Balimbing - 1 Ahon → Malinao	Admin	2026-04-01 13:01:15.412233	Admin
727	DELETE	Fare	254	Deleted Balimbing - 1 Ahon → Upland LMES (School)	Admin	2026-04-01 13:01:15.417579	Admin
728	DELETE	Fare	255	Deleted Balimbing - 1 Ahon → Sil. Lazaan	Admin	2026-04-01 13:01:15.422675	Admin
729	DELETE	Fare	256	Deleted Balimbing - 1 Ahon → Kan. Lazaan	Admin	2026-04-01 13:01:15.428613	Admin
730	DELETE	Fare	257	Deleted Balimbing - 1 Ahon → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.433898	Admin
731	DELETE	Fare	258	Deleted Balimbing - 1 Ahon → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:15.438851	Admin
732	DELETE	Fare	259	Deleted Balimbing - 1 Ahon → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.444418	Admin
733	DELETE	Fare	260	Deleted Balimbing - 1 Ahon → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.44991	Admin
734	DELETE	Fare	261	Deleted Balimbing - 1 Ahon → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:15.454786	Admin
735	DELETE	Fare	262	Deleted Balimbing - 1 Ahon → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:15.460446	Admin
736	DELETE	Fare	263	Deleted Balimbing - 1 Ahon → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:15.466182	Admin
737	DELETE	Fare	278	Deleted Balimbing - 2 Ahon → Balinacon	Admin	2026-04-01 13:01:15.470997	Admin
738	DELETE	Fare	279	Deleted Balimbing - 2 Ahon → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:15.476583	Admin
739	DELETE	Fare	280	Deleted Balimbing - 2 Ahon → Sinipian	Admin	2026-04-01 13:01:15.481721	Admin
740	DELETE	Fare	281	Deleted Balimbing - 2 Ahon → Malinao	Admin	2026-04-01 13:01:15.486322	Admin
741	DELETE	Fare	282	Deleted Balimbing - 2 Ahon → Upland LMES (School)	Admin	2026-04-01 13:01:15.491674	Admin
742	DELETE	Fare	283	Deleted Balimbing - 2 Ahon → Sil. Lazaan	Admin	2026-04-01 13:01:15.496881	Admin
743	DELETE	Fare	284	Deleted Balimbing - 2 Ahon → Kan. Lazaan	Admin	2026-04-01 13:01:15.501921	Admin
744	DELETE	Fare	285	Deleted Balimbing - 2 Ahon → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.507961	Admin
745	DELETE	Fare	286	Deleted Balimbing - 2 Ahon → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:15.512802	Admin
746	DELETE	Fare	287	Deleted Balimbing - 2 Ahon → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.517989	Admin
747	DELETE	Fare	288	Deleted Balimbing - 2 Ahon → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.523509	Admin
748	DELETE	Fare	289	Deleted Balimbing - 2 Ahon → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:15.5282	Admin
749	DELETE	Fare	290	Deleted Balimbing - 2 Ahon → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:15.53309	Admin
750	DELETE	Fare	291	Deleted Balimbing - 2 Ahon → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:15.538031	Admin
751	DELETE	Fare	236	Deleted Balinacon → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:15.544359	Admin
752	DELETE	Fare	237	Deleted Balinacon → Sinipian	Admin	2026-04-01 13:01:15.549338	Admin
753	DELETE	Fare	238	Deleted Balinacon → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:15.553826	Admin
754	DELETE	Fare	239	Deleted Balinacon → Malinao	Admin	2026-04-01 13:01:15.559206	Admin
755	DELETE	Fare	240	Deleted Balinacon → Upland LMES (School)	Admin	2026-04-01 13:01:15.564184	Admin
756	DELETE	Fare	241	Deleted Balinacon → Sil. Lazaan	Admin	2026-04-01 13:01:15.568907	Admin
757	DELETE	Fare	242	Deleted Balinacon → Kan. Lazaan	Admin	2026-04-01 13:01:15.574302	Admin
758	DELETE	Fare	243	Deleted Balinacon → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.579394	Admin
759	DELETE	Fare	244	Deleted Balinacon → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:15.584176	Admin
760	DELETE	Fare	245	Deleted Balinacon → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.590977	Admin
761	DELETE	Fare	246	Deleted Balinacon → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.598092	Admin
762	DELETE	Fare	247	Deleted Balinacon → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:15.605488	Admin
763	DELETE	Fare	248	Deleted Balinacon → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:15.612249	Admin
764	DELETE	Fare	249	Deleted Balinacon → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:15.619266	Admin
765	DELETE	Fare	334	Deleted Kan. Lazaan → Balinacon	Admin	2026-04-01 13:01:15.627935	Admin
766	DELETE	Fare	335	Deleted Kan. Lazaan → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:15.634806	Admin
767	DELETE	Fare	336	Deleted Kan. Lazaan → Sinipian	Admin	2026-04-01 13:01:15.641972	Admin
768	DELETE	Fare	337	Deleted Kan. Lazaan → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:15.648711	Admin
769	DELETE	Fare	338	Deleted Kan. Lazaan → Malinao	Admin	2026-04-01 13:01:15.656949	Admin
770	DELETE	Fare	339	Deleted Kan. Lazaan → Upland LMES (School)	Admin	2026-04-01 13:01:15.663041	Admin
771	DELETE	Fare	340	Deleted Kan. Lazaan → Sil. Lazaan	Admin	2026-04-01 13:01:15.668722	Admin
772	DELETE	Fare	341	Deleted Kan. Lazaan → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.676126	Admin
773	DELETE	Fare	342	Deleted Kan. Lazaan → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:15.681404	Admin
774	DELETE	Fare	343	Deleted Kan. Lazaan → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.687182	Admin
775	DELETE	Fare	344	Deleted Kan. Lazaan → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.695109	Admin
776	DELETE	Fare	345	Deleted Kan. Lazaan → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:15.702218	Admin
777	DELETE	Fare	346	Deleted Kan. Lazaan → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:15.708467	Admin
778	DELETE	Fare	347	Deleted Kan. Lazaan → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:15.713854	Admin
779	DELETE	Fare	362	Deleted Kan. Lazaan (Barod) → Balinacon	Admin	2026-04-01 13:01:15.719253	Admin
780	DELETE	Fare	363	Deleted Kan. Lazaan (Barod) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:15.725309	Admin
781	DELETE	Fare	364	Deleted Kan. Lazaan (Barod) → Sinipian	Admin	2026-04-01 13:01:15.73114	Admin
782	DELETE	Fare	365	Deleted Kan. Lazaan (Barod) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:15.736313	Admin
783	DELETE	Fare	366	Deleted Kan. Lazaan (Barod) → Malinao	Admin	2026-04-01 13:01:15.742126	Admin
784	DELETE	Fare	367	Deleted Kan. Lazaan (Barod) → Upland LMES (School)	Admin	2026-04-01 13:01:15.747645	Admin
785	DELETE	Fare	368	Deleted Kan. Lazaan (Barod) → Sil. Lazaan	Admin	2026-04-01 13:01:15.752917	Admin
786	DELETE	Fare	369	Deleted Kan. Lazaan (Barod) → Kan. Lazaan	Admin	2026-04-01 13:01:15.758466	Admin
787	DELETE	Fare	370	Deleted Kan. Lazaan (Barod) → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.763824	Admin
788	DELETE	Fare	371	Deleted Kan. Lazaan (Barod) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.769083	Admin
789	DELETE	Fare	372	Deleted Kan. Lazaan (Barod) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.774857	Admin
790	DELETE	Fare	373	Deleted Kan. Lazaan (Barod) → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:15.780522	Admin
791	DELETE	Fare	374	Deleted Kan. Lazaan (Barod) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:15.785425	Admin
792	DELETE	Fare	375	Deleted Kan. Lazaan (Barod) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:15.790699	Admin
793	DELETE	Fare	390	Deleted Kan. Lazaan (Ilaya) → Balinacon	Admin	2026-04-01 13:01:15.796458	Admin
794	DELETE	Fare	391	Deleted Kan. Lazaan (Ilaya) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:15.801782	Admin
795	DELETE	Fare	392	Deleted Kan. Lazaan (Ilaya) → Sinipian	Admin	2026-04-01 13:01:15.807414	Admin
796	DELETE	Fare	393	Deleted Kan. Lazaan (Ilaya) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:15.813366	Admin
797	DELETE	Fare	394	Deleted Kan. Lazaan (Ilaya) → Malinao	Admin	2026-04-01 13:01:15.818946	Admin
798	DELETE	Fare	395	Deleted Kan. Lazaan (Ilaya) → Upland LMES (School)	Admin	2026-04-01 13:01:15.825023	Admin
799	DELETE	Fare	396	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan	Admin	2026-04-01 13:01:15.830411	Admin
800	DELETE	Fare	397	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan	Admin	2026-04-01 13:01:15.835771	Admin
801	DELETE	Fare	398	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.841852	Admin
802	DELETE	Fare	399	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:15.848147	Admin
803	DELETE	Fare	400	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.853301	Admin
804	DELETE	Fare	401	Deleted Kan. Lazaan (Ilaya) → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:15.858956	Admin
805	DELETE	Fare	402	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:15.864112	Admin
806	DELETE	Fare	403	Deleted Kan. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:15.869061	Admin
807	DELETE	Fare	418	Deleted Kan. Lazaan (Siriaco) → Balinacon	Admin	2026-04-01 13:01:15.874249	Admin
808	DELETE	Fare	419	Deleted Kan. Lazaan (Siriaco) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:15.879625	Admin
809	DELETE	Fare	420	Deleted Kan. Lazaan (Siriaco) → Sinipian	Admin	2026-04-01 13:01:15.885009	Admin
810	DELETE	Fare	421	Deleted Kan. Lazaan (Siriaco) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:15.890383	Admin
811	DELETE	Fare	422	Deleted Kan. Lazaan (Siriaco) → Malinao	Admin	2026-04-01 13:01:15.895639	Admin
812	DELETE	Fare	423	Deleted Kan. Lazaan (Siriaco) → Upland LMES (School)	Admin	2026-04-01 13:01:15.900492	Admin
813	DELETE	Fare	424	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan	Admin	2026-04-01 13:01:15.906246	Admin
814	DELETE	Fare	425	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan	Admin	2026-04-01 13:01:15.91187	Admin
815	DELETE	Fare	426	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.917217	Admin
816	DELETE	Fare	427	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:15.922734	Admin
817	DELETE	Fare	428	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.928113	Admin
818	DELETE	Fare	429	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:15.933288	Admin
819	DELETE	Fare	430	Deleted Kan. Lazaan (Siriaco) → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:15.938739	Admin
820	DELETE	Fare	431	Deleted Kan. Lazaan (Siriaco) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:15.944228	Admin
821	DELETE	Fare	432	Deleted Kan. Lazaan (St. Bartolome) → Balinacon	Admin	2026-04-01 13:01:15.9496	Admin
822	DELETE	Fare	433	Deleted Kan. Lazaan (St. Bartolome) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:15.954732	Admin
823	DELETE	Fare	434	Deleted Kan. Lazaan (St. Bartolome) → Sinipian	Admin	2026-04-01 13:01:15.960516	Admin
824	DELETE	Fare	435	Deleted Kan. Lazaan (St. Bartolome) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:15.966119	Admin
825	DELETE	Fare	436	Deleted Kan. Lazaan (St. Bartolome) → Malinao	Admin	2026-04-01 13:01:15.971043	Admin
826	DELETE	Fare	437	Deleted Kan. Lazaan (St. Bartolome) → Upland LMES (School)	Admin	2026-04-01 13:01:15.976486	Admin
827	DELETE	Fare	438	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan	Admin	2026-04-01 13:01:15.981882	Admin
828	DELETE	Fare	439	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan	Admin	2026-04-01 13:01:15.986994	Admin
829	DELETE	Fare	440	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:15.992794	Admin
830	DELETE	Fare	441	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:15.998411	Admin
831	DELETE	Fare	442	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.003319	Admin
832	DELETE	Fare	443	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.009004	Admin
833	DELETE	Fare	444	Deleted Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:16.014774	Admin
834	DELETE	Fare	445	Deleted Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.01994	Admin
835	DELETE	Fare	292	Deleted Malinao → Balinacon	Admin	2026-04-01 13:01:16.025146	Admin
836	DELETE	Fare	293	Deleted Malinao → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:16.03085	Admin
837	DELETE	Fare	294	Deleted Malinao → Sinipian	Admin	2026-04-01 13:01:16.036149	Admin
838	DELETE	Fare	295	Deleted Malinao → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:16.042162	Admin
839	DELETE	Fare	296	Deleted Malinao → Upland LMES (School)	Admin	2026-04-01 13:01:16.047462	Admin
840	DELETE	Fare	297	Deleted Malinao → Sil. Lazaan	Admin	2026-04-01 13:01:16.052675	Admin
841	DELETE	Fare	298	Deleted Malinao → Kan. Lazaan	Admin	2026-04-01 13:01:16.058565	Admin
842	DELETE	Fare	299	Deleted Malinao → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:16.0641	Admin
843	DELETE	Fare	300	Deleted Malinao → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:16.069017	Admin
844	DELETE	Fare	301	Deleted Malinao → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.076964	Admin
845	DELETE	Fare	302	Deleted Malinao → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.084813	Admin
846	DELETE	Fare	303	Deleted Malinao → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:16.090579	Admin
847	DELETE	Fare	304	Deleted Malinao → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.095403	Admin
848	DELETE	Fare	305	Deleted Malinao → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:16.100331	Admin
849	DELETE	Fare	320	Deleted Sil. Lazaan → Balinacon	Admin	2026-04-01 13:01:16.105064	Admin
850	DELETE	Fare	321	Deleted Sil. Lazaan → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:16.111029	Admin
851	DELETE	Fare	322	Deleted Sil. Lazaan → Sinipian	Admin	2026-04-01 13:01:16.115823	Admin
852	DELETE	Fare	323	Deleted Sil. Lazaan → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:16.120183	Admin
853	DELETE	Fare	324	Deleted Sil. Lazaan → Malinao	Admin	2026-04-01 13:01:16.125651	Admin
854	DELETE	Fare	325	Deleted Sil. Lazaan → Upland LMES (School)	Admin	2026-04-01 13:01:16.130917	Admin
855	DELETE	Fare	326	Deleted Sil. Lazaan → Kan. Lazaan	Admin	2026-04-01 13:01:16.135818	Admin
856	DELETE	Fare	327	Deleted Sil. Lazaan → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:16.140947	Admin
857	DELETE	Fare	328	Deleted Sil. Lazaan → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:16.1456	Admin
858	DELETE	Fare	329	Deleted Sil. Lazaan → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.150308	Admin
859	DELETE	Fare	330	Deleted Sil. Lazaan → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.154824	Admin
860	DELETE	Fare	331	Deleted Sil. Lazaan → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:16.160063	Admin
861	DELETE	Fare	332	Deleted Sil. Lazaan → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.164717	Admin
862	DELETE	Fare	333	Deleted Sil. Lazaan → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:16.169991	Admin
863	DELETE	Fare	404	Deleted Sil. Lazaan (Dulo) → Balinacon	Admin	2026-04-01 13:01:16.175959	Admin
864	DELETE	Fare	405	Deleted Sil. Lazaan (Dulo) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:16.180852	Admin
865	DELETE	Fare	406	Deleted Sil. Lazaan (Dulo) → Sinipian	Admin	2026-04-01 13:01:16.185665	Admin
866	DELETE	Fare	407	Deleted Sil. Lazaan (Dulo) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:16.191046	Admin
867	DELETE	Fare	408	Deleted Sil. Lazaan (Dulo) → Malinao	Admin	2026-04-01 13:01:16.195899	Admin
868	DELETE	Fare	409	Deleted Sil. Lazaan (Dulo) → Upland LMES (School)	Admin	2026-04-01 13:01:16.201048	Admin
869	DELETE	Fare	410	Deleted Sil. Lazaan (Dulo) → Sil. Lazaan	Admin	2026-04-01 13:01:16.206575	Admin
870	DELETE	Fare	411	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan	Admin	2026-04-01 13:01:16.211711	Admin
871	DELETE	Fare	412	Deleted Sil. Lazaan (Dulo) → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:16.216824	Admin
872	DELETE	Fare	413	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:16.221788	Admin
873	DELETE	Fare	414	Deleted Sil. Lazaan (Dulo) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.227022	Admin
874	DELETE	Fare	415	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.231628	Admin
875	DELETE	Fare	416	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.236387	Admin
876	DELETE	Fare	417	Deleted Sil. Lazaan (Dulo) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:16.241713	Admin
877	DELETE	Fare	376	Deleted Sil. Lazaan (Ilaya) → Balinacon	Admin	2026-04-01 13:01:16.24707	Admin
878	DELETE	Fare	377	Deleted Sil. Lazaan (Ilaya) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:16.251945	Admin
879	DELETE	Fare	378	Deleted Sil. Lazaan (Ilaya) → Sinipian	Admin	2026-04-01 13:01:16.256973	Admin
880	DELETE	Fare	379	Deleted Sil. Lazaan (Ilaya) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:16.262184	Admin
881	DELETE	Fare	380	Deleted Sil. Lazaan (Ilaya) → Malinao	Admin	2026-04-01 13:01:16.267216	Admin
882	DELETE	Fare	381	Deleted Sil. Lazaan (Ilaya) → Upland LMES (School)	Admin	2026-04-01 13:01:16.272256	Admin
883	DELETE	Fare	382	Deleted Sil. Lazaan (Ilaya) → Sil. Lazaan	Admin	2026-04-01 13:01:16.27758	Admin
884	DELETE	Fare	383	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan	Admin	2026-04-01 13:01:16.282538	Admin
885	DELETE	Fare	384	Deleted Sil. Lazaan (Ilaya) → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:16.289719	Admin
886	DELETE	Fare	385	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:16.294858	Admin
887	DELETE	Fare	386	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.299677	Admin
888	DELETE	Fare	387	Deleted Sil. Lazaan (Ilaya) → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:16.305217	Admin
889	DELETE	Fare	388	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.311067	Admin
890	DELETE	Fare	389	Deleted Sil. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:16.316034	Admin
891	DELETE	Fare	348	Deleted Sil. Lazaan (Tower) → Balinacon	Admin	2026-04-01 13:01:16.320525	Admin
892	DELETE	Fare	349	Deleted Sil. Lazaan (Tower) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:16.325993	Admin
893	DELETE	Fare	350	Deleted Sil. Lazaan (Tower) → Sinipian	Admin	2026-04-01 13:01:16.330933	Admin
894	DELETE	Fare	351	Deleted Sil. Lazaan (Tower) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:16.336466	Admin
895	DELETE	Fare	352	Deleted Sil. Lazaan (Tower) → Malinao	Admin	2026-04-01 13:01:16.341801	Admin
896	DELETE	Fare	353	Deleted Sil. Lazaan (Tower) → Upland LMES (School)	Admin	2026-04-01 13:01:16.346988	Admin
897	DELETE	Fare	354	Deleted Sil. Lazaan (Tower) → Sil. Lazaan	Admin	2026-04-01 13:01:16.352297	Admin
898	DELETE	Fare	355	Deleted Sil. Lazaan (Tower) → Kan. Lazaan	Admin	2026-04-01 13:01:16.357938	Admin
899	DELETE	Fare	356	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:16.362993	Admin
900	DELETE	Fare	357	Deleted Sil. Lazaan (Tower) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.367725	Admin
901	DELETE	Fare	358	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.372965	Admin
902	DELETE	Fare	359	Deleted Sil. Lazaan (Tower) → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:16.378475	Admin
903	DELETE	Fare	360	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.383296	Admin
904	DELETE	Fare	361	Deleted Sil. Lazaan (Tower) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:16.388436	Admin
905	DELETE	Fare	264	Deleted Sinipian → Balinacon	Admin	2026-04-01 13:01:16.393949	Admin
906	DELETE	Fare	265	Deleted Sinipian → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:16.398829	Admin
907	DELETE	Fare	266	Deleted Sinipian → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:16.403329	Admin
908	DELETE	Fare	267	Deleted Sinipian → Malinao	Admin	2026-04-01 13:01:16.40887	Admin
909	DELETE	Fare	268	Deleted Sinipian → Upland LMES (School)	Admin	2026-04-01 13:01:16.414239	Admin
910	DELETE	Fare	269	Deleted Sinipian → Sil. Lazaan	Admin	2026-04-01 13:01:16.419042	Admin
911	DELETE	Fare	270	Deleted Sinipian → Kan. Lazaan	Admin	2026-04-01 13:01:16.424295	Admin
912	DELETE	Fare	271	Deleted Sinipian → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:16.429771	Admin
913	DELETE	Fare	272	Deleted Sinipian → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:16.434235	Admin
914	DELETE	Fare	273	Deleted Sinipian → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.439259	Admin
915	DELETE	Fare	274	Deleted Sinipian → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.444618	Admin
916	DELETE	Fare	275	Deleted Sinipian → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:16.449349	Admin
917	DELETE	Fare	276	Deleted Sinipian → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.45399	Admin
918	DELETE	Fare	277	Deleted Sinipian → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:16.461108	Admin
919	DELETE	Fare	306	Deleted Upland LMES (School) → Balinacon	Admin	2026-04-01 13:01:16.467895	Admin
920	DELETE	Fare	307	Deleted Upland LMES (School) → Balimbing - 1 Ahon	Admin	2026-04-01 13:01:16.473658	Admin
921	DELETE	Fare	308	Deleted Upland LMES (School) → Sinipian	Admin	2026-04-01 13:01:16.479029	Admin
922	DELETE	Fare	309	Deleted Upland LMES (School) → Balimbing - 2 Ahon	Admin	2026-04-01 13:01:16.483813	Admin
923	DELETE	Fare	310	Deleted Upland LMES (School) → Malinao	Admin	2026-04-01 13:01:16.488392	Admin
924	DELETE	Fare	311	Deleted Upland LMES (School) → Sil. Lazaan	Admin	2026-04-01 13:01:16.494905	Admin
925	DELETE	Fare	312	Deleted Upland LMES (School) → Kan. Lazaan	Admin	2026-04-01 13:01:16.500027	Admin
926	DELETE	Fare	313	Deleted Upland LMES (School) → Sil. Lazaan (Tower)	Admin	2026-04-01 13:01:16.504568	Admin
927	DELETE	Fare	314	Deleted Upland LMES (School) → Kan. Lazaan (Barod)	Admin	2026-04-01 13:01:16.510166	Admin
928	DELETE	Fare	315	Deleted Upland LMES (School) → Sil. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.515184	Admin
929	DELETE	Fare	316	Deleted Upland LMES (School) → Kan. Lazaan (Ilaya)	Admin	2026-04-01 13:01:16.52035	Admin
930	DELETE	Fare	317	Deleted Upland LMES (School) → Sil. Lazaan (Dulo)	Admin	2026-04-01 13:01:16.526369	Admin
931	DELETE	Fare	318	Deleted Upland LMES (School) → Kan. Lazaan (Siriaco)	Admin	2026-04-01 13:01:16.531256	Admin
932	DELETE	Fare	319	Deleted Upland LMES (School) → Kan. Lazaan (St. Bartolome)	Admin	2026-04-01 13:01:16.53805	Admin
933	CREATE	Fare	446	Balinacon → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 13:01:40.279672	Admin
934	CREATE	Fare	447	Balinacon → Sinipian base ₱20.00	Admin	2026-04-01 13:01:40.299098	Admin
935	CREATE	Fare	448	Balinacon → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 13:01:40.303029	Admin
936	CREATE	Fare	449	Balinacon → Malinao base ₱25.00	Admin	2026-04-01 13:01:40.307255	Admin
937	CREATE	Fare	450	Balinacon → Upland LMES (School) base ₱30.00	Admin	2026-04-01 13:01:40.311976	Admin
938	CREATE	Fare	451	Balinacon → Sil. Lazaan base ₱35.00	Admin	2026-04-01 13:01:40.315937	Admin
1257	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 16:55:10.798803	Admin
939	CREATE	Fare	452	Balinacon → Kan. Lazaan base ₱40.00	Admin	2026-04-01 13:01:40.319775	Admin
940	CREATE	Fare	453	Balinacon → Sil. Lazaan (Tower) base ₱45.00	Admin	2026-04-01 13:01:40.324005	Admin
941	CREATE	Fare	454	Balinacon → Kan. Lazaan (Barod) base ₱55.00	Admin	2026-04-01 13:01:40.329134	Admin
942	CREATE	Fare	455	Balinacon → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 13:01:40.332883	Admin
943	CREATE	Fare	456	Balinacon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 13:01:40.336447	Admin
944	CREATE	Fare	457	Balinacon → Sil. Lazaan (Dulo) base ₱60.00	Admin	2026-04-01 13:01:40.34122	Admin
945	CREATE	Fare	458	Balinacon → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 13:01:40.345486	Admin
946	CREATE	Fare	459	Balinacon → Kan. Lazaan (St. Bartolome) base ₱70.00	Admin	2026-04-01 13:01:40.349593	Admin
947	CREATE	Fare	460	Balimbing - 1 Ahon → Balinacon base ₱20.00	Admin	2026-04-01 13:01:40.353467	Admin
948	CREATE	Fare	461	Balimbing - 1 Ahon → Sinipian base ₱20.00	Admin	2026-04-01 13:01:40.35775	Admin
949	CREATE	Fare	462	Balimbing - 1 Ahon → Balimbing - 2 Ahon base ₱20.00	Admin	2026-04-01 13:01:40.36188	Admin
950	CREATE	Fare	463	Balimbing - 1 Ahon → Malinao base ₱20.00	Admin	2026-04-01 13:01:40.365684	Admin
951	CREATE	Fare	464	Balimbing - 1 Ahon → Upland LMES (School) base ₱25.00	Admin	2026-04-01 13:01:40.369235	Admin
952	CREATE	Fare	465	Balimbing - 1 Ahon → Sil. Lazaan base ₱30.00	Admin	2026-04-01 13:01:40.372785	Admin
953	CREATE	Fare	466	Balimbing - 1 Ahon → Kan. Lazaan base ₱35.00	Admin	2026-04-01 13:01:40.379103	Admin
954	CREATE	Fare	467	Balimbing - 1 Ahon → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 13:01:40.38327	Admin
955	CREATE	Fare	468	Balimbing - 1 Ahon → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 13:01:40.387223	Admin
956	CREATE	Fare	469	Balimbing - 1 Ahon → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 13:01:40.391372	Admin
957	CREATE	Fare	470	Balimbing - 1 Ahon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 13:01:40.395679	Admin
958	CREATE	Fare	471	Balimbing - 1 Ahon → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 13:01:40.399468	Admin
959	CREATE	Fare	472	Balimbing - 1 Ahon → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 13:01:40.403275	Admin
960	CREATE	Fare	473	Balimbing - 1 Ahon → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 13:01:40.407279	Admin
961	CREATE	Fare	474	Sinipian → Balinacon base ₱20.00	Admin	2026-04-01 13:01:40.411548	Admin
962	CREATE	Fare	475	Sinipian → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 13:01:40.415465	Admin
963	CREATE	Fare	476	Sinipian → Balimbing - 2 Ahon base ₱20.00	Admin	2026-04-01 13:01:40.419363	Admin
964	CREATE	Fare	477	Sinipian → Malinao base ₱20.00	Admin	2026-04-01 13:01:40.422983	Admin
965	CREATE	Fare	478	Sinipian → Upland LMES (School) base ₱25.00	Admin	2026-04-01 13:01:40.427717	Admin
966	CREATE	Fare	479	Sinipian → Sil. Lazaan base ₱30.00	Admin	2026-04-01 13:01:40.432261	Admin
967	CREATE	Fare	480	Sinipian → Kan. Lazaan base ₱35.00	Admin	2026-04-01 13:01:40.437024	Admin
968	CREATE	Fare	481	Sinipian → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 13:01:40.442242	Admin
969	CREATE	Fare	482	Sinipian → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 13:01:40.446637	Admin
970	CREATE	Fare	483	Sinipian → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 13:01:40.450706	Admin
971	CREATE	Fare	484	Sinipian → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 13:01:40.454322	Admin
972	CREATE	Fare	485	Sinipian → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 13:01:40.458345	Admin
973	CREATE	Fare	486	Sinipian → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 13:01:40.46241	Admin
974	CREATE	Fare	487	Sinipian → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 13:01:40.46594	Admin
975	CREATE	Fare	488	Balimbing - 2 Ahon → Balinacon base ₱20.00	Admin	2026-04-01 13:01:40.46998	Admin
976	CREATE	Fare	489	Balimbing - 2 Ahon → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 13:01:40.47395	Admin
977	CREATE	Fare	490	Balimbing - 2 Ahon → Sinipian base ₱20.00	Admin	2026-04-01 13:01:40.478051	Admin
978	CREATE	Fare	491	Balimbing - 2 Ahon → Malinao base ₱20.00	Admin	2026-04-01 13:01:40.482054	Admin
979	CREATE	Fare	492	Balimbing - 2 Ahon → Upland LMES (School) base ₱25.00	Admin	2026-04-01 13:01:40.485847	Admin
980	CREATE	Fare	493	Balimbing - 2 Ahon → Sil. Lazaan base ₱30.00	Admin	2026-04-01 13:01:40.4897	Admin
981	CREATE	Fare	494	Balimbing - 2 Ahon → Kan. Lazaan base ₱35.00	Admin	2026-04-01 13:01:40.493521	Admin
982	CREATE	Fare	495	Balimbing - 2 Ahon → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 13:01:40.497602	Admin
983	CREATE	Fare	496	Balimbing - 2 Ahon → Kan. Lazaan (Barod) base ₱50.00	Admin	2026-04-01 13:01:40.501667	Admin
984	CREATE	Fare	497	Balimbing - 2 Ahon → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 13:01:40.505536	Admin
985	CREATE	Fare	498	Balimbing - 2 Ahon → Kan. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 13:01:40.509532	Admin
986	CREATE	Fare	499	Balimbing - 2 Ahon → Sil. Lazaan (Dulo) base ₱55.00	Admin	2026-04-01 13:01:40.513602	Admin
987	CREATE	Fare	500	Balimbing - 2 Ahon → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 13:01:40.517408	Admin
988	CREATE	Fare	501	Balimbing - 2 Ahon → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 13:01:40.520956	Admin
989	CREATE	Fare	502	Malinao → Balinacon base ₱20.00	Admin	2026-04-01 13:01:40.524807	Admin
990	CREATE	Fare	503	Malinao → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 13:01:40.529146	Admin
991	CREATE	Fare	504	Malinao → Sinipian base ₱20.00	Admin	2026-04-01 13:01:40.53287	Admin
992	CREATE	Fare	505	Malinao → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 13:01:40.536363	Admin
993	CREATE	Fare	506	Malinao → Upland LMES (School) base ₱20.00	Admin	2026-04-01 13:01:40.540149	Admin
994	CREATE	Fare	507	Malinao → Sil. Lazaan base ₱25.00	Admin	2026-04-01 13:01:40.543999	Admin
995	CREATE	Fare	508	Malinao → Kan. Lazaan base ₱30.00	Admin	2026-04-01 13:01:40.547971	Admin
996	CREATE	Fare	509	Malinao → Sil. Lazaan (Tower) base ₱35.00	Admin	2026-04-01 13:01:40.552334	Admin
997	CREATE	Fare	510	Malinao → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 13:01:40.555944	Admin
998	CREATE	Fare	511	Malinao → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 13:01:40.559876	Admin
999	CREATE	Fare	512	Malinao → Kan. Lazaan (Ilaya) base ₱45.00	Admin	2026-04-01 13:01:40.563485	Admin
1000	CREATE	Fare	513	Malinao → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 13:01:40.567007	Admin
1001	CREATE	Fare	514	Malinao → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 13:01:40.570509	Admin
1002	CREATE	Fare	515	Malinao → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 13:01:40.574495	Admin
1003	CREATE	Fare	516	Upland LMES (School) → Balinacon base ₱25.00	Admin	2026-04-01 13:01:40.578595	Admin
1004	CREATE	Fare	517	Upland LMES (School) → Balimbing - 1 Ahon base ₱20.00	Admin	2026-04-01 13:01:40.582658	Admin
1005	CREATE	Fare	518	Upland LMES (School) → Sinipian base ₱20.00	Admin	2026-04-01 13:01:40.586523	Admin
1006	CREATE	Fare	519	Upland LMES (School) → Balimbing - 2 Ahon base ₱25.00	Admin	2026-04-01 13:01:40.590749	Admin
1007	CREATE	Fare	520	Upland LMES (School) → Malinao base ₱20.00	Admin	2026-04-01 13:01:40.594577	Admin
1008	CREATE	Fare	521	Upland LMES (School) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 13:01:40.598304	Admin
1009	CREATE	Fare	522	Upland LMES (School) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 13:01:40.602524	Admin
1010	CREATE	Fare	523	Upland LMES (School) → Sil. Lazaan (Tower) base ₱30.00	Admin	2026-04-01 13:01:40.606442	Admin
1011	CREATE	Fare	524	Upland LMES (School) → Kan. Lazaan (Barod) base ₱35.00	Admin	2026-04-01 13:01:40.611202	Admin
1012	CREATE	Fare	525	Upland LMES (School) → Sil. Lazaan (Ilaya) base ₱35.00	Admin	2026-04-01 13:01:40.614825	Admin
1013	CREATE	Fare	526	Upland LMES (School) → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 13:01:40.618592	Admin
1014	CREATE	Fare	527	Upland LMES (School) → Sil. Lazaan (Dulo) base ₱45.00	Admin	2026-04-01 13:01:40.622317	Admin
1015	CREATE	Fare	528	Upland LMES (School) → Kan. Lazaan (Siriaco) base ₱45.00	Admin	2026-04-01 13:01:40.626307	Admin
1016	CREATE	Fare	529	Upland LMES (School) → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 13:01:40.6302	Admin
1017	CREATE	Fare	530	Sil. Lazaan → Balinacon base ₱30.00	Admin	2026-04-01 13:01:40.633464	Admin
1018	CREATE	Fare	531	Sil. Lazaan → Balimbing - 1 Ahon base ₱25.00	Admin	2026-04-01 13:01:40.636844	Admin
1019	CREATE	Fare	532	Sil. Lazaan → Sinipian base ₱25.00	Admin	2026-04-01 13:01:40.64054	Admin
1020	CREATE	Fare	533	Sil. Lazaan → Balimbing - 2 Ahon base ₱30.00	Admin	2026-04-01 13:01:40.644274	Admin
1021	CREATE	Fare	534	Sil. Lazaan → Malinao base ₱20.00	Admin	2026-04-01 13:01:40.648031	Admin
1022	CREATE	Fare	535	Sil. Lazaan → Upland LMES (School) base ₱20.00	Admin	2026-04-01 13:01:40.651448	Admin
1023	CREATE	Fare	536	Sil. Lazaan → Kan. Lazaan base ₱30.00	Admin	2026-04-01 13:01:40.654759	Admin
1024	CREATE	Fare	537	Sil. Lazaan → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 13:01:40.658692	Admin
1025	CREATE	Fare	538	Sil. Lazaan → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 13:01:40.662546	Admin
1026	CREATE	Fare	539	Sil. Lazaan → Sil. Lazaan (Ilaya) base ₱35.00	Admin	2026-04-01 13:01:40.665831	Admin
1027	CREATE	Fare	540	Sil. Lazaan → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 13:01:40.669538	Admin
1028	CREATE	Fare	541	Sil. Lazaan → Sil. Lazaan (Dulo) base ₱40.00	Admin	2026-04-01 13:01:40.67311	Admin
1029	CREATE	Fare	542	Sil. Lazaan → Kan. Lazaan (Siriaco) base ₱45.00	Admin	2026-04-01 13:01:40.676838	Admin
1030	CREATE	Fare	543	Sil. Lazaan → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 13:01:40.680637	Admin
1031	CREATE	Fare	544	Kan. Lazaan → Balinacon base ₱30.00	Admin	2026-04-01 13:01:40.684161	Admin
1032	CREATE	Fare	545	Kan. Lazaan → Balimbing - 1 Ahon base ₱25.00	Admin	2026-04-01 13:01:40.687757	Admin
1033	CREATE	Fare	546	Kan. Lazaan → Sinipian base ₱25.00	Admin	2026-04-01 13:01:40.691533	Admin
1034	CREATE	Fare	547	Kan. Lazaan → Balimbing - 2 Ahon base ₱30.00	Admin	2026-04-01 13:01:40.695345	Admin
1035	CREATE	Fare	548	Kan. Lazaan → Malinao base ₱25.00	Admin	2026-04-01 13:01:40.698753	Admin
1036	CREATE	Fare	549	Kan. Lazaan → Upland LMES (School) base ₱20.00	Admin	2026-04-01 13:01:40.70229	Admin
1037	CREATE	Fare	550	Kan. Lazaan → Sil. Lazaan base ₱30.00	Admin	2026-04-01 13:01:40.705737	Admin
1038	CREATE	Fare	551	Kan. Lazaan → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 13:01:40.709473	Admin
1039	CREATE	Fare	552	Kan. Lazaan → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 13:01:40.712927	Admin
1040	CREATE	Fare	553	Kan. Lazaan → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 13:01:40.716634	Admin
1041	CREATE	Fare	554	Kan. Lazaan → Kan. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 13:01:40.720397	Admin
1042	CREATE	Fare	555	Kan. Lazaan → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 13:01:40.724505	Admin
1043	CREATE	Fare	556	Kan. Lazaan → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 13:01:40.728438	Admin
1044	CREATE	Fare	557	Kan. Lazaan → Kan. Lazaan (St. Bartolome) base ₱50.00	Admin	2026-04-01 13:01:40.731926	Admin
1045	CREATE	Fare	558	Sil. Lazaan (Tower) → Balinacon base ₱35.00	Admin	2026-04-01 13:01:40.73555	Admin
1046	CREATE	Fare	559	Sil. Lazaan (Tower) → Balimbing - 1 Ahon base ₱30.00	Admin	2026-04-01 13:01:40.739274	Admin
1047	CREATE	Fare	560	Sil. Lazaan (Tower) → Sinipian base ₱30.00	Admin	2026-04-01 13:01:40.743341	Admin
1048	CREATE	Fare	561	Sil. Lazaan (Tower) → Balimbing - 2 Ahon base ₱35.00	Admin	2026-04-01 13:01:40.746946	Admin
1049	CREATE	Fare	562	Sil. Lazaan (Tower) → Malinao base ₱25.00	Admin	2026-04-01 13:01:40.7505	Admin
1050	CREATE	Fare	563	Sil. Lazaan (Tower) → Upland LMES (School) base ₱20.00	Admin	2026-04-01 13:01:40.753736	Admin
1051	CREATE	Fare	564	Sil. Lazaan (Tower) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 13:01:40.757609	Admin
1052	CREATE	Fare	565	Sil. Lazaan (Tower) → Kan. Lazaan base ₱40.00	Admin	2026-04-01 13:01:40.761392	Admin
1053	CREATE	Fare	566	Sil. Lazaan (Tower) → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 13:01:40.764837	Admin
1054	CREATE	Fare	567	Sil. Lazaan (Tower) → Sil. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 13:01:40.768455	Admin
1055	CREATE	Fare	568	Sil. Lazaan (Tower) → Kan. Lazaan (Ilaya) base ₱45.00	Admin	2026-04-01 13:01:40.77183	Admin
1056	CREATE	Fare	569	Sil. Lazaan (Tower) → Sil. Lazaan (Dulo) base ₱30.00	Admin	2026-04-01 13:01:40.775546	Admin
1057	CREATE	Fare	570	Sil. Lazaan (Tower) → Kan. Lazaan (Siriaco) base ₱55.00	Admin	2026-04-01 13:01:40.77941	Admin
1058	CREATE	Fare	571	Sil. Lazaan (Tower) → Kan. Lazaan (St. Bartolome) base ₱60.00	Admin	2026-04-01 13:01:40.783007	Admin
1059	CREATE	Fare	572	Kan. Lazaan (Barod) → Balinacon base ₱40.00	Admin	2026-04-01 13:01:40.786529	Admin
1060	CREATE	Fare	573	Kan. Lazaan (Barod) → Balimbing - 1 Ahon base ₱30.00	Admin	2026-04-01 13:01:40.790817	Admin
1061	CREATE	Fare	574	Kan. Lazaan (Barod) → Sinipian base ₱30.00	Admin	2026-04-01 13:01:40.794786	Admin
1062	CREATE	Fare	575	Kan. Lazaan (Barod) → Balimbing - 2 Ahon base ₱35.00	Admin	2026-04-01 13:01:40.798609	Admin
1063	CREATE	Fare	576	Kan. Lazaan (Barod) → Malinao base ₱30.00	Admin	2026-04-01 13:01:40.801911	Admin
1064	CREATE	Fare	577	Kan. Lazaan (Barod) → Upland LMES (School) base ₱25.00	Admin	2026-04-01 13:01:40.805609	Admin
1065	CREATE	Fare	578	Kan. Lazaan (Barod) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 13:01:40.809438	Admin
1066	CREATE	Fare	579	Kan. Lazaan (Barod) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 13:01:40.812934	Admin
1067	CREATE	Fare	580	Kan. Lazaan (Barod) → Sil. Lazaan (Tower) base ₱40.00	Admin	2026-04-01 13:01:40.816511	Admin
1068	CREATE	Fare	581	Kan. Lazaan (Barod) → Sil. Lazaan (Ilaya) base ₱40.00	Admin	2026-04-01 13:01:40.820331	Admin
1069	CREATE	Fare	582	Kan. Lazaan (Barod) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 13:01:40.824235	Admin
1070	CREATE	Fare	583	Kan. Lazaan (Barod) → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 13:01:40.828136	Admin
1071	CREATE	Fare	584	Kan. Lazaan (Barod) → Kan. Lazaan (Siriaco) base ₱35.00	Admin	2026-04-01 13:01:40.831686	Admin
1072	CREATE	Fare	585	Kan. Lazaan (Barod) → Kan. Lazaan (St. Bartolome) base ₱45.00	Admin	2026-04-01 13:01:40.835315	Admin
1073	CREATE	Fare	586	Sil. Lazaan (Ilaya) → Balinacon base ₱40.00	Admin	2026-04-01 13:01:40.838746	Admin
1074	CREATE	Fare	587	Sil. Lazaan (Ilaya) → Balimbing - 1 Ahon base ₱35.00	Admin	2026-04-01 13:01:40.842728	Admin
1075	CREATE	Fare	588	Sil. Lazaan (Ilaya) → Sinipian base ₱35.00	Admin	2026-04-01 13:01:40.846655	Admin
1076	CREATE	Fare	589	Sil. Lazaan (Ilaya) → Balimbing - 2 Ahon base ₱40.00	Admin	2026-04-01 13:01:40.850279	Admin
1077	CREATE	Fare	590	Sil. Lazaan (Ilaya) → Malinao base ₱30.00	Admin	2026-04-01 13:01:40.853622	Admin
1078	CREATE	Fare	591	Sil. Lazaan (Ilaya) → Upland LMES (School) base ₱20.00	Admin	2026-04-01 13:01:40.857271	Admin
1079	CREATE	Fare	592	Sil. Lazaan (Ilaya) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 13:01:40.861766	Admin
1080	CREATE	Fare	593	Sil. Lazaan (Ilaya) → Kan. Lazaan base ₱30.00	Admin	2026-04-01 13:01:40.865333	Admin
1081	CREATE	Fare	594	Sil. Lazaan (Ilaya) → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 13:01:40.868716	Admin
1082	CREATE	Fare	595	Sil. Lazaan (Ilaya) → Kan. Lazaan (Barod) base ₱40.00	Admin	2026-04-01 13:01:40.872555	Admin
1083	CREATE	Fare	596	Sil. Lazaan (Ilaya) → Kan. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 13:01:40.876643	Admin
1084	CREATE	Fare	597	Sil. Lazaan (Ilaya) → Sil. Lazaan (Dulo) base ₱30.00	Admin	2026-04-01 13:01:40.880345	Admin
1085	CREATE	Fare	598	Sil. Lazaan (Ilaya) → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 13:01:40.883763	Admin
1086	CREATE	Fare	599	Sil. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome) base ₱65.00	Admin	2026-04-01 13:01:40.887799	Admin
1087	CREATE	Fare	600	Kan. Lazaan (Ilaya) → Balinacon base ₱40.00	Admin	2026-04-01 13:01:40.891525	Admin
1088	CREATE	Fare	601	Kan. Lazaan (Ilaya) → Balimbing - 1 Ahon base ₱35.00	Admin	2026-04-01 13:01:40.895058	Admin
1089	CREATE	Fare	602	Kan. Lazaan (Ilaya) → Sinipian base ₱35.00	Admin	2026-04-01 13:01:40.89852	Admin
1090	CREATE	Fare	603	Kan. Lazaan (Ilaya) → Balimbing - 2 Ahon base ₱40.00	Admin	2026-04-01 13:01:40.901958	Admin
1091	CREATE	Fare	604	Kan. Lazaan (Ilaya) → Malinao base ₱30.00	Admin	2026-04-01 13:01:40.90559	Admin
1092	CREATE	Fare	605	Kan. Lazaan (Ilaya) → Upland LMES (School) base ₱25.00	Admin	2026-04-01 13:01:40.909406	Admin
1093	CREATE	Fare	606	Kan. Lazaan (Ilaya) → Sil. Lazaan base ₱20.00	Admin	2026-04-01 13:01:40.913106	Admin
1094	CREATE	Fare	607	Kan. Lazaan (Ilaya) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 13:01:40.916415	Admin
1095	CREATE	Fare	608	Kan. Lazaan (Ilaya) → Sil. Lazaan (Tower) base ₱45.00	Admin	2026-04-01 13:01:40.920291	Admin
1096	CREATE	Fare	609	Kan. Lazaan (Ilaya) → Kan. Lazaan (Barod) base ₱20.00	Admin	2026-04-01 13:01:40.924191	Admin
1097	CREATE	Fare	610	Kan. Lazaan (Ilaya) → Sil. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 13:01:40.928038	Admin
1098	CREATE	Fare	611	Kan. Lazaan (Ilaya) → Sil. Lazaan (Dulo) base ₱50.00	Admin	2026-04-01 13:01:40.931847	Admin
1099	CREATE	Fare	612	Kan. Lazaan (Ilaya) → Kan. Lazaan (Siriaco) base ₱25.00	Admin	2026-04-01 13:01:40.935632	Admin
1100	CREATE	Fare	613	Kan. Lazaan (Ilaya) → Kan. Lazaan (St. Bartolome) base ₱30.00	Admin	2026-04-01 13:01:40.93908	Admin
1101	CREATE	Fare	614	Sil. Lazaan (Dulo) → Balinacon base ₱50.00	Admin	2026-04-01 13:01:40.942953	Admin
1102	CREATE	Fare	615	Sil. Lazaan (Dulo) → Balimbing - 1 Ahon base ₱45.00	Admin	2026-04-01 13:01:40.946543	Admin
1103	CREATE	Fare	616	Sil. Lazaan (Dulo) → Sinipian base ₱45.00	Admin	2026-04-01 13:01:40.950582	Admin
1104	CREATE	Fare	617	Sil. Lazaan (Dulo) → Balimbing - 2 Ahon base ₱45.00	Admin	2026-04-01 13:01:40.954922	Admin
1105	CREATE	Fare	618	Sil. Lazaan (Dulo) → Malinao base ₱40.00	Admin	2026-04-01 13:01:40.958791	Admin
1106	CREATE	Fare	619	Sil. Lazaan (Dulo) → Upland LMES (School) base ₱30.00	Admin	2026-04-01 13:01:40.962687	Admin
1107	CREATE	Fare	620	Sil. Lazaan (Dulo) → Sil. Lazaan base ₱25.00	Admin	2026-04-01 13:01:40.966335	Admin
1108	CREATE	Fare	621	Sil. Lazaan (Dulo) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 13:01:40.96983	Admin
1109	CREATE	Fare	622	Sil. Lazaan (Dulo) → Sil. Lazaan (Tower) base ₱20.00	Admin	2026-04-01 13:01:40.973634	Admin
1110	CREATE	Fare	623	Sil. Lazaan (Dulo) → Kan. Lazaan (Barod) base ₱55.00	Admin	2026-04-01 13:01:40.977449	Admin
1111	CREATE	Fare	624	Sil. Lazaan (Dulo) → Sil. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 13:01:40.980959	Admin
1112	CREATE	Fare	625	Sil. Lazaan (Dulo) → Kan. Lazaan (Ilaya) base ₱50.00	Admin	2026-04-01 13:01:40.984424	Admin
1113	CREATE	Fare	626	Sil. Lazaan (Dulo) → Kan. Lazaan (Siriaco) base ₱60.00	Admin	2026-04-01 13:01:40.988326	Admin
1114	CREATE	Fare	627	Sil. Lazaan (Dulo) → Kan. Lazaan (St. Bartolome) base ₱70.00	Admin	2026-04-01 13:01:40.992319	Admin
1115	CREATE	Fare	628	Kan. Lazaan (Siriaco) → Balinacon base ₱50.00	Admin	2026-04-01 13:01:40.996109	Admin
1116	CREATE	Fare	629	Kan. Lazaan (Siriaco) → Balimbing - 1 Ahon base ₱45.00	Admin	2026-04-01 13:01:40.99952	Admin
1117	CREATE	Fare	630	Kan. Lazaan (Siriaco) → Sinipian base ₱45.00	Admin	2026-04-01 13:01:41.002871	Admin
1118	CREATE	Fare	631	Kan. Lazaan (Siriaco) → Balimbing - 2 Ahon base ₱45.00	Admin	2026-04-01 13:01:41.007159	Admin
1119	CREATE	Fare	632	Kan. Lazaan (Siriaco) → Malinao base ₱40.00	Admin	2026-04-01 13:01:41.010952	Admin
1120	CREATE	Fare	633	Kan. Lazaan (Siriaco) → Upland LMES (School) base ₱30.00	Admin	2026-04-01 13:01:41.014768	Admin
1121	CREATE	Fare	634	Kan. Lazaan (Siriaco) → Sil. Lazaan base ₱25.00	Admin	2026-04-01 13:01:41.018906	Admin
1122	CREATE	Fare	635	Kan. Lazaan (Siriaco) → Kan. Lazaan base ₱25.00	Admin	2026-04-01 13:01:41.022674	Admin
1123	CREATE	Fare	636	Kan. Lazaan (Siriaco) → Sil. Lazaan (Tower) base ₱55.00	Admin	2026-04-01 13:01:41.026448	Admin
1124	CREATE	Fare	637	Kan. Lazaan (Siriaco) → Kan. Lazaan (Barod) base ₱20.00	Admin	2026-04-01 13:01:41.030338	Admin
1125	CREATE	Fare	638	Kan. Lazaan (Siriaco) → Sil. Lazaan (Ilaya) base ₱60.00	Admin	2026-04-01 13:01:41.033738	Admin
1126	CREATE	Fare	639	Kan. Lazaan (Siriaco) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 13:01:41.037344	Admin
1127	CREATE	Fare	640	Kan. Lazaan (Siriaco) → Sil. Lazaan (Dulo) base ₱60.00	Admin	2026-04-01 13:01:41.041318	Admin
1128	CREATE	Fare	641	Kan. Lazaan (Siriaco) → Kan. Lazaan (St. Bartolome) base ₱30.00	Admin	2026-04-01 13:01:41.044957	Admin
1129	CREATE	Fare	642	Kan. Lazaan (St. Bartolome) → Balinacon base ₱55.00	Admin	2026-04-01 13:01:41.048943	Admin
1130	CREATE	Fare	643	Kan. Lazaan (St. Bartolome) → Balimbing - 1 Ahon base ₱50.00	Admin	2026-04-01 13:01:41.052479	Admin
1131	CREATE	Fare	644	Kan. Lazaan (St. Bartolome) → Sinipian base ₱50.00	Admin	2026-04-01 13:01:41.055846	Admin
1132	CREATE	Fare	645	Kan. Lazaan (St. Bartolome) → Balimbing - 2 Ahon base ₱50.00	Admin	2026-04-01 13:01:41.059898	Admin
1133	CREATE	Fare	646	Kan. Lazaan (St. Bartolome) → Malinao base ₱40.00	Admin	2026-04-01 13:01:41.063704	Admin
1134	CREATE	Fare	647	Kan. Lazaan (St. Bartolome) → Upland LMES (School) base ₱36.00	Admin	2026-04-01 13:01:41.067296	Admin
1135	CREATE	Fare	648	Kan. Lazaan (St. Bartolome) → Sil. Lazaan base ₱30.00	Admin	2026-04-01 13:01:41.07058	Admin
1136	CREATE	Fare	649	Kan. Lazaan (St. Bartolome) → Kan. Lazaan base ₱30.00	Admin	2026-04-01 13:01:41.073964	Admin
1137	CREATE	Fare	650	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Tower) base ₱60.00	Admin	2026-04-01 13:01:41.077552	Admin
1138	CREATE	Fare	651	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Barod) base ₱30.00	Admin	2026-04-01 13:01:41.080958	Admin
1139	CREATE	Fare	652	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Ilaya) base ₱55.00	Admin	2026-04-01 13:01:41.084679	Admin
1140	CREATE	Fare	653	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Ilaya) base ₱20.00	Admin	2026-04-01 13:01:41.088209	Admin
1141	CREATE	Fare	654	Kan. Lazaan (St. Bartolome) → Sil. Lazaan (Dulo) base ₱20.00	Admin	2026-04-01 13:01:41.092141	Admin
1142	CREATE	Fare	655	Kan. Lazaan (St. Bartolome) → Kan. Lazaan (Siriaco) base ₱50.00	Admin	2026-04-01 13:01:41.095695	Admin
1143	REVOKE	QRCode	NVC-005E	QR status → Revoked	Admin	2026-04-01 13:09:23.95129	Admin
1144	RESTORE	QRCode	NVC-005E	QR regenerated with new AES key	Admin	2026-04-01 13:09:24.830099	Admin
1145	REVOKE	QRCode	NVC-002B	QR status → Revoked	Admin	2026-04-01 13:09:27.134686	Admin
1146	RESTORE	QRCode	NVC-002B	QR regenerated with new AES key	Admin	2026-04-01 13:09:27.830478	Admin
1147	UPDATE	Driver	5	Updated driver details	Admin	2026-04-01 13:09:45.338337	Admin
1148	UPDATE	Driver	5	Updated driver details	Admin	2026-04-01 13:09:47.860786	Admin
1149	UPDATE	Passenger	2	Updated passenger: Jose Santos	Admin	2026-04-01 13:10:28.628648	Admin
1150	UPDATE	Passenger	2	Updated passenger: Jose Santos	Admin	2026-04-01 13:10:31.454775	Admin
1151	UPDATE	Complaint	26	Status updated to In Progress	Admin	2026-04-01 13:10:42.959623	Admin
1152	UPDATE	Complaint	26	Status updated to Open	Admin	2026-04-01 13:10:46.049404	Admin
1153	REVOKE	QRCode	NVC-005E	QR status → Revoked	Admin	2026-04-01 13:18:03.947673	Admin
1154	RESTORE	QRCode	NVC-005E	QR regenerated with new AES key	Admin	2026-04-01 13:18:06.880303	Admin
1155	REVOKE	QRCode	NVC-005E	QR status → Revoked	Admin	2026-04-01 13:18:15.404526	Admin
1156	RESTORE	QRCode	NVC-005E	QR regenerated with new AES key	Admin	2026-04-01 13:18:18.481637	Admin
1157	REVOKE	QRCode	NVC-001A	QR status → Revoked	Admin	2026-04-01 13:19:50.672709	Admin
1158	RESTORE	QRCode	NVC-001A	QR regenerated with new AES key	Admin	2026-04-01 13:19:51.638704	Admin
1159	UPDATE	Payment	TXN-2831	Status → Refunded	Admin	2026-04-01 13:29:56.278193	Admin
1160	CREATE	Complaint	C-002	New report filed	Admin	2026-04-01 14:22:56.46498	Admin
1161	INSERT	Payment	P260407-9925	₱20.00 via GCash | Passenger:4 Driver:1	Admin	2026-04-07 11:13:49.057148	Admin
1162	INSERT	Payment	P260407-7700	₱35.00 via Cash | Passenger:4 Driver:1	Admin	2026-04-07 11:15:56.772367	Admin
1163	INSERT	Payment	P260407-6758	₱25.00 via Maya | Passenger:4 Driver:1	Admin	2026-04-07 11:30:05.786775	Admin
1164	INSERT	Payment	P260407-6836	₱25.00 via Maya | Passenger:4 Driver:1	Admin	2026-04-07 11:50:45.738485	Admin
1165	INSERT	Payment	P260407-6519	₱20.00 via GCash | Passenger:4 Driver:1	Admin	2026-04-07 12:35:05.166871	Admin
1166	INSERT	Payment	P260407-4462	₱20.00 via Maya | Passenger:2 Driver:3	Admin	2026-04-07 12:39:33.03249	Admin
1167	INSERT	Payment	P260407-8119	₱50.00 via Cash | Passenger:2 Driver:3	Admin	2026-04-07 12:58:36.577478	Admin
1168	INSERT	Payment	P260407-3157	₱60.00 via Cash | Passenger:2 Driver:3	Admin	2026-04-07 13:36:21.388841	Admin
1169	CREATE	Complaint	C-003	New report filed	Admin	2026-04-07 13:36:38.897273	Admin
1170	INSERT	Payment	P260407-5136	₱20.00 via Cash | Passenger:4 Driver:3	Passenger:4	2026-04-07 16:28:02.341149	User
1171	CREATE	Complaint	C-004	New report filed	Passenger:4	2026-04-07 16:28:34.950566	User
1172	INSERT	Payment	P260413-1051	₱20.00 via Maya | Passenger:4 Driver:7	Passenger:4	2026-04-13 11:00:58.442622	User
1173	CREATE	Complaint	C-005	New report filed	Passenger:4	2026-04-13 11:01:16.934438	User
1174	INSERT	Payment	P260413-4626	₱55.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 11:29:41.851009	User
1175	INSERT	Payment	P260413-1901	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 11:45:19.102043	User
1176	INSERT	Payment	P260413-1792	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 12:00:28.869229	User
1177	INSERT	Payment	P260413-2623	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 13:14:09.202136	User
1178	UPDATE	Driver	4	Updated driver details	Admin:<nil>	2026-04-13 13:16:29.309248	Admin
1179	UPDATE	Driver	4	Updated driver details	Admin:<nil>	2026-04-13 13:16:33.675028	Admin
1180	INSERT	Payment	P260413-1089	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 13:30:07.565531	User
1181	INSERT	Payment	P260413-2614	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 14:43:18.624054	User
1182	INSERT	Payment	P260413-7066	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 14:58:32.994354	User
1183	INSERT	Payment	P260413-7565	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:13:13.374072	User
1184	INSERT	Payment	P260413-3589	₱100.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:15:09.381237	User
1185	INSERT	Payment	P260413-4491	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:23:20.236258	User
1186	INSERT	Payment	P260413-1066	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:27:16.786362	User
1187	INSERT	Payment	P260413-9608	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:32:45.336837	User
1188	INSERT	Payment	P260413-3034	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:33:48.715212	User
1189	INSERT	Payment	P260413-1594	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:36:17.259422	User
1190	INSERT	Payment	P260413-7055	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 15:54:52.631597	User
1191	INSERT	Payment	P260413-5115	₱30.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:06:50.70603	User
1192	INSERT	Payment	P260413-8693	₱30.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:18:04.298758	User
1193	INSERT	Payment	P260413-7568	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:33:12.988749	User
1194	INSERT	Payment	P260413-9873	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:35:55.188598	User
1195	INSERT	Payment	P260413-4760	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:37:20.0612	User
1196	INSERT	Payment	P260413-3169	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:43:58.480331	User
1197	INSERT	Payment	P260413-2552	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:47:07.797325	User
1198	INSERT	Payment	P260413-5219	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-13 16:49:00.463075	User
1199	INSERT	Payment	P260414-9927	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 10:29:18.856771	User
1200	COMPLETE	Trip	P260414-9927	Trip completed by driver	Driver:7	2026-04-14 10:29:29.352603	Driver
1201	INSERT	Payment	P260414-1141	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 10:45:19.940759	User
1202	COMPLETE	Trip	P260414-1141	Trip completed by driver	Driver:7	2026-04-14 10:45:27.885813	Driver
1203	INSERT	Payment	P260414-3422	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 10:54:12.144689	User
1204	COMPLETE	Trip	P260414-3422	Trip completed by driver	Driver:7	2026-04-14 10:54:18.228124	Driver
1205	INSERT	Payment	P260414-3693	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 11:18:52.27125	User
1206	COMPLETE	Trip	P260414-3693	Trip completed by driver	Driver:7	2026-04-14 11:18:59.420142	Driver
1207	INSERT	Payment	P260414-9965	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 11:25:58.499023	User
1208	COMPLETE	Trip	P260414-9965	Trip completed by driver	Driver:7	2026-04-14 11:26:10.43587	Driver
1209	INSERT	Payment	P260414-8769	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 11:46:47.44868	User
1210	COMPLETE	Trip	P260414-8769	Trip completed by driver	Driver:7	2026-04-14 11:46:56.372882	Driver
1211	INSERT	Payment	P260414-3354	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 11:47:41.753155	User
1212	COMPLETE	Trip	P260414-3354	Trip completed by driver	Driver:7	2026-04-14 11:47:52.158916	Driver
1213	INSERT	Payment	P260414-4786	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 11:59:43.116731	User
1214	COMPLETE	Trip	P260414-4786	Trip completed by driver	Driver:7	2026-04-14 11:59:55.376103	Driver
1215	INSERT	Payment	P260414-5133	₱50.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 12:14:33.371053	User
1218	INSERT	Payment	P260414-8386	₱60.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 12:16:56.612423	User
1238	INSERT	Payment	P260414-7969	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 15:02:25.202495	User
1241	INSERT	Payment	P260414-5876	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 15:50:12.822232	User
1245	INSERT	Payment	P260414-1948	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 16:08:18.782344	User
1249	COMPLETE	Trip	P260414-0627	Trip completed by driver	Driver:7	2026-04-14 16:09:15.532203	Driver
1250	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-14 16:09:20.68765	User
1251	INSERT	Payment	P260414-8660	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 16:09:55.48268	User
1252	INSERT	Payment	P260414-0858	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 16:22:57.673267	User
1258	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 16:56:57.606342	Admin
1266	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:45:24.845595	Admin
1267	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:45:27.248603	Admin
1268	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:45:28.077665	Admin
1291	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:03:50.001479	Admin
1292	INSERT	Payment	P260414-4015	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 20:04:59.437025	User
1295	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:05:56.573552	Admin
1296	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:20:00.292292	Admin
1297	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:20:03.041622	Admin
1298	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:21:57.5309	Admin
1299	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:22:20.846953	Admin
1302	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:24:22.51798	Admin
1303	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:24:38.265515	Admin
1304	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:24:49.23976	Admin
1305	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:24:57.201298	Admin
1306	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:25:42.962089	Admin
1307	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:25:46.736436	Admin
1308	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:26:07.530106	Admin
1310	COMPLETE	Trip	P260414-2477	Trip completed by driver	Driver:7	2026-04-14 20:28:00.003127	Driver
1311	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-14 20:28:21.34653	User
1312	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:28:37.025979	Admin
1313	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:23:20.350419	Admin
1318	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:29:57.242571	Admin
1319	INSERT	Payment	P260415-4319	₱50.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 08:30:25.279209	User
1323	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:33:00.705286	Admin
1324	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:33:13.288284	Admin
1325	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:35:46.414259	Admin
1326	INSERT	Payment	P260415-7107	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 08:37:18.006578	User
1327	COMPLETE	Trip	P260415-7107	Trip completed by driver	Driver:7	2026-04-15 08:44:53.136659	Driver
1328	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-15 08:46:07.554663	User
1329	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:48:23.887091	Admin
1330	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 09:40:30.282874	Admin
1331	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 09:40:33.404439	Admin
1332	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 09:40:44.747924	Admin
1333	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 09:40:48.734025	Admin
1334	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 09:41:05.354803	Admin
1335	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 09:41:07.533919	Admin
1336	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:17:20.043415	Admin
1337	INSERT	Payment	P260415-2077	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 10:17:42.380868	User
1338	INSERT	Payment	P260415-5881	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 10:21:06.158248	User
1339	COMPLETE	Trip	P260415-5881	Trip completed by driver	Driver:7	2026-04-15 10:21:13.07269	Driver
1340	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-15 10:21:32.716075	User
1341	INSERT	Payment	P260415-2415	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 10:27:22.650464	User
1342	COMPLETE	Trip	P260415-2415	Trip completed by driver	Driver:7	2026-04-15 10:27:31.218471	Driver
1343	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:27:45.293631	Admin
1344	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:27:52.320654	Admin
1345	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:27:56.823912	Admin
1346	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:32:04.417378	Admin
1347	INSERT	Payment	P260415-6974	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 10:32:27.181296	User
1348	INSERT	Payment	P260415-6940	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 10:35:07.131212	User
1349	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:36:26.89942	Admin
1350	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:36:31.18998	Admin
1351	INSERT	Payment	P260415-4224	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 10:36:34.405021	User
1352	COMPLETE	Trip	P260415-4224	Trip completed by driver	Driver:7	2026-04-15 10:36:42.11528	Driver
1353	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-15 10:36:50.329901	User
1354	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:52:41.974648	Admin
1355	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 10:52:45.093769	Admin
1356	INSERT	Payment	P260415-1013	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 10:53:31.092461	User
1357	CANCEL	Trip	P260415-1013	Trip cancelled by driver	Driver:7	2026-04-15 10:53:42.634275	Driver
1358	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:00:28.774148	Admin
1359	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:00:31.780009	Admin
1360	INSERT	Payment	P260415-1762	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 11:00:51.798459	User
1361	CANCEL	Trip	P260415-1762	Trip cancelled by driver	Driver:7	2026-04-15 11:01:02.027427	Driver
1216	COMPLETE	Trip	P260414-5133	Trip completed by driver	Driver:7	2026-04-14 12:14:42.871819	Driver
1217	INSERT	Payment	P260414-4920	₱60.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 12:16:23.151865	User
1219	COMPLETE	Trip	P260414-8386	Trip completed by driver	Driver:7	2026-04-14 12:17:11.121354	Driver
1220	INSERT	Payment	P260414-7027	₱50.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 12:31:15.204105	User
1221	INSERT	Payment	P260414-1941	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 12:32:00.073136	User
1222	INSERT	Payment	P260414-8398	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 12:32:46.531889	User
1223	COMPLETE	Trip	P260414-8398	Trip completed by driver	Driver:7	2026-04-14 12:32:56.097557	Driver
1224	INSERT	Payment	P260414-5408	₱55.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 12:42:53.554448	User
1225	COMPLETE	Trip	P260414-5408	Trip completed by driver	Driver:7	2026-04-14 12:43:05.680786	Driver
1226	INSERT	Payment	P260414-8119	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 13:03:56.078215	User
1227	COMPLETE	Trip	P260414-8119	Trip completed by driver	Driver:7	2026-04-14 13:04:09.092748	Driver
1228	INSERT	Payment	P260414-4092	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 13:32:31.957851	User
1229	COMPLETE	Trip	P260414-4092	Trip completed by driver	Driver:7	2026-04-14 13:32:38.518222	Driver
1230	INSERT	Payment	P260414-5733	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 13:42:23.609411	User
1231	COMPLETE	Trip	P260414-5733	Trip completed by driver	Driver:7	2026-04-14 13:43:02.150798	Driver
1232	INSERT	Payment	P260414-6169	₱50.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 13:53:43.874249	User
1233	INSERT	Payment	P260414-7705	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 13:54:15.344868	User
1234	COMPLETE	Trip	P260414-7705	Trip completed by driver	Driver:7	2026-04-14 13:54:22.289029	Driver
1235	INSERT	Payment	P260414-6446	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 14:02:24.036562	User
1236	COMPLETE	Trip	P260414-6446	Trip completed by driver	Driver:7	2026-04-14 14:02:31.725517	Driver
1237	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-14 14:02:38.587355	User
1239	COMPLETE	Trip	P260414-7969	Trip completed by driver	Driver:7	2026-04-14 15:03:59.672909	Driver
1240	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-14 15:04:07.745388	User
1242	COMPLETE	Trip	P260414-5876	Trip completed by driver	Driver:7	2026-04-14 15:50:23.520202	Driver
1243	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-14 15:50:34.669776	User
1244	INSERT	Payment	P260414-9604	₱40.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 15:50:56.541946	User
1246	COMPLETE	Trip	P260414-1948	Trip completed by driver	Driver:7	2026-04-14 16:08:38.89026	Driver
1247	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-14 16:08:49.840218	User
1248	INSERT	Payment	P260414-0627	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 16:09:07.454409	User
1253	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 16:24:29.600464	Admin
1254	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 16:24:59.930162	Admin
1255	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 16:26:10.213069	Admin
1256	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 16:26:13.628311	Admin
1259	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:38:03.855438	Admin
1260	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:38:05.346055	Admin
1261	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:38:38.94007	Admin
1262	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:38:42.519667	Admin
1263	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:38:50.39087	Admin
1264	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:39:02.821813	Admin
1265	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 17:39:41.486064	Admin
1269	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 17:46:23.401469	Admin
1270	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 17:46:30.20912	Admin
1271	UPDATE	Driver	4	Updated driver details	Admin:<nil>	2026-04-14 17:46:32.422482	Admin
1272	UPDATE	Driver	4	Updated driver details	Admin:<nil>	2026-04-14 17:46:34.474784	Admin
1273	UPDATE	Driver	3	Updated driver details	Admin:<nil>	2026-04-14 17:46:51.544752	Admin
1274	UPDATE	Driver	3	Updated driver details	Admin:<nil>	2026-04-14 17:46:54.625082	Admin
1275	UPDATE	Driver	2	Updated driver details	Admin:<nil>	2026-04-14 17:46:58.178916	Admin
1276	UPDATE	Driver	2	Updated driver details	Admin:<nil>	2026-04-14 17:47:00.453574	Admin
1277	UPDATE	Driver	1	Updated driver details	Admin:<nil>	2026-04-14 17:47:02.689771	Admin
1278	UPDATE	Driver	1	Updated driver details	Admin:<nil>	2026-04-14 17:47:04.541024	Admin
1279	UPDATE	Driver	1	Updated driver details	Admin:<nil>	2026-04-14 17:51:23.353686	Admin
1280	UPDATE	Driver	1	Updated driver details	Admin:<nil>	2026-04-14 17:51:26.303174	Admin
1281	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 17:59:14.286004	Admin
1282	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 18:00:44.490117	Admin
1283	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 18:01:04.6097	Admin
1284	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 18:01:39.311938	Admin
1285	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 18:01:55.908797	Admin
1286	UPDATE	Driver	5	Updated driver details	Admin:<nil>	2026-04-14 18:02:53.614906	Admin
1287	UPDATE	Driver	2	Updated driver details	Admin:<nil>	2026-04-14 18:03:25.530861	Admin
1288	UPDATE	Driver	2	Updated driver details	Admin:<nil>	2026-04-14 18:03:28.66116	Admin
1289	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 18:18:10.017344	Admin
1290	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 18:18:13.12893	Admin
1293	COMPLETE	Trip	P260414-4015	Trip completed by driver	Driver:7	2026-04-14 20:05:18.805716	Driver
1294	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-14 20:05:34.321763	User
1300	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:24:03.469058	Admin
1301	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-14 20:24:05.445586	Admin
1309	INSERT	Payment	P260414-2477	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-14 20:26:47.759919	User
1314	INSERT	Payment	P260415-7381	₱30.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 08:24:58.371837	User
1315	COMPLETE	Trip	P260415-7381	Trip completed by driver	Driver:7	2026-04-15 08:25:36.331251	Driver
1316	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-15 08:25:47.493008	User
1317	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:25:53.317567	Admin
1320	COMPLETE	Trip	P260415-4319	Trip completed by driver	Driver:7	2026-04-15 08:31:01.077357	Driver
1321	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-15 08:31:11.983646	User
1322	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 08:32:11.695003	Admin
1362	INSERT	Payment	P260415-1414	₱35.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 11:02:11.440311	User
1363	CANCEL	Trip	P260415-1414	Trip cancelled by driver	Driver:7	2026-04-15 11:02:32.291472	Driver
1364	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:16:52.484848	Admin
1365	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:16:57.080398	Admin
1366	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:18:00.099535	Admin
1367	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:36:16.890928	Admin
1368	INSERT	Payment	P260415-8000	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 11:36:47.833717	User
1369	COMPLETE	Trip	P260415-8000	Trip completed by driver	Driver:7	2026-04-15 11:37:05.033918	Driver
1370	CREATE	Rating	7	Driver rated 5 stars	Passenger:4	2026-04-15 11:37:11.754099	User
1371	INSERT	Payment	P260415-2272	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 11:37:52.085169	User
1372	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:38:06.533389	Admin
1373	UPDATE	Driver	7	Updated driver details	Admin:<nil>	2026-04-15 11:38:11.90792	Admin
1374	INSERT	Payment	P260415-2036	₱20.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 11:38:31.845669	User
1375	CANCEL	Trip	P260415-2036	Trip cancelled by driver	Driver:7	2026-04-15 11:38:42.197578	Driver
1376	INSERT	Payment	P260415-5154	₱25.00 via Cash | Passenger:4 Driver:7	Passenger:4	2026-04-15 11:39:34.961074	User
1377	CANCEL	Trip	P260415-5154	Trip cancelled by driver	Driver:7	2026-04-15 11:39:52.498328	Driver
\.


--
-- TOC entry 5168 (class 0 OID 25095)
-- Dependencies: 232
-- Data for Name: complaints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.complaints (id, report_code, passenger_id, driver_id, violation_type, details, admin_notes, status, reported_at, resolved_at) FROM stdin;
26	C-001	4	3	Reckless Driving	test		Open	2026-03-31 22:45:17.470894	\N
27	C-002	4	1	Harassment	test	\N	Open	2026-04-01 14:22:56.44591	\N
28	C-003	2	3	Reckless Driving	test	\N	Open	2026-04-07 13:36:38.890964	\N
29	C-004	4	3	Harassment	test	\N	Open	2026-04-07 16:28:34.924301	\N
30	C-005	4	7	Harassment	nanghehepo	\N	Open	2026-04-13 11:01:16.929907	\N
\.


--
-- TOC entry 5160 (class 0 OID 25012)
-- Dependencies: 224
-- Data for Name: drivers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.drivers (id, username, password_hash, is_active, status, first_name, middle_name, last_name, contact, email, driver_code, franchise, body_no, plate_number, license_no, association, created_at, profile_pic) FROM stdin;
1	juan1	pass123	t	Inactive	Juan	A.	Dela Cruz	09123456789	\N	D-001	NVC-001A	01	abc 1234	NAG-123456	Nagcarlan TODA	2026-03-13 16:38:10.127763	\N
5	elena	\N	t	Inactive	Elena	T.	Garcia	09334455667	\N	D-005	NVC-005E	05		NAG-456789	Nagcarlan TODA	2026-03-13 16:38:10.127763	\N
2	maria1	pass123	t	Inactive	Maria	S.	Reyes	09987654321	\N	D-002	NVC-002B	02	\N	NAG-654321	Nagcarlan TODA	2026-03-13 16:38:10.127763	\N
7	andrew	123456	t	Active	Andrew		Cauyan	09494439017	\N	D-006	NVC-00F2	09	ABC 123	NAG-123456	Nagcarlan TODA	2026-03-24 10:17:01.41261	\N
4	roberto	\N	t	Inactive	Roberto	C.	Lim	09223344556	\N	D-004	NVC-004D	04		NAG-321098	Nagcarlan TODA	2026-03-13 16:38:10.127763	\N
3	pedro	\N	t	Inactive	Pedro	M.	Santos	09112233445	\N	D-003	NVC-003C	03		NAG-789012	Nagcarlan TODA	2026-03-13 16:38:10.127763	\N
\.


--
-- TOC entry 5164 (class 0 OID 25056)
-- Dependencies: 228
-- Data for Name: fare_matrix; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fare_matrix (id, origin, destination, base_fare, discounted_fare, night_fare, special_fare, created_at, association) FROM stdin;
446	Balinacon	Balimbing - 1 Ahon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.277645	LP-TODA
447	Balinacon	Sinipian	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.297503	LP-TODA
448	Balinacon	Balimbing - 2 Ahon	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.302031	LP-TODA
449	Balinacon	Malinao	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.306068	LP-TODA
450	Balinacon	Upland LMES (School)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.311174	LP-TODA
451	Balinacon	Sil. Lazaan	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.315152	LP-TODA
452	Balinacon	Kan. Lazaan	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.319029	LP-TODA
453	Balinacon	Sil. Lazaan (Tower)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.32284	LP-TODA
454	Balinacon	Kan. Lazaan (Barod)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.328048	LP-TODA
455	Balinacon	Sil. Lazaan (Ilaya)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.332073	LP-TODA
456	Balinacon	Kan. Lazaan (Ilaya)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.335657	LP-TODA
457	Balinacon	Sil. Lazaan (Dulo)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.339989	LP-TODA
458	Balinacon	Kan. Lazaan (Siriaco)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.344602	LP-TODA
459	Balinacon	Kan. Lazaan (St. Bartolome)	70.00	65.00	80.50	130.00	2026-04-01 13:01:40.34879	LP-TODA
460	Balimbing - 1 Ahon	Balinacon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.352593	LP-TODA
461	Balimbing - 1 Ahon	Sinipian	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.356466	LP-TODA
462	Balimbing - 1 Ahon	Balimbing - 2 Ahon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.361007	LP-TODA
463	Balimbing - 1 Ahon	Malinao	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.364929	LP-TODA
464	Balimbing - 1 Ahon	Upland LMES (School)	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.368482	LP-TODA
465	Balimbing - 1 Ahon	Sil. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.371996	LP-TODA
466	Balimbing - 1 Ahon	Kan. Lazaan	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.378115	LP-TODA
467	Balimbing - 1 Ahon	Sil. Lazaan (Tower)	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.382312	LP-TODA
468	Balimbing - 1 Ahon	Kan. Lazaan (Barod)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.386323	LP-TODA
469	Balimbing - 1 Ahon	Sil. Lazaan (Ilaya)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.390308	LP-TODA
470	Balimbing - 1 Ahon	Kan. Lazaan (Ilaya)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.394854	LP-TODA
471	Balimbing - 1 Ahon	Sil. Lazaan (Dulo)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.398705	LP-TODA
472	Balimbing - 1 Ahon	Kan. Lazaan (Siriaco)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.402366	LP-TODA
473	Balimbing - 1 Ahon	Kan. Lazaan (St. Bartolome)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.406142	LP-TODA
474	Sinipian	Balinacon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.410635	LP-TODA
475	Sinipian	Balimbing - 1 Ahon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.414646	LP-TODA
476	Sinipian	Balimbing - 2 Ahon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.418485	LP-TODA
477	Sinipian	Malinao	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.422238	LP-TODA
478	Sinipian	Upland LMES (School)	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.426833	LP-TODA
479	Sinipian	Sil. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.431301	LP-TODA
480	Sinipian	Kan. Lazaan	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.435943	LP-TODA
481	Sinipian	Sil. Lazaan (Tower)	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.441034	LP-TODA
482	Sinipian	Kan. Lazaan (Barod)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.445751	LP-TODA
483	Sinipian	Sil. Lazaan (Ilaya)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.449938	LP-TODA
484	Sinipian	Kan. Lazaan (Ilaya)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.453477	LP-TODA
485	Sinipian	Sil. Lazaan (Dulo)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.457325	LP-TODA
486	Sinipian	Kan. Lazaan (Siriaco)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.461606	LP-TODA
487	Sinipian	Kan. Lazaan (St. Bartolome)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.465191	LP-TODA
488	Balimbing - 2 Ahon	Balinacon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.469023	LP-TODA
489	Balimbing - 2 Ahon	Balimbing - 1 Ahon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.472944	LP-TODA
490	Balimbing - 2 Ahon	Sinipian	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.47716	LP-TODA
491	Balimbing - 2 Ahon	Malinao	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.481211	LP-TODA
492	Balimbing - 2 Ahon	Upland LMES (School)	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.484999	LP-TODA
493	Balimbing - 2 Ahon	Sil. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.488938	LP-TODA
494	Balimbing - 2 Ahon	Kan. Lazaan	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.492692	LP-TODA
495	Balimbing - 2 Ahon	Sil. Lazaan (Tower)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.496498	LP-TODA
496	Balimbing - 2 Ahon	Kan. Lazaan (Barod)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.500801	LP-TODA
497	Balimbing - 2 Ahon	Sil. Lazaan (Ilaya)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.504647	LP-TODA
498	Balimbing - 2 Ahon	Kan. Lazaan (Ilaya)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.508663	LP-TODA
499	Balimbing - 2 Ahon	Sil. Lazaan (Dulo)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.512686	LP-TODA
500	Balimbing - 2 Ahon	Kan. Lazaan (Siriaco)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.516557	LP-TODA
501	Balimbing - 2 Ahon	Kan. Lazaan (St. Bartolome)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.520209	LP-TODA
502	Malinao	Balinacon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.523931	LP-TODA
503	Malinao	Balimbing - 1 Ahon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.52826	LP-TODA
504	Malinao	Sinipian	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.532095	LP-TODA
505	Malinao	Balimbing - 2 Ahon	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.535597	LP-TODA
506	Malinao	Upland LMES (School)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.53917	LP-TODA
507	Malinao	Sil. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.543253	LP-TODA
508	Malinao	Kan. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.5469	LP-TODA
509	Malinao	Sil. Lazaan (Tower)	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.551456	LP-TODA
510	Malinao	Kan. Lazaan (Barod)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.555211	LP-TODA
511	Malinao	Sil. Lazaan (Ilaya)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.559119	LP-TODA
512	Malinao	Kan. Lazaan (Ilaya)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.562729	LP-TODA
513	Malinao	Sil. Lazaan (Dulo)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.566245	LP-TODA
514	Malinao	Kan. Lazaan (Siriaco)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.569738	LP-TODA
515	Malinao	Kan. Lazaan (St. Bartolome)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.573538	LP-TODA
516	Upland LMES (School)	Balinacon	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.577486	LP-TODA
517	Upland LMES (School)	Balimbing - 1 Ahon	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.581843	LP-TODA
518	Upland LMES (School)	Sinipian	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.585705	LP-TODA
519	Upland LMES (School)	Balimbing - 2 Ahon	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.589587	LP-TODA
520	Upland LMES (School)	Malinao	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.59371	LP-TODA
521	Upland LMES (School)	Sil. Lazaan	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.597469	LP-TODA
522	Upland LMES (School)	Kan. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.601484	LP-TODA
523	Upland LMES (School)	Sil. Lazaan (Tower)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.605691	LP-TODA
524	Upland LMES (School)	Kan. Lazaan (Barod)	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.60956	LP-TODA
525	Upland LMES (School)	Sil. Lazaan (Ilaya)	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.614034	LP-TODA
526	Upland LMES (School)	Kan. Lazaan (Ilaya)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.617841	LP-TODA
527	Upland LMES (School)	Sil. Lazaan (Dulo)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.621466	LP-TODA
528	Upland LMES (School)	Kan. Lazaan (Siriaco)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.625351	LP-TODA
529	Upland LMES (School)	Kan. Lazaan (St. Bartolome)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.629445	LP-TODA
530	Sil. Lazaan	Balinacon	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.632704	LP-TODA
531	Sil. Lazaan	Balimbing - 1 Ahon	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.636133	LP-TODA
532	Sil. Lazaan	Sinipian	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.639611	LP-TODA
533	Sil. Lazaan	Balimbing - 2 Ahon	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.643485	LP-TODA
534	Sil. Lazaan	Malinao	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.646988	LP-TODA
535	Sil. Lazaan	Upland LMES (School)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.650758	LP-TODA
536	Sil. Lazaan	Kan. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.653991	LP-TODA
537	Sil. Lazaan	Sil. Lazaan (Tower)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.657843	LP-TODA
538	Sil. Lazaan	Kan. Lazaan (Barod)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.661826	LP-TODA
539	Sil. Lazaan	Sil. Lazaan (Ilaya)	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.665105	LP-TODA
540	Sil. Lazaan	Kan. Lazaan (Ilaya)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.668718	LP-TODA
541	Sil. Lazaan	Sil. Lazaan (Dulo)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.672133	LP-TODA
542	Sil. Lazaan	Kan. Lazaan (Siriaco)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.675976	LP-TODA
543	Sil. Lazaan	Kan. Lazaan (St. Bartolome)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.679776	LP-TODA
544	Kan. Lazaan	Balinacon	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.683448	LP-TODA
545	Kan. Lazaan	Balimbing - 1 Ahon	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.686884	LP-TODA
546	Kan. Lazaan	Sinipian	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.690626	LP-TODA
547	Kan. Lazaan	Balimbing - 2 Ahon	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.694327	LP-TODA
548	Kan. Lazaan	Malinao	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.698051	LP-TODA
549	Kan. Lazaan	Upland LMES (School)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.701448	LP-TODA
550	Kan. Lazaan	Sil. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.70499	LP-TODA
551	Kan. Lazaan	Sil. Lazaan (Tower)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.708758	LP-TODA
552	Kan. Lazaan	Kan. Lazaan (Barod)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.712224	LP-TODA
553	Kan. Lazaan	Sil. Lazaan (Ilaya)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.715855	LP-TODA
554	Kan. Lazaan	Kan. Lazaan (Ilaya)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.719505	LP-TODA
555	Kan. Lazaan	Sil. Lazaan (Dulo)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.723577	LP-TODA
556	Kan. Lazaan	Kan. Lazaan (Siriaco)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.727351	LP-TODA
557	Kan. Lazaan	Kan. Lazaan (St. Bartolome)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.731234	LP-TODA
558	Sil. Lazaan (Tower)	Balinacon	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.734758	LP-TODA
559	Sil. Lazaan (Tower)	Balimbing - 1 Ahon	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.738365	LP-TODA
560	Sil. Lazaan (Tower)	Sinipian	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.742362	LP-TODA
561	Sil. Lazaan (Tower)	Balimbing - 2 Ahon	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.746238	LP-TODA
562	Sil. Lazaan (Tower)	Malinao	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.749758	LP-TODA
563	Sil. Lazaan (Tower)	Upland LMES (School)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.753035	LP-TODA
564	Sil. Lazaan (Tower)	Sil. Lazaan	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.756421	LP-TODA
565	Sil. Lazaan (Tower)	Kan. Lazaan	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.76042	LP-TODA
566	Sil. Lazaan (Tower)	Kan. Lazaan (Barod)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.76409	LP-TODA
567	Sil. Lazaan (Tower)	Sil. Lazaan (Ilaya)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.7676	LP-TODA
568	Sil. Lazaan (Tower)	Kan. Lazaan (Ilaya)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.771116	LP-TODA
569	Sil. Lazaan (Tower)	Sil. Lazaan (Dulo)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.774791	LP-TODA
570	Sil. Lazaan (Tower)	Kan. Lazaan (Siriaco)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.778546	LP-TODA
571	Sil. Lazaan (Tower)	Kan. Lazaan (St. Bartolome)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.782173	LP-TODA
572	Kan. Lazaan (Barod)	Balinacon	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.785845	LP-TODA
573	Kan. Lazaan (Barod)	Balimbing - 1 Ahon	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.789157	LP-TODA
574	Kan. Lazaan (Barod)	Sinipian	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.793976	LP-TODA
575	Kan. Lazaan (Barod)	Balimbing - 2 Ahon	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.797831	LP-TODA
576	Kan. Lazaan (Barod)	Malinao	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.801163	LP-TODA
577	Kan. Lazaan (Barod)	Upland LMES (School)	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.804799	LP-TODA
578	Kan. Lazaan (Barod)	Sil. Lazaan	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.808727	LP-TODA
579	Kan. Lazaan (Barod)	Kan. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.812224	LP-TODA
580	Kan. Lazaan (Barod)	Sil. Lazaan (Tower)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.815798	LP-TODA
581	Kan. Lazaan (Barod)	Sil. Lazaan (Ilaya)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.819499	LP-TODA
582	Kan. Lazaan (Barod)	Kan. Lazaan (Ilaya)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.823279	LP-TODA
583	Kan. Lazaan (Barod)	Sil. Lazaan (Dulo)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.827065	LP-TODA
584	Kan. Lazaan (Barod)	Kan. Lazaan (Siriaco)	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.830875	LP-TODA
585	Kan. Lazaan (Barod)	Kan. Lazaan (St. Bartolome)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.834471	LP-TODA
586	Sil. Lazaan (Ilaya)	Balinacon	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.83805	LP-TODA
587	Sil. Lazaan (Ilaya)	Balimbing - 1 Ahon	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.841823	LP-TODA
588	Sil. Lazaan (Ilaya)	Sinipian	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.845852	LP-TODA
589	Sil. Lazaan (Ilaya)	Balimbing - 2 Ahon	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.849543	LP-TODA
590	Sil. Lazaan (Ilaya)	Malinao	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.852896	LP-TODA
591	Sil. Lazaan (Ilaya)	Upland LMES (School)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.856169	LP-TODA
592	Sil. Lazaan (Ilaya)	Sil. Lazaan	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.860931	LP-TODA
593	Sil. Lazaan (Ilaya)	Kan. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.864466	LP-TODA
594	Sil. Lazaan (Ilaya)	Sil. Lazaan (Tower)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.86797	LP-TODA
595	Sil. Lazaan (Ilaya)	Kan. Lazaan (Barod)	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.871666	LP-TODA
596	Sil. Lazaan (Ilaya)	Kan. Lazaan (Ilaya)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.875809	LP-TODA
597	Sil. Lazaan (Ilaya)	Sil. Lazaan (Dulo)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.879502	LP-TODA
598	Sil. Lazaan (Ilaya)	Kan. Lazaan (Siriaco)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.883061	LP-TODA
599	Sil. Lazaan (Ilaya)	Kan. Lazaan (St. Bartolome)	65.00	60.00	74.75	120.00	2026-04-01 13:01:40.886863	LP-TODA
600	Kan. Lazaan (Ilaya)	Balinacon	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.890724	LP-TODA
601	Kan. Lazaan (Ilaya)	Balimbing - 1 Ahon	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.894251	LP-TODA
602	Kan. Lazaan (Ilaya)	Sinipian	35.00	30.00	40.25	60.00	2026-04-01 13:01:40.897778	LP-TODA
603	Kan. Lazaan (Ilaya)	Balimbing - 2 Ahon	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.901227	LP-TODA
604	Kan. Lazaan (Ilaya)	Malinao	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.904798	LP-TODA
605	Kan. Lazaan (Ilaya)	Upland LMES (School)	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.908488	LP-TODA
606	Kan. Lazaan (Ilaya)	Sil. Lazaan	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.912386	LP-TODA
607	Kan. Lazaan (Ilaya)	Kan. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.915716	LP-TODA
608	Kan. Lazaan (Ilaya)	Sil. Lazaan (Tower)	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.91942	LP-TODA
609	Kan. Lazaan (Ilaya)	Kan. Lazaan (Barod)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.923157	LP-TODA
610	Kan. Lazaan (Ilaya)	Sil. Lazaan (Ilaya)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.927165	LP-TODA
611	Kan. Lazaan (Ilaya)	Sil. Lazaan (Dulo)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.930951	LP-TODA
612	Kan. Lazaan (Ilaya)	Kan. Lazaan (Siriaco)	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.934801	LP-TODA
613	Kan. Lazaan (Ilaya)	Kan. Lazaan (St. Bartolome)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.938365	LP-TODA
614	Sil. Lazaan (Dulo)	Balinacon	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.942251	LP-TODA
615	Sil. Lazaan (Dulo)	Balimbing - 1 Ahon	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.945781	LP-TODA
616	Sil. Lazaan (Dulo)	Sinipian	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.949771	LP-TODA
617	Sil. Lazaan (Dulo)	Balimbing - 2 Ahon	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.953339	LP-TODA
618	Sil. Lazaan (Dulo)	Malinao	40.00	35.00	46.00	70.00	2026-04-01 13:01:40.957972	LP-TODA
619	Sil. Lazaan (Dulo)	Upland LMES (School)	30.00	25.00	34.50	50.00	2026-04-01 13:01:40.961852	LP-TODA
620	Sil. Lazaan (Dulo)	Sil. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.965629	LP-TODA
621	Sil. Lazaan (Dulo)	Kan. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:40.969089	LP-TODA
622	Sil. Lazaan (Dulo)	Sil. Lazaan (Tower)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.972569	LP-TODA
623	Sil. Lazaan (Dulo)	Kan. Lazaan (Barod)	55.00	50.00	63.25	100.00	2026-04-01 13:01:40.976511	LP-TODA
624	Sil. Lazaan (Dulo)	Sil. Lazaan (Ilaya)	20.00	15.00	23.00	30.00	2026-04-01 13:01:40.98012	LP-TODA
625	Sil. Lazaan (Dulo)	Kan. Lazaan (Ilaya)	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.983692	LP-TODA
626	Sil. Lazaan (Dulo)	Kan. Lazaan (Siriaco)	60.00	55.00	69.00	110.00	2026-04-01 13:01:40.987401	LP-TODA
627	Sil. Lazaan (Dulo)	Kan. Lazaan (St. Bartolome)	70.00	65.00	80.50	130.00	2026-04-01 13:01:40.991502	LP-TODA
628	Kan. Lazaan (Siriaco)	Balinacon	50.00	45.00	57.50	90.00	2026-04-01 13:01:40.995248	LP-TODA
629	Kan. Lazaan (Siriaco)	Balimbing - 1 Ahon	45.00	40.00	51.75	80.00	2026-04-01 13:01:40.998781	LP-TODA
630	Kan. Lazaan (Siriaco)	Sinipian	45.00	40.00	51.75	80.00	2026-04-01 13:01:41.002175	LP-TODA
631	Kan. Lazaan (Siriaco)	Balimbing - 2 Ahon	45.00	40.00	51.75	80.00	2026-04-01 13:01:41.005886	LP-TODA
632	Kan. Lazaan (Siriaco)	Malinao	40.00	35.00	46.00	70.00	2026-04-01 13:01:41.010177	LP-TODA
633	Kan. Lazaan (Siriaco)	Upland LMES (School)	30.00	25.00	34.50	50.00	2026-04-01 13:01:41.013761	LP-TODA
634	Kan. Lazaan (Siriaco)	Sil. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:41.017818	LP-TODA
635	Kan. Lazaan (Siriaco)	Kan. Lazaan	25.00	20.00	28.75	40.00	2026-04-01 13:01:41.021873	LP-TODA
636	Kan. Lazaan (Siriaco)	Sil. Lazaan (Tower)	55.00	50.00	63.25	100.00	2026-04-01 13:01:41.025444	LP-TODA
637	Kan. Lazaan (Siriaco)	Kan. Lazaan (Barod)	20.00	15.00	23.00	30.00	2026-04-01 13:01:41.029478	LP-TODA
638	Kan. Lazaan (Siriaco)	Sil. Lazaan (Ilaya)	60.00	55.00	69.00	110.00	2026-04-01 13:01:41.032954	LP-TODA
639	Kan. Lazaan (Siriaco)	Kan. Lazaan (Ilaya)	20.00	15.00	23.00	30.00	2026-04-01 13:01:41.036474	LP-TODA
640	Kan. Lazaan (Siriaco)	Sil. Lazaan (Dulo)	60.00	55.00	69.00	110.00	2026-04-01 13:01:41.040305	LP-TODA
641	Kan. Lazaan (Siriaco)	Kan. Lazaan (St. Bartolome)	30.00	25.00	34.50	50.00	2026-04-01 13:01:41.044091	LP-TODA
642	Kan. Lazaan (St. Bartolome)	Balinacon	55.00	50.00	63.25	100.00	2026-04-01 13:01:41.048166	LP-TODA
643	Kan. Lazaan (St. Bartolome)	Balimbing - 1 Ahon	50.00	45.00	57.50	90.00	2026-04-01 13:01:41.051664	LP-TODA
644	Kan. Lazaan (St. Bartolome)	Sinipian	50.00	45.00	57.50	90.00	2026-04-01 13:01:41.055032	LP-TODA
645	Kan. Lazaan (St. Bartolome)	Balimbing - 2 Ahon	50.00	45.00	57.50	90.00	2026-04-01 13:01:41.059161	LP-TODA
646	Kan. Lazaan (St. Bartolome)	Malinao	40.00	35.00	46.00	70.00	2026-04-01 13:01:41.062878	LP-TODA
647	Kan. Lazaan (St. Bartolome)	Upland LMES (School)	36.00	31.00	41.40	62.00	2026-04-01 13:01:41.066416	LP-TODA
648	Kan. Lazaan (St. Bartolome)	Sil. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:41.06986	LP-TODA
649	Kan. Lazaan (St. Bartolome)	Kan. Lazaan	30.00	25.00	34.50	50.00	2026-04-01 13:01:41.072991	LP-TODA
650	Kan. Lazaan (St. Bartolome)	Sil. Lazaan (Tower)	60.00	55.00	69.00	110.00	2026-04-01 13:01:41.076789	LP-TODA
651	Kan. Lazaan (St. Bartolome)	Kan. Lazaan (Barod)	30.00	25.00	34.50	50.00	2026-04-01 13:01:41.080258	LP-TODA
652	Kan. Lazaan (St. Bartolome)	Sil. Lazaan (Ilaya)	55.00	50.00	63.25	100.00	2026-04-01 13:01:41.083909	LP-TODA
653	Kan. Lazaan (St. Bartolome)	Kan. Lazaan (Ilaya)	20.00	15.00	23.00	30.00	2026-04-01 13:01:41.087281	LP-TODA
654	Kan. Lazaan (St. Bartolome)	Sil. Lazaan (Dulo)	20.00	15.00	23.00	30.00	2026-04-01 13:01:41.091294	LP-TODA
655	Kan. Lazaan (St. Bartolome)	Kan. Lazaan (Siriaco)	50.00	45.00	57.50	90.00	2026-04-01 13:01:41.094928	LP-TODA
\.


--
-- TOC entry 5174 (class 0 OID 25156)
-- Dependencies: 238
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, title, description, type, is_read, created_at) FROM stdin;
1	System Test	Testing if the ID sequence is fixed.	TEST_SYNC	f	2026-03-24 09:12:08.959164
2	New Driver Registered	Andrew  Cauyan (NVC-00F2) has been enrolled as a driver.	driver	f	2026-03-24 10:17:01.477488
\.


--
-- TOC entry 5166 (class 0 OID 25070)
-- Dependencies: 230
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, ref_code, passenger_id, driver_id, route, amount, method, status, paid_at, passenger_type, trip_type, ewallet_account, contact_number) FROM stdin;
6	P260407-6836	4	1	Balimbing - 2 Ahon → Balinacon	25.00	Maya	Paid	2026-04-07 11:50:45.727122	Regular	Regular Trip	09123456789	09123456789
7	P260407-6519	4	1	Malinao → Balinacon	20.00	GCash	Paid	2026-04-07 12:35:05.159694	Student	Regular Trip	09123456789	09123456789
8	P260407-4462	2	3	Balimbing - 2 Ahon → Balinacon	20.00	Maya	Paid	2026-04-07 12:39:33.028468	Senior Citizen	Regular Trip	09112233445	09112233445
9	P260407-8119	2	3	Balimbing - 1 Ahon → Sil. Lazaan (Dulo)	50.00	Cash	Paid	2026-04-07 12:58:36.571613	Student	Regular Trip		09112233445
10	P260407-3157	2	3	Balimbing - 1 Ahon → Kan. Lazaan	60.00	Cash	Paid	2026-04-07 13:36:21.382524	Student	Special Trip		09112233445
11	P260407-5136	4	3	Balimbing - 1 Ahon → Balinacon	20.00	Cash	Paid	2026-04-07 16:28:02.332099	Regular	Regular Trip		09112233445
12	P260413-1051	4	7	Balimbing - 1 Ahon → Balinacon	20.00	Maya	Paid	2026-04-13 11:00:58.413739	Regular	Regular Trip	09494439017	09494439017
13	P260413-4626	4	7	Balinacon → Sil. Lazaan (Ilaya)	55.00	Cash	Paid	2026-04-13 11:29:41.844945	Regular	Regular Trip		09494439017
14	P260413-1901	4	7	Balimbing - 2 Ahon → Malinao	20.00	Cash	Paid	2026-04-13 11:45:19.095776	Regular	Regular Trip		09494439017
15	P260413-1792	4	7	Balimbing - 1 Ahon → Balinacon	20.00	Cash	Paid	2026-04-13 12:00:28.807257	Regular	Regular Trip		09494439017
16	P260413-2623	4	7	Balinacon → Balimbing - 1 Ahon	20.00	Cash	Paid	2026-04-13 13:14:09.179765	Regular	Regular Trip		09494439017
17	P260413-1089	4	7	Balinacon → Malinao	25.00	Cash	Paid	2026-04-13 13:30:07.544732	Regular	Regular Trip		09494439017
18	P260413-2614	4	7	Balimbing - 1 Ahon → Balinacon	20.00	Cash	Paid	2026-04-13 14:43:18.593202	Regular	Regular Trip		09494439017
19	P260413-7066	4	7	Balinacon → Sil. Lazaan	35.00	Cash	Paid	2026-04-13 14:58:32.954961	Regular	Regular Trip		09494439017
20	P260413-7565	4	7	Kan. Lazaan → Upland LMES (School)	25.00	Cash	Paid	2026-04-13 15:13:13.364371	Regular	Regular Trip		09494439017
21	P260413-3589	4	7	Sinipian → Sil. Lazaan (Dulo)	100.00	Cash	Paid	2026-04-13 15:15:09.376299	Student	Special Trip		09494439017
22	P260413-4491	4	7	Balimbing - 2 Ahon → Balinacon	20.00	Cash	Paid	2026-04-13 15:23:20.22947	Senior Citizen	Regular Trip		09494439017
23	P260413-1066	4	7	Kan. Lazaan → Sinipian	35.00	Cash	Paid	2026-04-13 15:27:16.780685	Regular	Regular Trip		09494439017
24	P260413-9608	4	7	Malinao → Balinacon	25.00	Cash	Paid	2026-04-13 15:32:45.32748	Regular	Regular Trip		09494439017
25	P260413-3034	4	7	Balinacon → Balimbing - 2 Ahon	25.00	Cash	Paid	2026-04-13 15:33:48.709663	Regular	Regular Trip		09494439017
26	P260413-1594	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-13 15:36:17.25513	Regular	Regular Trip		09494439017
27	P260413-7055	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-13 15:54:52.605033	Regular	Regular Trip		09494439017
28	P260413-5115	4	7	Kan. Lazaan → Kan. Lazaan (Barod)	30.00	Cash	Paid	2026-04-13 16:06:50.677502	Regular	Regular Trip		09494439017
29	P260413-8693	4	7	Balimbing - 2 Ahon → Kan. Lazaan	30.00	Cash	Paid	2026-04-13 16:18:04.104775	Student	Regular Trip		09494439017
30	P260413-7568	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-13 16:33:12.952775	Regular	Regular Trip		09494439017
31	P260413-9873	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-13 16:35:55.177458	Regular	Regular Trip		09494439017
32	P260413-4760	4	7	Balinacon → Malinao	25.00	Cash	Paid	2026-04-13 16:37:20.056148	Regular	Regular Trip		09494439017
33	P260413-3169	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-13 16:43:58.471872	Regular	Regular Trip		09494439017
34	P260413-2552	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-13 16:47:07.787909	Regular	Regular Trip		09494439017
35	P260413-5219	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-13 16:49:00.444467	Regular	Regular Trip		09494439017
39	P260414-9927	4	7	Kan. Lazaan → Upland LMES (School)	25.00	Cash	Paid	2026-04-14 10:29:18.791552	Regular	Regular Trip		09494439017
40	P260414-1141	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-14 10:45:19.907921	Regular	Regular Trip		09494439017
41	P260414-3422	4	7	Balimbing - 2 Ahon → Sinipian	20.00	Cash	Paid	2026-04-14 10:54:12.135149	Regular	Regular Trip		09494439017
42	P260414-3693	4	7	Balimbing - 1 Ahon → Balimbing - 2 Ahon	20.00	Cash	Paid	2026-04-14 11:18:52.258135	Regular	Regular Trip		09494439017
43	P260414-9965	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-14 11:25:58.488042	Regular	Regular Trip		09494439017
44	P260414-8769	4	7	Balimbing - 1 Ahon → Sinipian	20.00	Cash	Paid	2026-04-14 11:46:47.168022	Regular	Regular Trip		09494439017
45	P260414-3354	4	7	Kan. Lazaan → Upland LMES (School)	25.00	Cash	Paid	2026-04-14 11:47:41.745942	Regular	Regular Trip		09494439017
46	P260414-4786	4	7	Balimbing - 1 Ahon → Upland LMES (School)	25.00	Cash	Paid	2026-04-14 11:59:43.105744	Regular	Regular Trip		09494439017
47	P260414-5133	4	7	Kan. Lazaan (St. Bartolome) → Kan. Lazaan	50.00	Cash	Paid	2026-04-14 12:14:33.363749	Regular	Regular Trip		09494439017
48	P260414-4920	4	7	Balimbing - 2 Ahon → Kan. Lazaan (Siriaco)	60.00	Cash	Paid	2026-04-14 12:16:23.139283	Regular	Regular Trip		09494439017
49	P260414-8386	4	7	Balimbing - 1 Ahon → Kan. Lazaan (St. Bartolome)	60.00	Cash	Paid	2026-04-14 12:16:56.602411	Regular	Regular Trip		09494439017
50	P260414-7027	4	7	Balimbing - 2 Ahon → Sil. Lazaan (Ilaya)	50.00	Cash	Paid	2026-04-14 12:31:15.196442	Regular	Regular Trip		09494439017
51	P260414-1941	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-14 12:32:00.066849	Regular	Regular Trip		09494439017
52	P260414-8398	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-14 12:32:46.520278	Regular	Regular Trip		09494439017
53	P260414-5408	4	7	Sil. Lazaan (Ilaya) → Balinacon	55.00	Cash	Paid	2026-04-14 12:42:53.469061	Regular	Regular Trip		09494439017
54	P260414-8119	4	7	Balimbing - 1 Ahon → Balimbing - 2 Ahon	20.00	Cash	Paid	2026-04-14 13:03:56.053546	Regular	Regular Trip		09494439017
55	P260414-4092	4	7	Balimbing - 1 Ahon → Balimbing - 2 Ahon	20.00	Cash	Paid	2026-04-14 13:32:31.854858	Regular	Regular Trip		09494439017
56	P260414-5733	4	7	Balimbing - 1 Ahon → Balinacon	20.00	Cash	Paid	2026-04-14 13:42:23.436609	Regular	Regular Trip		09494439017
57	P260414-6169	4	7	Balimbing - 2 Ahon → Kan. Lazaan (Barod)	50.00	Cash	Paid	2026-04-14 13:53:43.867377	Regular	Regular Trip		09494439017
58	P260414-7705	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-14 13:54:15.337889	Regular	Regular Trip		09494439017
59	P260414-6446	4	7	Balimbing - 1 Ahon → Balimbing - 2 Ahon	20.00	Cash	Paid	2026-04-14 14:02:24.029422	Regular	Regular Trip		09494439017
60	P260414-7969	4	7	Balimbing - 2 Ahon → Upland LMES (School)	25.00	Cash	Paid	2026-04-14 15:02:25.193668	Regular	Regular Trip		09494439017
61	P260414-5876	4	7	Balimbing - 1 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-14 15:50:12.812463	Regular	Regular Trip		09494439017
62	P260414-9604	4	7	Kan. Lazaan → Balinacon	40.00	Cash	Paid	2026-04-14 15:50:56.536238	Regular	Regular Trip		09494439017
63	P260414-1948	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-14 16:08:18.775514	Regular	Regular Trip		09494439017
64	P260414-0627	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-14 16:09:07.449587	Regular	Regular Trip		09494439017
65	P260414-8660	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-14 16:09:55.478991	Regular	Regular Trip		09494439017
66	P260414-0858	4	7	Balimbing - 2 Ahon → Balimbing - 1 Ahon	20.00	Cash	Paid	2026-04-14 16:22:57.6641	Regular	Regular Trip		09494439017
67	P260414-4015	4	7	Balinacon → Balimbing - 2 Ahon	25.00	Cash	Paid	2026-04-14 20:04:59.423497	Regular	Regular Trip		09494439017
68	P260414-2477	4	7	Balimbing - 2 Ahon → Malinao	20.00	Cash	Paid	2026-04-14 20:26:47.753933	Regular	Regular Trip		09494439017
69	P260415-7381	4	7	Balimbing - 1 Ahon → Balinacon	30.00	Cash	Paid	2026-04-15 08:24:58.350182	Regular	Special Trip		09494439017
70	P260415-4319	4	7	Balimbing - 1 Ahon → Sil. Lazaan (Ilaya)	50.00	Cash	Paid	2026-04-15 08:30:25.253515	Regular	Regular Trip		09494439017
71	P260415-7107	4	7	Balimbing - 2 Ahon → Upland LMES (School)	25.00	Cash	Paid	2026-04-15 08:37:18.001598	Regular	Regular Trip		09494439017
72	P260415-2077	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-15 10:17:42.367356	Regular	Regular Trip		09494439017
73	P260415-5881	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-15 10:21:06.151911	Regular	Regular Trip		09494439017
74	P260415-2415	4	7	Balimbing - 2 Ahon → Balinacon	20.00	Cash	Paid	2026-04-15 10:27:22.647496	Student	Regular Trip		09494439017
75	P260415-6974	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-15 10:32:27.176326	Regular	Regular Trip		09494439017
76	P260415-6940	4	7	Kan. Lazaan → Balimbing - 2 Ahon	35.00	Cash	Paid	2026-04-15 10:35:07.12651	Regular	Regular Trip		09494439017
77	P260415-4224	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-15 10:36:34.401894	Regular	Regular Trip		09494439017
78	P260415-1013	4	7	Balimbing - 2 Ahon → Malinao	20.00	Cash	Paid	2026-04-15 10:53:31.088447	Regular	Regular Trip		09494439017
79	P260415-1762	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-15 11:00:51.793592	Regular	Regular Trip		09494439017
80	P260415-1414	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	Paid	2026-04-15 11:02:11.437698	Regular	Regular Trip		09494439017
81	P260415-8000	4	7	Balimbing - 1 Ahon → Malinao	20.00	Cash	Paid	2026-04-15 11:36:47.820547	Regular	Regular Trip		09494439017
82	P260415-2272	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-15 11:37:52.081657	Regular	Regular Trip		09494439017
83	P260415-2036	4	7	Balimbing - 2 Ahon → Balinacon	20.00	Cash	Paid	2026-04-15 11:38:31.841955	Student	Regular Trip		09494439017
84	P260415-5154	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	Paid	2026-04-15 11:39:34.95335	Regular	Regular Trip		09494439017
\.


--
-- TOC entry 5162 (class 0 OID 25037)
-- Dependencies: 226
-- Data for Name: qr_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.qr_codes (id, driver_id, franchise, qr_id, status, issued_at) FROM stdin;
3	3	NVC-003C	QR-AES-NVC003C-2b8e	Active	2026-03-13 16:38:10.127763
4	4	NVC-004D	QR-AES-NVC004D-4c9a	Active	2026-03-13 16:38:10.127763
6	7	NVC-00F2	QR-AES-NVC00F2-f025	Active	2026-03-24 10:17:01.438038
2	2	NVC-002B	QR-AES-NVC002B-54bf	Active	2026-03-13 16:38:10.127763
5	5	NVC-005E	QR-AES-NVC005E-163e	Active	2026-03-13 16:38:10.127763
1	1	NVC-001A	QR-AES-NVC001A-22c2	Active	2026-03-13 16:38:10.127763
\.


--
-- TOC entry 5178 (class 0 OID 25216)
-- Dependencies: 242
-- Data for Name: ratings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ratings (id, passenger_id, driver_id, rating, created_at) FROM stdin;
1	4	7	5	2026-04-14 14:02:38.583776
2	4	7	5	2026-04-14 15:04:07.742866
3	4	7	5	2026-04-14 15:50:34.666568
4	4	7	5	2026-04-14 16:08:49.838226
5	4	7	5	2026-04-14 16:09:20.685724
6	4	7	5	2026-04-14 20:05:34.317111
7	4	7	5	2026-04-14 20:28:21.343797
8	4	7	5	2026-04-15 08:25:47.48666
9	4	7	5	2026-04-15 08:31:11.979897
10	4	7	5	2026-04-15 08:46:07.552745
11	4	7	5	2026-04-15 10:21:32.712814
12	4	7	5	2026-04-15 10:36:50.326323
13	4	7	5	2026-04-15 11:37:11.74806
\.


--
-- TOC entry 5176 (class 0 OID 25184)
-- Dependencies: 240
-- Data for Name: toda_stations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.toda_stations (id, name, lat, lng, logo, created_at, color) FROM stdin;
1	LP TODA	14.139550	121.414681		2026-03-25 15:56:22.745084	#3b82f6
\.


--
-- TOC entry 5170 (class 0 OID 25120)
-- Dependencies: 234
-- Data for Name: trip_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trip_logs (id, trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at, status, ended_at) FROM stdin;
68	P260415-4224	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	-479	2026-04-15 10:36:34.401894	completed	2026-04-15 10:36:42.11221
69	P260415-1013	4	7	Balimbing - 2 Ahon → Malinao	20.00	Cash	0	2026-04-15 10:53:31.088447	cancelled	2026-04-15 10:53:42.630477
70	P260415-1762	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	0	2026-04-15 11:00:51.793592	cancelled	2026-04-15 11:01:02.024111
71	P260415-1414	4	7	Balimbing - 2 Ahon → Kan. Lazaan	35.00	Cash	0	2026-04-15 11:02:11.437698	cancelled	2026-04-15 11:02:32.286298
72	P260415-8000	4	7	Balimbing - 1 Ahon → Malinao	20.00	Cash	-479	2026-04-15 11:36:47.820547	completed	2026-04-15 11:37:05.026907
73	P260415-2036	4	7	Balimbing - 2 Ahon → Balinacon	20.00	Cash	0	2026-04-15 11:38:31.841955	cancelled	2026-04-15 11:38:42.193622
74	P260415-5154	4	7	Balimbing - 2 Ahon → Balinacon	25.00	Cash	0	2026-04-15 11:39:34.95335	cancelled	2026-04-15 11:39:52.494779
\.


--
-- TOC entry 5158 (class 0 OID 24994)
-- Dependencies: 222
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, username, first_name, middle_name, last_name, phone_number, email, password_hash, status, created_at, profile_pic) FROM stdin;
1	maria	Maria	\N	Lopez	09123456789	maria@example.com	secret	Active	2026-03-13 16:38:10.127763	\N
3	kendricklamar	Maki		Lucido	09123456789	maki@gmail.com	123456	Active	2026-03-16 09:13:33.912015	\N
4	drew	Andrew		Cauyan	09123456789	andrew@wew.com	123456	Active	2026-03-16 14:25:33.885943	p_4_1773643119.jpg
2	jose	Jose	\N	Santos	09112223344	jose@example.com	secret	Active	2026-03-13 16:38:10.127763	\N
\.


--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 219
-- Name: admins_admin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admins_admin_id_seq', 2, false);


--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 235
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1377, true);


--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 231
-- Name: complaints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.complaints_id_seq', 30, true);


--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 223
-- Name: drivers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.drivers_id_seq', 7, true);


--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 227
-- Name: fare_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fare_matrix_id_seq', 655, true);


--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 237
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 2, true);


--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 229
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_id_seq', 84, true);


--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 225
-- Name: qr_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.qr_codes_id_seq', 6, true);


--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 241
-- Name: ratings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ratings_id_seq', 13, true);


--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 239
-- Name: toda_stations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.toda_stations_id_seq', 5, true);


--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 233
-- Name: trip_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.trip_logs_id_seq', 74, true);


--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 221
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 5, false);


--
-- TOC entry 4955 (class 2606 OID 24990)
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (admin_id);


--
-- TOC entry 4957 (class 2606 OID 24992)
-- Name: admins admins_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_username_key UNIQUE (username);


--
-- TOC entry 4991 (class 2606 OID 25154)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4983 (class 2606 OID 25106)
-- Name: complaints complaints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_pkey PRIMARY KEY (id);


--
-- TOC entry 4985 (class 2606 OID 25108)
-- Name: complaints complaints_report_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_report_code_key UNIQUE (report_code);


--
-- TOC entry 4963 (class 2606 OID 25033)
-- Name: drivers drivers_driver_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_driver_code_key UNIQUE (driver_code);


--
-- TOC entry 4965 (class 2606 OID 25035)
-- Name: drivers drivers_franchise_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_franchise_key UNIQUE (franchise);


--
-- TOC entry 4967 (class 2606 OID 25029)
-- Name: drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- TOC entry 4969 (class 2606 OID 25031)
-- Name: drivers drivers_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_username_key UNIQUE (username);


--
-- TOC entry 4975 (class 2606 OID 25068)
-- Name: fare_matrix fare_matrix_origin_destination_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_matrix
    ADD CONSTRAINT fare_matrix_origin_destination_key UNIQUE (origin, destination);


--
-- TOC entry 4977 (class 2606 OID 25066)
-- Name: fare_matrix fare_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_matrix
    ADD CONSTRAINT fare_matrix_pkey PRIMARY KEY (id);


--
-- TOC entry 4993 (class 2606 OID 25167)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4979 (class 2606 OID 25081)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- TOC entry 4981 (class 2606 OID 25083)
-- Name: payments payments_ref_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_ref_code_key UNIQUE (ref_code);


--
-- TOC entry 4971 (class 2606 OID 25047)
-- Name: qr_codes qr_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT qr_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 4973 (class 2606 OID 25049)
-- Name: qr_codes qr_codes_qr_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT qr_codes_qr_id_key UNIQUE (qr_id);


--
-- TOC entry 4998 (class 2606 OID 25225)
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (id);


--
-- TOC entry 4995 (class 2606 OID 25196)
-- Name: toda_stations toda_stations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.toda_stations
    ADD CONSTRAINT toda_stations_pkey PRIMARY KEY (id);


--
-- TOC entry 4987 (class 2606 OID 25128)
-- Name: trip_logs trip_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4989 (class 2606 OID 25130)
-- Name: trip_logs trip_logs_trip_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_trip_code_key UNIQUE (trip_code);


--
-- TOC entry 4959 (class 2606 OID 25008)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4961 (class 2606 OID 25010)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 4996 (class 1259 OID 25236)
-- Name: idx_ratings_driver_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ratings_driver_id ON public.ratings USING btree (driver_id);


--
-- TOC entry 5002 (class 2606 OID 25114)
-- Name: complaints complaints_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- TOC entry 5003 (class 2606 OID 25109)
-- Name: complaints complaints_passenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_passenger_id_fkey FOREIGN KEY (passenger_id) REFERENCES public.users(user_id);


--
-- TOC entry 5000 (class 2606 OID 25089)
-- Name: payments payments_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- TOC entry 5001 (class 2606 OID 25084)
-- Name: payments payments_passenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_passenger_id_fkey FOREIGN KEY (passenger_id) REFERENCES public.users(user_id);


--
-- TOC entry 4999 (class 2606 OID 25050)
-- Name: qr_codes qr_codes_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qr_codes
    ADD CONSTRAINT qr_codes_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE;


--
-- TOC entry 5006 (class 2606 OID 25231)
-- Name: ratings ratings_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- TOC entry 5007 (class 2606 OID 25226)
-- Name: ratings ratings_passenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_passenger_id_fkey FOREIGN KEY (passenger_id) REFERENCES public.users(user_id);


--
-- TOC entry 5004 (class 2606 OID 25136)
-- Name: trip_logs trip_logs_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- TOC entry 5005 (class 2606 OID 25131)
-- Name: trip_logs trip_logs_passenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_logs
    ADD CONSTRAINT trip_logs_passenger_id_fkey FOREIGN KEY (passenger_id) REFERENCES public.users(user_id);


-- Completed on 2026-04-15 11:50:07

--
-- PostgreSQL database dump complete
--

\unrestrict VM27KyYq7yzYwhEc4WAjvDr43AkZ5TIZa2cPBYd116d3XaYazSNpDOxSdkE9zRG

