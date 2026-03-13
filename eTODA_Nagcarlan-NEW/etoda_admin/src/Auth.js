import { useState } from 'react';

const BASE = 'http://localhost:8080';

async function api(path, method = 'GET', body = null) {
  try {
    const opts = { method, headers: {} };
    if (body) { opts.headers['Content-Type'] = 'application/json'; opts.body = JSON.stringify(body); }
    const r = await fetch(BASE + path, opts);
    return r.json();
  } catch {
    return { success: false, error: 'Cannot reach Go server on port 8080.' };
  }
}

// simple authentication component for admin portal
function Auth({ onSuccess, notify }) {
  const [mode, setMode] = useState('login'); // 'login' or 'signup'
  const [form, setForm] = useState({ username:'', password:'', full_name:'', email:'' });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async () => {
    setLoading(true);
    try {
      if (mode === 'login') {
        const r = await api('/api/login', 'POST', { username: form.username, password: form.password });
        if (r.role === 'admin') {
          onSuccess(r);
        } else if (r.role === 'driver' || r.role === 'passenger') {
          notify('Please login using the mobile app.', 'error');
        } else {
          notify(r.message || 'Login failed', 'error');
        }
      } else {
        const r = await api('/api/admin/signup', 'POST', { username: form.username, password: form.password, full_name: form.full_name, email: form.email });
        if (r.message && r.message.includes('success')) {
          notify('Admin account created – please login', 'success');
          setMode('login');
          setForm({ username:'', password:'', full_name:'', email:'' });
        } else {
          notify(r.error||r.message||'Signup failed','error');
        }
      }
    } catch (e) {
      notify('Unable to reach server','error');
    }
    setLoading(false);
  };

  return (
    <div className="auth-container">
      <h2>{mode === 'login' ? 'Administrator Login' : 'Create Admin Account'}</h2>
      <div className="form-row">
        <div className="field">
          <label>Username</label>
          <input value={form.username} onChange={e => setForm(p=>({...p,username:e.target.value}))} />
        </div>
      </div>
      <div className="form-row">
        <div className="field">
          <label>Password</label>
          <input type="password" value={form.password} onChange={e => setForm(p=>({...p,password:e.target.value}))} />
        </div>
      </div>
      {mode==='signup' && (
        <>
          <div className="form-row">
            <div className="field">
              <label>Full name</label>
              <input value={form.full_name} onChange={e=>setForm(p=>({...p,full_name:e.target.value}))} />
            </div>
          </div>
          <div className="form-row">
            <div className="field">
              <label>Email</label>
              <input value={form.email} onChange={e=>setForm(p=>({...p,email:e.target.value}))} />
            </div>
          </div>
        </>
      )}
      <div style={{marginTop:12}}>
        <button className="btn" onClick={handleSubmit} disabled={loading}>{loading? 'Please wait...' : mode==='login'?'Login':'Sign up'}</button>
      </div>
      <div style={{marginTop:8,fontSize:'.85rem'}}>
        {mode==='login' ? (
          <span>Need an account? <a href="#" onClick={e=>{e.preventDefault();setMode('signup');}}>Sign up</a></span>
        ) : (
          <span>Already have one? <a href="#" onClick={e=>{e.preventDefault();setMode('login');}}>Login</a></span>
        )}
      </div>
    </div>
  );
}

export default Auth;