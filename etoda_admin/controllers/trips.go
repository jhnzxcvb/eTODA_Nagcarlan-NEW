package controllers

import (
	"database/sql"
	"etoda_admin/utils"
	"fmt"
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

	// Only fetch from trip_logs to show finalized trip history.
	baseQuery := `
		SELECT 
			trip_code, p_name, d_name, d_contact, d_plate, d_body, route, fare_amount, payment_method, status, started_at, duration, passenger_id, driver_id, id
		FROM (
			SELECT 
				tl.trip_code, 
				COALESCE(u.first_name || ' ' || u.last_name, 'Guest') as p_name,
				COALESCE(d.first_name || ' ' || d.last_name, 'Driver') as d_name,
				COALESCE(d.contact, '—') as d_contact, COALESCE(d.plate_number, '—') as d_plate, COALESCE(d.body_no, '—') as d_body,
				COALESCE(tl.route, '—') as route,
				tl.fare_amount, tl.payment_method, tl.status,
				tl.started_at as started_at,
				COALESCE(tl.duration_min, 0) as duration,
				tl.passenger_id, tl.driver_id, tl.id
			FROM trip_logs tl
			LEFT JOIN users u ON tl.passenger_id = u.user_id
			LEFT JOIN drivers d ON tl.driver_id = d.id
		) sub`

	var rows *sql.Rows
	var err error
	if passengerID != "" {
		rows, err = DB.Query(baseQuery+" WHERE sub.passenger_id = $1 ORDER BY sub.id DESC ", passengerID)
	} else if driverID != "" {
		rows, err = DB.Query(baseQuery+" WHERE sub.driver_id = $1 ORDER BY sub.id DESC ", driverID)
	} else {
		rows, err = DB.Query(baseQuery + " ORDER BY sub.id DESC ")
	}

	if err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}
	defer rows.Close()

	count := 0
	// We use a map to match the specific keys expected by the Admin dashboard React code.
	list := []map[string]interface{}{}
	for rows.Next() {
		var code, pName, dName, contact, plate, body, route, method, status string
		var startedAt time.Time
		var amount float64
		var duration, pID, dID, id int
		if err := rows.Scan(&code, &pName, &dName, &contact, &plate, &body, &route, &amount, &method, &status, &startedAt, &duration, &pID, &dID, &id); err != nil {
			continue
		}
		count++
		if duration < 0 {
			duration = 0
		}

		list = append(list, map[string]interface{}{
			"id":             id,
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
			"started_at":     startedAt.Format(time.RFC3339),
		})
	}
	utils.LogInfo("Trips", fmt.Sprintf("Fetched %d trip records for admin dashboard", count))

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
			p.method,
			p.paid_at
		FROM payments p
		LEFT JOIN users u ON p.passenger_id = u.user_id
		WHERE p.driver_id = $1 
		AND NOT EXISTS (SELECT 1 FROM trip_logs tl WHERE tl.trip_code = p.ref_code)
		ORDER BY p.id DESC LIMIT 1`

	var t struct {
		Code, Passenger, Route, Method string
		Amount                         float64
		StartedAt                      time.Time
	}

	err := DB.QueryRow(query, driverID).Scan(&t.Code, &t.Passenger, &t.Route, &t.Amount, &t.Method, &t.StartedAt)
	if err != nil {
		utils.JSONOK(w, nil) // Return null if no active trip
		return
	}

	duration := int(time.Since(t.StartedAt).Minutes())
	if duration < 0 {
		duration = 0
	}

	utils.JSONOK(w, map[string]interface{}{
		"trip_code":      t.Code,
		"passenger_name": t.Passenger,
		"route":          t.Route,
		"fare_amount":    t.Amount,
		"payment_method": t.Method,
		"duration_min":   duration,
		"started_at":     t.StartedAt.Format(time.RFC3339),
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

	// Insert into logs as completed and retrieve the actual database timestamp
	var endedAt time.Time
	var finalDuration int

	// Calculate duration in minutes (minimum 1)
	err = DB.QueryRow(`
		INSERT INTO trip_logs 
			(trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at, ended_at, status)
		VALUES ($1, $2, $3, $4, $5, $6, GREATEST(1, CAST(EXTRACT(EPOCH FROM (NOW() - $7))/60 AS INTEGER)), $7, NOW(), 'completed')
		RETURNING ended_at, duration_min`,
		b.TripCode, pID, b.DriverID, route, amount, method, startedAt).Scan(&endedAt, &finalDuration)

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
				"duration_min":   finalDuration,
				"ended_at":       endedAt.Format("03:04 PM"),
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

	// Insert into logs as cancelled and retrieve the actual database timestamp
	var endedAt time.Time
	err = DB.QueryRow(`
		INSERT INTO trip_logs 
			(trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at, ended_at, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), 'cancelled')
		RETURNING ended_at`,
		b.TripCode, pID, b.DriverID, route, amount, method, 0, startedAt).Scan(&endedAt)

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
				"cancelled_at":   endedAt.Format("03:04 PM"),
			},
		}
		WSHub.NotifyPassenger(strconv.Itoa(pID), payload)
		WSHub.NotifyDriver(strconv.Itoa(b.DriverID), payload)
	}()

	utils.LogAudit(DB, "CANCEL", "Trip", b.TripCode, "Trip cancelled by driver", "Driver:"+strconv.Itoa(b.DriverID), "Driver")
	utils.JSONOK(w, map[string]string{"message": "Trip cancelled successfully"})
}
