package controllers

import (
	"fmt"
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Complaints handles GET (list) and POST (new complaint from Flutter)
func Complaints(w http.ResponseWriter, r *http.Request) {
	switch r.Method {

	case "GET":
		rows, _ := DB.Query(`
	        SELECT c.id,c.report_code,
	        COALESCE(p.first_name||' '||COALESCE(p.middle_name,'')||' '||p.last_name,'—'),COALESCE(d.name,'—'),COALESCE(d.franchise,'—'),
	        COALESCE(c.violation_type,''),COALESCE(c.firebase_id,''),
	        COALESCE(c.admin_notes,''),c.status,
	        to_char(c.reported_at,'YYYY-MM-DD')
	        FROM complaints c
	        LEFT JOIN users p ON c.passenger_id=p.user_id
	        LEFT JOIN drivers d ON c.driver_id=d.id
	        ORDER BY c.id DESC`)
		defer rows.Close()
		list := []models.Complaint{}
		for rows.Next() {
			var c models.Complaint
			rows.Scan(&c.ID, &c.Code, &c.PassengerName, &c.DriverName, &c.Franchise, &c.Violation, &c.FirebaseID, &c.AdminNotes, &c.Status, &c.ReportedAt)
			list = append(list, c)
		}
		if list == nil {
			list = []models.Complaint{}
		}
		utils.JSONOK(w, list)

	case "POST":
		// New complaint filed from Flutter app
		var b struct {
			PassengerID int    `json:"passenger_id"`
			DriverID    int    `json:"driver_id"`
			Violation   string `json:"violation_type"`
			FirebaseID  string `json:"firebase_id"`
		}
		if err := utils.Decode(r, &b); err != nil {
			utils.JSONErr(w, "Invalid JSON", 400)
			return
		}

		var cnt int
		DB.QueryRow("SELECT COUNT(*) FROM complaints").Scan(&cnt)
		code := fmt.Sprintf("C-%03d", cnt+1)

		var cID int
		err := DB.QueryRow(
			`INSERT INTO complaints(report_code, passenger_id, driver_id, violation_type, firebase_id, status, reported_at)
			 VALUES($1,$2,$3,$4,$5,'Pending',NOW()) RETURNING id`,
			code, b.PassengerID, b.DriverID, b.Violation, b.FirebaseID,
		).Scan(&cID)
		if err != nil {
			utils.JSONErr(w, err.Error(), 500)
			return
		}

		utils.LogAudit(DB, "CREATE", "Complaint", code, fmt.Sprintf("New complaint %s filed", code))

		// 🔔 Auto-insert notification
		InsertNotification(
			"New Complaint Filed",
			fmt.Sprintf("Complaint %s has been submitted.", code),
			"complaint",
		)

		w.WriteHeader(201)
		utils.JSONOK(w, map[string]interface{}{
			"message": "Complaint filed",
			"id":      cID,
			"code":    code,
		})

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}

// ComplaintByID handles PATCH (update status/notes) on a single complaint
func ComplaintByID(w http.ResponseWriter, r *http.Request) {
	switch r.Method {

	case "PATCH":
		id := utils.PathID(r.URL.Path, "/api/complaints/")
		var b struct {
			Status     string `json:"status"`
			AdminNotes string `json:"admin_notes"`
		}
		utils.Decode(r, &b)
		var code string
		DB.QueryRow("SELECT report_code FROM complaints WHERE id=$1", id).Scan(&code)
		if b.Status == "Resolved" {
			DB.Exec("UPDATE complaints SET status=$1,admin_notes=COALESCE(NULLIF($2,''),admin_notes),resolved_at=NOW() WHERE id=$3", b.Status, b.AdminNotes, id)
		} else {
			DB.Exec("UPDATE complaints SET status=$1,admin_notes=COALESCE(NULLIF($2,''),admin_notes) WHERE id=$3", b.Status, b.AdminNotes, id)
		}
		utils.LogAudit(DB, "UPDATE", "Complaint", code, fmt.Sprintf("Status → %s", b.Status))
		utils.JSONOK(w, map[string]string{"message": "Updated"})

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}