package controllers

import (
	"fmt"
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Passengers handler for listing passengers (now backed by users table).
func Passengers(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	search := r.URL.Query().Get("search")
	q := `SELECT user_id,
		username,
		(first_name || ' ' || COALESCE(middle_name,'') || ' ' || last_name) AS name,
		COALESCE(email,''),
		'Registered' AS session_type,
		COALESCE(status,'Active'),
		to_char(created_at,'YYYY-MM-DD')
		FROM users WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += ` AND (username ILIKE $1 OR first_name ILIKE $1 OR last_name ILIKE $1 OR email ILIKE $1)`
	}
	q += " ORDER BY user_id"
	rows, _ := DB.Query(q, args...)
	defer rows.Close()
	list := []models.Passenger{}
	for rows.Next() {
		var p models.Passenger
		rows.Scan(&p.ID, &p.Code, &p.Name, &p.Email, &p.SessionType, &p.Status, &p.RegisteredAt)
		list = append(list, p)
	}
	if list == nil {
		list = []models.Passenger{}
	}
	utils.JSONOK(w, list)
}

// PassengerByID handles status updates for a passenger record (stored in users table).
func PassengerByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	id := utils.PathID(r.URL.Path, "/api/passengers/")
	var b struct {
		Status string `json:"status"`
	}
	utils.Decode(r, &b)
	var name string
	DB.QueryRow("SELECT (first_name||' '||COALESCE(middle_name,'')||' '||last_name) FROM users WHERE user_id=$1", id).Scan(&name)
	DB.Exec("UPDATE users SET status=$1 WHERE user_id=$2", b.Status, id)
	utils.LogAudit(DB, "UPDATE", "Passenger", id, fmt.Sprintf("%s status → %s", name, b.Status))
	utils.JSONOK(w, map[string]string{"message": "Updated"})
}
