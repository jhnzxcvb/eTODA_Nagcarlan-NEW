package controllers

import (
	"database/sql"
	"etoda_admin/utils"
	"net/http"
	"strconv"
	"time"
)

// Trips handles the /api/trips endpoint, serving trip history for both admin and users.
func Trips(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	// If passenger_id is provided, filter results for the mobile app's history view.
	passengerID := r.URL.Query().Get("passenger_id")
	driverID := r.URL.Query().Get("driver_id")

	baseQuery := `
		SELECT 
			t.trip_code, 
			COALESCE(u.first_name || ' ' || u.last_name, 'Guest') as p_name,
			COALESCE(d.first_name || ' ' || d.last_name, 'Driver') as d_name,
			COALESCE(d.contact, '—') as d_contact,
			COALESCE(d.plate_number, '—') as d_plate,
			COALESCE(d.body_no, '—') as d_body,
			COALESCE(t.route, '—') as route,
			t.fare_amount, 
			t.payment_method, 
			t.status,
			to_char(t.started_at, 'YYYY-MM-DD HH24:MI') as started_at,
			COALESCE(t.duration_min, 0) as duration
		FROM trip_logs t
		LEFT JOIN users u ON t.passenger_id = u.user_id
		LEFT JOIN drivers d ON t.driver_id = d.id`

	var rows *sql.Rows
	var err error
	if passengerID != "" {
		rows, err = DB.Query(baseQuery+" WHERE t.passenger_id = $1 ORDER BY t.id DESC", passengerID)
	} else if driverID != "" {
		rows, err = DB.Query(baseQuery+" WHERE t.driver_id = $1 ORDER BY t.id DESC", driverID)
	} else {
		rows, err = DB.Query(baseQuery + " ORDER BY t.id DESC")
	}

	if err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}
	defer rows.Close()

	// We use a map to match the specific keys expected by the Admin dashboard React code.
	list := []map[string]interface{}{}
	for rows.Next() {
		var code, pName, dName, contact, plate, body, route, method, status, date string
		var amount float64
		var duration int
		if err := rows.Scan(&code, &pName, &dName, &contact, &plate, &body, &route, &amount, &method, &status, &date, &duration); err != nil {
			continue
		}

		list = append(list, map[string]interface{}{
			"trip_code":      code,
			"passenger_name": pName,
			"driver_name":    dName,
			"driver_contact": contact,
			"plate_number":   plate,
			"body_no":        body,
			"route":          route,
			"fare_amount":    amount,
			"payment_method": method,
			"status":         status,
			"duration_min":   duration,
			"started_at":     date,
		})
	}

	if err := rows.Err(); err != nil {
		utils.JSONErr(w, "Error iterating rows: "+err.Error(), 500)
		return
	}

	if list == nil {
		list = []map[string]interface{}{}
	}
	utils.JSONOK(w, list)
}

// ActiveTrip checks if a driver has a trip that just started (real-time detection)
func ActiveTrip(w http.ResponseWriter, r *http.Request) {
	driverID := r.URL.Query().Get("driver_id")
	if driverID == "" {
		utils.JSONErr(w, "driver_id required", 400)
		return
	}

	query := `
		SELECT 
			p.ref_code, 
			COALESCE(u.first_name || ' ' || u.last_name, 'Guest'),
			COALESCE(p.route, '—'),
			p.amount, 
			p.method
		FROM payments p
		LEFT JOIN users u ON p.passenger_id = u.user_id
		WHERE p.driver_id = $1 
		AND NOT EXISTS (SELECT 1 FROM trip_logs tl WHERE tl.trip_code = p.ref_code)
		ORDER BY p.id DESC LIMIT 1`

	var t struct {
		Code, Passenger, Route, Method string
		Amount                         float64
		Duration                       int
	}

	err := DB.QueryRow(query, driverID).Scan(&t.Code, &t.Passenger, &t.Route, &t.Amount, &t.Method)
	if err != nil {
		utils.JSONOK(w, nil) // Return null if no active trip
		return
	}

	utils.JSONOK(w, map[string]interface{}{
		"trip_code":      t.Code,
		"passenger_name": t.Passenger,
		"route":          t.Route,
		"fare_amount":    t.Amount,
		"payment_method": t.Method,
		"duration_min":   0,
		"status":         "ongoing",
	})
}

