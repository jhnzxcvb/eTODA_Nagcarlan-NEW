package controllers

import (
	"fmt"
	"net/http"
	"strings"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// fetchDrivers returns a slice of admin drivers matching the optional search term.
func fetchDrivers(search string) ([]models.AdminDriver, error) {
	q := `SELECT d.id,d.driver_code,d.name,d.franchise,
        COALESCE(d.body_no,''),COALESCE(d.contact,''),
        COALESCE(d.license_no,''),COALESCE(d.association,''),
        d.status,COALESCE(qr.qr_id,''),
        to_char(d.created_at,'YYYY-MM-DD')
        FROM drivers d LEFT JOIN qr_codes qr ON d.id=qr.driver_id WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += ` AND (d.name ILIKE $1 OR d.franchise ILIKE $1 OR d.driver_code ILIKE $1)`
	}
	q += " ORDER BY d.id"
	rows, err := DB.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []models.AdminDriver{}
	for rows.Next() {
		var d models.AdminDriver
		rows.Scan(&d.ID, &d.Code, &d.Name, &d.Franchise, &d.BodyNo, &d.Contact, &d.LicenseNo, &d.Association, &d.Status, &d.QRId, &d.CreatedAt)
		list = append(list, d)
	}
	return list, nil
}

// Drivers handler supports GET and POST for admin driver records.
func Drivers(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		list, err := fetchDrivers(r.URL.Query().Get("search"))
		if err != nil {
			utils.JSONErr(w, err.Error(), 500)
			return
		}
		if list == nil {
			list = []models.AdminDriver{}
		}
		utils.JSONOK(w, list)

	case "POST":
		var b struct {
			Username    string `json:"username"`
			Password    string `json:"password"`
			Name        string `json:"name"`
			Franchise   string `json:"franchise"`
			BodyNo      string `json:"body_no"`
			Contact     string `json:"contact"`
			LicenseNo   string `json:"license_no"`
			Association string `json:"association"`
		}
		if err := utils.Decode(r, &b); err != nil {
			utils.JSONErr(w, "Invalid JSON", 400)
			return
		}
		if strings.TrimSpace(b.Name) == "" || strings.TrimSpace(b.Franchise) == "" {
			utils.JSONErr(w, "Name and Franchise are required", 400)
			return
		}
		if b.Association == "" {
			b.Association = "Nagcarlan TODA"
		}
		var cnt int
		DB.QueryRow("SELECT COUNT(*) FROM drivers").Scan(&cnt)
		code := fmt.Sprintf("D-%03d", cnt+1)

		var dID int
		err := DB.QueryRow(
			`INSERT INTO drivers(driver_code,name,franchise,body_no,contact,license_no,association,status)
             VALUES($1,$2,$3,$4,$5,$6,$7,'Active') RETURNING id`,
			code, b.Name, b.Franchise, b.BodyNo, b.Contact, b.LicenseNo, b.Association,
		).Scan(&dID)
		if err != nil {
			utils.JSONErr(w, err.Error(), 500)
			return
		}
		qrID := fmt.Sprintf("QR-AES-%s-%s", strings.ReplaceAll(b.Franchise, "-", ""), utils.RandHex())
		DB.Exec(`INSERT INTO qr_codes(driver_id,franchise,qr_id,status) VALUES($1,$2,$3,'Active')`, dID, b.Franchise, qrID)

		// if mobile login info was provided, store it as well
		if b.Username != "" || b.Password != "" {
			DB.Exec(`UPDATE drivers SET username=$1, password_hash=$2 WHERE id=$3`, b.Username, b.Password, dID)
		}

		utils.LogAudit(DB, "ENROLL", "Driver", code, fmt.Sprintf("Enrolled %s (%s)", b.Name, b.Franchise))

		var d models.AdminDriver
		DB.QueryRow(`SELECT d.id,d.driver_code,d.name,d.franchise,
            COALESCE(d.body_no,''),COALESCE(d.contact,''),COALESCE(d.license_no,''),
            COALESCE(d.association,''),d.status,COALESCE(qr.qr_id,''),
            to_char(d.created_at,'YYYY-MM-DD')
            FROM drivers d LEFT JOIN qr_codes qr ON d.id=qr.driver_id WHERE d.id=$1`, dID).
			Scan(&d.ID, &d.Code, &d.Name, &d.Franchise, &d.BodyNo, &d.Contact, &d.LicenseNo, &d.Association, &d.Status, &d.QRId, &d.CreatedAt)

		w.WriteHeader(201)
		utils.JSONOK(w, d)

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}

// DriverByID handles PATCH/DELETE on a single driver.
func DriverByID(w http.ResponseWriter, r *http.Request) {
	id := utils.PathID(r.URL.Path, "/api/drivers/")
	switch r.Method {
	case "PATCH":
		var b map[string]string
		utils.Decode(r, &b)
		sets, args := []string{}, []interface{}{}
		for _, f := range []string{"username", "password", "name", "franchise", "body_no", "contact", "license_no", "association", "status"} {
			if v, ok := b[f]; ok {
				args = append(args, v)
				if f == "password" {
					sets = append(sets, fmt.Sprintf("password_hash=$%d", len(args)))
				} else {
					sets = append(sets, fmt.Sprintf("%s=$%d", f, len(args)))
				}
			}
		}
		if len(sets) == 0 {
			utils.JSONErr(w, "Nothing to update", 400)
			return
		}
		args = append(args, id)
		DB.Exec(fmt.Sprintf("UPDATE drivers SET %s WHERE id=$%d", strings.Join(sets, ","), len(args)), args...)
		utils.LogAudit(DB, "UPDATE", "Driver", id, fmt.Sprintf("Updated fields: %s", strings.Join(sets, ", ")))
		utils.JSONOK(w, map[string]string{"message": "Updated"})

	case "DELETE":
		var name, code string
		DB.QueryRow("SELECT name,driver_code FROM drivers WHERE id=$1", id).Scan(&name, &code)
		DB.Exec("DELETE FROM drivers WHERE id=$1", id)
		utils.LogAudit(DB, "DELETE", "Driver", code, fmt.Sprintf("Removed driver %s", name))
		utils.JSONOK(w, map[string]string{"message": name + " removed"})

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}
