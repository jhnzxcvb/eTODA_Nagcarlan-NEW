package controllers

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"etoda_admin/models"
)

// PassengerSignup handles registration for passengers only
func PassengerSignup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input struct {
		Username    string `json:"username"`
		FirstName   string `json:"first_name"`
		MiddleName  string `json:"middle_name"`
		LastName    string `json:"last_name"`
		PhoneNumber string `json:"phone_number"`
		Email       string `json:"email"`
		Password    string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Invalid input format"})
		return
	}

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

	// 🔔 Auto-insert notification for new passenger
	go NotifyNewPassenger(input.FirstName + " " + input.LastName)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "Passenger registered successfully"})
}

// AdminSignup allows creation of new administrator accounts.
func AdminSignup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input struct {
		Username string `json:"username"`
		Password string `json:"password"`
		FullName string `json:"full_name"`
		Email    string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Invalid input format"})
		return
	}

	query := `INSERT INTO admins (username, password_hash, full_name, email) 
				VALUES ($1, $2, $3, $4)`
	_, err := DB.Exec(query, input.Username, input.Password, input.FullName, input.Email)
	w.Header().Set("Content-Type", "application/json")
	if err != nil {
		log.Printf("Admin signup error for %s: %v", input.Username, err)
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"message": "Username already taken"})
		return
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "Admin registered successfully"})
}

// UnifiedLogin checks the admins table first, then users, then drivers
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

	w.Header().Set("Content-Type", "application/json")

	// --- 1. ATTEMPT ADMIN LOGIN ---
	var a models.Admin
	var adminPass string
	adminQuery := `SELECT admin_id, username, COALESCE(full_name, ''), COALESCE(email, ''), password_hash
                  FROM admins WHERE username=$1`
	err := DB.QueryRow(adminQuery, creds.Username).Scan(&a.AdminID, &a.Username, &a.FullName, &a.Email, &adminPass)
	if err == nil && adminPass == creds.Password {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success":   true,
			"role":      "admin",
			"admin_id":  a.AdminID,
			"username":  a.Username,
			"full_name": a.FullName,
			"email":     a.Email,
			"message":   "Admin login successful",
		})
		return
	}

	// --- 2. ATTEMPT PASSENGER LOGIN ---
	var u struct {
		UserID      int
		Username    string
		FirstName   string
		MiddleName  string
		LastName    string
		PhoneNumber string
		Email       string
		ProfilePic  string
	}
	var userPass string
	userQuery := `SELECT user_id, username, first_name, COALESCE(middle_name, ''), last_name,
                         COALESCE(phone_number, ''), COALESCE(email, ''), COALESCE(profile_pic, ''), password_hash
                  FROM users WHERE username=$1`
	err = DB.QueryRow(userQuery, creds.Username).Scan(
		&u.UserID, &u.Username, &u.FirstName, &u.MiddleName, &u.LastName, &u.PhoneNumber, &u.Email, &u.ProfilePic, &userPass,
	)

	if err == nil && userPass == creds.Password {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success":      true,
			"role":         "passenger",
			"user_id":      u.UserID,
			"username":     u.Username,
			"first_name":   u.FirstName,
			"middle_name":  u.MiddleName,
			"last_name":    u.LastName,
			"phone_number": u.PhoneNumber,
			"email":        u.Email,
			"profile_pic":  u.ProfilePic,
			"message":      "Passenger login successful",
		})
		return
	}

	// --- 3. ATTEMPT DRIVER LOGIN ---
	var d struct {
		DriverID      int
		Username      string
		FirstName     string
		MiddleName    string
		LastName      string
		PhoneNumber   string
		BodyNumber    string
		LicenseNumber string
		PlateNumber   string
	}
	var driverPass string
	var email, franchise, association, profilePic string

	// Fetch necessary fields using the actual 'drivers' table schema
	driverQuery := `SELECT id, COALESCE(username, ''), COALESCE(first_name, ''), COALESCE(middle_name, ''), COALESCE(last_name, ''),
                           COALESCE(contact, ''), COALESCE(body_no, ''),
                           COALESCE(license_no, ''), COALESCE(plate_number, ''), 
                           COALESCE(email, ''), COALESCE(franchise, ''), COALESCE(association, ''), COALESCE(profile_pic, ''), COALESCE(password_hash, '')
                    FROM drivers WHERE username=$1`
	err = DB.QueryRow(driverQuery, creds.Username).Scan(
		&d.DriverID, &d.Username, &d.FirstName, &d.MiddleName, &d.LastName,
		&d.PhoneNumber, &d.BodyNumber, &d.LicenseNumber, &d.PlateNumber, &email, &franchise, &association, &profilePic, &driverPass,
	)

	if err == nil && driverPass == creds.Password {

		json.NewEncoder(w).Encode(map[string]interface{}{
			"success":        true,
			"role":           "driver",
			"driver_id":      d.DriverID,
			"username":       d.Username,
			"first_name":     d.FirstName,
			"middle_name":    d.MiddleName,
			"last_name":      d.LastName,
			"full_name":      strings.TrimSpace(d.FirstName + " " + d.MiddleName + " " + d.LastName),
			"phone_number":   d.PhoneNumber,
			"email":          email,
			"body_number":    d.BodyNumber,
			"plate_number":   d.PlateNumber,
			"license_number": d.LicenseNumber,
			"franchise":      franchise,
			"association":    association,
			"profile_pic":    profilePic,
			"message":        "Driver login successful",
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

	driverQuery := "SELECT id, contact FROM drivers WHERE username = $1"
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
		query = "UPDATE drivers SET password_hash = $1 WHERE id = $2"
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
