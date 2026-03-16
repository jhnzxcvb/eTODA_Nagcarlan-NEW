package controllers

import (
	"etoda_admin/utils"
	"net/http"
)

// InsertNotification is a helper called by other controllers to create a notification.
func InsertNotification(title, description, notifType string) {
	DB.Exec(
		`INSERT INTO notifications (title, description, type, is_read, created_at)
		 VALUES ($1, $2, $3, FALSE, NOW())`,
		title, description, notifType,
	)
}

// GetNotifications returns all notifications ordered by newest first.
func GetNotifications(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	rows, err := DB.Query(`
		SELECT id, title, description, type, is_read,
		       to_char(created_at, 'YYYY-MM-DD HH24:MI:SS')
		FROM notifications
		ORDER BY created_at DESC
		LIMIT 50
	`)
	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()

	type Notification struct {
		ID          int    `json:"id"`
		Title       string `json:"title"`
		Description string `json:"description"`
		Type        string `json:"type"`
		IsRead      bool   `json:"is_read"`
		CreatedAt   string `json:"created_at"`
	}

	list := []Notification{}
	for rows.Next() {
		var n Notification
		rows.Scan(&n.ID, &n.Title, &n.Description, &n.Type, &n.IsRead, &n.CreatedAt)
		list = append(list, n)
	}
	if list == nil {
		list = []Notification{}
	}
	utils.JSONOK(w, list)
}

// MarkNotificationsRead marks all notifications as read.
func MarkNotificationsRead(w http.ResponseWriter, r *http.Request) {
	if r.Method != "PATCH" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	DB.Exec(`UPDATE notifications SET is_read = TRUE WHERE is_read = FALSE`)
	utils.JSONOK(w, map[string]string{"message": "All marked as read"})
}

// DeleteNotification deletes a single notification by ID.
func DeleteNotification(w http.ResponseWriter, r *http.Request) {
	if r.Method != "DELETE" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	id := utils.PathID(r.URL.Path, "/api/notifications/")
	DB.Exec(`DELETE FROM notifications WHERE id = $1`, id)
	utils.JSONOK(w, map[string]string{"message": "Deleted"})
}

// ClearNotifications deletes all notifications.
func ClearNotifications(w http.ResponseWriter, r *http.Request) {
	if r.Method != "DELETE" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	DB.Exec(`DELETE FROM notifications`)
	utils.JSONOK(w, map[string]string{"message": "Cleared"})
}