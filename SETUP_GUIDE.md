# eTODA Admin Dashboard v3 — Setup Guide
## Go Backend + React Frontend + PostgreSQL

---

## ⚠️ FIRST TIME ONLY — Fix the Go Security Error

If you see **"SECURITY ERROR: checksum mismatch"**, run these commands
inside the `backend` folder before anything else:

```powershell
del go.sum
```
```powershell
go mod tidy
```
```powershell
go mod download
```

Then continue with Step 4 below.

---

## STEP 1 — Create the Database (pgAdmin)

1. Open **pgAdmin 4**
2. Expand: Servers → PostgreSQL → Databases
3. Right-click **Databases** → Create → Database
4. Name: `etoda_db` → click **Save**

---

## STEP 2 — Run the Schema

1. Click on **etoda_db** in pgAdmin
2. Click **Tools → Query Tool**
3. Click the folder icon → open `backend/schema.sql`
4. Press **F5** to run

You should see: `eTODA v3 database ready!`

---

## STEP 3 — Set Your Password

Open `backend/.env` and update:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=etoda_db
DB_USER=postgres
DB_PASSWORD=your_actual_password_here
PORT=8080
```

---

## STEP 4 — Run the Go Backend (Terminal 1)

In VS Code click **Terminal → New Terminal**, then:

```powershell
cd etoda-v3\backend
```

Then run (replace the password):

```powershell
$env:DB_HOST="localhost"; $env:DB_PORT="5432"; $env:DB_NAME="etoda_db"; $env:DB_USER="postgres"; $env:DB_PASSWORD="1"; go run main.go
```

You should see:
```
✅ Connected to PostgreSQL
🚀 Server running on http://localhost:8080
```

Keep this terminal open!

---

## STEP 5 — Run the React Frontend (Terminal 2)

Click the **+** button in the terminal panel to open a second terminal, then:

```powershell
cd etoda-v3\frontend
```

First time only — install packages:

```powershell
npm install
```

Start the frontend:

```powershell
npm start
```

Browser opens at **http://localhost:3000** ✅

Keep this terminal open too!

---

## Every Day — Quick Start

Open VS Code with your etoda-v3 folder, then:

**Terminal 1 — Backend:**
```powershell
cd etoda-v3\backend
$env:DB_HOST="localhost"; $env:DB_PORT="5432"; $env:DB_NAME="etoda_db"; $env:DB_USER="postgres"; $env:DB_PASSWORD="1"; go run main.go
```

**Terminal 2 — Frontend:**
```powershell
cd etoda-v3\frontend
npm start
```

Open: **http://localhost:3000**

---

## Dashboard Panels

| Panel | What You Can Do |
|-------|----------------|
| Dashboard | Live stats, system status |
| Drivers | Enroll, edit, remove, toggle active/inactive |
| Passengers | View, suspend, restore accounts |
| Fare Matrix | Add routes or upload CSV/Excel file |
| Payments | View transactions, settle, refund |
| QR Codes | Revoke or restore and regenerate |
| Complaints | Edit status, add notes, quick-resolve |
| Trip History | Search and view all trips |
| Audit Trail | Full log of every admin action |

---

## Upload Tariff — How to Use

Click **Upload Tariff** in the Fare Matrix panel.
Accepts: `.csv`, `.xlsx`, `.xls`

**CSV format:**
```
origin,destination,base_fare
Poblacion,Talangan,15
Poblacion,Malinao,20
```

**Excel format (columns A B C):**
- A = origin
- B = destination  
- C = base_fare
- Row 1 = header (skipped automatically)

Discounted, Night, Special fares are auto-calculated.
Existing routes are updated if they already exist.

---

## Complaints — Edit and Resolve

- Click **Edit** on any row to open the edit modal
- Change status: Pending / Investigating / Resolved
- Add or update Admin Notes
- Click Save to apply
- Or click **Resolve** directly on the table row for quick resolve

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| SECURITY ERROR checksum mismatch | Run: `del go.sum` then `go mod tidy` then `go mod download` |
| Cannot connect to PostgreSQL | Check your password in the run command |
| go command not found | Install Go from https://go.dev/dl/ then restart VS Code |
| npm not found | Install Node.js from https://nodejs.org |
| Frontend says Cannot reach Go server | Start the backend (Terminal 1) first |
| cd Cannot find path backend | You are already inside backend. Skip the cd command. |
| Port 8080 in use | Run: netstat -ano pipe findstr :8080 then taskkill /PID number /F |
| Port 3000 in use | Run: netstat -ano pipe findstr :3000 then taskkill /PID number /F |
