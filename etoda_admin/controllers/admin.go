package controllers

import (
	"etoda_admin/utils"
	"fmt"
	"net/http"
)

// GetSettings handles GET /api/settings
func GetSettings(w http.ResponseWriter, r *http.Request) {
	var notifications, maintenance, autoLogout bool
	err := DB.QueryRow("SELECT notifications, maintenance, auto_logout FROM system_settings WHERE id = 1").
		Scan(&notifications, &maintenance, &autoLogout)
	if err != nil {
		// If no settings exist, return defaults
		utils.JSONOK(w, map[string]bool{"notifications": true, "maintenance": false, "autoLogout": false})
		return
	}
	utils.JSONOK(w, map[string]bool{"notifications": notifications, "maintenance": maintenance, "autoLogout": autoLogout})
}

// UpdateSettings handles PATCH /api/settings
func UpdateSettings(w http.ResponseWriter, r *http.Request) {
	var b map[string]bool
	utils.Decode(r, &b)

	for k, v := range b {
		column := ""
		switch k {
		case "notifications":
			column = "notifications"
		case "maintenance":
			column = "maintenance"
		case "autoLogout":
			column = "auto_logout"
		}
		if column != "" {
			DB.Exec(fmt.Sprintf("UPDATE system_settings SET %s = $1 WHERE id = 1", column), v)
		}
	}
	adminID := fmt.Sprintf("%v", r.Context().Value("admin_id"))
	utils.LogAudit(DB, "UPDATE", "Settings", "System", "Updated system preferences", "Admin:"+adminID, "Admin")
	utils.JSONOK(w, "Settings updated")
}
