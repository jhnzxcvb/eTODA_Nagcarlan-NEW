package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

var db *sql.DB

func main() {
	connStr := fmt.Sprintf(
		"host=%s port=%s dbname=%s user=%s password=%s sslmode=disable",
		env("DB_HOST", "localhost"), env("DB_PORT", "5432"),
		env("DB_NAME", "etoda_db"), env("DB_USER", "postgres"),
		env("DB_PASSWORD", "postgres"),
	)
	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("DB open error:", err)
	}
	if err = db.Ping(); err != nil {
		log.Fatal("❌ Cannot connect to PostgreSQL:", err)
	}
	fmt.Println("✅ Connected to PostgreSQL")

	mux := http.NewServeMux()

	// Dashboard
	mux.HandleFunc("/api/dashboard", cors(dashboard))

	// Drivers
	mux.HandleFunc("/api/drivers", cors(drivers))
	mux.HandleFunc("/api/drivers/", cors(driverByID))

	// Passengers
	mux.HandleFunc("/api/passengers", cors(passengers))
	mux.HandleFunc("/api/passengers/", cors(passengerByID))

	// Fare Matrix
	mux.HandleFunc("/api/fare", cors(fare))
	mux.HandleFunc("/api/fare/", cors(fareByID))

	// Payments
	mux.HandleFunc("/api/payments", cors(payments))
	mux.HandleFunc("/api/payments/", cors(paymentByID))

	// QR Codes
	mux.HandleFunc("/api/qrcodes", cors(qrcodes))
	mux.HandleFunc("/api/qrcodes/", cors(qrcodeByID))

	// Complaints
	mux.HandleFunc("/api/complaints", cors(complaints))
	mux.HandleFunc("/api/complaints/", cors(complaintByID))

	// Trips
	mux.HandleFunc("/api/trips", cors(trips))

	// Audit Trail
	mux.HandleFunc("/api/audit", cors(auditTrail))

	port := env("PORT", "8080")
	fmt.Println("🚀 Server running on http://localhost:" + port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}

// ── HELPERS ──────────────────────────────────────────────────────

func env(k, d string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return d
}

func cors(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == "OPTIONS" {
			w.WriteHeader(204)
			return
		}
		h(w, r)
	}
}

func jsonOK(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "data": data})
}

func jsonErr(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "error": msg})
}

func decode(r *http.Request, v interface{}) error {
	return json.NewDecoder(r.Body).Decode(v)
}

func pathID(path, prefix string) string {
	return strings.TrimPrefix(path, prefix)
}

func randHex() string {
	const h = "abcdef0123456789"
	b := make([]byte, 4)
	for i := range b {
		b[i] = h[rand.Intn(len(h))]
	}
	return string(b)
}

func logAudit(action, entity, entityID, detail string) {
	db.Exec(
		`INSERT INTO audit_logs (action, entity, entity_id, detail, performed_by, created_at) VALUES ($1,$2,$3,$4,'Admin',NOW())`,
		action, entity, entityID, detail,
	)
}

// ── DASHBOARD ────────────────────────────────────────────────────

func dashboard(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	type Stats struct {
		ActiveDrivers     int     `json:"active_drivers"`
		Passengers        int     `json:"passengers"`
		RevenueToday      float64 `json:"revenue_today"`
		PendingComplaints int     `json:"pending_complaints"`
		TripsToday        int     `json:"trips_today"`
		TotalDrivers      int     `json:"total_drivers"`
		TotalTrips        int     `json:"total_trips"`
		ActiveQR          int     `json:"active_qr"`
	}
	var s Stats
	db.QueryRow(`SELECT COUNT(*) FROM drivers WHERE status='Active'`).Scan(&s.ActiveDrivers)
	db.QueryRow(`SELECT COUNT(*) FROM drivers`).Scan(&s.TotalDrivers)
	db.QueryRow(`SELECT COUNT(*) FROM passengers`).Scan(&s.Passengers)
	db.QueryRow(`SELECT COALESCE(SUM(amount),0) FROM payments WHERE status='Settled' AND paid_at::date=CURRENT_DATE`).Scan(&s.RevenueToday)
	db.QueryRow(`SELECT COUNT(*) FROM complaints WHERE status!='Resolved'`).Scan(&s.PendingComplaints)
	db.QueryRow(`SELECT COUNT(*) FROM trip_logs WHERE started_at::date=CURRENT_DATE`).Scan(&s.TripsToday)
	db.QueryRow(`SELECT COUNT(*) FROM trip_logs`).Scan(&s.TotalTrips)
	db.QueryRow(`SELECT COUNT(*) FROM qr_codes WHERE status='Active'`).Scan(&s.ActiveQR)
	jsonOK(w, s)
}

