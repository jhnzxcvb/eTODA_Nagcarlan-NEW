package utils

import (
	"database/sql"
	"encoding/json"
	"math/rand"
	"net/http"
	"os"
	"strings"
)

// Env returns the value of environment variable k or the default d when unset.
func Env(k, d string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return d
}

// JSONOK writes a success JSON response.
func JSONOK(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "data": data})
}

// JSONErr writes an error JSON response with a status code.
func JSONErr(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]interface{}{"success": false, "error": msg})
}

// Decode parses JSON body into v.
func Decode(r *http.Request, v interface{}) error {
	return json.NewDecoder(r.Body).Decode(v)
}

// PathID strips prefix from path.
func PathID(path, prefix string) string {
	return strings.TrimPrefix(path, prefix)
}

// RandHex returns a random 4‑character hex string.
func RandHex() string {
	const h = "abcdef0123456789"
	b := make([]byte, 4)
	for i := range b {
		b[i] = h[rand.Intn(len(h))]
	}
	return string(b)
}

// LogAudit inserts an audit record using the provided database handle.
func LogAudit(db *sql.DB, action, entity, entityID, detail string) {
	db.Exec(
		`INSERT INTO audit_logs (action, entity, entity_id, detail, performed_by, created_at) VALUES ($1,$2,$3,$4,'Admin',NOW())`,
		action, entity, entityID, detail,
	)
}
