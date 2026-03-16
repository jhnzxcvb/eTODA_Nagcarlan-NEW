package models

// UserDriver is used by authentication/profile handlers for mobile users.
type UserDriver struct {
	DriverID      int    `json:"driver_id"`
	Username      string `json:"username"`
	FirstName     string `json:"first_name"`
	MiddleName    string `json:"middle_name"`
	LastName      string `json:"last_name"`
	PhoneNumber   string `json:"phone_number"`
	Email         string `json:"email"` // Added to match potential future updates
	PlateNumber   string `json:"plate_number"`
	BodyNumber    string `json:"body_number"`
	LicenseNumber string `json:"license_number"`
	IsActive      bool   `json:"is_active"`
	Password      string `json:"password,omitempty"`
}
