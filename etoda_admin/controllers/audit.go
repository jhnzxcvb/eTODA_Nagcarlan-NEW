package controllers

import (
	"fmt"
	"net/http"

	"etoda_admin/models"
	"etoda_admin/utils"
)

// ─────────────────────────────────────────────
// AuditTrail — paginated, filtered audit logs
// GET /api/audit?page=1&pageSize=10&entity=Driver&search=foo&dateFrom=...&dateTo=...
// ─────────────────────────────────────────────
func AuditTrail(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	search := r.URL.Query().Get("search")
	entity := r.URL.Query().Get("entity")
	dateFrom := r.URL.Query().Get("dateFrom")
	dateTo := r.URL.Query().Get("dateTo")
	page := utils.QueryInt(r, "page", 1)
	pageSize := utils.QueryInt(r, "pageSize", 10)
	offset := (page - 1) * pageSize

	args := []interface{}{}
	where := " WHERE 1=1"

	if search != "" {
		args = append(args, "%"+search+"%")
		n := len(args)
		where += fmt.Sprintf(
			` AND (detail ILIKE $%d OR entity_id ILIKE $%d OR performed_by ILIKE $%d)`,
			n, n, n,
		)
	}
	if entity != "" && entity != "All" {
		args = append(args, entity)
		where += fmt.Sprintf(` AND entity=$%d`, len(args))
	}
	// FIX #7: Date range filtering
	if dateFrom != "" {
		args = append(args, dateFrom)
		where += fmt.Sprintf(` AND created_at >= $%d`, len(args))
	}
	if dateTo != "" {
		args = append(args, dateTo)
		where += fmt.Sprintf(` AND created_at <= $%d`, len(args))
	}

	// Total count
	var total int
	DB.QueryRow(`SELECT COUNT(*) FROM audit_logs`+where, args...).Scan(&total)

	// Paginated data
	args = append(args, pageSize, offset)
	dataQ := `
		SELECT id, action, entity, entity_id, detail, performed_by,
		       to_char(created_at, 'YYYY-MM-DD HH24:MI:SS')
		FROM audit_logs` + where +
		fmt.Sprintf(` ORDER BY id DESC LIMIT $%d OFFSET $%d`, len(args)-1, len(args))

	rows, err := DB.Query(dataQ, args...)
	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()

	list := []models.AuditLog{}
	for rows.Next() {
		var a models.AuditLog
		rows.Scan(
			&a.ID, &a.Action, &a.Entity, &a.EntityID,
			&a.Detail, &a.PerformedBy, &a.CreatedAt,
		)
		list = append(list, a)
	}

	utils.JSONOKWithTotal(w, list, total)
}

// ─────────────────────────────────────────────
// AuditStats — summary counts for dashboard cards
// GET /api/audit/stats
// Returns: { ENROLL, CREATE, INSERT, UPDATE, DELETE, REVOKE, RESTORE,
//
//	total, today, lastActivity, byEntity }
//
// ─────────────────────────────────────────────
func AuditStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	// Per-action and per-entity counts
	rows, err := DB.Query(`
		SELECT action, entity, COUNT(*)::int AS cnt
		FROM audit_logs
		GROUP BY action, entity
	`)
	if err != nil {
		utils.JSONErr(w, err.Error(), 500)
		return
	}
	defer rows.Close()

	type StatsResult struct {
		ENROLL       int            `json:"ENROLL"`
		CREATE       int            `json:"CREATE"`
		INSERT       int            `json:"INSERT"`
		UPDATE       int            `json:"UPDATE"`
		DELETE       int            `json:"DELETE"`
		REVOKE       int            `json:"REVOKE"`
		RESTORE      int            `json:"RESTORE"`
		Total        int            `json:"total"`
		Today        int            `json:"today"`
		LastActivity *string        `json:"lastActivity"`
		ByEntity     map[string]int `json:"byEntity"`
	}

	result := StatsResult{ByEntity: map[string]int{}}

	for rows.Next() {
		var action, entity string
		var cnt int
		if err := rows.Scan(&action, &entity, &cnt); err != nil {
			continue
		}
		result.ByEntity[entity] += cnt
		result.Total += cnt
		switch action {
		case "ENROLL":
			result.ENROLL += cnt
		case "CREATE":
			result.CREATE += cnt
		case "INSERT":
			result.INSERT += cnt
		case "UPDATE":
			result.UPDATE += cnt
		case "DELETE":
			result.DELETE += cnt
		case "REVOKE":
			result.REVOKE += cnt
		case "RESTORE":
			result.RESTORE += cnt
		}
	}

	// FIX #3: Today's log count
	DB.QueryRow(`
		SELECT COUNT(*)::int FROM audit_logs
		WHERE created_at >= CURRENT_DATE
	`).Scan(&result.Today)

	// FIX #3: Most recent activity timestamp
	var lastActivity string
	err = DB.QueryRow(`
		SELECT to_char(created_at, 'YYYY-MM-DD HH24:MI:SS')
		FROM audit_logs
		ORDER BY created_at DESC
		LIMIT 1
	`).Scan(&lastActivity)
	if err == nil && lastActivity != "" {
		result.LastActivity = &lastActivity
	}

	utils.JSONOK(w, result)
}
