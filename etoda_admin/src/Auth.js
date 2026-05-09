import { useState } from 'react';
import { Building2, User, Lock, ArrowRight, Eye, EyeOff } from 'lucide-react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faExclamationCircle } from '@fortawesome/free-solid-svg-icons';

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

const GREEN = '#2d5a1b';

function Auth({ onSuccess, notify }) {
  const [form, setForm]           = useState({ username: '', password: '' });
  const [loading, setLoading]     = useState(false);
  const [errors, setErrors]       = useState({});
  const [focused, setFocused]     = useState('');
  const [showPass, setShowPass]   = useState(false);
  const [showForgot, setShowForgot] = useState(false);
  const [failedAttempts, setFailedAttempts] = useState(0);
  const [lockoutEndTime, setLockoutEndTime] = useState(null);
  const [serverError, setServerError] = useState('');
  const [attemptsLeft, setAttemptsLeft] = useState(null);

  const validate = () => {
    const e = {};
    setServerError('');
    if (form.username.length < 3) e.username = 'Username must be at least 3 characters';
    if (form.password.length < 6) e.password = 'Password must be at least 6 characters';
    setErrors(e);
    setAttemptsLeft(null);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    if (lockoutEndTime && new Date() < lockoutEndTime) {
      const remaining = Math.ceil((lockoutEndTime - new Date()) / 60000);
      notify(`Account locked. Please try again in ${remaining} minute(s).`, 'login-error');
      return;
    }

    setLoading(true);
    const r = await api('/api/login', 'POST', { username: form.username, password: form.password, role: 'admin' });
    setLoading(false);

    if (r.success && r.role === 'admin') {
      setFailedAttempts(0);
      setLockoutEndTime(null);
      setAttemptsLeft(null);
      onSuccess(r);
    } else if (r.role === 'driver' || r.role === 'passenger') {
      const msg = 'Insufficient privileges. Admin access required.';
      setServerError(msg);
      setAttemptsLeft(null);
      notify(msg, 'login-error');
    } else {
      const newAttempts = failedAttempts + 1;
      setFailedAttempts(newAttempts);

      if (newAttempts >= 5) {
        setLockoutEndTime(new Date(Date.now() + 15 * 60000));
        const msg = 'Too many failed attempts. Account locked for 15 minutes.';
        setServerError(msg);
        setAttemptsLeft(0);
        notify(msg, 'login-error');
      } else {
        const remaining = 5 - newAttempts;
        const msg = r.message || r.error || 'Invalid credentials.';
        setServerError(msg);
        setAttemptsLeft(remaining);
        notify(`${msg} Attempts left: ${remaining}`, 'login-error');
      }
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: '#f1f5f9', // Light background to provide contrast for white cards
      display: 'flex', flexDirection: 'column',
      justifyContent: 'center', alignItems: 'center',
      padding: '60px 24px 40px',
      fontFamily: "'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif",
      position: 'relative', overflow: 'hidden',
    }}>


      {/* Logo */}
      <div style={{ width: '96px', height: '96px', borderRadius: '50%', background: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2, marginBottom: '-48px', boxShadow: '0 10px 30px rgba(0,0,0,0.08)' }}>
        <div style={{ width: '72px', height: '72px', borderRadius: '50%', background: GREEN, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 14px rgba(45,90,27,0.35)' }}>
          <Building2 size={34} color="#fff" strokeWidth={1.5} />
        </div>
      </div>

      {/* White Card */}
      <div style={{ background: '#ffffff', borderRadius: '24px', boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)', maxWidth: '440px', width: '100%', padding: '68px 40px 40px', position: 'relative', zIndex: 1, border: '1px solid #e2e8f0', borderTop: `6px solid ${GREEN}` }}>

        {/* Title */}
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <h1 style={{ fontSize: '1.9rem', fontWeight: '800', color: GREEN, margin: '0 0 6px', letterSpacing: '-0.3px' }}>eTODA Nagcarlan</h1>
          <p style={{ fontSize: '0.92rem', color: 'rgba(0,0,0,0.54)', margin: 0 }}>Login to your admin account</p>
        </div>

        {/* Server-side Error Indication with Smooth Transition */}
        <div className={`error-container ${serverError ? 'visible error-shake' : ''}`}>
            {serverError && (
              <div style={{ 
                background: '#fff1f2', 
                border: '1px solid #fda4af40', 
                color: '#991b1b', 
                padding: '12px 16px', 
                borderRadius: '12px', 
                fontSize: '0.85rem', 
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
              }}>
                 <FontAwesomeIcon icon={faExclamationCircle} style={{ color: '#e11d48', fontSize: '1rem' }} />
                 <div style={{ display: 'flex', flexDirection: 'column', lineHeight: '1.4' }}>
                    <span style={{ fontWeight: '600' }}>{serverError}</span>
                    {attemptsLeft !== null && attemptsLeft > 0 && (
                      <span style={{ fontSize: '0.72rem', color: '#be123c', opacity: 0.8 }}>
                        Remaining attempts: <span style={{ fontWeight: '700' }}>{attemptsLeft}</span>
                      </span>
                    )}
                 </div>
              </div>
            )}
        </div>

        <form onSubmit={handleSubmit}>

          {/* Username */}
          <div style={{ marginBottom: '14px' }}>
            <div style={{ position: 'relative', borderRadius: '12px', background: '#f8fafc', border: `1.5px solid ${focused === 'username' ? GREEN : errors.username ? '#ef4444' : '#e2e8f0'}`, transition: 'all 0.2s ease' }}>
              <User size={17} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: focused === 'username' ? GREEN : '#9ca3af', transition: 'color 0.2s' }} />
              <input
                type="text" placeholder="Username"
                value={form.username}
                onChange={e => { setForm(p => ({ ...p, username: e.target.value })); setServerError(''); setAttemptsLeft(null); }}
                onFocus={() => setFocused('username')}
                onBlur={() => setFocused('')}
                style={{ width: '100%', padding: '15px 14px 15px 44px', border: 'none', borderRadius: '12px', fontSize: '1rem', background: 'transparent', outline: 'none', boxSizing: 'border-box', color: '#1a1a1a' }}
              />
            </div>
            {errors.username && <div style={{ color: '#ef4444', fontSize: '0.78rem', marginTop: '4px', paddingLeft: '2px' }}>{errors.username}</div>}
          </div>

          {/* Password with show/hide toggle */}
          <div style={{ marginBottom: '10px' }}>
            <div style={{ position: 'relative', borderRadius: '12px', background: '#f8fafc', border: `1.5px solid ${focused === 'password' ? GREEN : errors.password ? '#ef4444' : '#e2e8f0'}`, transition: 'all 0.2s ease' }}>
              <Lock size={17} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: focused === 'password' ? GREEN : '#9ca3af', transition: 'color 0.2s' }} />
              <input
                type={showPass ? 'text' : 'password'}
                placeholder="Password"
                value={form.password}
                onChange={e => { setForm(p => ({ ...p, password: e.target.value })); setServerError(''); setAttemptsLeft(null); }}
                onFocus={() => setFocused('password')}
                onBlur={() => setFocused('')}
                style={{ width: '100%', padding: '15px 44px 15px 44px', border: 'none', borderRadius: '12px', fontSize: '1rem', background: 'transparent', outline: 'none', boxSizing: 'border-box', color: '#1a1a1a' }}
              />
              {/* Show/Hide toggle button */}
              <button
                type="button"
                onClick={() => setShowPass(!showPass)}
                style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', padding: '4px', color: '#9ca3af', display: 'flex', alignItems: 'center' }}
              >
                {showPass ? <EyeOff size={17} /> : <Eye size={17} />}
              </button>
            </div>
            {errors.password && <div style={{ color: '#ef4444', fontSize: '0.78rem', marginTop: '4px', paddingLeft: '2px' }}>{errors.password}</div>}
          </div>

          {/* Forgot Password */}
          <div style={{ textAlign: 'right', marginBottom: '22px' }}>
            <button
              type="button"
              onClick={() => setShowForgot(true)}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: GREEN, fontSize: '0.85rem', fontWeight: '600', padding: 0, opacity: 0.8 }}
            >
              Forgot Password?
            </button>
          </div>

          {/* Login Button */}
          <button
            type="submit" disabled={loading}
            style={{ width: '100%', padding: '15px', background: loading ? '#4a7c5f' : GREEN, color: '#fff', border: 'none', borderRadius: '12px', fontSize: '0.95rem', fontWeight: '700', cursor: loading ? 'not-allowed' : 'pointer', letterSpacing: '0.5px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', boxShadow: '0 10px 15px -3px rgba(45,90,27,0.3)', transition: 'all 0.3s ease', opacity: loading ? 0.75 : 1 }}
            onMouseEnter={e => { if (!loading) { e.currentTarget.style.transform = 'translateY(-1px)'; e.currentTarget.style.boxShadow = '0 20px 25px -5px rgba(45,90,27,0.2)'; } }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 10px 15px -3px rgba(45,90,27,0.3)'; }}
          >
            {loading ? 'Authenticating...' : (<>Sign In <ArrowRight size={18} /></>)}
          </button>

          {/* Divider */}
          <div style={{ display: 'flex', alignItems: 'center', margin: '20px 0', gap: '10px' }}>
            <div style={{ flex: 1, height: '1px', background: 'rgba(0,0,0,0.12)' }} />
            <span style={{ fontSize: '0.75rem', color: '#9aaa7a', fontWeight: '600', letterSpacing: '0.5px' }}>ADMIN PORTAL</span>
            <div style={{ flex: 1, height: '1px', background: 'rgba(0,0,0,0.12)' }} />
          </div>

          {/* Authorized badge */}
          <div style={{ textAlign: 'center', padding: '12px', border: `1px solid ${GREEN}40`, borderRadius: '12px', color: GREEN, fontSize: '0.75rem', fontWeight: '600', letterSpacing: '0.5px', background: `${GREEN}05` }}>
            🔒 AUTHORIZED PERSONNEL ONLY
          </div>

        </form>
      </div>

      {/* Footer */}
      <div style={{ marginTop: '32px', fontSize: '12px', color: '#94a3b8', textAlign: 'center', letterSpacing: '0.3px' }}>
        eTODA Nagcarlan · LGU Admin System
      </div>

      {/* ── Forgot Password Modal ── */}
      {showForgot && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: '24px' }}>
          <div style={{ background: '#fff', borderRadius: '24px', padding: '36px 32px', maxWidth: '400px', width: '100%', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
            <h2 style={{ fontSize: '1.3rem', fontWeight: '800', color: GREEN, margin: '0 0 8px' }}>Forgot Password?</h2>
            <p style={{ fontSize: '0.88rem', color: '#6b7280', margin: '0 0 24px' }}>
              Please contact your system administrator to reset your admin password.
            </p>
            <div style={{ background: '#f0fdf4', border: `1.5px solid ${GREEN}`, borderRadius: '12px', padding: '14px 16px', marginBottom: '24px' }}>
              <div style={{ fontSize: '0.82rem', color: GREEN, fontWeight: '700', marginBottom: '4px' }}>📞 Contact Admin Office</div>
              <div style={{ fontSize: '0.8rem', color: '#374151' }}>eTODA Nagcarlan LGU Admin Office</div>
              <div style={{ fontSize: '0.8rem', color: '#374151' }}>Nagcarlan, Laguna</div>
            </div>
            <button
              onClick={() => setShowForgot(false)}
              style={{ width: '100%', padding: '13px', background: GREEN, color: '#fff', border: 'none', borderRadius: '12px', fontSize: '0.95rem', fontWeight: '700', cursor: 'pointer', letterSpacing: '0.5px' }}
            >
              Got it
            </button>
          </div>
        </div>
      )}

    </div>
  );
}

export default Auth;