package controllers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
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
		var u struct {
			UserID      int    `json:"user_id"`
			Username    string `json:"username"`
			FirstName   string `json:"first_name"`
			MiddleName  string `json:"middle_name"`
			LastName    string `json:"last_name"`
			PhoneNumber string `json:"phone_number"`
			Email       string `json:"email"`
			ProfilePic  string `json:"profile_pic"`
		}
		query := `SELECT user_id, username, first_name, COALESCE(middle_name, ''), last_name,
                         COALESCE(phone_number, ''), COALESCE(email, ''), COALESCE(profile_pic, '')
                  FROM users WHERE user_id = $1`

		err := DB.QueryRow(query, id).Scan(
			&u.UserID, &u.Username, &u.FirstName, &u.MiddleName, &u.LastName, &u.PhoneNumber, &u.Email, &u.ProfilePic,
		)
		if err != nil {
			log.Printf("❌ Passenger profile fetch error (ID: %s): %v", id, err)
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		json.NewEncoder(w).Encode(u)

	} else if role == "driver" {
		var d struct {
			DriverID      int    `json:"driver_id"`
			Username      string `json:"username"`
			FirstName     string `json:"first_name"`
			MiddleName    string `json:"middle_name"`
			LastName      string `json:"last_name"`
			PhoneNumber   string `json:"phone_number"`
			Email         string `json:"email"`
			LicenseNumber string `json:"license_number"`
			BodyNumber    string `json:"body_number"`
			PlateNumber   string `json:"plate_number"`
			Franchise     string `json:"franchise"`
			Association   string `json:"association"`
			ProfilePic    string `json:"profile_pic"`
		}
		// Map the actual 'drivers' table schema to the struct
		query := `SELECT id, COALESCE(username, ''), COALESCE(first_name, ''), COALESCE(middle_name, ''), COALESCE(last_name, ''),
                         COALESCE(contact, ''), COALESCE(email, ''), COALESCE(license_no, ''), COALESCE(body_no, ''), COALESCE(plate_number, ''),
                         COALESCE(franchise, ''), COALESCE(association, ''), COALESCE(profile_pic, '')
                  FROM drivers WHERE id = $1`

		err := DB.QueryRow(query, id).Scan(
			&d.DriverID, &d.Username, &d.FirstName, &d.MiddleName, &d.LastName,
			&d.PhoneNumber, &d.Email, &d.LicenseNumber, &d.BodyNumber, &d.PlateNumber,
			&d.Franchise, &d.Association, &d.ProfilePic,
		)
		if err != nil {
			log.Printf("❌ Driver profile fetch error (ID: %s): %v", id, err)
			http.Error(w, "Driver not found", http.StatusNotFound)
			return
		}

		json.NewEncoder(w).Encode(map[string]interface{}{
			"driver_id":      d.DriverID,
			"username":       d.Username,
			"first_name":     d.FirstName,
			"middle_name":    d.MiddleName,
			"last_name":      d.LastName,
			"full_name":      strings.TrimSpace(d.FirstName + " " + d.MiddleName + " " + d.LastName),
			"phone_number":   d.PhoneNumber,
			"email":          d.Email,
			"license_number": d.LicenseNumber,
			"plate_number":   d.PlateNumber,
			"body_number":    d.BodyNumber,
			"franchise":      d.Franchise,
			"association":    d.Association,
			"profile_pic":    d.ProfilePic,
		})

	} else {
		http.Error(w, "Invalid role. Use 'passenger' or 'driver'", http.StatusBadRequest)
	}
}

