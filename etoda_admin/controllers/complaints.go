package controllers

import (
	"etoda_admin/models"
	"etoda_admin/utils"
	"fmt"
	"net/http"
	"strconv"
	"strings"
)

// Complaints handles /api/complaints
func Complaints(w http.ResponseWriter, r *http.Request) {
	// Ensure response is JSON
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case "GET":
		passengerID := r.URL.Query().Get("passenger_id")
		driverID := r.URL.Query().Get("driver_id") // Keep existing driverID filter if any

		baseQuery := `
			SELECT c.id, c.report_code, 
			COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, ''),
			COALESCE(d.first_name, '') || ' ' || COALESCE(d.last_name, ''), 
			COALESCE(d.franchise,'—'),
			COALESCE(c.violation_type,''), 
			COALESCE(c.details,''), 
			COALESCE(c.admin_notes,''), 
			c.status, 
			COALESCE(to_char(c.reported_at,'YYYY-MM-DD'), '')
			FROM complaints c
			LEFT JOIN users p ON c.passenger_id = p.user_id
			LEFT JOIN drivers d ON c.driver_id = d.id`

		var whereClauses []string
		var args []interface{}
		argCounter := 1

		if passengerID != "" {
			whereClauses = append(whereClauses, fmt.Sprintf("c.passenger_id = $%d", argCounter))
			args = append(args, passengerID)
			argCounter++
		}
		if driverID != "" { // Assuming driverID filter might also be needed for admin or future features
			whereClauses = append(whereClauses, fmt.Sprintf("c.driver_id = $%d", argCounter))
			args = append(args, driverID)
			argCounter++
		}

		if len(whereClauses) > 0 {
			baseQuery += " WHERE " + strings.Join(whereClauses, " AND ")
		}

		baseQuery += " ORDER BY c.id DESC"

		rows, err := DB.Query(baseQuery, args...)

		if err != nil {
			utils.JSONErr(w, "Database selection error: "+err.Error(), 500)
			return
		}
		defer rows.Close()

		list := []models.Complaint{}
		for rows.Next() {
			var c models.Complaint
			if err := rows.Scan(&c.ID, &c.Code, &c.PassengerName, &c.DriverName, &c.Franchise, &c.Violation, &c.Details, &c.AdminNotes, &c.Status, &c.ReportedAt); err != nil {
				continue
			}
			list = append(list, c)
		}
		utils.JSONOK(w, list)

	case "POST":
		var b struct {
			PassengerID int    `json:"passenger_id"`
			DriverID    int    `json:"driver_id"`
			Violation   string `json:"violation_type"`
			Details     string `json:"details"`
		}
		if err := utils.Decode(r, &b); err != nil {
			utils.JSONErr(w, "Invalid request payload", 400)
			return
		}

		if b.DriverID == 0 {
			utils.JSONErr(w, "Driver ID is required and cannot be 0", 400)
			return
		}

		var cnt int
		DB.QueryRow("SELECT COUNT(*) FROM complaints").Scan(&cnt)
		code := fmt.Sprintf("C-%03d", cnt+1)

		var pID interface{} = nil
		if b.PassengerID != 0 {
			pID = b.PassengerID
		}

		err := DB.QueryRow(
			`INSERT INTO complaints(report_code, passenger_id, driver_id, violation_type, details, status, reported_at) 
			 VALUES($1, $2, $3, $4, $5, 'Open', NOW()) RETURNING id`,
			code, pID, b.DriverID, b.Violation, b.Details,
		).Scan(&cnt)

		if err != nil {
			utils.JSONErr(w, "Database error: "+err.Error(), 500)
			return
		}

		performedBy := "Passenger:" + strconv.Itoa(b.PassengerID)
		if b.PassengerID == 0 {
			performedBy = "Passenger:Guest"
		}

		utils.LogAudit(DB, "CREATE", "Complaint", code, "New report filed", performedBy, "User")
		// Return 201 Created status for successful resource creation
		w.WriteHeader(http.StatusCreated)
		utils.JSONOK(w, map[string]interface{}{"report_code": code, "status": "success"})

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}

// ComplaintByID handles /api/complaints/{id}
func ComplaintByID(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract ID and check if it's empty
	id := strings.TrimPrefix(r.URL.Path, "/api/complaints/")
	if id == "" || id == "/" {
		utils.JSONErr(w, "Complaint ID is required", 400)
		return
	}

	if r.Method == "PATCH" {
		var b struct {
			Status     string `json:"status"`
			AdminNotes string `json:"admin_notes"`
		}
		if err := utils.Decode(r, &b); err != nil {
			utils.JSONErr(w, "Invalid update data", 400)
			return
		}

		// Fetch current complaint details to get passenger_id and report_code
		var pID int
		var reportCode string
		err := DB.QueryRow(
			`SELECT passenger_id, report_code FROM complaints WHERE id = $1`,
			id,
		).Scan(&pID, &reportCode)
		if err != nil {
			utils.JSONErr(w, "Complaint not found or database error: "+err.Error(), 404)
			return
		}
		res, err := DB.Exec(
			"UPDATE complaints SET status = $1, admin_notes = $2 WHERE id = $3",
			b.Status, b.AdminNotes, id,
		)

		if err != nil {
			utils.JSONErr(w, "Update failed", 500)
			return
		}

		// Check if any row was actually updated
		rowsAffected, _ := res.RowsAffected()
		if rowsAffected == 0 {
			utils.JSONErr(w, "Complaint not found", 404)
			return
		}

		adminID := fmt.Sprintf("%v", r.Context().Value("admin_id"))
		utils.LogAudit(DB, "UPDATE", "Complaint", id, "Status updated to "+b.Status, "Admin:"+adminID, "Admin")

		// --- NEW: Send WebSocket notification to passenger ---
		if pID != 0 {
			WSHub.NotifyPassenger(strconv.Itoa(pID), map[string]interface{}{
				"event":        "complaint_updated",
				"report_code":  reportCode,
				"new_status":   b.Status,
				"admin_notes":  b.AdminNotes,
			})
		}
		// --- END NEW ---
		utils.JSONOK(w, map[string]interface{}{
			"message":     "Update successful",
			"id":          id,
			"status":      b.Status,
			"admin_notes": b.AdminNotes,
		})
		return
	}

	utils.JSONErr(w, "Method not allowed", 405)
}
