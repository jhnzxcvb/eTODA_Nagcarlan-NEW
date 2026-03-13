import { useState } from 'react';
import { Building2, User, Lock } from 'lucide-react';

const BASE = 'http://localhost:8080';

async function api(path, method = 'GET', body = null) {
  try {
    const opts = { method, headers: {} };
    if (body) { opts.headers['Content-Type'] = 'application/json'; opts.body = JSON.stringify(body); }
    const r = await fetch(BASE + path, opts);
    return r.json();
  } catch {
    return { success: false, error: 'Cannot connect to server.' };
  }
}

// simple authentication component for admin portal
function Auth({ onSuccess, notify }) {
  const [form, setForm] = useState({ username:'', password:'' });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});

  const validate = () => {
    const e = {};
    if (form.username.length < 3) e.username = 'Username must be at least 3 characters';
    if (form.password.length < 6) e.password = 'Password must be at least 6 characters';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    const r = await api('/auth/login', 'POST', { username: form.username, password: form.password, role: 'admin' });
    setLoading(false);
    if (r.success && r.role === 'admin') {
      onSuccess(r);
    } else if (r.role === 'driver' || r.role === 'passenger') {
      notify('Access denied. Admins only.', 'login-error');
    } else {
      notify(r.error || 'Invalid credentials. Please try again.', 'login-error');
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #f5e642 0%, #d4b800 50%, #1a4731 100%)',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '20px',
      position: 'relative'
    }}>
      <div style={{textAlign: 'center', marginBottom: '24px'}}>
        <div style={{
          width: '80px',
          height: '80px',
          borderRadius: '50%',
          background: '#fff',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto 16px',
          boxShadow: '0 4px 20px rgba(0,0,0,0.1)'
        }}>
          <Building2 size={40} color="#1a4731" />
        </div>
        <h1 style={{
          fontSize: '2.5rem',
          fontWeight: 'bold',
          color: '#1a4731',
          margin: '0 0 8px',
          fontFamily: 'Roboto, sans-serif'
        }}>eTODA Nagcarlan</h1>
        <p style={{
          fontSize: '1.1rem',
          color: '#1a4731',
          margin: '0 0 16px',
          opacity: 0.8
        }}>Admin Portal</p>
        <div style={{
          display: 'inline-block',
          padding: '4px 12px',
          background: '#1a4731',
          color: '#fff',
          borderRadius: '12px',
          fontSize: '0.8rem',
          fontWeight: 'bold'
        }}>Authorized Personnel Only</div>
      </div>

      <div style={{
        background: '#fff',
        borderRadius: '24px',
        padding: '36px 32px',
        boxShadow: '0 10px 40px rgba(0,0,0,0.15)',
        maxWidth: '420px',
        width: '100%'
      }}>
        <form onSubmit={handleSubmit}>
          <div style={{marginBottom: '20px'}}>
            <div style={{position: 'relative'}}>
              <User size={18} style={{position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#666'}} />
              <input
                type="text"
                placeholder="Username"
                value={form.username}
                onChange={e => setForm(p=>({...p,username:e.target.value}))}
                style={{
                  width: '100%',
                  padding: '12px 12px 12px 40px',
                  border: '1px solid #ddd',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  boxSizing: 'border-box'
                }}
              />
            </div>
            {errors.username && <div style={{color: '#ef4444', fontSize: '0.8rem', marginTop: '4px'}}>{errors.username}</div>}
          </div>

          <div style={{marginBottom: '20px'}}>
            <div style={{position: 'relative'}}>
              <Lock size={18} style={{position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#666'}} />
              <input
                type="password"
                placeholder="Password"
                value={form.password}
                onChange={e => setForm(p=>({...p,password:e.target.value}))}
                style={{
                  width: '100%',
                  padding: '12px 12px 12px 40px',
                  border: '1px solid #ddd',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  boxSizing: 'border-box'
                }}
              />
            </div>
            {errors.password && <div style={{color: '#ef4444', fontSize: '0.8rem', marginTop: '4px'}}>{errors.password}</div>}
          </div>

          <div style={{textAlign: 'right', marginBottom: '20px'}}>
            <a href="#" style={{color: '#1a4731', textDecoration: 'none', fontSize: '0.9rem'}}>Forgot Password?</a>
          </div>

          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: '12px',
              background: '#1a4731',
              color: '#fff',
              border: 'none',
              borderRadius: '8px',
              fontSize: '1rem',
              fontWeight: 'bold',
              cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.7 : 1
            }}
          >
            {loading ? 'Please wait...' : 'LOGIN'}
          </button>
        </form>
      </div>

      <div style={{
        position: 'absolute',
        bottom: '20px',
        left: '50%',
        transform: 'translateX(-50%)',
        fontSize: '11px',
        color: 'rgba(255,255,255,0.7)',
        textAlign: 'center'
      }}>
        eTODA Nagcarlan · LGU Admin System
      </div>
    </div>
  );
}

export default Auth;