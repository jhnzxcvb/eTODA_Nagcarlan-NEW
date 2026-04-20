// src/components/App.js
import React, { useState, useEffect, useRef } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faHome, faUsers, faUser, faDollarSign, faCreditCard,
  faMobileAlt, faExclamationTriangle, faCar, faClipboard,
  faChevronUp, faSignOutAlt, faCog, faUserCircle, faBell,
  faUserPlus, faIdCard, faQrcode, faMapMarkerAlt, faLock,
  faEnvelope, faUserShield, faSave, faToggleOn, faToggleOff,
} from '@fortawesome/free-solid-svg-icons';
import Auth from '../Auth';
import Dashboard from './dashboard/Dashboard';
import Drivers from './drivers/Drivers';
import TodaStations from './drivers/TodaStations';
import Passengers from './passengers/Passengers';
import Trips from './trips/Trips';
import Payments from './payments/Payments';
import Complaints from './complaints/Complaints';
import Fare from './fare/Fare';
import QRCodes from './qrcodes/QRCodes';
import Audit from './audit/Audit';
import { Toasts, useToast } from './ui/Toast';
import { api } from '../lib/api';

const BASE = 'http://localhost:8080';

const NOTIF_STYLE = {
  complaint: { icon: faExclamationTriangle, color: '#dc2626', bg: '#fee2e2' },
  driver:    { icon: faUserPlus,            color: '#2d5a1b', bg: '#e8f5e9' },
  passenger: { icon: faUser,               color: '#8e44ad', bg: '#f3e8ff' },
  qrcode:    { icon: faQrcode,             color: '#d97706', bg: '#fff8e1' },
  default:   { icon: faIdCard,             color: '#0284c7', bg: '#e0f2fe' },
};

