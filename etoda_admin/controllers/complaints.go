package controllers

import (
	"etoda_admin/models"
	"etoda_admin/utils"
	"fmt"
	"net/http"
	"strings"
)

// Complaints handles /api/complaints
func Complaints(w http.ResponseWriter, r *http.Request) {
	// Ensure response is JSON
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case "GET":
		rows, err := DB.Query(`
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
			LEFT JOIN drivers d ON c.driver_id = d.id
			ORDER BY c.id DESC`)

		if err != nil {
			utils.JSONErr(w, "Database selection error", 500)
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

		utils.LogAudit(DB, "CREATE", "Complaint", code, "New report filed")
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

		utils.LogAudit(DB, "UPDATE", "Complaint", id, "Status updated to "+b.Status)
		utils.JSONOK(w, map[string]string{"message": "Update successful"})
		return
	}

	utils.JSONErr(w, "Method not allowed", 405)
}
