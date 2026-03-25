package controllers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"
)

// TODAStation represents a station in the database
type TODAStation struct {
	ID    int     `json:"id"`
	Name  string  `json:"name"`
	Lat   float64 `json:"lat"`
	Lng   float64 `json:"lng"`
	Logo  string  `json:"logo"`
	Color string  `json:"color"`
}

// GetStations handles GET /api/stations
func GetStations(w http.ResponseWriter, r *http.Request) {
	search := r.URL.Query().Get("search")
	var query string
	var args []interface{}

	if search != "" {
		query = "SELECT id, name, lat, lng, COALESCE(logo, ''), COALESCE(color, '#16a34a') FROM toda_stations WHERE name ILIKE $1 ORDER BY id DESC"
		args = append(args, "%"+search+"%")
	} else {
		query = "SELECT id, name, lat, lng, COALESCE(logo, ''), COALESCE(color, '#16a34a') FROM toda_stations ORDER BY id DESC"
	}

	rows, err := DB.Query(query, args...)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var stations []TODAStation
	for rows.Next() {
		var s TODAStation
		if err := rows.Scan(&s.ID, &s.Name, &s.Lat, &s.Lng, &s.Logo, &s.Color); err != nil {
			continue
		}
		stations = append(stations, s)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "data": stations})
}

// AddStation handles POST /api/stations
func AddStation(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	name := r.FormValue("name")
	lat, _ := strconv.ParseFloat(r.FormValue("lat"), 64)
	lng, _ := strconv.ParseFloat(r.FormValue("lng"), 64)
	color := r.FormValue("color")

	var logo string
	file, header, err := r.FormFile("logo")
	if err == nil {
		defer file.Close()
		os.MkdirAll("uploads", os.ModePerm)
		filename := strings.ReplaceAll(header.Filename, " ", "_")
		logo = fmt.Sprintf("station_%s", filename)
		out, err := os.Create(filepath.Join("uploads", logo))
		if err == nil {
			defer out.Close()
			io.Copy(out, file)
		}
	}

	var id int
	err = DB.QueryRow("INSERT INTO toda_stations (name, lat, lng, logo, color) VALUES ($1, $2, $3, $4, $5) RETURNING id",
		name, lat, lng, logo, color).Scan(&id)
	if err != nil {
		http.Error(w, "Failed to create station", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
}

// UpdateStation handles PATCH /api/stations/:id
func UpdateStation(w http.ResponseWriter, r *http.Request) {
	idStr := path.Base(r.URL.Path)
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	if err := r.ParseMultipartForm(10 << 20); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	name := r.FormValue("name")
	lat, _ := strconv.ParseFloat(r.FormValue("lat"), 64)
	lng, _ := strconv.ParseFloat(r.FormValue("lng"), 64)
	color := r.FormValue("color")

	var logo string
	file, header, err := r.FormFile("logo")
	if err == nil {
		defer file.Close()
		os.MkdirAll("uploads", os.ModePerm)
		filename := strings.ReplaceAll(header.Filename, " ", "_")
		logo = fmt.Sprintf("station_%s", filename)
		out, err := os.Create(filepath.Join("uploads", logo))
		if err == nil {
			defer out.Close()
			io.Copy(out, file)
		}
	}

	if logo != "" {
		_, err = DB.Exec("UPDATE toda_stations SET name = $1, lat = $2, lng = $3, logo = $4, color = $5 WHERE id = $6",
			name, lat, lng, logo, color, id)
	} else {
		_, err = DB.Exec("UPDATE toda_stations SET name = $1, lat = $2, lng = $3, color = $4 WHERE id = $5",
			name, lat, lng, color, id)
	}

	if err != nil {
		http.Error(w, "Failed to update station", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
}

// DeleteStation handles DELETE /api/stations/:id
func DeleteStation(w http.ResponseWriter, r *http.Request) {
	idStr := path.Base(r.URL.Path)
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	_, err = DB.Exec("DELETE FROM toda_stations WHERE id = $1", id)
	if err != nil {
		http.Error(w, "Failed to delete station", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
}