// CompleteTrip marks a trip as completed and notifies the passenger via WebSocket
func CompleteTrip(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var b struct {
		TripCode string `json:"trip_code"`
		DriverID int    `json:"driver_id"`
	}

	if err := utils.Decode(r, &b); err != nil {
		utils.JSONErr(w, "Invalid request body", 400)
		return
	}

	if b.TripCode == "" || b.DriverID == 0 {
		utils.JSONErr(w, "trip_code and driver_id are required", 400)
		return
	}

	// Logic change: Trip records are created in trip_logs ONLY when completed or cancelled.
	// We fetch the trip details from the payments table.
	var pID int
	var pName, route, method, dName string
	var amount float64
	var startedAt time.Time

	err := DB.QueryRow(`
		SELECT p.passenger_id, COALESCE(u.first_name || ' ' || u.last_name, 'Guest'), p.route, p.method, p.amount, p.paid_at, COALESCE(d.first_name || ' ' || d.last_name, 'Driver')
		FROM payments p
		LEFT JOIN users u ON p.passenger_id = u.user_id
		LEFT JOIN drivers d ON p.driver_id = d.id
		WHERE p.ref_code = $1`, b.TripCode).Scan(&pID, &pName, &route, &method, &amount, &startedAt, &dName)

	if err != nil {
		utils.JSONErr(w, "Trip payment record not found", 404)
		return
	}

	duration := int(time.Since(startedAt).Minutes())

	// Insert into logs as completed
	_, err = DB.Exec(`
		INSERT INTO trip_logs 
			(trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at, ended_at, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), 'completed')`,
		b.TripCode, pID, b.DriverID, route, amount, method, duration, startedAt)

	if err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}

	// ─ REAL-TIME: Notify passenger via WebSocket ─
	go func() {
		payload := map[string]interface{}{
			"event": "trip_ended",
			"trip": map[string]interface{}{
				"trip_code":      b.TripCode,
				"passenger_id":   pID,
				"driver_id":      b.DriverID,
				"passenger_name": pName,
				"driver_name":    dName,
				"route":          route,
				"fare_amount":    amount,
				"ended_at":       time.Now().Format(time.RFC3339),
			},
		}
		WSHub.NotifyPassenger(strconv.Itoa(pID), payload)
	}()

	utils.LogAudit(DB, "COMPLETE", "Trip", b.TripCode, "Trip completed by driver", "Driver:"+strconv.Itoa(b.DriverID), "Driver")
	utils.JSONOK(w, map[string]string{"message": "Trip completed successfully"})
}

// CancelTrip marks a trip as cancelled and records it in trip_logs
func CancelTrip(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var b struct {
		TripCode string `json:"trip_code"`
		DriverID int    `json:"driver_id"`
	}

	if err := utils.Decode(r, &b); err != nil {
		utils.JSONErr(w, "Invalid request body", 400)
		return
	}

	if b.TripCode == "" || b.DriverID == 0 {
		utils.JSONErr(w, "trip_code and driver_id are required", 400)
		return
	}

	var pID int
	var pName, route, method, dName string
	var amount float64
	var startedAt time.Time

	err := DB.QueryRow(`
		SELECT p.passenger_id, COALESCE(u.first_name || ' ' || u.last_name, 'Guest'), p.route, p.method, p.amount, p.paid_at, COALESCE(d.first_name || ' ' || d.last_name, 'Driver')
		FROM payments p
		LEFT JOIN users u ON p.passenger_id = u.user_id
		LEFT JOIN drivers d ON p.driver_id = d.id
		WHERE p.ref_code = $1`, b.TripCode).Scan(&pID, &pName, &route, &method, &amount, &startedAt, &dName)

	if err != nil {
		utils.JSONErr(w, "Payment record not found", 404)
		return
	}

	// Insert into logs as cancelled
	_, err = DB.Exec(`
		INSERT INTO trip_logs 
			(trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at, ended_at, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), 'cancelled')`,
		b.TripCode, pID, b.DriverID, route, amount, method, 0, startedAt)

	if err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}

	// Notify via WebSocket
	go func() {
		payload := map[string]interface{}{
			"event": "trip_cancelled",
			"trip": map[string]interface{}{
				"trip_code":      b.TripCode,
				"passenger_id":   pID,
				"driver_id":      b.DriverID,
				"passenger_name": pName,
				"driver_name":    dName,
				"route":          route,
				"fare_amount":    amount,
				"cancelled_at":   time.Now().Format(time.RFC3339),
			},
		}
		WSHub.NotifyPassenger(strconv.Itoa(pID), payload)
		WSHub.NotifyDriver(strconv.Itoa(b.DriverID), payload)
	}()

	utils.LogAudit(DB, "CANCEL", "Trip", b.TripCode, "Trip cancelled by driver", "Driver:"+strconv.Itoa(b.DriverID), "Driver")
	utils.JSONOK(w, map[string]string{"message": "Trip cancelled successfully"})
}
