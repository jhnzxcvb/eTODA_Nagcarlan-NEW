package controllers

import (
	"fmt"
	"log"
	"net/http"
	"strings"

	"etoda_admin/models"
	"etoda_admin/utils"
)

func Passengers(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	search := r.URL.Query().Get("search")
	q := `SELECT user_id,
		COALESCE(username,''),
		TRIM(REGEXP_REPLACE(first_name || ' ' || COALESCE(NULLIF(TRIM(middle_name),''),'') || ' ' || last_name, '\s+', ' ', 'g')) AS name,
		COALESCE(email,''),
		COALESCE(phone_number,''),
		'Registered' AS session_type,
		COALESCE(status,'Active'),
		to_char(created_at,'YYYY-MM-DD')
		FROM users WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += ` AND (username ILIKE $1 OR first_name ILIKE $1 OR last_name ILIKE $1 OR email ILIKE $1 OR phone_number ILIKE $1)`
	}
	q += " ORDER BY user_id"

	rows, err := DB.Query(q, args...)
	if err != nil {
		log.Println("Passengers query error:", err)
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()

	list := []models.Passenger{}
	for rows.Next() {
		var p models.Passenger
		if err := rows.Scan(&p.ID, &p.Username, &p.Name, &p.Email, &p.Contact, &p.SessionType, &p.Status, &p.RegisteredAt); err != nil {
			log.Println("Passengers scan error:", err)
			continue
		}
		list = append(list, p)
	}
	if list == nil {
		list = []models.Passenger{}
	}
	utils.JSONOK(w, list)
}

func PassengerByID(w http.ResponseWriter, r *http.Request) {
	id := utils.PathID(r.URL.Path, "/api/passengers/")

	switch r.Method {
	case "GET":
		var p models.Passenger
		err := DB.QueryRow(`SELECT user_id,
			COALESCE(username,''),
			TRIM(REGEXP_REPLACE(first_name || ' ' || COALESCE(NULLIF(TRIM(middle_name),''),'') || ' ' || last_name, '\s+', ' ', 'g')) AS name,
			COALESCE(email,''),
			COALESCE(phone_number,''),
			'Registered' AS session_type,
			COALESCE(status,'Active'),
			to_char(created_at,'YYYY-MM-DD')
			FROM users WHERE user_id=$1`, id).Scan(&p.ID, &p.Username, &p.Name, &p.Email, &p.Contact, &p.SessionType, &p.Status, &p.RegisteredAt)
		if err != nil {
			log.Println("PassengerByID query error:", err)
			utils.JSONErr(w, "Passenger not found", 404)
			return
		}
		utils.JSONOK(w, p)
	case "PATCH":
		var b map[string]string
		utils.Decode(r, &b)

		sets, args := []string{}, []interface{}{}

		if v, ok := b["status"]; ok {
			args = append(args, v)
			sets = append(sets, fmt.Sprintf("status=$%d", len(args)))
		}
		if v, ok := b["email"]; ok {
			args = append(args, v)
			sets = append(sets, fmt.Sprintf("email=$%d", len(args)))
		}
		if v, ok := b["contact"]; ok {
			args = append(args, v)
			sets = append(sets, fmt.Sprintf("phone_number=$%d", len(args)))
		}
		if v, ok := b["name"]; ok {
			parts := strings.Fields(strings.TrimSpace(v))
			switch len(parts) {
			case 1:
				args = append(args, parts[0])
				sets = append(sets, fmt.Sprintf("first_name=$%d", len(args)))
				args = append(args, "")
				sets = append(sets, fmt.Sprintf("middle_name=$%d", len(args)))
				args = append(args, "")
				sets = append(sets, fmt.Sprintf("last_name=$%d", len(args)))
			case 2:
				args = append(args, parts[0])
				sets = append(sets, fmt.Sprintf("first_name=$%d", len(args)))
				args = append(args, "")
				sets = append(sets, fmt.Sprintf("middle_name=$%d", len(args)))
				args = append(args, parts[1])
				sets = append(sets, fmt.Sprintf("last_name=$%d", len(args)))
			default:
				args = append(args, parts[0])
				sets = append(sets, fmt.Sprintf("first_name=$%d", len(args)))
				args = append(args, strings.Join(parts[1:len(parts)-1], " "))
				sets = append(sets, fmt.Sprintf("middle_name=$%d", len(args)))
				args = append(args, parts[len(parts)-1])
				sets = append(sets, fmt.Sprintf("last_name=$%d", len(args)))
			}
		}

		if len(sets) == 0 {
			utils.JSONErr(w, "Nothing to update", 400)
			return
		}

		args = append(args, id)
		DB.Exec(fmt.Sprintf("UPDATE users SET %s WHERE user_id=$%d", strings.Join(sets, ","), len(args)), args...)

		var name string
		DB.QueryRow("SELECT (first_name||' '||last_name) FROM users WHERE user_id=$1", id).Scan(&name)
		adminID := fmt.Sprintf("%v", r.Context().Value("admin_id"))
		utils.LogAudit(DB, "UPDATE", "Passenger", id, fmt.Sprintf("Updated passenger: %s", name), "Admin:"+adminID, "Admin")
		utils.JSONOK(w, map[string]string{"message": "Updated"})

	case "DELETE":
		var name string
		DB.QueryRow("SELECT (first_name||' '||last_name) FROM users WHERE user_id=$1", id).Scan(&name)
		DB.Exec("DELETE FROM users WHERE user_id=$1", id)
		adminID := fmt.Sprintf("%v", r.Context().Value("admin_id"))
		utils.LogAudit(DB, "DELETE", "Passenger", id, fmt.Sprintf("Deleted passenger: %s", name), "Admin:"+adminID, "Admin")
		utils.JSONOK(w, map[string]string{"message": "Deleted"})

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}

func NotifyNewPassenger(name string) {
	InsertNotification(
		"New Passenger Registered",
		fmt.Sprintf("%s has created a passenger account.", name),
		"passenger",
	)
}
