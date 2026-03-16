import { useState } from 'react';
import { Building2, User, Lock, ArrowRight } from 'lucide-react';

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

// ─── Exact colors from Flutter main.dart (nagcarlanGreen + nagcarlanGradient) ───
// nagcarlanGreen  = #4a7c00  (yellow-green, olive)
// nagcarlanGradient top    = #f5e642 (bright yellow)
// nagcarlanGradient bottom = #ffffff (white)

const GREEN = '#2d5a1b';

function Auth({ onSuccess, notify }) {
  const [form, setForm] = useState({ username: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});
  const [focused, setFocused] = useState('');

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
    const r = await api('/api/login', 'POST', { username: form.username, password: form.password, role: 'admin' });
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
      /* nagcarlanGradient: yellow top → white bottom, exactly like Flutter */
      background: 'linear-gradient(180deg, #e6cc00 0%, #fff59d 50%, #ffffff 100%)',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '60px 24px 40px',
      fontFamily: "'Segoe UI', sans-serif",
      position: 'relative',
      overflow: 'hidden',
    }}>

      {/* Subtle background blobs */}
      <div style={{
        position: 'absolute', top: '-140px', right: '-140px',
        width: '420px', height: '420px', borderRadius: '50%',
        background: 'rgba(255,255,255,0.18)', pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', bottom: '-120px', left: '-120px',
        width: '380px', height: '380px', borderRadius: '50%',
        background: 'rgba(245,230,66,0.12)', pointerEvents: 'none',
      }} />

      {/* Logo — matches Flutter: white circle with alpha 200, icon is nagcarlanGreen */}
      <div style={{
        width: '96px', height: '96px',
        borderRadius: '50%',
        /* Colors.white.withAlpha(200) ≈ rgba(255,255,255,0.78) */
        background: 'rgba(255,255,255,0.78)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        zIndex: 2,
        marginBottom: '-48px',
        boxShadow: '0 4px 20px rgba(0,0,0,0.10)',
      }}>
        <Building2 size={52} color={GREEN} strokeWidth={1.5} />
      </div>

      {/* White Card */}
      <div style={{
        background: '#ffffff',
        borderRadius: '28px',
        boxShadow: '0 20px 60px rgba(0,0,0,0.10), 0 4px 16px rgba(0,0,0,0.06)',
        maxWidth: '440px',
        width: '100%',
        padding: '68px 36px 36px',
        position: 'relative',
        zIndex: 1,
      }}>

        {/* Title — matches Flutter: nagcarlanGreen, bold */}
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <h1 style={{
            fontSize: '1.9rem',
            fontWeight: '800',
            color: GREEN,
            margin: '0 0 6px',
            letterSpacing: '-0.3px',
          }}>eTODA Nagcarlan</h1>
          {/* "Login to your account" → Colors.black54 */}
          <p style={{
            fontSize: '0.95rem',
            color: 'rgba(0,0,0,0.54)',
            margin: 0,
          }}>Login to your admin account</p>
        </div>

        <form onSubmit={handleSubmit}>

          {/* Username — Flutter: filled white, no border, focusedBorder nagcarlanGreen */}
          <div style={{ marginBottom: '16px' }}>
            <div style={{
              position: 'relative', borderRadius: '15px',
              background: '#ffffff',
              border: `2px solid ${focused === 'username' ? GREEN : errors.username ? '#ef4444' : 'transparent'}`,
              boxShadow: '0 2px 10px rgba(0,0,0,0.07)',
              transition: 'border 0.2s',
            }}>
              <User size={18} style={{
                position: 'absolute', left: '14px', top: '50%',
                transform: 'translateY(-50%)',
                color: GREEN,   /* prefixIcon always nagcarlanGreen in Flutter */
                transition: 'color 0.2s',
              }} />
              <input
                type="text" placeholder="Username"
                value={form.username}
                onChange={e => setForm(p => ({ ...p, username: e.target.value }))}
                onFocus={() => setFocused('username')}
                onBlur={() => setFocused('')}
                style={{
                  width: '100%', padding: '15px 14px 15px 44px',
                  border: 'none', borderRadius: '15px',
                  fontSize: '1rem', background: 'transparent',
                  outline: 'none', boxSizing: 'border-box', color: '#1a1a1a',
                }}
              />
            </div>
            {errors.username && (
              <div style={{ color: '#ef4444', fontSize: '0.78rem', marginTop: '4px', paddingLeft: '2px' }}>
                {errors.username}
              </div>
            )}
          </div>

          {/* Password */}
          <div style={{ marginBottom: '4px' }}>
            <div style={{
              position: 'relative', borderRadius: '15px',
              background: '#ffffff',
              border: `2px solid ${focused === 'password' ? GREEN : errors.password ? '#ef4444' : 'transparent'}`,
              boxShadow: '0 2px 10px rgba(0,0,0,0.07)',
              transition: 'border 0.2s',
            }}>
              <Lock size={18} style={{
                position: 'absolute', left: '14px', top: '50%',
                transform: 'translateY(-50%)',
                color: GREEN,
              }} />
              <input
                type="password" placeholder="Password"
                value={form.password}
                onChange={e => setForm(p => ({ ...p, password: e.target.value }))}
                onFocus={() => setFocused('password')}
                onBlur={() => setFocused('')}
                style={{
                  width: '100%', padding: '15px 14px 15px 44px',
                  border: 'none', borderRadius: '15px',
                  fontSize: '1rem', background: 'transparent',
                  outline: 'none', boxSizing: 'border-box', color: '#1a1a1a',
                }}
              />
            </div>
            {errors.password && (
              <div style={{ color: '#ef4444', fontSize: '0.78rem', marginTop: '4px', paddingLeft: '2px' }}>
                {errors.password}
              </div>
            )}
          </div>

          {/* Forgot Password — Flutter: color nagcarlanGreen, bold */}
          <div style={{ textAlign: 'right', marginBottom: '20px' }}>
            <a href="#" style={{
              color: GREEN, textDecoration: 'none',
              fontSize: '0.88rem', fontWeight: '700',
            }}>Forgot Password?</a>
          </div>

          {/* Login Button — Flutter: backgroundColor nagcarlanGreen, white text, radius 15, elevation 5 */}
          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%', padding: '16px',
              background: loading ? '#6a9c20' : GREEN,
              color: '#fff', border: 'none',
              borderRadius: '15px', fontSize: '1.05rem',
              fontWeight: '800', cursor: loading ? 'not-allowed' : 'pointer',
              letterSpacing: '1.5px',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
              boxShadow: '0 5px 20px rgba(74,124,0,0.35)',
              transition: 'opacity 0.2s',
              opacity: loading ? 0.75 : 1,
            }}
            onMouseEnter={e => { if (!loading) e.currentTarget.style.opacity = '0.88'; }}
            onMouseLeave={e => { e.currentTarget.style.opacity = '1'; }}
          >
            {loading ? 'Please wait...' : (<>LOGIN <ArrowRight size={16} /></>)}
          </button>

          {/* OR Divider — Flutter: Colors.black12 lines, Colors.grey[600] text */}
          <div style={{
            display: 'flex', alignItems: 'center',
            margin: '20px 0', gap: '10px',
          }}>
            <div style={{ flex: 1, height: '1px', background: 'rgba(0,0,0,0.12)' }} />
            <span style={{ fontSize: '0.8rem', color: '#757575', fontWeight: '700', letterSpacing: '0.5px' }}>
              ADMIN PORTAL
            </span>
            <div style={{ flex: 1, height: '1px', background: 'rgba(0,0,0,0.12)' }} />
          </div>

          {/* Authorized badge — Flutter: OutlinedButton style, nagcarlanGreen border + text */}
          <div style={{
            textAlign: 'center', padding: '14px',
            border: `1.5px solid ${GREEN}`,
            borderRadius: '15px',
            color: GREEN,
            fontSize: '0.88rem', fontWeight: '800',
            letterSpacing: '0.5px', background: 'transparent',
          }}>
            🔒 AUTHORIZED PERSONNEL ONLY
          </div>

        </form>
      </div>

      {/* Footer */}
      <div style={{
        marginTop: '24px', fontSize: '11px',
        color: 'rgba(74,124,0,0.5)', textAlign: 'center', letterSpacing: '0.3px',
      }}>
        eTODA Nagcarlan · LGU Admin System
      </div>

    </div>
  );
}

export default Auth;