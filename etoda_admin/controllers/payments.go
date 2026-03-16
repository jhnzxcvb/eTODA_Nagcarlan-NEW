package controllers

import (
	"fmt"
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Payments lists all payment records.
func Payments(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	rows, err := DB.Query(`
        SELECT py.id,py.ref_code,
        COALESCE(p.first_name||' '||COALESCE(p.middle_name,'')||' '||p.last_name,'—'),COALESCE(d.name,'—'),
        COALESCE(py.route,''),py.amount,py.method,py.status,
        to_char(py.paid_at,'YYYY-MM-DD HH24:MI')
        FROM payments py
        LEFT JOIN users p ON py.passenger_id=p.user_id
        LEFT JOIN drivers d ON py.driver_id=d.id
        ORDER BY py.id DESC`)
	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()
	list := []models.Payment{}
	for rows.Next() {
		var p models.Payment
		rows.Scan(&p.ID, &p.RefCode, &p.PassengerName, &p.DriverName, &p.Route, &p.Amount, &p.Method, &p.Status, &p.PaidAt)
		list = append(list, p)
	}
	if list == nil {
		list = []models.Payment{}
	}
	utils.JSONOK(w, list)
}

// PaymentByID updates payment status.
func PaymentByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	id := utils.PathID(r.URL.Path, "/api/payments/")
	var b struct {
		Status string `json:"status"`
	}
	utils.Decode(r, &b)
	var ref string
	DB.QueryRow("SELECT ref_code FROM payments WHERE id=$1", id).Scan(&ref)
	DB.Exec("UPDATE payments SET status=$1 WHERE id=$2", b.Status, id)
	utils.LogAudit(DB, "UPDATE", "Payment", ref, fmt.Sprintf("Status → %s", b.Status))
	utils.JSONOK(w, map[string]string{"message": "Updated"})
}
