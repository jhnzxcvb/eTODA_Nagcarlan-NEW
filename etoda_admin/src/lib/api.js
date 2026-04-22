// src/lib/api.js
export const BASE = 'http://localhost:8080';

async function api(endpoint, method = 'GET', body = null) {
  try {
    const isFormData = body instanceof FormData;
    const headers = {
      'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
    };
    if (!isFormData) {
      headers['Content-Type'] = 'application/json';
    }

    const response = await fetch(BASE + endpoint, {
      method,
      headers,
      body: isFormData ? body : (body ? JSON.stringify(body) : null),
    });
    
    const contentType = response.headers.get("content-type");
    if (!contentType || !contentType.includes("application/json")) {
      return { success: false, error: `Server returned an error: ${response.status} ${response.statusText}` };
    }
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error("API Fetch Error:", error);
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