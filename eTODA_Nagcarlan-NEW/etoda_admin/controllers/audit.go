package controllers

import (
	"fmt"
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// AuditTrail returns the latest audit log entries, with optional filtering.
func AuditTrail(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}
	search := r.URL.Query().Get("search")
	entity := r.URL.Query().Get("entity")
	q := `SELECT id,action,entity,entity_id,detail,performed_by,to_char(created_at,'YYYY-MM-DD HH24:MI:SS') FROM audit_logs WHERE 1=1`
	args := []interface{}{}
	if search != "" {
		args = append(args, "%"+search+"%")
		q += fmt.Sprintf(` AND (detail ILIKE $%d OR entity_id ILIKE $%d OR performed_by ILIKE $%d)`, len(args), len(args), len(args))
	}
	if entity != "" && entity != "All" {
		args = append(args, entity)
		q += fmt.Sprintf(` AND entity=$%d`, len(args))
	}
	q += " ORDER BY id DESC LIMIT 200"
	rows, err := DB.Query(q, args...)
	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()
	list := []models.AuditLog{}
	for rows.Next() {
		var a models.AuditLog
		rows.Scan(&a.ID, &a.Action, &a.Entity, &a.EntityID, &a.Detail, &a.PerformedBy, &a.CreatedAt)
		list = append(list, a)
	}
	if list == nil {
		list = []models.AuditLog{}
	}
	utils.JSONOK(w, list)
}
