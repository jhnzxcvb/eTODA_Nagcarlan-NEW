package controllers

import (
	"fmt"
	"net/http"
	"time"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Payments lists all payment records.
func Payments(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	rows, err := DB.Query(`
		SELECT
			py.id, py.ref_code,
			COALESCE(p.first_name||' '||COALESCE(p.middle_name,'')||' '||p.last_name,'—'),
			COALESCE(d.first_name||' '||d.last_name,'—'),
			COALESCE(py.route,''),
			py.amount, py.method, py.status,
			to_char(py.paid_at,'YYYY-MM-DD HH24:MI'),
			COALESCE(py.passenger_type,''),
			COALESCE(py.trip_type,''),
			COALESCE(py.ewallet_account,''),
			COALESCE(py.contact_number,'')
		FROM payments py
		LEFT JOIN users p ON py.passenger_id = p.user_id
		LEFT JOIN drivers d ON py.driver_id = d.id
		ORDER BY py.id DESC`)
	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()

	list := []models.Payment{}
	for rows.Next() {
		var p models.Payment
		rows.Scan(
			&p.ID, &p.RefCode, &p.PassengerName, &p.DriverName,
			&p.Route, &p.Amount, &p.Method, &p.Status, &p.PaidAt,
			&p.PassengerType, &p.TripType, &p.EwalletAccount, &p.ContactNumber,
		)
		list = append(list, p)
	}
	if list == nil {
		list = []models.Payment{}
	}
	utils.JSONOK(w, list)
}

// CreatePayment records a new payment submitted from the Flutter passenger app.
func CreatePayment(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var b struct {
		PassengerID    int     `json:"passenger_id"`
		DriverID       int     `json:"driver_id"`
		Route          string  `json:"route"`
		Amount         float64 `json:"amount"`
		Method         string  `json:"method"`
		PassengerType  string  `json:"passenger_type"`
		TripType       string  `json:"trip_type"`
		EwalletAccount string  `json:"ewallet_account"`
		ContactNumber  string  `json:"contact_number"`
		PassengerName  string  `json:"passenger_name"` // Received but redundant if using ID joins
		DriverName     string  `json:"driver_name"`    // Received but redundant
		Status         string  `json:"status"`
	}

	if err := utils.Decode(r, &b); err != nil {
		utils.JSONErr(w, "Invalid request body", 400)
		return
	}

	// Validate required fields
	if b.PassengerID == 0 || b.DriverID == 0 {
		utils.JSONErr(w, "passenger_id and driver_id are required", 400)
		return
	}
	if b.Amount <= 0 {
		utils.JSONErr(w, "amount must be greater than zero", 400)
		return
	}
	if b.Method == "" {
		utils.JSONErr(w, "method is required", 400)
		return
	}
	if b.Status == "" {
		b.Status = "Paid"
	}

	// Generate unique ref code: PYYMMDD-Tail (Shortened to fit VARCHAR(15) columns)
	now := time.Now()
	ref := fmt.Sprintf("P%s-%04d",
		now.Format("060102"),
		now.UnixMilli()%9999,
	)

	var id int
	err := DB.QueryRow(`
		INSERT INTO payments
			(ref_code, passenger_id, driver_id, route, amount, method,
			 passenger_type, trip_type, ewallet_account, contact_number,
			 status, paid_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
		RETURNING id`,
		ref,
		b.PassengerID,
		b.DriverID,
		b.Route,
		b.Amount,
		b.Method,
		b.PassengerType,
		b.TripType,
		b.EwalletAccount,
		b.ContactNumber,
		b.Status,
	).Scan(&id)

	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}

	utils.LogAudit(DB, "INSERT", "Payment", ref,
		fmt.Sprintf("₱%.2f via %s | Passenger:%d Driver:%d",
			b.Amount, b.Method, b.PassengerID, b.DriverID))

	utils.JSONOK(w, map[string]interface{}{
		"id":       id,
		"ref_code": ref,
	})
}

// PaymentByID updates payment status (PATCH /api/payments/:id).
func PaymentByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	id := utils.PathID(r.URL.Path, "/api/payments/")
	var b struct {
		Status string `json:"status"`
	}
	utils.Decode(r, &b)
	var ref string
	DB.QueryRow("SELECT ref_code FROM payments WHERE id=$1", id).Scan(&ref)
	DB.Exec("UPDATE payments SET status=$1 WHERE id=$2", b.Status, id)
	utils.LogAudit(DB, "UPDATE", "Payment", ref, fmt.Sprintf("Status → %s", b.Status))
	utils.JSONOK(w, map[string]string{"message": "Updated"})
}
