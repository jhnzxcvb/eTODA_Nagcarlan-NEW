package controllers

import (
	"fmt"
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// Fare handler manages fare matrix CRUD operations.
func Fare(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		rows, _ := DB.Query("SELECT id,origin,destination,base_fare,discounted_fare,night_fare,special_fare,to_char(created_at,'YYYY-MM-DD') FROM fare_matrix ORDER BY id")
		defer rows.Close()
		list := []models.Fare{}
		for rows.Next() {
			var f models.Fare
			rows.Scan(&f.ID, &f.Origin, &f.Destination, &f.BaseFare, &f.DiscountedFare, &f.NightFare, &f.SpecialFare, &f.CreatedAt)
			list = append(list, f)
		}
		if list == nil {
			list = []models.Fare{}
		}
		utils.JSONOK(w, list)

	case "POST":
		var b struct {
			Origin      string  `json:"origin"`
			Destination string  `json:"destination"`
			BaseFare    float64 `json:"base_fare"`
		}
		utils.Decode(r, &b)
		if b.Origin == "" || b.Destination == "" || b.BaseFare == 0 {
			utils.JSONErr(w, "All fields required", 400)
			return
		}
		var f models.Fare
		err := DB.QueryRow(
			`INSERT INTO fare_matrix(origin,destination,base_fare,discounted_fare,night_fare,special_fare)
             VALUES($1,$2,$3,$4,$5,$6)
             ON CONFLICT(origin,destination) DO UPDATE SET
               base_fare=EXCLUDED.base_fare,discounted_fare=EXCLUDED.discounted_fare,
               night_fare=EXCLUDED.night_fare,special_fare=EXCLUDED.special_fare
             RETURNING id,origin,destination,base_fare,discounted_fare,night_fare,special_fare,to_char(created_at,'YYYY-MM-DD')`,
			b.Origin, b.Destination, b.BaseFare,
			b.BaseFare*0.8, b.BaseFare*1.15, b.BaseFare*3,
		).Scan(&f.ID, &f.Origin, &f.Destination, &f.BaseFare, &f.DiscountedFare, &f.NightFare, &f.SpecialFare, &f.CreatedAt)
		if err != nil {
			utils.JSONErr(w, err.Error(), 500)
			return
		}
		utils.LogAudit(DB, "CREATE", "Fare", fmt.Sprintf("%d", f.ID), fmt.Sprintf("%s → %s base ₱%.2f", b.Origin, b.Destination, b.BaseFare))
		w.WriteHeader(201)
		utils.JSONOK(w, f)

	default:
		utils.JSONErr(w, "Method not allowed", 405)
	}
}

// FareByID deletes a fare entry.
func FareByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != "DELETE" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	id := utils.PathID(r.URL.Path, "/api/fare/")
	var origin, dest string
	DB.QueryRow("SELECT origin,destination FROM fare_matrix WHERE id=$1", id).Scan(&origin, &dest)
	DB.Exec("DELETE FROM fare_matrix WHERE id=$1", id)
	utils.LogAudit(DB, "DELETE", "Fare", id, fmt.Sprintf("Deleted %s → %s", origin, dest))
	utils.JSONOK(w, map[string]string{"message": "Deleted"})
}
