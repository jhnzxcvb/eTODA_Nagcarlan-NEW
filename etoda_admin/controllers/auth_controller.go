package controllers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"etoda_admin/models"
)

// PassengerSignup handles registration for passengers only
func PassengerSignup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Create a temporary struct to match Flutter's incoming JSON exactly
	var input struct {
		Username    string `json:"username"`
		FirstName   string `json:"first_name"`
		MiddleName  string `json:"middle_name"`
		LastName    string `json:"last_name"`
		PhoneNumber string `json:"phone_number"`
		Email       string `json:"email"`
		Password    string `json:"password"` // Matches Flutter's key
	}

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Invalid input format"})
		return
	}

	// Storing password as plain text for development as per your request
	query := `INSERT INTO users (username, first_name, middle_name, last_name, phone_number, email, password_hash) 
			  VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err := DB.Exec(query,
		input.Username, input.FirstName, input.MiddleName, input.LastName, input.PhoneNumber, input.Email, input.Password)

	w.Header().Set("Content-Type", "application/json")
	if err != nil {
		log.Printf("Signup error for %s: %v", input.Username, err)
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Username or Email already taken"})
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "Passenger registered successfully"})
}

// UnifiedLogin checks the users table first, then falls back to the drivers table
func UnifiedLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var creds struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&creds); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Invalid input format"})
		return
	}

	// --- 1. ATTEMPT PASSENGER LOGIN (users table) ---
	var u models.User
	var userPass string
	userQuery := `SELECT user_id, username, first_name, COALESCE(middle_name, ''), last_name, phone_number, email, password_hash 
                  FROM users WHERE username=$1`

	err := DB.QueryRow(userQuery, creds.Username).Scan(
		&u.UserID, &u.Username, &u.FirstName, &u.MiddleName, &u.LastName, &u.PhoneNumber, &u.Email, &userPass,
	)

	w.Header().Set("Content-Type", "application/json")

	if err == nil && userPass == creds.Password {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"role":         "passenger",
			"user_id":      u.UserID,
			"username":     u.Username,
			"first_name":   u.FirstName,
			"middle_name":  u.MiddleName,
			"last_name":    u.LastName,
			"phone_number": u.PhoneNumber,
			"email":        u.Email,
			"message":      "Passenger login successful",
		})
		return
	}

	// --- 2. ATTEMPT DRIVER LOGIN (drivers table) ---
	var d models.UserDriver
	var driverPass string
	driverQuery := `SELECT id AS driver_id, username, first_name, COALESCE(middle_name, ''), last_name, 
                           body_number, plate_number, password_hash 
                    FROM drivers WHERE username=$1`

	err = DB.QueryRow(driverQuery, creds.Username).Scan(
		&d.DriverID, &d.Username, &d.FirstName, &d.MiddleName, &d.LastName, &d.BodyNumber, &d.PlateNumber, &driverPass,
	)

	if err == nil && driverPass == creds.Password {
		fullName := fmt.Sprintf("%s %s %s", d.FirstName, d.MiddleName, d.LastName)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"role":         "driver",
			"driver_id":    d.DriverID,
			"username":     d.Username,
			"first_name":   d.FirstName,
			"middle_name":  d.MiddleName,
			"last_name":    d.LastName,
			"full_name":    fullName,
			"body_number":  d.BodyNumber,
			"plate_number": d.PlateNumber,
			"message":      "Driver login successful",
		})
		return
	}

	log.Printf("❌ Authentication failed for username: %s", creds.Username)
	w.WriteHeader(http.StatusUnauthorized)
	json.NewEncoder(w).Encode(map[string]string{"message": "Invalid username or password"})
}

// FindUserForReset identifies a user by username across both tables
func FindUserForReset(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Username string `json:"username"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Invalid input"})
		return
	}

	w.Header().Set("Content-Type", "application/json")

	// 1. Try Users table
	var userID int
	var phone string
	userQuery := "SELECT user_id, phone_number FROM users WHERE username = $1"
	err := DB.QueryRow(userQuery, req.Username).Scan(&userID, &phone)

	if err == nil {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"id":           userID,
			"role":         "passenger",
			"phone_number": phone,
		})
		return
	}

	// 2. Try Drivers table
	driverQuery := "SELECT driver_id, phone_number FROM drivers WHERE username = $1"
	err = DB.QueryRow(driverQuery, req.Username).Scan(&userID, &phone)

	if err == nil {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"id":           userID,
			"role":         "driver",
			"phone_number": phone,
		})
		return
	}

	w.WriteHeader(http.StatusNotFound)
	json.NewEncoder(w).Encode(map[string]string{"message": "Username not found"})
}

// ResetPassword handles the final database update for the new password
func ResetPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		ID          int    `json:"id"`
		Role        string `json:"role"`
		NewPassword string `json:"new_password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Invalid input"})
		return
	}

	var query string
	if req.Role == "passenger" {
		query = "UPDATE users SET password_hash = $1 WHERE user_id = $2"
	} else if req.Role == "driver" {
		query = "UPDATE drivers SET password_hash = $1 WHERE driver_id = $2"
	} else {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Invalid role"})
		return
	}

	_, err := DB.Exec(query, req.NewPassword, req.ID)
	w.Header().Set("Content-Type", "application/json")

	if err != nil {
		log.Printf("❌ Reset error: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"message": "Failed to update password"})
		return
	}

	json.NewEncoder(w).Encode(map[string]string{"message": "Password updated successfully"})
}
