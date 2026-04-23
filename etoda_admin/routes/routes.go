package routes

import (
	"net/http"
	"strings"

	"etoda_admin/controllers"
	"etoda_admin/middleware"
)

// SetupRoutes registers all endpoints for the eTODA system (Web Admin & Mobile App)
func SetupRoutes(mux *http.ServeMux) {

	// --- 1. SYSTEM / UTILITY ENDPOINTS ---
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.Write([]byte("🚀 Nagcarlan eTODA API is running..."))
	})

	// Serve uploaded files (e.g., logos, avatars) with CORS headers
	mux.HandleFunc("/uploads/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		if r.Method == "OPTIONS" {
			return
		}
		http.StripPrefix("/uploads/", http.FileServer(http.Dir("uploads"))).ServeHTTP(w, r)
	})

	// --- 1.5 WEBSOCKET ENDPOINTS (Real-Time Driver and Passenger Notifications) ---
	// Driver app connects here when shift starts: ws://host:port/ws/driver?driverID=<id>
	mux.HandleFunc("/ws/driver", controllers.DriverWebSocketHandler)
	// Passenger app connects here when trip starts: ws://host:port/ws/passenger?passengerID=<id>
	mux.HandleFunc("/ws/passenger", controllers.PassengerWebSocketHandler)

	// --- 2. UNIFIED AUTH & SIGNUP (Mobile & Web) ---
	mux.HandleFunc("/api/login", middleware.CORS(middleware.JSONContentTypeMiddleware(controllers.UnifiedLogin)))
	mux.HandleFunc("/api/signup", middleware.CORS(middleware.JSONContentTypeMiddleware(controllers.PassengerSignup)))
	mux.HandleFunc("/api/admin/signup", middleware.CORS(middleware.JSONContentTypeMiddleware(controllers.AdminSignup)))

	// Forgot Password Flow
	mux.HandleFunc("/api/forgot-password/find-user", middleware.CORS(controllers.FindUserForReset))
	mux.HandleFunc("/api/forgot-password/reset", middleware.CORS(controllers.ResetPassword))

	// --- 3. PROFILE MANAGEMENT ---
	mux.HandleFunc("/api/profile", middleware.CORS(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == "PATCH" {
			controllers.UpdateProfile(w, r)
			return
		}
		controllers.GetProfile(w, r)
	}))
	mux.HandleFunc("/api/passenger/update-profile", middleware.CORS(controllers.UpdatePassengerProfile))
	mux.HandleFunc("/api/driver/update-profile", middleware.CORS(controllers.UpdateDriverProfile))

	// --- 4. ADMIN & DASHBOARD ENDPOINTS (Web App) ---
	mux.HandleFunc("/api/dashboard", middleware.CORS(controllers.Dashboard))
	mux.HandleFunc("/api/dashboard/report", middleware.CORS(controllers.GenerateReport))

	// ── AUDIT: /stats must be registered BEFORE /audit to avoid prefix conflict ──
	mux.HandleFunc("/api/audit/stats", middleware.CORS(controllers.AuditStats))
	mux.HandleFunc("/api/audit", middleware.CORS(controllers.AuditTrail))

	// Drivers Management
	mux.HandleFunc("/api/drivers", middleware.CORS(controllers.Drivers))
	mux.HandleFunc("/api/drivers/", middleware.CORS(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/rating") {
			controllers.GetDriverRating(w, r)
			return
		}
		controllers.DriverByID(w, r)
	}))

	// Passengers Management
	mux.HandleFunc("/api/passengers", middleware.CORS(controllers.Passengers))
	mux.HandleFunc("/api/passengers/", middleware.CORS(controllers.PassengerByID))

	// Fare Management
	mux.HandleFunc("/api/fare", middleware.CORS(controllers.Fare))
	mux.HandleFunc("/api/fare/", middleware.CORS(controllers.FareByID))

	// ── PAYMENTS: GET = list all, POST = create from Flutter app ──
	mux.HandleFunc("/api/payments", middleware.CORS(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case "GET":
			controllers.Payments(w, r)
		case "POST":
			controllers.CreatePayment(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}))
	mux.HandleFunc("/api/payments/", middleware.CORS(controllers.PaymentByID))

	// QR Codes & Operations
	mux.HandleFunc("/api/qrcodes/lookup", middleware.CORS(controllers.QRLookup))
	mux.HandleFunc("/api/qrcodes", middleware.CORS(controllers.QRCodes))
	mux.HandleFunc("/api/qrcodes/", middleware.CORS(controllers.QRCodeByID))

	// Ratings
	mux.HandleFunc("/api/ratings", middleware.CORS(middleware.JSONContentTypeMiddleware(controllers.AddRating)))

	// Complaints Management
	mux.HandleFunc("/api/complaints", middleware.CORS(controllers.Complaints))
	mux.HandleFunc("/api/complaints/", middleware.CORS(controllers.ComplaintByID))

	// Trips
	mux.HandleFunc("/api/trips", middleware.CORS(controllers.Trips))
	// mux.HandleFunc("/api/trips/active", middleware.CORS(controllers.ActiveTrip))
	mux.HandleFunc("/api/trips/complete", middleware.CORS(controllers.CompleteTrip))
	// mux.HandleFunc("/api/trips/cancel", middleware.CORS(controllers.CancelTrip))
	mux.HandleFunc("/api/trip_requests", middleware.CORS(controllers.CreateTripRequest))
	mux.HandleFunc("/api/trip_requests/respond", middleware.CORS(controllers.RespondTripRequest))

	// TODA Stations Management
	mux.HandleFunc("/api/stations", middleware.CORS(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case "GET":
			controllers.GetStations(w, r)
		case "POST":
			controllers.AddStation(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	mux.HandleFunc("/api/stations/", middleware.CORS(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case "PATCH":
			controllers.UpdateStation(w, r)
		case "DELETE":
			controllers.DeleteStation(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Notifications
	mux.HandleFunc("/api/notifications", middleware.CORS(controllers.GetNotifications))
	mux.HandleFunc("/api/notifications/read", middleware.CORS(controllers.MarkNotificationsRead))
	mux.HandleFunc("/api/notifications/clear", middleware.CORS(controllers.ClearNotifications))
	mux.HandleFunc("/api/notifications/", middleware.CORS(controllers.DeleteNotification))

	// --- 6. SYSTEM SETTINGS ---
	mux.HandleFunc("/api/settings", middleware.CORS(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case "GET":
			controllers.GetSettings(w, r)
		case "PATCH":
			controllers.UpdateSettings(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}))
}
