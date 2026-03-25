package routes

import (
	"net/http"

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

	// --- 2. UNIFIED AUTH & SIGNUP (Mobile & Web) ---
	// Using CORS and JSON middleware to ensure cross-platform compatibility
	mux.HandleFunc("/api/login", middleware.CORS(middleware.JSONContentTypeMiddleware(controllers.UnifiedLogin)))
	mux.HandleFunc("/api/signup", middleware.CORS(middleware.JSONContentTypeMiddleware(controllers.PassengerSignup)))
	// administrative accounts (web portal)
	mux.HandleFunc("/api/admin/signup", middleware.CORS(middleware.JSONContentTypeMiddleware(controllers.AdminSignup)))

	// Forgot Password Flow
	mux.HandleFunc("/api/forgot-password/find-user", middleware.CORS(controllers.FindUserForReset))
	mux.HandleFunc("/api/forgot-password/reset", middleware.CORS(controllers.ResetPassword))

	// --- 3. PROFILE MANAGEMENT ---
	mux.HandleFunc("/api/profile", middleware.CORS(controllers.GetProfile))
	mux.HandleFunc("/api/passenger/update-profile", middleware.CORS(controllers.UpdatePassengerProfile))
	mux.HandleFunc("/api/driver/update-profile", middleware.CORS(controllers.UpdateDriverProfile))

	// --- 4. ADMIN & DASHBOARD ENDPOINTS (Web App) ---
	mux.HandleFunc("/api/dashboard", middleware.CORS(controllers.Dashboard))
	mux.HandleFunc("/api/audit", middleware.CORS(controllers.AuditTrail))

	// Drivers Management
	mux.HandleFunc("/api/drivers", middleware.CORS(controllers.Drivers))
	mux.HandleFunc("/api/drivers/", middleware.CORS(controllers.DriverByID))

	// Passengers Management
	mux.HandleFunc("/api/passengers", middleware.CORS(controllers.Passengers))
	mux.HandleFunc("/api/passengers/", middleware.CORS(controllers.PassengerByID))

	// Fare & Payments
	mux.HandleFunc("/api/fare", middleware.CORS(controllers.Fare))
	mux.HandleFunc("/api/fare/", middleware.CORS(controllers.FareByID))
	mux.HandleFunc("/api/payments", middleware.CORS(controllers.Payments))
	mux.HandleFunc("/api/payments/", middleware.CORS(controllers.PaymentByID))

	// QR Codes & Operations
	mux.HandleFunc("/api/qrcodes", middleware.CORS(controllers.QRCodes))
	mux.HandleFunc("/api/qrcodes/", middleware.CORS(controllers.QRCodeByID))
	mux.HandleFunc("/api/complaints", middleware.CORS(controllers.Complaints))
	mux.HandleFunc("/api/complaints/", middleware.CORS(controllers.ComplaintByID))
	mux.HandleFunc("/api/trips", middleware.CORS(controllers.Trips))

	mux.HandleFunc("/api/notifications", middleware.CORS(controllers.GetNotifications))
	mux.HandleFunc("/api/notifications/read", middleware.CORS(controllers.MarkNotificationsRead))
	mux.HandleFunc("/api/notifications/clear", middleware.CORS(controllers.ClearNotifications))
	mux.HandleFunc("/api/notifications/", middleware.CORS(controllers.DeleteNotification))

	mux.HandleFunc("/api/qrcodes/lookup", middleware.CORS(controllers.QRLookup))
}
