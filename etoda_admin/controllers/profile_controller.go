package controllers

import (
	"encoding/json"
	"log"
	"net/http"

	"etoda_admin/models"
)

// GetProfile fetches the details of a user or driver based on their ID and Role
func GetProfile(w http.ResponseWriter, r *http.Request) {
	// Retrieve parameters from URL: /profile?role=passenger&id=1
	role := r.URL.Query().Get("role")
	id := r.URL.Query().Get("id")

	if id == "" || role == "" {
		http.Error(w, "Missing id or role parameter", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	if role == "passenger" {
		var u models.User
		query := `SELECT user_id, username, first_name, COALESCE(middle_name, ''), last_name, phone_number, email 
                  FROM users WHERE user_id = $1`

		err := DB.QueryRow(query, id).Scan(
			&u.UserID, &u.Username, &u.FirstName, &u.MiddleName, &u.LastName, &u.PhoneNumber, &u.Email,
		)
		if err != nil {
			log.Printf("❌ Passenger profile fetch error (ID: %s): %v", id, err)
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		json.NewEncoder(w).Encode(u)

	} else if role == "driver" {
		var d models.UserDriver
		query := `SELECT id AS driver_id, username, first_name, COALESCE(middle_name, ''), last_name, 
                         phone_number, plate_number, COALESCE(body_number, ''), COALESCE(license_no,'') AS license_number 
                  FROM drivers WHERE id = $1`

		err := DB.QueryRow(query, id).Scan(
			&d.DriverID, &d.Username, &d.FirstName, &d.MiddleName, &d.LastName,
			&d.PhoneNumber, &d.PlateNumber, &d.BodyNumber, &d.LicenseNumber,
		)
		if err != nil {
			log.Printf("❌ Driver profile fetch error (ID: %s): %v", id, err)
			http.Error(w, "Driver not found", http.StatusNotFound)
			return
		}
		json.NewEncoder(w).Encode(d)

	} else {
		http.Error(w, "Invalid role. Use 'passenger' or 'driver'", http.StatusBadRequest)
	}
}

// UpdatePassengerProfile handles the POST request from the Passenger Edit Profile screen
func UpdatePassengerProfile(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID          int    `json:"user_id"`
		FirstName       string `json:"first_name"`
		MiddleName      string `json:"middle_name"`
		LastName        string `json:"last_name"`
		PhoneNumber     string `json:"phone_number"`
		CurrentPassword string `json:"current_password"`
		NewPassword     string `json:"new_password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// optional password change
	if req.CurrentPassword != "" || req.NewPassword != "" {
		var storedPassword string
		err := DB.QueryRow("SELECT password_hash FROM users WHERE user_id = $1", req.UserID).Scan(&storedPassword)
		if err != nil {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		if storedPassword != req.CurrentPassword {
			http.Error(w, "Incorrect current password", http.StatusUnauthorized)
			return
		}
	}

	var query string
	var params []interface{}
	if req.NewPassword != "" {
		query = `UPDATE users SET first_name=$1, middle_name=$2, last_name=$3, phone_number=$4, password_hash=$5 
                 WHERE user_id=$6`
		params = []interface{}{req.FirstName, req.MiddleName, req.LastName, req.PhoneNumber, req.NewPassword, req.UserID}
	} else {
		query = `UPDATE users SET first_name=$1, middle_name=$2, last_name=$3, phone_number=$4 
                 WHERE user_id=$5`
		params = []interface{}{req.FirstName, req.MiddleName, req.LastName, req.PhoneNumber, req.UserID}
	}

	if _, err := DB.Exec(query, params...); err != nil {
		log.Printf("❌ Passenger update error: %v", err)
		http.Error(w, "Failed to update profile", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Passenger profile updated successfully"})
}

// UpdateDriverProfile handles the POST request from the Driver Edit Profile screen
func UpdateDriverProfile(w http.ResponseWriter, r *http.Request) {
	var req struct {
		DriverID        int    `json:"driver_id"`
		FirstName       string `json:"first_name"`
		MiddleName      string `json:"middle_name"`
		LastName        string `json:"last_name"`
		PhoneNumber     string `json:"phone_number"`
		PlateNumber     string `json:"plate_number"`
		CurrentPassword string `json:"current_password"`
		NewPassword     string `json:"new_password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.CurrentPassword != "" || req.NewPassword != "" {
		var storedPassword string
		err := DB.QueryRow("SELECT password_hash FROM drivers WHERE id = $1", req.DriverID).Scan(&storedPassword)
		if err != nil {
			http.Error(w, "Driver not found", http.StatusNotFound)
			return
		}
		if storedPassword != req.CurrentPassword {
			http.Error(w, "Incorrect current password", http.StatusUnauthorized)
			return
		}
	}

	var query string
	var params []interface{}
	if req.NewPassword != "" {
		query = `UPDATE drivers SET first_name=$1, middle_name=$2, last_name=$3, phone_number=$4, plate_number=$5, password_hash=$6 
                 WHERE id=$7`
		params = []interface{}{req.FirstName, req.MiddleName, req.LastName, req.PhoneNumber, req.PlateNumber, req.NewPassword, req.DriverID}
	} else {
		query = `UPDATE drivers SET first_name=$1, middle_name=$2, last_name=$3, phone_number=$4, plate_number=$5 
                 WHERE id=$6`
		params = []interface{}{req.FirstName, req.MiddleName, req.LastName, req.PhoneNumber, req.PlateNumber, req.DriverID}
	}

	if _, err := DB.Exec(query, params...); err != nil {
		log.Printf("❌ Driver update error: %v", err)
		http.Error(w, "Failed to update profile", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Driver profile updated successfully"})
}
