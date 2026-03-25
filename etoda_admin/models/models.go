package models

// Shared data types used across the admin API

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

// Admin represents an administrator account for the web portal.
type Admin struct {
	AdminID  int    `json:"admin_id"`
	Username string `json:"username"`
	FullName string `json:"full_name"`
	Email    string `json:"email"`
}

// AdminDriver represents a driver record shown in the admin panel.
type AdminDriver struct {
	ID          int    `json:"id"`
	Code        string `json:"driver_code"`
	FirstName   string `json:"first_name"`
	MiddleName  string `json:"middle_name"`
	LastName    string `json:"last_name"`
	Franchise   string `json:"franchise"`
	BodyNo      string `json:"body_no"`
	Contact     string `json:"contact"`
	LicenseNo   string `json:"license_no"`
	Association string `json:"association"`
	PlateNumber string `json:"plate_number"`
	Status      string `json:"status"`
	Username    string `json:"username"`
	QRId        string `json:"qr_id"`
	QRStatus    string `json:"qr_status"`
	CreatedAt   string `json:"created_at"`
	HasPassword bool   `json:"has_password"`
}

type Passenger struct {
	ID           int    `json:"id"`
	Username     string `json:"username"`
	Name         string `json:"name"`
	Email        string `json:"email"`
	Contact      string `json:"contact"`
	SessionType  string `json:"session_type"`
	Status       string `json:"status"`
	RegisteredAt string `json:"registered_at"`
}

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

type QRCode struct {
	ID         int    `json:"id"`
	Franchise  string `json:"franchise"`
	DriverName string `json:"driver_name"`
	QRId       string `json:"qr_id"`
	Status     string `json:"status"`
	IssuedAt   string `json:"issued_at"`
}

// Complaint matches your PostgreSQL 'complaints' table
type Complaint struct {
	ID            int    `json:"id"`
	Code          string `json:"report_code"`
	PassengerName string `json:"passenger_name"`
	DriverName    string `json:"driver_name"`
	Franchise     string `json:"franchise"`
	Violation     string `json:"violation_type"`
	Details       string `json:"details"`
	AdminNotes    string `json:"admin_notes"`
	Status        string `json:"status"`
	ReportedAt    string `json:"reported_at"`
}

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

type AuditLog struct {
	ID          int    `json:"id"`
	Action      string `json:"action"`
	Entity      string `json:"entity"`
	EntityID    string `json:"entity_id"`
	Detail      string `json:"detail"`
	PerformedBy string `json:"performed_by"`
	CreatedAt   string `json:"created_at"`
}