// ── DRIVERS ──────────────────────────────────────────────────────

type Driver struct {
	ID          int    `json:"id"`
	Code        string `json:"driver_code"`
	Name        string `json:"name"`
	Franchise   string `json:"franchise"`
	BodyNo      string `json:"body_no"`
	Contact     string `json:"contact"`
	LicenseNo   string `json:"license_no"`
	Association string `json:"association"`
	Status      string `json:"status"`
	QRId        string `json:"qr_id"`
	CreatedAt   string `json:"created_at"`
}

func fetchDrivers(search string) ([]Driver, error) {
	q := `SELECT d.id,d.driver_code,d.name,d.franchise,
		COALESCE(d.body_no,''),COALESCE(d.contact,''),
		COALESCE(d.license_no,''),COALESCE(d.association,''),
		d.status,COALESCE(qr.qr_id,''),
		to_char(d.created_at,'YYYY-MM-DD')
		FROM drivers d LEFT JOIN qr_codes qr ON d.id=qr.driver_id WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += ` AND (d.name ILIKE $1 OR d.franchise ILIKE $1 OR d.driver_code ILIKE $1)`
	}
	q += " ORDER BY d.id"
	rows, err := db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Driver{}
	for rows.Next() {
		var d Driver
		rows.Scan(&d.ID, &d.Code, &d.Name, &d.Franchise, &d.BodyNo, &d.Contact, &d.LicenseNo, &d.Association, &d.Status, &d.QRId, &d.CreatedAt)
		list = append(list, d)
	}
	return list, nil
}

func drivers(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		list, err := fetchDrivers(r.URL.Query().Get("search"))
		if err != nil {
			jsonErr(w, err.Error(), 500)
			return
		}
		if list == nil {
			list = []Driver{}
		}
		jsonOK(w, list)

	case "POST":
		var b struct {
			Name        string `json:"name"`
			Franchise   string `json:"franchise"`
			BodyNo      string `json:"body_no"`
			Contact     string `json:"contact"`
			LicenseNo   string `json:"license_no"`
			Association string `json:"association"`
		}
		if err := decode(r, &b); err != nil {
			jsonErr(w, "Invalid JSON", 400)
			return
		}
		if strings.TrimSpace(b.Name) == "" || strings.TrimSpace(b.Franchise) == "" {
			jsonErr(w, "Name and Franchise are required", 400)
			return
		}
		if b.Association == "" {
			b.Association = "Nagcarlan TODA"
		}
		var cnt int
		db.QueryRow("SELECT COUNT(*) FROM drivers").Scan(&cnt)
		code := fmt.Sprintf("D-%03d", cnt+1)

		var dID int
		err := db.QueryRow(
			`INSERT INTO drivers(driver_code,name,franchise,body_no,contact,license_no,association,status)
			 VALUES($1,$2,$3,$4,$5,$6,$7,'Active') RETURNING id`,
			code, b.Name, b.Franchise, b.BodyNo, b.Contact, b.LicenseNo, b.Association,
		).Scan(&dID)
		if err != nil {
			jsonErr(w, err.Error(), 500)
			return
		}
		qrID := fmt.Sprintf("QR-AES-%s-%s", strings.ReplaceAll(b.Franchise, "-", ""), randHex())
		db.Exec(`INSERT INTO qr_codes(driver_id,franchise,qr_id,status) VALUES($1,$2,$3,'Active')`, dID, b.Franchise, qrID)

		logAudit("ENROLL", "Driver", code, fmt.Sprintf("Enrolled %s (%s)", b.Name, b.Franchise))

		var d Driver
		db.QueryRow(`SELECT d.id,d.driver_code,d.name,d.franchise,
			COALESCE(d.body_no,''),COALESCE(d.contact,''),COALESCE(d.license_no,''),
			COALESCE(d.association,''),d.status,COALESCE(qr.qr_id,''),
			to_char(d.created_at,'YYYY-MM-DD')
			FROM drivers d LEFT JOIN qr_codes qr ON d.id=qr.driver_id WHERE d.id=$1`, dID).
			Scan(&d.ID, &d.Code, &d.Name, &d.Franchise, &d.BodyNo, &d.Contact, &d.LicenseNo, &d.Association, &d.Status, &d.QRId, &d.CreatedAt)

		w.WriteHeader(201)
		jsonOK(w, d)

	default:
		jsonErr(w, "Method not allowed", 405)
	}
}

func driverByID(w http.ResponseWriter, r *http.Request) {
	id := pathID(r.URL.Path, "/api/drivers/")
	switch r.Method {
	case "PATCH":
		var b map[string]string
		decode(r, &b)
		sets, args := []string{}, []interface{}{}
		for _, f := range []string{"name", "franchise", "body_no", "contact", "license_no", "association", "status"} {
			if v, ok := b[f]; ok {
				args = append(args, v)
				sets = append(sets, fmt.Sprintf("%s=$%d", f, len(args)))
			}
		}
		if len(sets) == 0 {
			jsonErr(w, "Nothing to update", 400)
			return
		}
		args = append(args, id)
		db.Exec(fmt.Sprintf("UPDATE drivers SET %s WHERE id=$%d", strings.Join(sets, ","), len(args)), args...)
		logAudit("UPDATE", "Driver", id, fmt.Sprintf("Updated fields: %s", strings.Join(sets, ", ")))
		jsonOK(w, map[string]string{"message": "Updated"})

	case "DELETE":
		var name, code string
		db.QueryRow("SELECT name,driver_code FROM drivers WHERE id=$1", id).Scan(&name, &code)
		db.Exec("DELETE FROM drivers WHERE id=$1", id)
		logAudit("DELETE", "Driver", code, fmt.Sprintf("Removed driver %s", name))
		jsonOK(w, map[string]string{"message": name + " removed"})

	default:
		jsonErr(w, "Method not allowed", 405)
	}
}

// ── PASSENGERS ───────────────────────────────────────────────────

type Passenger struct {
	ID           int    `json:"id"`
	Code         string `json:"passenger_code"`
	Name         string `json:"name"`
	Email        string `json:"email"`
	SessionType  string `json:"session_type"`
	Status       string `json:"status"`
	RegisteredAt string `json:"registered_at"`
}

func passengers(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	search := r.URL.Query().Get("search")
	q := `SELECT id,passenger_code,COALESCE(name,''),COALESCE(email,''),session_type,status,to_char(registered_at,'YYYY-MM-DD') FROM passengers WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += ` AND (name ILIKE $1 OR email ILIKE $1 OR passenger_code ILIKE $1)`
	}
	q += " ORDER BY id"
	rows, _ := db.Query(q, args...)
	defer rows.Close()
	list := []Passenger{}
	for rows.Next() {
		var p Passenger
		rows.Scan(&p.ID, &p.Code, &p.Name, &p.Email, &p.SessionType, &p.Status, &p.RegisteredAt)
		list = append(list, p)
	}
	if list == nil {
		list = []Passenger{}
	}
	jsonOK(w, list)
}

func passengerByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	id := pathID(r.URL.Path, "/api/passengers/")
	var b struct{ Status string `json:"status"` }
	decode(r, &b)
	var name string
	db.QueryRow("SELECT COALESCE(name,'Guest') FROM passengers WHERE id=$1", id).Scan(&name)
	db.Exec("UPDATE passengers SET status=$1 WHERE id=$2", b.Status, id)
	logAudit("UPDATE", "Passenger", id, fmt.Sprintf("%s status → %s", name, b.Status))
	jsonOK(w, map[string]string{"message": "Updated"})
}

// ── FARE MATRIX ──────────────────────────────────────────────────

type Fare struct {
	ID             int     `json:"id"`
	Origin         string  `json:"origin"`
	Destination    string  `json:"destination"`
	BaseFare       float64 `json:"base_fare"`
	DiscountedFare float64 `json:"discounted_fare"`
	NightFare      float64 `json:"night_fare"`
	SpecialFare    float64 `json:"special_fare"`
	CreatedAt      string  `json:"created_at"`
}

func fare(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		rows, _ := db.Query("SELECT id,origin,destination,base_fare,discounted_fare,night_fare,special_fare,to_char(created_at,'YYYY-MM-DD') FROM fare_matrix ORDER BY id")
		defer rows.Close()
		list := []Fare{}
		for rows.Next() {
			var f Fare
			rows.Scan(&f.ID, &f.Origin, &f.Destination, &f.BaseFare, &f.DiscountedFare, &f.NightFare, &f.SpecialFare, &f.CreatedAt)
			list = append(list, f)
		}
		if list == nil {
			list = []Fare{}
		}
		jsonOK(w, list)

	case "POST":
		var b struct {
			Origin      string  `json:"origin"`
			Destination string  `json:"destination"`
			BaseFare    float64 `json:"base_fare"`
		}
		decode(r, &b)
		if b.Origin == "" || b.Destination == "" || b.BaseFare == 0 {
			jsonErr(w, "All fields required", 400)
			return
		}
		var f Fare
		err := db.QueryRow(
			`INSERT INTO fare_matrix(origin,destination,base_fare,discounted_fare,night_fare,special_fare)
			 VALUES($1,$2,$3,$4,$5,$6)
			 ON CONFLICT(origin,destination) DO UPDATE SET
			   base_fare=EXCLUDED.base_fare,discounted_fare=EXCLUDED.discounted_fare,
			   night_fare=EXCLUDED.night_fare,special_fare=EXCLUDED.special_fare
			 RETURNING id,origin,destination,base_fare,discounted_fare,night_fare,special_fare,to_char(created_at,'YYYY-MM-DD')`,
			b.Origin, b.Destination, b.BaseFare,
			b.BaseFare*0.8, b.BaseFare*1.15, b.BaseFare*3,
		).Scan(&f.ID, &f.Origin, &f.Destination, &f.BaseFare, &f.DiscountedFare, &f.NightFare, &f.SpecialFare, &f.CreatedAt)
		if err != nil {
			jsonErr(w, err.Error(), 500)
			return
		}
		logAudit("CREATE", "Fare", fmt.Sprintf("%d", f.ID), fmt.Sprintf("%s → %s base ₱%.2f", b.Origin, b.Destination, b.BaseFare))
		w.WriteHeader(201)
		jsonOK(w, f)

	default:
		jsonErr(w, "Method not allowed", 405)
	}
}

func fareByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "DELETE" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	id := pathID(r.URL.Path, "/api/fare/")
	var origin, dest string
	db.QueryRow("SELECT origin,destination FROM fare_matrix WHERE id=$1", id).Scan(&origin, &dest)
	db.Exec("DELETE FROM fare_matrix WHERE id=$1", id)
	logAudit("DELETE", "Fare", id, fmt.Sprintf("Deleted %s → %s", origin, dest))
	jsonOK(w, map[string]string{"message": "Deleted"})
}

// ── PAYMENTS ─────────────────────────────────────────────────────

type Payment struct {
	ID            int     `json:"id"`
	RefCode       string  `json:"ref_code"`
	PassengerName string  `json:"passenger_name"`
	DriverName    string  `json:"driver_name"`
	Route         string  `json:"route"`
	Amount        float64 `json:"amount"`
	Method        string  `json:"method"`
	Status        string  `json:"status"`
	PaidAt        string  `json:"paid_at"`
}

func payments(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	rows, err := db.Query(`
		SELECT py.id,py.ref_code,
		COALESCE(p.name,'—'),COALESCE(d.name,'—'),
		COALESCE(py.route,''),py.amount,py.method,py.status,
		to_char(py.paid_at,'YYYY-MM-DD HH24:MI')
		FROM payments py
		LEFT JOIN passengers p ON py.passenger_id=p.id
		LEFT JOIN drivers d ON py.driver_id=d.id
		ORDER BY py.id DESC`)
	if err != nil {
		jsonErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()
	list := []Payment{}
	for rows.Next() {
		var p Payment
		rows.Scan(&p.ID, &p.RefCode, &p.PassengerName, &p.DriverName, &p.Route, &p.Amount, &p.Method, &p.Status, &p.PaidAt)
		list = append(list, p)
	}
	if list == nil {
		list = []Payment{}
	}
	jsonOK(w, list)
}

func paymentByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	id := pathID(r.URL.Path, "/api/payments/")
	var b struct{ Status string `json:"status"` }
	decode(r, &b)
	var ref string
	db.QueryRow("SELECT ref_code FROM payments WHERE id=$1", id).Scan(&ref)
	db.Exec("UPDATE payments SET status=$1 WHERE id=$2", b.Status, id)
	logAudit("UPDATE", "Payment", ref, fmt.Sprintf("Status → %s", b.Status))
	jsonOK(w, map[string]string{"message": "Updated"})
}

