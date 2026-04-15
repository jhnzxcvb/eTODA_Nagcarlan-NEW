package controllers

import (
	"database/sql"
	"net/http"

	"etoda_admin/utils"
)

// QRLookup handles GET /api/qrcodes/lookup?qr_id=...
// Called by the Flutter app after scanning a QR code.
// Returns full driver info wrapped in a 'data' key for the Flutter app.
func QRLookup(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	qrID := r.URL.Query().Get("qr_id")
	if qrID == "" {
		utils.JSONErr(w, "qr_id is required", 400)
		return
	}

	// Look up QR code + driver in one join
	row := DB.QueryRow(`
		SELECT
			qr.qr_id,
			COALESCE(qr.status, '')           AS qr_status,
			d.id,
			COALESCE(d.driver_code, '')       AS driver_code,
			COALESCE(d.first_name, '')        AS first_name,
			COALESCE(d.middle_name, '')       AS middle_name,
			COALESCE(d.last_name, '')         AS last_name,
			COALESCE(d.franchise, '')         AS franchise,
			COALESCE(CAST(d.body_no AS TEXT), '') AS body_no,
			COALESCE(d.contact, '')           AS contact,
			COALESCE(d.license_no, '')        AS license_no,
			COALESCE(d.plate_number, '')      AS plate_number,
			COALESCE(d.association, '')       AS association,
			COALESCE(d.status, '')            AS status,
			COALESCE(to_char(d.created_at, 'YYYY-MM-DD'), '') AS created_at,
			COALESCE(d.profile_pic, '')       AS profile_pic,
			(SELECT COALESCE(AVG(rating), 0.0) FROM ratings WHERE driver_id = d.id) AS average_rating,
			(SELECT COUNT(id) FROM ratings WHERE driver_id = d.id) AS total_ratings
		FROM qr_codes qr
		JOIN drivers d ON qr.driver_id = d.id
		WHERE qr.qr_id = $1
	`, qrID)

	var result struct {
		QRId         string  `json:"qr_id"`
		QRStatus     string  `json:"qr_status"`
		ID           int     `json:"id"`
		DriverCode   string  `json:"driver_code"`
		FirstName    string  `json:"first_name"`
		MiddleName   string  `json:"middle_name"`
		LastName     string  `json:"last_name"`
		Franchise    string  `json:"franchise"`
		BodyNo       string  `json:"body_no"`
		Contact      string  `json:"contact"`
		LicenseNo    string  `json:"license_no"`
		PlateNumber  string  `json:"plate_number"`
		Association  string  `json:"association"`
		Status       string  `json:"status"`
		CreatedAt    string  `json:"created_at"`
		ProfilePic   string  `json:"profile_pic"`
		AvgRating    float64 `json:"average_rating"`
		TotalRatings int     `json:"total_ratings"`
	}

	err := row.Scan(
		&result.QRId, &result.QRStatus,
		&result.ID, &result.DriverCode,
		&result.FirstName, &result.MiddleName, &result.LastName,
		&result.Franchise, &result.BodyNo, &result.Contact,
		&result.LicenseNo, &result.PlateNumber, &result.Association,
		&result.Status, &result.CreatedAt,
		&result.ProfilePic, &result.AvgRating, &result.TotalRatings,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			utils.JSONErr(w, "QR code not found", 404)
		} else {
			// Log the actual error for debugging
			utils.JSONErr(w, "Database error: "+err.Error(), 500)
		}
		return
	}

	utils.JSONOK(w, result)
}
