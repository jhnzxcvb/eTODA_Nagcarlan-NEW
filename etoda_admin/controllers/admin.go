package controllers

import (
	"etoda_admin/utils"
	"fmt"
	"net/http"
	"strings"
)

// UpdateProfile handles PATCH /api/profile
func UpdateProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	adminID := r.Context().Value("admin_id")
	if adminID == nil {
		utils.JSONErr(w, "Unauthorized", 401)
		return
	}

	var b map[string]interface{}
	if err := utils.Decode(r, &b); err != nil {
		utils.JSONErr(w, "Invalid request", 400)
		return
	}

	sets, args := []string{}, []interface{}{}
	fields := []string{"full_name", "email", "username"}

	for _, f := range fields {
		if v, ok := b[f]; ok {
			args = append(args, v)
			sets = append(sets, fmt.Sprintf("%s=$%d", f, len(args)))
		}
	}

	if pw, ok := b["password"].(string); ok && strings.TrimSpace(pw) != "" {
		args = append(args, pw) // In a real app, hash this first
		sets = append(sets, fmt.Sprintf("password_hash=$%d", len(args)))
	}

	if len(sets) == 0 {
		utils.JSONErr(w, "Nothing to update", 400)
		return
	}

	args = append(args, adminID)
	query := fmt.Sprintf("UPDATE admins SET %s WHERE id=$%d", strings.Join(sets, ","), len(args))
	if _, err := DB.Exec(query, args...); err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}

	utils.LogAudit(DB, "UPDATE", "Admin", fmt.Sprintf("%v", adminID), "Updated admin profile", "Admin:"+fmt.Sprintf("%v", adminID), "Admin")
	utils.JSONOK(w, "Profile updated")
}

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
