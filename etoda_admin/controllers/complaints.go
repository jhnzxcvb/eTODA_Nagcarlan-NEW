package controllers

import (
	"fmt"
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Complaints lists all complaints.
func Complaints(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
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
}

// ComplaintByID updates status/notes of a complaint.
func ComplaintByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
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
}