// ── QR CODES ─────────────────────────────────────────────────────

type QRCode struct {
	ID         int    `json:"id"`
	Franchise  string `json:"franchise"`
	DriverName string `json:"driver_name"`
	QRId       string `json:"qr_id"`
	Status     string `json:"status"`
	IssuedAt   string `json:"issued_at"`
}

func qrcodes(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	rows, _ := db.Query(`
		SELECT q.id,q.franchise,COALESCE(d.name,'—'),q.qr_id,q.status,
		to_char(q.issued_at,'YYYY-MM-DD')
		FROM qr_codes q LEFT JOIN drivers d ON q.driver_id=d.id
		ORDER BY q.id`)
	defer rows.Close()
	list := []QRCode{}
	for rows.Next() {
		var q QRCode
		rows.Scan(&q.ID, &q.Franchise, &q.DriverName, &q.QRId, &q.Status, &q.IssuedAt)
		list = append(list, q)
	}
	if list == nil {
		list = []QRCode{}
	}
	jsonOK(w, list)
}

func qrcodeByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	id := pathID(r.URL.Path, "/api/qrcodes/")
	var b struct{ Status string `json:"status"` }
	decode(r, &b)
	var franchise string
	db.QueryRow("SELECT franchise FROM qr_codes WHERE id=$1", id).Scan(&franchise)
	if b.Status == "Active" {
		newQR := fmt.Sprintf("QR-AES-%s-%s", strings.ReplaceAll(franchise, "-", ""), randHex())
		db.Exec("UPDATE qr_codes SET status=$1,qr_id=$2 WHERE id=$3", b.Status, newQR, id)
		logAudit("RESTORE", "QRCode", franchise, "QR regenerated with new AES key")
	} else {
		db.Exec("UPDATE qr_codes SET status=$1 WHERE id=$2", b.Status, id)
		logAudit("REVOKE", "QRCode", franchise, fmt.Sprintf("QR status → %s", b.Status))
	}
	jsonOK(w, map[string]string{"message": "Updated"})
}

// ── COMPLAINTS ───────────────────────────────────────────────────

type Complaint struct {
	ID            int    `json:"id"`
	Code          string `json:"report_code"`
	PassengerName string `json:"passenger_name"`
	DriverName    string `json:"driver_name"`
	Franchise     string `json:"franchise"`
	Violation     string `json:"violation_type"`
	FirebaseID    string `json:"firebase_id"`
	AdminNotes    string `json:"admin_notes"`
	Status        string `json:"status"`
	ReportedAt    string `json:"reported_at"`
}

func complaints(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	rows, _ := db.Query(`
		SELECT c.id,c.report_code,
		COALESCE(p.name,'—'),COALESCE(d.name,'—'),COALESCE(d.franchise,'—'),
		COALESCE(c.violation_type,''),COALESCE(c.firebase_id,''),
		COALESCE(c.admin_notes,''),c.status,
		to_char(c.reported_at,'YYYY-MM-DD')
		FROM complaints c
		LEFT JOIN passengers p ON c.passenger_id=p.id
		LEFT JOIN drivers d ON c.driver_id=d.id
		ORDER BY c.id DESC`)
	defer rows.Close()
	list := []Complaint{}
	for rows.Next() {
		var c Complaint
		rows.Scan(&c.ID, &c.Code, &c.PassengerName, &c.DriverName, &c.Franchise, &c.Violation, &c.FirebaseID, &c.AdminNotes, &c.Status, &c.ReportedAt)
		list = append(list, c)
	}
	if list == nil {
		list = []Complaint{}
	}
	jsonOK(w, list)
}

func complaintByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	id := pathID(r.URL.Path, "/api/complaints/")
	var b struct {
		Status     string `json:"status"`
		AdminNotes string `json:"admin_notes"`
	}
	decode(r, &b)
	var code string
	db.QueryRow("SELECT report_code FROM complaints WHERE id=$1", id).Scan(&code)
	if b.Status == "Resolved" {
		db.Exec("UPDATE complaints SET status=$1,admin_notes=COALESCE(NULLIF($2,''),admin_notes),resolved_at=NOW() WHERE id=$3", b.Status, b.AdminNotes, id)
	} else {
		db.Exec("UPDATE complaints SET status=$1,admin_notes=COALESCE(NULLIF($2,''),admin_notes) WHERE id=$3", b.Status, b.AdminNotes, id)
	}
	logAudit("UPDATE", "Complaint", code, fmt.Sprintf("Status → %s", b.Status))
	jsonOK(w, map[string]string{"message": "Updated"})
}

// ── TRIPS ────────────────────────────────────────────────────────

type Trip struct {
	ID            int     `json:"id"`
	TripCode      string  `json:"trip_code"`
	PassengerName string  `json:"passenger_name"`
	DriverName    string  `json:"driver_name"`
	DriverContact string  `json:"driver_contact"`
	Route         string  `json:"route"`
	FareAmount    float64 `json:"fare_amount"`
	Method        string  `json:"payment_method"`
	DurationMin   int     `json:"duration_min"`
	StartedAt     string  `json:"started_at"`
}

func trips(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	search := r.URL.Query().Get("search")
	q := `SELECT t.id,t.trip_code,
		COALESCE(p.name,'—'),COALESCE(d.name,'—'),COALESCE(d.contact,'—'),
		COALESCE(t.route,''),t.fare_amount,COALESCE(t.payment_method,''),
		t.duration_min,to_char(t.started_at,'YYYY-MM-DD')
		FROM trip_logs t
		LEFT JOIN passengers p ON t.passenger_id=p.id
		LEFT JOIN drivers d ON t.driver_id=d.id
		WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += ` AND (p.name ILIKE $1 OR d.name ILIKE $1 OR t.route ILIKE $1 OR t.trip_code ILIKE $1)`
	}
	q += " ORDER BY t.id DESC"
	rows, err := db.Query(q, args...)
	if err != nil {
		jsonErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()
	list := []Trip{}
	for rows.Next() {
		var t Trip
		rows.Scan(&t.ID, &t.TripCode, &t.PassengerName, &t.DriverName, &t.DriverContact, &t.Route, &t.FareAmount, &t.Method, &t.DurationMin, &t.StartedAt)
		list = append(list, t)
	}
	if list == nil {
		list = []Trip{}
	}
	jsonOK(w, list)
}

// ── AUDIT TRAIL ──────────────────────────────────────────────────

type AuditLog struct {
	ID          int    `json:"id"`
	Action      string `json:"action"`
	Entity      string `json:"entity"`
	EntityID    string `json:"entity_id"`
	Detail      string `json:"detail"`
	PerformedBy string `json:"performed_by"`
	CreatedAt   string `json:"created_at"`
}

func auditTrail(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		jsonErr(w, "Method not allowed", 405)
		return
	}
	search := r.URL.Query().Get("search")
	entity := r.URL.Query().Get("entity")
	q := `SELECT id,action,entity,entity_id,detail,performed_by,to_char(created_at,'YYYY-MM-DD HH24:MI:SS') FROM audit_logs WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += fmt.Sprintf(` AND (detail ILIKE $%d OR entity_id ILIKE $%d OR performed_by ILIKE $%d)`, len(args), len(args), len(args))
	}
	if entity != "" && entity != "All" {
		args = append(args, entity)
		q += fmt.Sprintf(` AND entity=$%d`, len(args))
	}
	q += " ORDER BY id DESC LIMIT 200"
	rows, err := db.Query(q, args...)
	if err != nil {
		jsonErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()
	list := []AuditLog{}
	for rows.Next() {
		var a AuditLog
		rows.Scan(&a.ID, &a.Action, &a.Entity, &a.EntityID, &a.Detail, &a.PerformedBy, &a.CreatedAt)
		list = append(list, a)
	}
	if list == nil {
		list = []AuditLog{}
	}
	jsonOK(w, list)
}

// suppress unused import
var _ = time.Now
