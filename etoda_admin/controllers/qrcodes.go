package controllers

import (
	"fmt"
	"net/http"
	"strings"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// QRCodes returns all qr code entries.
func QRCodes(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	rows, _ := DB.Query(`
		SELECT q.id, q.franchise, COALESCE(NULLIF(TRIM(d.first_name || ' ' || d.last_name), ''), '—'), q.qr_id, q.status,
		to_char(q.issued_at,'YYYY-MM-DD')
		FROM qr_codes q LEFT JOIN drivers d ON q.driver_id=d.id
		ORDER BY q.id`)
	defer rows.Close()
	list := []models.QRCode{}
	for rows.Next() {
		var q models.QRCode
		rows.Scan(&q.ID, &q.Franchise, &q.DriverName, &q.QRId, &q.Status, &q.IssuedAt)
		list = append(list, q)
	}
	if list == nil {
		list = []models.QRCode{}
	}
	utils.JSONOK(w, list)
}

// QRCodeByID updates or regenerates a qr code.
func QRCodeByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	id := utils.PathID(r.URL.Path, "/api/qrcodes/")
	var b struct {
		Status string `json:"status"`
	}
	utils.Decode(r, &b)
	var franchise string
	DB.QueryRow("SELECT franchise FROM qr_codes WHERE id=$1", id).Scan(&franchise)
	if b.Status == "Active" {
		newQR := fmt.Sprintf("QR-AES-%s-%s", strings.ReplaceAll(franchise, "-", ""), utils.RandHex())
		DB.Exec("UPDATE qr_codes SET status=$1,qr_id=$2 WHERE id=$3", b.Status, newQR, id)
		adminID := fmt.Sprintf("%v", r.Context().Value("admin_id"))
		utils.LogAudit(DB, "RESTORE", "QRCode", franchise, "QR regenerated with new AES key", "Admin:"+adminID, "Admin")
	} else {
		DB.Exec("UPDATE qr_codes SET status=$1 WHERE id=$2", b.Status, id)
		adminID := fmt.Sprintf("%v", r.Context().Value("admin_id"))
		utils.LogAudit(DB, "REVOKE", "QRCode", franchise, fmt.Sprintf("QR status → %s", b.Status), "Admin:"+adminID, "Admin")
	}
	utils.JSONOK(w, map[string]string{"message": "Updated"})
}
