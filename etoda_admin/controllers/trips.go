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
			tl.trip_code, 
			COALESCE(u.first_name || ' ' || u.last_name, 'Guest') as p_name,
			COALESCE(d.first_name || ' ' || d.last_name, 'Driver') as d_name,
			COALESCE(d.contact, '—') as d_contact, COALESCE(d.plate_number, '—') as d_plate, COALESCE(d.body_no, '—') as d_body,
			COALESCE(tl.route, '—') as route,
			COALESCE(tl.fare_amount, 0), COALESCE(tl.payment_method, '—'), COALESCE(tl.status, '—'),
			to_char(COALESCE(p.paid_at, tl.started_at), 'Mon DD, YYYY, HH12:MI AM') as started_at,
			to_char(tl.ended_at, 'Mon DD, YYYY, HH12:MI AM') as ended_at,
			tl.duration_min,
			tl.passenger_id, tl.driver_id, tl.id
		FROM trip_logs tl
		LEFT JOIN users u ON tl.passenger_id = u.user_id
		LEFT JOIN drivers d ON tl.driver_id = d.id
		LEFT JOIN payments p ON LOWER(TRIM(tl.trip_code)) = LOWER(TRIM(p.ref_code))
		WHERE LOWER(tl.status) = 'completed'`

	var rows *sql.Rows
	var err error
	if passengerID != "" {
		rows, err = DB.Query(baseQuery+" AND tl.passenger_id = $1 ORDER BY tl.ended_at DESC ", passengerID)
	} else if driverID != "" {
		rows, err = DB.Query(baseQuery+" AND tl.driver_id = $1 ORDER BY tl.ended_at DESC ", driverID)
	} else {
		rows, err = DB.Query(baseQuery + " ORDER BY tl.ended_at DESC ")
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
		var startedAt, endedAt sql.NullString
		var dbDurationMin sql.NullInt32
		var amount float64
		var pID, dID, id int
		if err := rows.Scan(&code, &pName, &dName, &contact, &plate, &body, &route, &amount, &method, &status, &startedAt, &endedAt, &dbDurationMin, &pID, &dID, &id); err != nil {
			utils.LogInfo("Trips", "Scan error for code "+code+": "+err.Error())
			continue
		}
		count++

		// Since we only fetch completed trips, we use the recorded duration
		duration := int(dbDurationMin.Int32)
		// Ensure duration is not negative
		if duration < 0 {
			duration = 0
		}

		var startedAtStr interface{} = nil
		if startedAt.Valid && startedAt.String != "" {
			startedAtStr = startedAt.String
		}

		var endedAtStr interface{} = nil
		if endedAt.Valid && endedAt.String != "" {
			endedAtStr = endedAt.String
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
			"started_at":     startedAtStr,
			"ended_at":       endedAtStr,
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
	// Insert into logs by selecting source data directly from the payments table.
	// This ensures 'started_at' perfectly matches 'paid_at' and duration is calculated
	// accurately within the database, avoiding Go-side timezone or precision issues.
	var endedAt time.Time
	var finalDuration, pID int
	err := DB.QueryRow(`
		INSERT INTO trip_logs 
			(trip_code, passenger_id, driver_id, route, fare_amount, payment_method, duration_min, started_at, ended_at, status)
		SELECT 
			p.ref_code, p.passenger_id, $2, p.route, p.amount, p.method, 
			GREATEST(1, CAST(EXTRACT(EPOCH FROM (NOW() - p.paid_at))/60 AS INTEGER)), 
			p.paid_at, NOW(), 'completed'
		FROM payments p
		WHERE LOWER(TRIM(p.ref_code)) = LOWER(TRIM($1))
		RETURNING ended_at, duration_min, passenger_id`,
		b.TripCode, b.DriverID).Scan(&endedAt, &finalDuration, &pID)

	if err != nil {
		utils.JSONErr(w, "Trip record not found or Database error: "+err.Error(), 500)
		return
	}

	// Fetch metadata for real-time notification
	var pName, dName, route, method string
	var amount float64
	DB.QueryRow(`
		SELECT 
			COALESCE(u.first_name || ' ' || u.last_name, 'Guest'), 
			COALESCE(d.first_name || ' ' || d.last_name, 'Driver'),
			p.route, p.method, p.amount
		FROM payments p
		LEFT JOIN users u ON p.passenger_id = u.user_id
		LEFT JOIN drivers d ON p.driver_id = d.id
		WHERE LOWER(TRIM(p.ref_code)) = LOWER(TRIM($1))`, b.TripCode).Scan(&pName, &dName, &route, &method, &amount)

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
