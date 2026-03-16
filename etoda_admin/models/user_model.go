package models

type User struct {
	UserID      int    `json:"user_id"`
	Username    string `json:"username"`
	FirstName   string `json:"first_name"`
	MiddleName  string `json:"middle_name"`
	LastName    string `json:"last_name"`
	PhoneNumber string `json:"phone_number"`
	Email       string `json:"email"`
	Password    string `json:"password_hash,omitempty"`
}