// UpdatePassengerProfile handles the POST request from the Passenger Edit Profile screen
func UpdatePassengerProfile(w http.ResponseWriter, r *http.Request) {
	// Parse multipart form to handle file uploads and form-data from Flutter
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		log.Printf("❌ Passenger update form error: %v", err)
		http.Error(w, "Invalid form data", http.StatusBadRequest)
		return
	}

	userIDStr := r.FormValue("user_id")
	firstName := r.FormValue("first_name")
	middleName := r.FormValue("middle_name")
	lastName := r.FormValue("last_name")
	phoneNumber := r.FormValue("phone_number")
	email := r.FormValue("email")
	currentPassword := r.FormValue("current_password")
	newPassword := r.FormValue("new_password")
	removeAvatar := r.FormValue("remove_avatar")

	userID, _ := strconv.Atoi(userIDStr)
	if userID == 0 {
		http.Error(w, "Missing or invalid user_id", http.StatusBadRequest)
		return
	}

	// Before updating, get the old avatar filename to delete it later
	var oldProfilePic string
	DB.QueryRow("SELECT COALESCE(profile_pic, '') FROM users WHERE user_id = $1", userID).Scan(&oldProfilePic)

	var profilePic string
	file, header, err := r.FormFile("avatar")
	if err == nil {
		defer file.Close()
		os.MkdirAll("uploads", os.ModePerm)
		filename := strings.ReplaceAll(header.Filename, " ", "_")
		profilePic = fmt.Sprintf("pass_%d_%s", userID, filename)
		out, err := os.Create(filepath.Join("uploads", profilePic))
		if err == nil {
			defer out.Close()
			io.Copy(out, file)
		}
	}

	// optional password change
	if currentPassword != "" || newPassword != "" {
		var storedPassword string
		err := DB.QueryRow("SELECT password_hash FROM users WHERE user_id = $1", userID).Scan(&storedPassword)
		if err != nil {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		if storedPassword != currentPassword {
			http.Error(w, "Incorrect current password", http.StatusUnauthorized)
			return
		}
	}

	var query string
	var params []interface{}
	fields := []string{"first_name=$1", "middle_name=$2", "last_name=$3", "phone_number=$4", "email=$5"}
	params = []interface{}{firstName, middleName, lastName, phoneNumber, email}
	paramIdx := 6

	if newPassword != "" {
		fields = append(fields, fmt.Sprintf("password_hash=$%d", paramIdx))
		params = append(params, newPassword)
		paramIdx++
	}
	if profilePic != "" {
		fields = append(fields, fmt.Sprintf("profile_pic=$%d", paramIdx))
		params = append(params, profilePic)
		paramIdx++
	} else if removeAvatar == "true" {
		fields = append(fields, fmt.Sprintf("profile_pic=$%d", paramIdx))
		params = append(params, "") // Set to empty string
		paramIdx++
	}
	query = fmt.Sprintf(`UPDATE users SET %s WHERE user_id=$%d`, strings.Join(fields, ", "), paramIdx)
	params = append(params, userID)

	if _, err := DB.Exec(query, params...); err != nil {
		log.Printf("❌ Passenger update error: %v", err)
		http.Error(w, "Failed to update profile", http.StatusInternalServerError)
		return
	}

	// If update was successful, delete old file
	if oldProfilePic != "" && (profilePic != "" || removeAvatar == "true") {
		os.Remove(filepath.Join("uploads", oldProfilePic))
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Passenger profile updated successfully"})
}

// UpdateDriverProfile handles the POST request from the Driver Edit Profile screen
func UpdateDriverProfile(w http.ResponseWriter, r *http.Request) {
	// Parse multipart form to handle file uploads and form-data from Flutter
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		log.Printf("❌ Driver update form error: %v", err)
		http.Error(w, "Invalid form data", http.StatusBadRequest)
		return
	}

	driverIDStr := r.FormValue("driver_id")
	firstName := r.FormValue("first_name")
	middleName := r.FormValue("middle_name")
	lastName := r.FormValue("last_name")
	phoneNumber := r.FormValue("phone_number")
	email := r.FormValue("email")

	removeAvatar := r.FormValue("remove_avatar")

	currentPassword := r.FormValue("current_password")
	newPassword := r.FormValue("new_password")

	driverID, _ := strconv.Atoi(driverIDStr)
	if driverID == 0 {
		http.Error(w, "Missing or invalid driver_id", http.StatusBadRequest)
		return
	}

	// Before updating, get the old avatar filename to delete it later
	var oldProfilePic string
	DB.QueryRow("SELECT COALESCE(profile_pic, '') FROM drivers WHERE id = $1", driverID).Scan(&oldProfilePic)

	var profilePic string
	file, header, err := r.FormFile("avatar")
	if err == nil {
		defer file.Close()
		os.MkdirAll("uploads", os.ModePerm)
		filename := strings.ReplaceAll(header.Filename, " ", "_")
		profilePic = fmt.Sprintf("driver_%d_%s", driverID, filename)
		out, err := os.Create(filepath.Join("uploads", profilePic))
		if err == nil {
			defer out.Close()
			io.Copy(out, file)
		}
	}

	// Optional password change
	if currentPassword != "" || newPassword != "" {
		var storedPassword string
		err := DB.QueryRow("SELECT password_hash FROM drivers WHERE id = $1", driverID).Scan(&storedPassword)
		if err != nil {
			http.Error(w, "Driver not found", http.StatusNotFound)
			return
		}
		if storedPassword != currentPassword {
			http.Error(w, "Incorrect current password", http.StatusUnauthorized)
			return
		}
	}

	var query string
	var params []interface{}
	fields := []string{"first_name=$1", "middle_name=$2", "last_name=$3", "contact=$4", "email=$5"}
	params = []interface{}{firstName, middleName, lastName, phoneNumber, email}
	paramIdx := 6

	if newPassword != "" {
		fields = append(fields, fmt.Sprintf("password_hash=$%d", paramIdx))
		params = append(params, newPassword)
		paramIdx++
	}
	if profilePic != "" {
		fields = append(fields, fmt.Sprintf("profile_pic=$%d", paramIdx))
		params = append(params, profilePic)
		paramIdx++
	} else if removeAvatar == "true" {
		fields = append(fields, fmt.Sprintf("profile_pic=$%d", paramIdx))
		params = append(params, "")
		paramIdx++
	}
	query = fmt.Sprintf(`UPDATE drivers SET %s WHERE id=$%d`, strings.Join(fields, ", "), paramIdx)
	params = append(params, driverID)

	if _, err := DB.Exec(query, params...); err != nil {
		log.Printf("❌ Driver update error: %v", err)
		http.Error(w, "Failed to update profile", http.StatusInternalServerError)
		return
	}

	// If update was successful, delete old file
	if oldProfilePic != "" && (profilePic != "" || removeAvatar == "true") {
		os.Remove(filepath.Join("uploads", oldProfilePic))
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Driver profile updated successfully"})
}
