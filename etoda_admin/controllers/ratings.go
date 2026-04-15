package controllers

import (
	"etoda_admin/utils"
	"net/http"
	"strconv"
	"strings"
)

// Ratings handles the submission of a new rating (POST /api/ratings)
func AddRating(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var b struct {
		PassengerID int `json:"passenger_id"`
		DriverID    int `json:"driver_id"`
		Rating      int `json:"rating"`
	}

	if err := utils.Decode(r, &b); err != nil {
		utils.JSONErr(w, "Invalid request body", 400)
		return
	}

	if b.PassengerID == 0 || b.DriverID == 0 || b.Rating < 1 || b.Rating > 5 {
		utils.JSONErr(w, "Valid passenger_id, driver_id, and rating (1-5) are required", 400)
		return
	}

	_, err := DB.Exec(`
		INSERT INTO ratings (passenger_id, driver_id, rating, created_at)
		VALUES ($1, $2, $3, NOW())`,
		b.PassengerID, b.DriverID, b.Rating)

	if err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}

	utils.LogAudit(DB, "CREATE", "Rating", strconv.Itoa(b.DriverID),
		"Driver rated "+strconv.Itoa(b.Rating)+" stars", "Passenger:"+strconv.Itoa(b.PassengerID), "User")

	utils.JSONOK(w, map[string]string{"message": "Rating submitted successfully"})
}

// GetDriverRating calculates the average rating for a driver (GET /api/drivers/:id/rating)
func GetDriverRating(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	// Extract ID from path: /api/drivers/7/rating -> 7
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		utils.JSONErr(w, "Driver ID required", 400)
		return
	}
	driverID := pathParts[3]

	var avgRating float64
	var totalRatings int

	// Query average and count. COALESCE ensures we return 0.0 instead of an error if no ratings exist.
	err := DB.QueryRow(`
		SELECT COALESCE(AVG(rating), 0.0), COUNT(id) 
		FROM ratings 
		WHERE driver_id = $1`, driverID).Scan(&avgRating, &totalRatings)

	if err != nil {
		utils.JSONErr(w, "Database error: "+err.Error(), 500)
		return
	}

	utils.JSONOK(w, map[string]interface{}{
		"driver_id":      driverID,
		"average_rating": avgRating,
		"total_ratings":  totalRatings,
	})
}