export default function App() {
  const [auth, setAuth] = useState(() => {
    try {
      const saved = localStorage.getItem('adminUser');
      return saved ? JSON.parse(saved) : null;
    } catch { return null; }
  });

  const [panel, setPanel]               = useState('dashboard');
  const { toasts, notify, dismiss }     = useToast();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [notifOpen, setNotifOpen]       = useState(false);
  const [notifications, setNotifications] = useState([]);
  const dropdownRef = useRef();
  const notifRef    = useRef();

  // ── Audit navigation: view name + prefill search ID ──
  const [searchParam, setSearchParam] = useState('');

  // Called by Audit.js: navigate(viewName, entityId)
  const auditNavigate = (view, id = '') => {
    setSearchParam(id);
    setPanel(view);
  };

  const unreadCount = notifications.filter(n => !n.is_read).length;

  const fetchNotifications = async () => {
    try {
      const res = await fetch(`${BASE}/api/notifications`);
      const data = await res.json();
      if (Array.isArray(data.data)) setNotifications(data.data);
    } catch {}
  };

  useEffect(() => {
    if (!auth) return;
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, [auth]);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) setDropdownOpen(false);
      if (notifRef.current    && !notifRef.current.contains(e.target))    setNotifOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLoginSuccess = (userData) => {
    localStorage.setItem('adminUser', JSON.stringify(userData));
    setAuth(userData);
  };

  const logout = () => {
    localStorage.removeItem('adminUser');
    localStorage.removeItem('adminToken');
    setAuth(null);
    setDropdownOpen(false);
    notify('Logged out', 'info');
  };

  const markAllRead = async () => {
    await fetch(`${BASE}/api/notifications/read`, { method: 'PATCH' });
    setNotifications(n => n.map(x => ({ ...x, is_read: true })));
  };

  const deleteNotif = async (id, e) => {
    e.stopPropagation();
    await fetch(`${BASE}/api/notifications/${id}`, { method: 'DELETE' });
    setNotifications(n => n.filter(x => x.id !== id));
  };

  const clearAll = async () => {
    await fetch(`${BASE}/api/notifications/clear`, { method: 'DELETE' });
    setNotifications([]);
    setNotifOpen(false);
  };

  const markRead = async (id) => {
    setNotifications(n => n.map(x => x.id === id ? { ...x, is_read: true } : x));
  };

  const timeAgo = (dateStr) => {
    const diff = Math.floor((Date.now() - new Date(dateStr)) / 1000);
    if (diff < 60)    return `${diff}s ago`;
    if (diff < 3600)  return `${Math.floor(diff/60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff/3600)}h ago`;
    return `${Math.floor(diff/86400)}d ago`;
  };

  // ── Profile Update Logic ──
  const [profileForm, setProfileForm] = useState({ full_name: '', email: '', username: '', password: '' });
  useEffect(() => {
    if (auth && panel === 'profile') {
      setProfileForm({
        full_name: auth.full_name || '',
        email: auth.email || '',
        username: auth.username || '',
        password: ''
      });
    }
  }, [auth, panel]);

  const handleUpdateProfile = async (e) => {
    e.preventDefault();
    const res = await api('/api/profile', 'PATCH', profileForm);
    if (res.success) {
      const updated = { ...auth, ...profileForm };
      delete updated.password;
      setAuth(updated);
      localStorage.setItem('adminUser', JSON.stringify(updated));
      notify('Profile updated successfully', 'success');
    } else {
      notify(res.error || 'Failed to update profile', 'error');
    }
  };

  // ── Settings Placeholder Logic ──
  const [settings, setSettings] = useState({
    notifications: true,
    maintenance: false,
    autoLogout: false
  });

  if (!auth) {
    return (
      <>
        <Auth onSuccess={handleLoginSuccess} notify={notify} />
        <Toasts toasts={toasts} dismiss={dismiss} />
      </>
    );
  }

  const NAV = [
    ['dashboard',  faHome,                'Dashboard'],
    ['drivers',    faUsers,               'Drivers'],
    ['passengers', faUser,                'Passengers'],
    ['fare',       faDollarSign,          'Fare Matrix'],
    ['stations',   faMapMarkerAlt,        'TODA Stations'],
    ['payments',   faCreditCard,          'Payments'],
    ['qrcodes',    faMobileAlt,           'QR Codes'],
    ['complaints', faExclamationTriangle, 'Complaints'],
    ['trips',      faCar,                 'Trip History'],
    ['audit',      faClipboard,           'Audit Trail'],
  ];
  const TITLE = Object.fromEntries(NAV.map(([id,, l]) => [id, l]));

  // Clear searchParam when user manually clicks a sidebar nav item
  const handleNavClick = (id) => {
    setSearchParam('');
    setPanel(id);
  };

  return (
    <div className="app">
      <aside className="sb">
        <div className="sb-brand">
          <div className="sb-logo">e<span>TODA</span></div>
          <div className="sb-tag">Nagcarlan Admin</div>
        </div>
        <nav style={{ paddingTop: 8 }}>
          <div className="sb-sec">Navigation</div>
          {NAV.map(([id, icon, lbl]) => (
            <button
              key={id}
              className={`sb-btn${panel === id ? ' active' : ''}`}
              onClick={() => handleNavClick(id)}
            >
              <FontAwesomeIcon icon={icon} className="sb-ico" style={{ color: 'var(--gold)' }} />
              {lbl}
            </button>
          ))}
        </nav>

        {/* Profile Footer */}
        <div ref={dropdownRef} style={{ position: 'relative', padding: '12px', marginTop: 'auto' }}>
          {dropdownOpen && (
            <div style={{
              position: 'absolute', bottom: 'calc(100% - 8px)', left: '12px', right: '12px',
              background: '#fff', borderRadius: '14px',
              boxShadow: '0 -4px 24px rgba(0,0,0,0.18)', overflow: 'hidden',
              zIndex: 1000, animation: 'fadeSlideUp 0.15s ease',
            }}>
              <style>{`@keyframes fadeSlideUp{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}`}</style>
              {[
                { icon: faUserCircle, color: '#2d5a1b', bg: '#e8f5e9', label: 'Edit Profile',  sub: 'Update your info',   action: () => { setPanel('profile');  setDropdownOpen(false); }, textColor: '#1a1a1a' },
                { icon: faCog,        color: '#f59e0b', bg: '#fff8e1', label: 'Settings',       sub: 'System preferences', action: () => { setPanel('settings'); setDropdownOpen(false); }, textColor: '#1a1a1a' },
                { icon: faSignOutAlt, color: '#dc2626', bg: '#fee2e2', label: 'Logout',         sub: 'Sign out of admin',  action: logout,                                                  textColor: '#dc2626' },
              ].map((item, i, arr) => (
                <div key={item.label} onClick={item.action}
                  style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '13px 16px', cursor: 'pointer', borderBottom: i < arr.length - 1 ? '1px solid #f0f0f0' : 'none', transition: 'background 0.15s' }}
                  onMouseEnter={e => e.currentTarget.style.background = item.textColor === '#dc2626' ? '#fff5f5' : '#f5f5f5'}
                  onMouseLeave={e => e.currentTarget.style.background = '#fff'}
                >
                  <div style={{ width: 32, height: 32, borderRadius: '50%', background: item.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <FontAwesomeIcon icon={item.icon} style={{ color: item.color, fontSize: 15 }} />
                  </div>
                  <div>
                    <div style={{ fontSize: '0.85rem', fontWeight: '700', color: item.textColor }}>{item.label}</div>
                    <div style={{ fontSize: '0.72rem', color: '#888' }}>{item.sub}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
          <div onClick={() => setDropdownOpen(!dropdownOpen)}
            style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: '12px', background: dropdownOpen ? 'rgba(255,255,255,0.15)' : 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.12)', cursor: 'pointer', transition: 'background 0.2s', userSelect: 'none' }}
            onMouseEnter={e => { if (!dropdownOpen) e.currentTarget.style.background = 'rgba(255,255,255,0.13)'; }}
            onMouseLeave={e => { if (!dropdownOpen) e.currentTarget.style.background = 'rgba(255,255,255,0.08)'; }}
          >
            <div style={{ width: 38, height: 38, borderRadius: '50%', background: 'var(--gold)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, boxShadow: '0 2px 8px rgba(0,0,0,0.2)' }}>
              <FontAwesomeIcon icon={faUser} style={{ color: '#1a4731', fontSize: 16 }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: '.82rem', color: '#fff', fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {auth.full_name || auth.username || 'TODA Admin'}
              </div>
              <div style={{ fontSize: '.68rem', color: 'rgba(255,255,255,0.5)' }}>Administrator</div>
            </div>
            <FontAwesomeIcon icon={faChevronUp} style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11, transform: dropdownOpen ? 'rotate(180deg)' : 'rotate(0deg)', transition: 'transform 0.2s', flexShrink: 0 }} />
          </div>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div>
            <div className="tb-title">{TITLE[panel] || 'Dashboard'}</div>
            <div className="tb-sub">eTODA Nagcarlan Management System</div>
          </div>
          <div className="tb-right" style={{ display: 'flex', alignItems: 'center', gap: 16 }}>

            {/* ── Notification Bell ── */}
            <div ref={notifRef} style={{ position: 'relative' }}>
              <button
                onClick={() => { setNotifOpen(!notifOpen); if (!notifOpen) fetchNotifications(); }}
                style={{ position: 'relative', background: 'none', border: 'none', cursor: 'pointer', padding: '6px 8px', borderRadius: '10px', transition: 'background 0.2s' }}
                onMouseEnter={e => e.currentTarget.style.background = '#f0f0f0'}
                onMouseLeave={e => e.currentTarget.style.background = 'none'}
              >
                <FontAwesomeIcon icon={faBell} style={{ fontSize: 18, color: '#1a4731' }} />
                {unreadCount > 0 && (
                  <span style={{ position: 'absolute', top: 2, right: 2, width: 17, height: 17, borderRadius: '50%', background: '#dc2626', color: '#fff', fontSize: '0.65rem', fontWeight: '800', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid #fff', animation: 'pulse 1.5s infinite' }}>
                    {unreadCount}
                  </span>
                )}
              </button>

              {notifOpen && (
                <div style={{ position: 'absolute', top: 'calc(100% + 10px)', right: 0, width: 340, background: '#fff', borderRadius: '16px', boxShadow: '0 8px 32px rgba(0,0,0,0.15)', zIndex: 2000, overflow: 'hidden', animation: 'fadeSlideDown 0.15s ease' }}>
                  <style>{`
                    @keyframes fadeSlideDown{from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:translateY(0)}}
                    @keyframes pulse{0%,100%{transform:scale(1)}50%{transform:scale(1.15)}}
                  `}</style>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 16px', borderBottom: '1px solid #f0f0f0' }}>
                    <div style={{ fontWeight: '800', fontSize: '0.95rem', color: '#1a1a1a' }}>
                      🔔 Notifications
                      {unreadCount > 0 && (
                        <span style={{ marginLeft: 8, padding: '2px 8px', background: '#dc2626', color: '#fff', borderRadius: '20px', fontSize: '0.7rem', fontWeight: '700' }}>
                          {unreadCount} new
                        </span>
                      )}
                    </div>
                    {unreadCount > 0 && (
                      <button onClick={markAllRead} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: '0.75rem', color: '#2d5a1b', fontWeight: '700' }}>
                        Mark all read
                      </button>
                    )}
                  </div>
                  <div style={{ maxHeight: 360, overflowY: 'auto' }}>
                    {notifications.length === 0 ? (
                      <div style={{ padding: '32px 16px', textAlign: 'center', color: '#aaa', fontSize: '0.85rem' }}>
                        🎉 You're all caught up!
                      </div>
                    ) : notifications.map(n => {
                      const style = NOTIF_STYLE[n.type] || NOTIF_STYLE.default;
                      return (
                        <div key={n.id} onClick={() => markRead(n.id)}
                          style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 16px', background: n.is_read ? '#fff' : '#f8fffe', borderBottom: '1px solid #f5f5f5', cursor: 'pointer', transition: 'background 0.15s', borderLeft: n.is_read ? '3px solid transparent' : `3px solid ${style.color}` }}
                          onMouseEnter={e => e.currentTarget.style.background = '#f5f5f5'}
                          onMouseLeave={e => e.currentTarget.style.background = n.is_read ? '#fff' : '#f8fffe'}
                        >
                          <div style={{ width: 36, height: 36, borderRadius: '50%', background: style.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                            <FontAwesomeIcon icon={style.icon} style={{ color: style.color, fontSize: 15 }} />
                          </div>
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div style={{ fontSize: '0.82rem', fontWeight: n.is_read ? '500' : '700', color: '#1a1a1a', marginBottom: 2 }}>{n.title}</div>
                            <div style={{ fontSize: '0.75rem', color: '#666', marginBottom: 4 }}>{n.description}</div>
                            <div style={{ fontSize: '0.7rem', color: '#aaa' }}>{timeAgo(n.created_at)}</div>
                          </div>
                          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, flexShrink: 0 }}>
                            {!n.is_read && <div style={{ width: 8, height: 8, borderRadius: '50%', background: style.color }} />}
                            <button onClick={(e) => deleteNotif(n.id, e)}
                              style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ccc', fontSize: 13, padding: 0 }}
                              onMouseEnter={e => e.currentTarget.style.color = '#999'}
                              onMouseLeave={e => e.currentTarget.style.color = '#ccc'}
                            >✕</button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  {notifications.length > 0 && (
                    <div onClick={clearAll}
                      style={{ padding: '12px 16px', textAlign: 'center', fontSize: '0.78rem', color: '#dc2626', fontWeight: '700', cursor: 'pointer', borderTop: '1px solid #f0f0f0', transition: 'background 0.15s' }}
                      onMouseEnter={e => e.currentTarget.style.background = '#fff5f5'}
                      onMouseLeave={e => e.currentTarget.style.background = '#fff'}
                    >
                      Clear All Notifications
                    </div>
                  )}
                </div>
              )}
            </div>

          </div>
        </header>

        <div className="content">
          {panel === 'dashboard'  && <Dashboard    notify={notify} setPanel={setPanel} />}
          {panel === 'drivers'    && <Drivers      notify={notify} setPanel={setPanel} initialSearch={searchParam} />}
          {panel === 'passengers' && <Passengers   notify={notify} setPanel={setPanel} initialSearch={searchParam} />}
          {panel === 'fare'       && <Fare         notify={notify} setPanel={setPanel} initialSearch={searchParam} />}
          {panel === 'stations'   && <TodaStations notify={notify} setPanel={setPanel} />}
          {panel === 'payments'   && <Payments     notify={notify} setPanel={setPanel} initialSearch={searchParam} />}
          {panel === 'qrcodes'    && <QRCodes      notify={notify} setPanel={setPanel} initialSearch={searchParam} />}
          {panel === 'complaints' && <Complaints   notify={notify} setPanel={setPanel} initialSearch={searchParam} />}
          {panel === 'trips'      && <Trips        notify={notify} setPanel={setPanel} initialSearch={searchParam} />}
          {panel === 'audit'      && <Audit        notify={notify} navigate={auditNavigate} />}

          {/* ── Admin Profile Panel ── */}
          {panel === 'profile' && (
            <div className="card animate-fade-in" style={{ maxWidth: 600, margin: '0 auto' }}>
              <div className="card-head">
                <div className="card-title">
                  <FontAwesomeIcon icon={faUserCircle} style={{ marginRight: 10, color: 'var(--gold)' }} />
                  Administrator Profile
                </div>
              </div>
              <form onSubmit={handleUpdateProfile} style={{ padding: '20px' }}>
                <div className="field">
                  <label><FontAwesomeIcon icon={faIdCard} style={{ marginRight: 8 }} />Full Name</label>
                  <input 
                    value={profileForm.full_name} 
                    onChange={e => setProfileForm({...profileForm, full_name: e.target.value})} 
                    placeholder="Enter your full name"
                  />
                </div>
                <div className="field">
                  <label><FontAwesomeIcon icon={faEnvelope} style={{ marginRight: 8 }} />Email Address</label>
                  <input 
                    type="email" 
                    value={profileForm.email} 
                    onChange={e => setProfileForm({...profileForm, email: e.target.value})} 
                    placeholder="admin@etoda.gov"
                  />
                </div>
                <div className="field">
                  <label><FontAwesomeIcon icon={faUserShield} style={{ marginRight: 8 }} />Username</label>
                  <input 
                    value={profileForm.username} 
                    onChange={e => setProfileForm({...profileForm, username: e.target.value})} 
                  />
                </div>
                <div className="field">
                  <label><FontAwesomeIcon icon={faLock} style={{ marginRight: 8 }} />New Password</label>
                  <input 
                    type="password" 
                    value={profileForm.password} 
                    onChange={e => setProfileForm({...profileForm, password: e.target.value})} 
                    placeholder="Leave blank to keep current password"
                  />
                </div>
                <div style={{ marginTop: 24, display: 'flex', justifyContent: 'flex-end' }}>
                  <button type="submit" className="btn btn-green">
                    <FontAwesomeIcon icon={faSave} style={{ marginRight: 8 }} />
                    Save Changes
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ── Settings Panel ── */}
          {panel === 'settings' && (
            <div className="card animate-fade-in" style={{ maxWidth: 600, margin: '0 auto' }}>
              <div className="card-head">
                <div className="card-title">
                  <FontAwesomeIcon icon={faCog} style={{ marginRight: 10, color: 'var(--gold)' }} />
                  System Settings
                </div>
              </div>
              <div style={{ padding: '10px 0' }}>
                {[
                  { id: 'notifications', label: 'Push Notifications', sub: 'Receive alerts for new driver enrollments', icon: faBell },
                  { id: 'maintenance', label: 'Maintenance Mode', sub: 'Disable mobile app access temporarily', icon: faCog },
                  { id: 'autoLogout', label: 'Security Timeout', sub: 'Automatically logout after 30 mins of inactivity', icon: faLock },
                ].map((s) => (
                  <div key={s.id} onClick={() => toggleSetting(s.id)}
                    style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid #f0f0f0', cursor: 'pointer' }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 15 }}>
                      <div style={{ width: 36, height: 36, borderRadius: '50%', background: '#f5f5f5', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <FontAwesomeIcon icon={s.icon} style={{ color: 'var(--gold)' }} />
                      </div>
                      <div>
                        <div style={{ fontSize: '0.9rem', fontWeight: '700' }}>{s.label}</div>
                        <div style={{ fontSize: '0.75rem', color: '#888' }}>{s.sub}</div>
                      </div>
                    </div>
                    <FontAwesomeIcon icon={settings[s.id] ? faToggleOn : faToggleOff} style={{ fontSize: 24, color: settings[s.id] ? 'var(--green)' : '#ccc' }} />
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
      <Toasts toasts={toasts} dismiss={dismiss} />
    </div>
  );
}