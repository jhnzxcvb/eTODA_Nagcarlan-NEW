package controllers

import (
	"database/sql"
	"etoda_admin/utils"
	"net/http"
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

	query := `
		SELECT 
			t.trip_code, 
			COALESCE(u.first_name || ' ' || u.last_name, 'Guest'),
			COALESCE(d.first_name || ' ' || d.last_name, 'Driver'),
			COALESCE(d.contact, '—'),
			COALESCE(d.plate_number, '—'),
			COALESCE(d.body_no, '—'),
			COALESCE(t.route, '—'),
			t.fare_amount, 
			t.payment_method, 
			to_char(t.started_at, 'YYYY-MM-DD HH24:MI'),
			COALESCE(t.duration_min, 0)
		FROM trip_logs t
		LEFT JOIN users u ON t.passenger_id = u.user_id
		LEFT JOIN drivers d ON t.driver_id = d.id`

	var rows *sql.Rows
	var err error
	if passengerID != "" {
		rows, err = DB.Query(query+" WHERE t.passenger_id = $1 ORDER BY t.id DESC", passengerID)
	} else if driverID != "" {
		rows, err = DB.Query(query+" WHERE t.driver_id = $1 ORDER BY t.id DESC", driverID)
	} else {
		rows, err = DB.Query(query + " ORDER BY t.id DESC")
	}

	if err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}
	defer rows.Close()

	// We use a map to match the specific keys expected by the Admin dashboard React code.
	list := []map[string]interface{}{}
	for rows.Next() {
		var code, pName, dName, contact, plate, body, route, method, date string
		var amount float64
		var duration int
		if err := rows.Scan(&code, &pName, &dName, &contact, &plate, &body, &route, &amount, &method, &date, &duration); err != nil {
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
			t.trip_code, 
			COALESCE(u.first_name || ' ' || u.last_name, 'Guest'),
			COALESCE(t.route, '—'),
			t.fare_amount, 
			t.payment_method,
			COALESCE(t.duration_min, 0)
		FROM trip_logs t
		LEFT JOIN users u ON t.passenger_id = u.user_id
		WHERE t.driver_id = $1 
		AND t.started_at > NOW() - INTERVAL '10 minutes'
		ORDER BY t.id DESC LIMIT 1`

	var t struct {
		Code, Passenger, Route, Method string
		Amount                         float64
		Duration                       int
	}

	err := DB.QueryRow(query, driverID).Scan(&t.Code, &t.Passenger, &t.Route, &t.Amount, &t.Method, &t.Duration)
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
		"duration_min":   t.Duration,
	})
}
