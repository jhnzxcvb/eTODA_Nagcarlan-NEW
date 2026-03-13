// src/lib/api.js
const BASE = 'http://localhost:8080';

async function api(endpoint, method = 'GET', body = null) {
  try {
    const response = await fetch(BASE + endpoint, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
      },
      body: body ? JSON.stringify(body) : null,
    });
    const data = await response.json();
    return data;
  } catch (error) {
    return { success: false, error: 'Failed to connect to server. Please check if the backend is running.' };
  }
}

/* ── VIOLATION TYPES (replacing Colorum) ── */
const VIOLATIONS = [
  'Overcharging',
  'Underpayment of Fare',
  'Rude / Discourteous Behavior',
  'Reckless Driving',
  'Refusal to Convey Passenger',
  'Unauthorized Route Deviation',
  'No Receipt / No QR Scan',
  'Vehicle Not Roadworthy',
  'No Franchise Plate Displayed',
  'Driver Under the Influence',
  'Sexual Harassment',
  'Lost Item / Theft',
  'Other Violation',
];

export { api, VIOLATIONS };