package controllers

import (
	"encoding/csv"
	"etoda_admin/utils"
	"fmt"
	"log"
	"net/http"
	"time"
)

// Dashboard returns aggregated statistics.
func Dashboard(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var activeDrivers, totalDrivers, passengers, revenueCount, pendingComplaints, tripsToday, totalTrips, activeQR int                                             // Today's values
	var activeDriversYesterday, totalDriversYesterday, passengersYesterday, pendingComplaintsYesterday, tripsYesterday, totalTripsYesterday, activeQRYesterday int // Yesterday's values
	var revenueToday, revenueYesterday float64

	// Helper function to execute a query and scan, logging any errors.
	// For dashboard metrics, we often prefer to return 0 for a failed metric
	// rather than failing the entire request, but logging is crucial.
	queryAndScan := func(query string, dest ...interface{}) {
		err := DB.QueryRow(query).Scan(dest...)
		if err != nil {
			log.Printf("Dashboard DB query error: %v for query: %s", err, query)
			// Variables will retain their zero-values (0 or 0.0) if an error occurs,
			// which is acceptable for a dashboard if we want partial data.
			// If a critical error should halt the response, you'd add:
			// utils.JSONErr(w, "Internal server error", http.StatusInternalServerError)
			// return
		}
	}

	// --- Today's Stats ---
	queryAndScan(`SELECT COUNT(*) FROM drivers WHERE status='Active'`, &activeDrivers)
	queryAndScan(`SELECT COUNT(*) FROM drivers`, &totalDrivers)
	queryAndScan(`SELECT COUNT(*) FROM users`, &passengers)
	// Revenue Queries: Updated to use 'Paid' status and localized Manila date logic.
	// We compare the Manila-shifted paid_at date to the Manila-shifted current date.
	queryAndScan(`SELECT COALESCE(SUM(amount),0)::FLOAT8, COUNT(*)::INT FROM payments WHERE status ILIKE 'Paid' AND (paid_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &revenueToday, &revenueCount)
	queryAndScan(`SELECT COUNT(*) FROM complaints WHERE status!='Resolved'`, &pendingComplaints)
	// Trip Queries: Applied the same simplified date logic.
	queryAndScan(`SELECT COUNT(*) FROM trip_logs WHERE (started_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &tripsToday)
	queryAndScan(`SELECT COUNT(*) FROM trip_logs`, &totalTrips)
	queryAndScan(`SELECT COUNT(*) FROM qr_codes WHERE status='Active'`, &activeQR)

	// --- Yesterday's Stats (for trend calculation) ---
	// For cumulative metrics (active_drivers, total_drivers, passengers, pending_complaints, total_trips, active_qr),
	// "yesterday's value" is defined as the count of records created *before the start of today* that meet the criteria.
	// This provides the total count as of the end of yesterday.
	queryAndScan(`SELECT COUNT(*) FROM drivers WHERE status='Active' AND created_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &activeDriversYesterday)
	queryAndScan(`SELECT COUNT(*) FROM drivers WHERE created_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &totalDriversYesterday)
	queryAndScan(`SELECT COUNT(*) FROM users WHERE created_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &passengersYesterday)
	queryAndScan(`SELECT COALESCE(SUM(amount),0)::FLOAT8 FROM payments WHERE status ILIKE 'Paid' AND (paid_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date - 1`, &revenueYesterday)
	queryAndScan(`SELECT COUNT(*) FROM complaints WHERE status!='Resolved' AND reported_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &pendingComplaintsYesterday)
	// For daily trips, we need the count specifically for yesterday.
	queryAndScan(`SELECT COUNT(*) FROM trip_logs WHERE (started_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date - 1`, &tripsYesterday)
	queryAndScan(`SELECT COUNT(*) FROM trip_logs WHERE started_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &totalTripsYesterday)
	queryAndScan(`SELECT COUNT(*) FROM qr_codes WHERE status='Active' AND issued_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &activeQRYesterday)

	// Diagnostic Logging
	log.Printf("[Dashboard Stats] Today: Active Drivers: %d, Total Drivers: %d, Passengers: %d, Revenue: %.2f (%d txns), Pending Complaints: %d, Trips Today: %d, Total Trips: %d, Active QR: %d", activeDrivers, totalDrivers, passengers, revenueToday, revenueCount, pendingComplaints, tripsToday, totalTrips, activeQR)
	log.Printf("[Dashboard Stats] Yesterday: Active Drivers: %d, Total Drivers: %d, Passengers: %d, Revenue: %.2f, Pending Complaints: %d, Trips Yesterday: %d, Total Trips: %d, Active QR: %d", activeDriversYesterday, totalDriversYesterday, passengersYesterday, revenueYesterday, pendingComplaintsYesterday, tripsYesterday, totalTripsYesterday, activeQRYesterday)

	utils.JSONOK(w, map[string]interface{}{
		"active_drivers": activeDrivers,
		"total_drivers":  totalDrivers,
		"passengers":     passengers,
		"revenue_today":  revenueToday,
		"revenue_count":  revenueCount,
		// Ensure revenue_yesterday is included in the JSON response
		"pending_complaints": pendingComplaints,
		"trips_today":        tripsToday,
		"total_trips":        totalTrips,
		"active_qr":          activeQR,

		"active_drivers_yesterday":     activeDriversYesterday,
		"total_drivers_yesterday":      totalDriversYesterday,
		"passengers_yesterday":         passengersYesterday,
		"revenue_yesterday":            revenueYesterday, // Already present, but listed for clarity
		"pending_complaints_yesterday": pendingComplaintsYesterday,
		"trips_yesterday":              tripsYesterday,
		"total_trips_yesterday":        totalTripsYesterday,
		"active_qr_yesterday":          activeQRYesterday,
	})
}

// GenerateReport exports dashboard stats as a CSV file.
func GenerateReport(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	var activeDrivers, totalDrivers, passengers, revenueCount, pendingComplaints, tripsToday, totalTrips, activeQR int
	var activeDriversYesterday, totalDriversYesterday, passengersYesterday, pendingComplaintsYesterday, tripsYesterday, totalTripsYesterday, activeQRYesterday int
	var revenueToday, revenueYesterday float64

	queryAndScan := func(query string, dest ...interface{}) {
		err := DB.QueryRow(query).Scan(dest...)
		if err != nil {
			log.Printf("Report DB query error: %v", err)
		}
	}

	// Fetch Today's Stats
	queryAndScan(`SELECT COUNT(*) FROM drivers WHERE status='Active'`, &activeDrivers)
	queryAndScan(`SELECT COUNT(*) FROM drivers`, &totalDrivers)
	queryAndScan(`SELECT COUNT(*) FROM users`, &passengers)
	queryAndScan(`SELECT COALESCE(SUM(amount),0)::FLOAT8, COUNT(*)::INT FROM payments WHERE status ILIKE 'Paid' AND (paid_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &revenueToday, &revenueCount)
	queryAndScan(`SELECT COUNT(*) FROM complaints WHERE status!='Resolved'`, &pendingComplaints)
	queryAndScan(`SELECT COUNT(*) FROM trip_logs WHERE (started_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &tripsToday)
	queryAndScan(`SELECT COUNT(*) FROM trip_logs`, &totalTrips)
	queryAndScan(`SELECT COUNT(*) FROM qr_codes WHERE status='Active'`, &activeQR)

	// Fetch Yesterday's Stats
	queryAndScan(`SELECT COUNT(*) FROM drivers WHERE status='Active' AND created_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &activeDriversYesterday)
	queryAndScan(`SELECT COUNT(*) FROM drivers WHERE created_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &totalDriversYesterday)
	queryAndScan(`SELECT COUNT(*) FROM users WHERE created_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &passengersYesterday)
	queryAndScan(`SELECT COALESCE(SUM(amount),0)::FLOAT8 FROM payments WHERE status ILIKE 'Paid' AND (paid_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date - 1`, &revenueYesterday)
	queryAndScan(`SELECT COUNT(*) FROM complaints WHERE status!='Resolved' AND reported_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &pendingComplaintsYesterday)
	queryAndScan(`SELECT COUNT(*) FROM trip_logs WHERE (started_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date - 1`, &tripsYesterday)
	queryAndScan(`SELECT COUNT(*) FROM trip_logs WHERE started_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &totalTripsYesterday)
	queryAndScan(`SELECT COUNT(*) FROM qr_codes WHERE status='Active' AND issued_at < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date`, &activeQRYesterday)

	w.Header().Set("Content-Type", "text/csv")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment;filename=etoda_dashboard_report_%s.csv", time.Now().Format("2006-01-02")))

	writer := csv.NewWriter(w)
	defer writer.Flush()

	// CSV Headers
	writer.Write([]string{"Metric", "Current Value", "Previous (Yesterday/Cumulative)", "Difference"})

	// Data Rows
	writer.Write([]string{"Active Drivers", fmt.Sprint(activeDrivers), fmt.Sprint(activeDriversYesterday), fmt.Sprint(activeDrivers - activeDriversYesterday)})
	writer.Write([]string{"Total Drivers", fmt.Sprint(totalDrivers), fmt.Sprint(totalDriversYesterday), fmt.Sprint(totalDrivers - totalDriversYesterday)})
	writer.Write([]string{"Total Passengers", fmt.Sprint(passengers), fmt.Sprint(passengersYesterday), fmt.Sprint(passengers - passengersYesterday)})
	writer.Write([]string{"Revenue Today", fmt.Sprintf("%.2f", revenueToday), fmt.Sprintf("%.2f", revenueYesterday), fmt.Sprintf("%.2f", revenueToday-revenueYesterday)})
	writer.Write([]string{"Revenue Transactions", fmt.Sprint(revenueCount), "-", "-"})
	writer.Write([]string{"Open Complaints", fmt.Sprint(pendingComplaints), fmt.Sprint(pendingComplaintsYesterday), fmt.Sprint(pendingComplaints - pendingComplaintsYesterday)})
	writer.Write([]string{"Trips Today", fmt.Sprint(tripsToday), fmt.Sprint(tripsYesterday), fmt.Sprint(tripsToday - tripsYesterday)})
	writer.Write([]string{"Total Trips", fmt.Sprint(totalTrips), fmt.Sprint(totalTripsYesterday), fmt.Sprint(totalTrips - totalTripsYesterday)})
	writer.Write([]string{"Active QR Codes", fmt.Sprint(activeQR), fmt.Sprint(activeQRYesterday), fmt.Sprint(activeQR - activeQRYesterday)})

	adminID := fmt.Sprintf("%v", r.Context().Value("admin_id"))
	utils.LogAudit(DB, "EXPORT", "Dashboard", "Report", "Generated CSV Dashboard Report", "Admin:"+adminID, "Admin")
}

// GetTripChartData fetches time-series trip data for the dashboard chart.
func GetTripChartData(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		utils.JSONErr(w, "Method not allowed", 405)
		return
	}

	dateRange := r.URL.Query().Get("range")
	if dateRange == "" {
		utils.JSONErr(w, "Missing 'range' parameter", http.StatusBadRequest)
		return
	}

	var query string
	var chartData []map[string]interface{}

	switch dateRange {
	case "today":
		// Hourly trips for today (Manila timezone)
		query = `
			SELECT
				TO_CHAR(started_at AT TIME ZONE 'Asia/Manila', 'HH24') AS hour_of_day,
				COUNT(*) AS trips
			FROM trip_logs
			WHERE (started_at AT TIME ZONE 'Asia/Manila')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date
			GROUP BY hour_of_day
			ORDER BY hour_of_day;
		`
		rows, err := DB.Query(query)
		if err != nil {
			utils.JSONErr(w, "Database error: "+err.Error(), 500)
			return
		}
		defer rows.Close()

		hourlyData := make(map[string]int)
		for rows.Next() {
			var hour string
			var trips int
			if err := rows.Scan(&hour, &trips); err != nil {
				log.Printf("Error scanning hourly trip data: %v", err)
				continue
			}
			hourlyData[hour] = trips
		}

		// Fill in missing hours with 0 and format for chart
		for h := 0; h < 24; h++ {
			hourStr := fmt.Sprintf("%02d", h)
			var hourVal int
			if h%12 == 0 && h != 0 {
				hourVal = 12
			} else {
				hourVal = h % 12
			}
			label := fmt.Sprintf("%d%s", hourVal, func() string {
				if h == 0 {
					return "am"
				} else if h < 12 {
					return "am"
				} else {
					return "pm"
				}
			}())
			chartData = append(chartData, map[string]interface{}{
				"day":   label,
				"trips": hourlyData[hourStr],
			})
		}

	case "week":
		// Daily trips for the last 7 days (Manila timezone)
		query = `
			SELECT
				TO_CHAR(started_at AT TIME ZONE 'Asia/Manila', 'Dy') AS day_of_week,
				COUNT(*) AS trips
			FROM trip_logs
			WHERE (started_at AT TIME ZONE 'Asia/Manila')::date >= (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date - INTERVAL '6 days'
			  AND (started_at AT TIME ZONE 'Asia/Manila')::date <= (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date
			GROUP BY (started_at AT TIME ZONE 'Asia/Manila')::date, day_of_week
			ORDER BY (started_at AT TIME ZONE 'Asia/Manila')::date;
		`
		rows, err := DB.Query(query)
		if err != nil {
			utils.JSONErr(w, "Database error: "+err.Error(), 500)
			return
		}
		defer rows.Close()

		for rows.Next() {
			var day string
			var trips int
			if err := rows.Scan(&day, &trips); err != nil {
				log.Printf("Error scanning daily trip data: %v", err)
				continue
			}
			chartData = append(chartData, map[string]interface{}{
				"day":   day,
				"trips": trips,
			})
		}

	case "month":
		// Weekly trips for the last 4 weeks (Manila timezone)
		// This query is more complex and might require specific week numbering logic.
		// For simplicity, we'll return mock data for now, or you can implement a more advanced SQL query.
		// Example: Aggregate by week number, then map to "Wk 1", "Wk 2", etc.
		// For a real implementation, you'd calculate the week number relative to the current month/year.
		// For this example, we'll just return some placeholder data if 'month' is requested.
		chartData = []map[string]interface{}{
			{"day": "Wk 1", "trips": 84},
			{"day": "Wk 2", "trips": 97},
			{"day": "Wk 3", "trips": 110},
			{"day": "Wk 4", "trips": 103},
		}

	default:
		utils.JSONErr(w, "Invalid 'range' parameter", http.StatusBadRequest)
		return
	}

	utils.JSONOK(w, chartData)
}
