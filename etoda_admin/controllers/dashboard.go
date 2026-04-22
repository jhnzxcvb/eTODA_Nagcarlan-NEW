package controllers

import (
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Dashboard returns aggregated statistics.
func Dashboard(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	var s models.Stats
	DB.QueryRow(`SELECT COUNT(*) FROM drivers WHERE status='Active'`).Scan(&s.ActiveDrivers)
	DB.QueryRow(`SELECT COUNT(*) FROM drivers`).Scan(&s.TotalDrivers)
	DB.QueryRow(`SELECT COUNT(*) FROM users`).Scan(&s.Passengers)
	DB.QueryRow(`SELECT COALESCE(SUM(amount),0), COUNT(*) FROM payments WHERE status='Settled' AND paid_at::date=CURRENT_DATE`).Scan(&s.RevenueToday, &s.RevenueCount)
	DB.QueryRow(`SELECT COUNT(*) FROM complaints WHERE status!='Resolved'`).Scan(&s.PendingComplaints)
	DB.QueryRow(`SELECT COUNT(*) FROM trip_logs WHERE started_at::date=CURRENT_DATE`).Scan(&s.TripsToday)
	DB.QueryRow(`SELECT COUNT(*) FROM trip_logs`).Scan(&s.TotalTrips)
	DB.QueryRow(`SELECT COUNT(*) FROM qr_codes WHERE status='Active'`).Scan(&s.ActiveQR)
	utils.JSONOK(w, s)
}
