package controllers

import (
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Trips returns trip log entries, optionally filtered by search term.
func Trips(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	search := r.URL.Query().Get("search")
	q := `SELECT t.id,t.trip_code,
        COALESCE(p.first_name||' '||COALESCE(p.middle_name,'')||' '||p.last_name,'—'),COALESCE(d.name,'—'),COALESCE(d.contact,'—'),
        COALESCE(t.route,''),t.fare_amount,COALESCE(t.payment_method,''),
        t.duration_min,to_char(t.started_at,'YYYY-MM-DD')
        FROM trip_logs t
        LEFT JOIN users p ON t.passenger_id=p.user_id
        LEFT JOIN drivers d ON t.driver_id=d.id
        WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += ` AND (p.name ILIKE $1 OR d.name ILIKE $1 OR t.route ILIKE $1 OR t.trip_code ILIKE $1)`
	}
	q += " ORDER BY t.id DESC"
	rows, err := DB.Query(q, args...)
	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()
	list := []models.Trip{}
	for rows.Next() {
		var t models.Trip
		rows.Scan(&t.ID, &t.TripCode, &t.PassengerName, &t.DriverName, &t.DriverContact, &t.Route, &t.FareAmount, &t.Method, &t.DurationMin, &t.StartedAt)
		list = append(list, t)
	}
	if list == nil {
		list = []models.Trip{}
	}
	utils.JSONOK(w, list)
}
