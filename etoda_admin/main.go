package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	"etoda_admin/controllers"
	"etoda_admin/routes"
	"etoda_admin/utils"

	_ "github.com/lib/pq"
)

func main() {
	// build connection string using environment variables
	host := utils.Env("DB_HOST", "localhost")
	port := utils.Env("DB_PORT", "5432")
	name := utils.Env("DB_NAME", "etoda_db")
	user := utils.Env("DB_USER", "postgres")
	pass := utils.Env("DB_PASSWORD", "1") // default to 1 if unset
	if pass == "" {
		log.Println("⚠️ DB_PASSWORD not set; connection may fail")
	}
	connStr := fmt.Sprintf(
		"host=%s port=%s dbname=%s user=%s password=%s sslmode=disable",
		host, port, name, user, pass,
	)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("DB open error:", err)
	}
	if err := db.Ping(); err != nil {
		log.Fatal("? Cannot connect to PostgreSQL:", err)
	}
	fmt.Println("? Connected to PostgreSQL")

	controllers.DB = db

	mux := http.NewServeMux()
	routes.SetupRoutes(mux)

	appPort := utils.Env("PORT", "8080")
	fmt.Println("🚀 Server running on http://localhost:" + appPort)
	log.Fatal(http.ListenAndServe(":"+appPort, mux))
}
