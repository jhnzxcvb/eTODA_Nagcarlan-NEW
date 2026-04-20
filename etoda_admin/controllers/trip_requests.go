package controllers

import (
	"fmt"
	"math/rand"
	"net/http"
	"sync"
	"time"

	"etoda_admin/utils"
)

type TripRequest struct {
	RequestID     string    `json:"request_id"`
	PassengerID   int       `json:"passenger_id"`
	DriverID      int       `json:"driver_id"`
	PassengerName string    `json:"passenger_name"`
	Route         string    `json:"route"`
	Fare          float64   `json:"fare"`
	FromLocation  string    `json:"from_location"`
	ToLocation    string    `json:"to_location"`
	Status        string    `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
}

var (
	tripRequests   = make(map[string]TripRequest)
	tripRequestsMu sync.Mutex
)

func storeTripRequest(request TripRequest) {
	tripRequestsMu.Lock()
	defer tripRequestsMu.Unlock()
	tripRequests[request.RequestID] = request
}

func removeTripRequest(id string) {
	tripRequestsMu.Lock()
	defer tripRequestsMu.Unlock()
	delete(tripRequests, id)
}

func getTripRequest(id string) (TripRequest, bool) {
	tripRequestsMu.Lock()
	defer tripRequestsMu.Unlock()
	r, ok := tripRequests[id]
	return r, ok
}

func CreateTripRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var b struct {
		PassengerID   int     `json:"passenger_id"`
		DriverID      int     `json:"driver_id"`
		PassengerName string  `json:"passenger_name"`
		Route         string  `json:"route"`
		Fare          float64 `json:"fare"`
		FromLocation  string  `json:"from_location"`
		ToLocation    string  `json:"to_location"`
	}

	if err := utils.Decode(r, &b); err != nil {
		utils.JSONErr(w, "Invalid request body", 400)
		return
	}

	if b.PassengerID == 0 || b.DriverID == 0 {
		utils.JSONErr(w, "passenger_id and driver_id are required", 400)
		return
	}
	if b.Route == "" {
		utils.JSONErr(w, "route is required", 400)
		return
	}
	if b.Fare <= 0 {
		utils.JSONErr(w, "fare must be greater than zero", 400)
		return
	}

	rand.Seed(time.Now().UnixNano())
	reqID := fmt.Sprintf("RQ%s%04d", time.Now().Format("060102150405"), rand.Intn(10000))
	tripRequest := TripRequest{
		RequestID:     reqID,
		PassengerID:   b.PassengerID,
		DriverID:      b.DriverID,
		PassengerName: b.PassengerName,
		Route:         b.Route,
		Fare:          b.Fare,
		FromLocation:  b.FromLocation,
		ToLocation:    b.ToLocation,
		Status:        "pending",
		CreatedAt:     time.Now(),
	}

	storeTripRequest(tripRequest)

	// Notify the driver in real-time.
	payload := map[string]interface{}{
		"event": "trip_request",
		"request": map[string]interface{}{
			"request_id":     tripRequest.RequestID,
			"passenger_id":   tripRequest.PassengerID,
			"driver_id":      tripRequest.DriverID,
			"passenger_name": tripRequest.PassengerName,
			"route":          tripRequest.Route,
			"fare":           tripRequest.Fare,
			"from_location":  tripRequest.FromLocation,
			"to_location":    tripRequest.ToLocation,
			"status":         tripRequest.Status,
		},
	}
	WSHub.NotifyDriver(fmt.Sprintf("%d", b.DriverID), payload)

	utils.JSONOK(w, map[string]interface{}{
		"request_id": reqID,
		"message":    "Driver notified of your trip request.",
	})
}

func RespondTripRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var b struct {
		RequestID   string `json:"request_id"`
		DriverID    int    `json:"driver_id"`
		PassengerID int    `json:"passenger_id"`
		Accepted    bool   `json:"accepted"`
	}

	if err := utils.Decode(r, &b); err != nil {
		utils.JSONErr(w, "Invalid request body", 400)
		return
	}

	if b.RequestID == "" || b.DriverID == 0 || b.PassengerID == 0 {
		utils.JSONErr(w, "request_id, driver_id and passenger_id are required", 400)
		return
	}

	req, ok := getTripRequest(b.RequestID)
	if !ok {
		utils.JSONErr(w, "Trip request not found", 404)
		return
	}

	if req.DriverID != b.DriverID || req.PassengerID != b.PassengerID {
		utils.JSONErr(w, "Request details do not match", 400)
		return
	}

	removeTripRequest(b.RequestID)

	if b.Accepted {
		payload := map[string]interface{}{
			"event": "trip_approved",
			"request": map[string]interface{}{
				"request_id":    req.RequestID,
				"passenger_id":  req.PassengerID,
				"driver_id":     req.DriverID,
				"route":         req.Route,
				"fare":          req.Fare,
				"from_location": req.FromLocation,
				"to_location":   req.ToLocation,
			},
		}
		WSHub.NotifyPassenger(fmt.Sprintf("%d", req.PassengerID), payload)
		utils.JSONOK(w, map[string]string{"message": "Trip request accepted"})
		return
	}

	payload := map[string]interface{}{
		"event": "trip_rejected",
		"request": map[string]interface{}{
			"request_id":    req.RequestID,
			"passenger_id":  req.PassengerID,
			"driver_id":     req.DriverID,
			"route":         req.Route,
			"fare":          req.Fare,
			"from_location": req.FromLocation,
			"to_location":   req.ToLocation,
		},
	}
	WSHub.NotifyPassenger(fmt.Sprintf("%d", req.PassengerID), payload)
	utils.JSONOK(w, map[string]string{"message": "Trip request rejected"})
}
