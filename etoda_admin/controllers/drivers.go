package controllers

import (
	"fmt"
	"net/http"
	"strings"

	"etoda_admin/models"
	"etoda_admin/utils"
)

<<<<<<< Updated upstream
=======
const driverSelect = `
	SELECT d.id, d.driver_code, TRIM(COALESCE(d.first_name, '') || ' ' || COALESCE(d.middle_name, '') || ' ' || COALESCE(d.last_name, '')), d.franchise,
	       COALESCE(d.body_no,''), COALESCE(d.contact,''),
	       COALESCE(d.license_no,''), COALESCE(d.association,''),
	       d.status,
	       COALESCE(d.username,''),
	       COALESCE(qr.qr_id,''),
	       COALESCE(qr.status,''),
	       to_char(d.created_at,'YYYY-MM-DD'),
	       (d.password_hash IS NOT NULL AND d.password_hash != '') AS has_password
	FROM drivers d
	LEFT JOIN qr_codes qr ON d.id = qr.driver_id`

func scanDriver(row interface{ Scan(...interface{}) error }, d *models.AdminDriver) error {
	return row.Scan(
		&d.ID, &d.Code, &d.Name, &d.Franchise,
		&d.BodyNo, &d.Contact, &d.LicenseNo, &d.Association,
		&d.Status, &d.Username,
		&d.QRId, &d.QRStatus, &d.CreatedAt,
		&d.HasPassword,
	)
}

>>>>>>> Stashed changes
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
		q += ` AND (d.first_name ILIKE $1 OR d.last_name ILIKE $1 OR d.franchise ILIKE $1 OR d.driver_code ILIKE $1)`
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

		// Split name for the new DB schema
		parts := strings.Fields(b.Name)
		firstName, middleName, lastName := "", "", ""
		if len(parts) == 1 {
			firstName = parts[0]
		} else if len(parts) == 2 {
			firstName = parts[0]
			lastName = parts[1]
		} else if len(parts) > 2 {
			firstName = parts[0]
			lastName = parts[len(parts)-1]
			middleName = strings.Join(parts[1:len(parts)-1], " ")
		}

		var dID int
		err := DB.QueryRow(
<<<<<<< Updated upstream
			`INSERT INTO drivers(driver_code,name,franchise,body_no,contact,license_no,association,status)
             VALUES($1,$2,$3,$4,$5,$6,$7,'Active') RETURNING id`,
			code, b.Name, b.Franchise, b.BodyNo, b.Contact, b.LicenseNo, b.Association,
=======
			`INSERT INTO drivers(driver_code,first_name,middle_name,last_name,franchise,body_no,contact,license_no,association,status)
			 VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,'Active') RETURNING id`,
			code, firstName, middleName, lastName, b.Franchise, b.BodyNo, b.Contact, b.LicenseNo, b.Association,
>>>>>>> Stashed changes
		).Scan(&dID)
		if err != nil {
			utils.JSONErr(w, err.Error(), 500)
			return
		}
		qrID := fmt.Sprintf("QR-AES-%s-%s", strings.ReplaceAll(b.Franchise, "-", ""), utils.RandHex())
		DB.Exec(`INSERT INTO qr_codes(driver_id,franchise,qr_id,status) VALUES($1,$2,$3,'Active')`, dID, b.Franchise, qrID)

		if b.Username != "" || b.Password != "" {
			DB.Exec(`UPDATE drivers SET username=$1, password_hash=$2 WHERE id=$3`, b.Username, b.Password, dID)
		}

		utils.LogAudit(DB, "ENROLL", "Driver", code, fmt.Sprintf("Enrolled %s (%s)", b.Name, b.Franchise))

		// 🔔 Auto-insert notification
		InsertNotification(
			"New Driver Registered",
			fmt.Sprintf("%s (%s) has been enrolled as a driver.", b.Name, b.Franchise),
			"driver",
		)

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

func DriverByID(w http.ResponseWriter, r *http.Request) {
	id := utils.PathID(r.URL.Path, "/api/drivers/")
	switch r.Method {
	case "PATCH":
		var b map[string]string
		utils.Decode(r, &b)
		sets, args := []string{}, []interface{}{}
<<<<<<< Updated upstream
		for _, f := range []string{"username", "password", "name", "franchise", "body_no", "contact", "license_no", "association", "status"} {
			if v, ok := b[f]; ok {
				args = append(args, v)
				if f == "password" {
					sets = append(sets, fmt.Sprintf("password_hash=$%d", len(args)))
				} else {
=======

		for _, f := range []string{"username", "name", "franchise", "body_no", "contact", "license_no", "plate_number", "association", "status"} {
			if v, ok := b[f]; ok {
				if f == "name" {
					nameStr, _ := v.(string)
					parts := strings.Fields(nameStr)
					firstName, middleName, lastName := "", "", ""
					if len(parts) == 1 {
						firstName = parts[0]
					} else if len(parts) == 2 {
						firstName = parts[0]
						lastName = parts[1]
					} else if len(parts) > 2 {
						firstName = parts[0]
						lastName = parts[len(parts)-1]
						middleName = strings.Join(parts[1:len(parts)-1], " ")
					}
					args = append(args, firstName, middleName, lastName)
					sets = append(sets, fmt.Sprintf("first_name=$%d, middle_name=$%d, last_name=$%d", len(args)-2, len(args)-1, len(args)))
				} else {
					args = append(args, v)
>>>>>>> Stashed changes
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
		var fName, lName, code string
		DB.QueryRow("SELECT COALESCE(first_name,''), COALESCE(last_name,''), driver_code FROM drivers WHERE id=$1", id).Scan(&fName, &lName, &code)
		DB.Exec("DELETE FROM drivers WHERE id=$1", id)
		utils.LogAudit(DB, "DELETE", "Driver", code, fmt.Sprintf("Removed driver %s %s", fName, lName))
		utils.JSONOK(w, map[string]string{"message": fName + " removed"})

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}