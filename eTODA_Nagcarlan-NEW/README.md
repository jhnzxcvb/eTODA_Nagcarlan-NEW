eTODA Nagcarlan - Full Stack Implementation

This repository houses the unified codebase for the eTODA system.

Frontend: Flutter mobile application for users (Passengers/Drivers).

Backend: Go-based API providing robust data handling for both management and user sides.  A single `/api/login` endpoint now supports three roles – admin, driver, and passenger – and an `/api/signup` endpoint accepts both mobile user registrations and (via `/api/admin/signup`) administrator account creation.

Admin: Web-based management portal with its own login/signup screens; credentials are stored in a new `admins` table in the database.

All components are fully integrated and tested for end-to-end functionality.
