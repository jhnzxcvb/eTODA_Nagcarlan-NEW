// src/components/App.js
import React, { useState, useEffect, useRef } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faHome, faUsers, faUser, faDollarSign, faCreditCard, faMobileAlt, faExclamationTriangle, faCar, faClipboard, faChevronUp, faSignOutAlt, faCog, faUserCircle } from '@fortawesome/free-solid-svg-icons';
import Auth from '../Auth';
import Dashboard from './dashboard/Dashboard';
import Drivers from './drivers/Drivers';
import Passengers from './passengers/Passengers';
import Trips from './trips/Trips';
import Payments from './payments/Payments';
import Complaints from './complaints/Complaints';
import Fare from './fare/Fare';
import QRCodes from './qrcodes/QRCodes';
import Audit from './audit/Audit';
import { Toasts, useToast } from './ui/Toast';

export default function App() {
  // ── FIX: Initialize auth from localStorage so refresh keeps you logged in ──
  const [auth, setAuth] = useState(() => {
    try {
      const saved = localStorage.getItem('adminUser');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const [panel, setPanel] = useState('dashboard');
  const { toasts, notify, dismiss } = useToast();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef();

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // ── FIX: Save user to localStorage when auth changes ──
  const handleLoginSuccess = (userData) => {
    localStorage.setItem('adminUser', JSON.stringify(userData));
    setAuth(userData);
  };

  const logout = () => {
    localStorage.removeItem('adminUser');
    localStorage.removeItem('adminToken');
    setAuth(null);
    notify('Logged out', 'info');
  };

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
    ['payments',   faCreditCard,          'Payments'],
    ['qrcodes',    faMobileAlt,           'QR Codes'],
    ['complaints', faExclamationTriangle, 'Complaints'],
    ['trips',      faCar,                 'Trip History'],
    ['audit',      faClipboard,           'Audit Trail'],
  ];
  const TITLE = Object.fromEntries(NAV.map(([id,, l]) => [id, l]));

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
              onClick={() => setPanel(id)}
            >
              <FontAwesomeIcon icon={icon} className="sb-ico" style={{ color: 'var(--gold)' }} />
              {lbl}
            </button>
          ))}
        </nav>

        {/* ── Profile Footer ── */}
        <div ref={dropdownRef} style={{ position: 'relative', padding: '12px', marginTop: 'auto' }}>

          {/* Dropdown Menu */}
          {dropdownOpen && (
            <div style={{
              position: 'absolute',
              bottom: 'calc(100% - 8px)',
              left: '12px',
              right: '12px',
              background: '#fff',
              borderRadius: '14px',
              boxShadow: '0 -4px 24px rgba(0,0,0,0.18)',
              overflow: 'hidden',
              zIndex: 1000,
              animation: 'fadeSlideUp 0.15s ease',
            }}>
              <style>{`
                @keyframes fadeSlideUp {
                  from { opacity: 0; transform: translateY(8px); }
                  to   { opacity: 1; transform: translateY(0); }
                }
              `}</style>

              {/* Edit Profile */}
              <div
                onClick={() => { setPanel('profile'); setDropdownOpen(false); }}
                style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  padding: '13px 16px', cursor: 'pointer',
                  borderBottom: '1px solid #f0f0f0', transition: 'background 0.15s',
                }}
                onMouseEnter={e => e.currentTarget.style.background = '#f5f5f5'}
                onMouseLeave={e => e.currentTarget.style.background = '#fff'}
              >
                <div style={{ width: 32, height: 32, borderRadius: '50%', background: '#e8f5e9', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <FontAwesomeIcon icon={faUserCircle} style={{ color: '#2d5a1b', fontSize: 16 }} />
                </div>
                <div>
                  <div style={{ fontSize: '0.85rem', fontWeight: '700', color: '#1a1a1a' }}>Edit Profile</div>
                  <div style={{ fontSize: '0.72rem', color: '#888' }}>Update your info</div>
                </div>
              </div>

              {/* Settings */}
              <div
                onClick={() => { setPanel('settings'); setDropdownOpen(false); }}
                style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  padding: '13px 16px', cursor: 'pointer',
                  borderBottom: '1px solid #f0f0f0', transition: 'background 0.15s',
                }}
                onMouseEnter={e => e.currentTarget.style.background = '#f5f5f5'}
                onMouseLeave={e => e.currentTarget.style.background = '#fff'}
              >
                <div style={{ width: 32, height: 32, borderRadius: '50%', background: '#fff8e1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <FontAwesomeIcon icon={faCog} style={{ color: '#f59e0b', fontSize: 15 }} />
                </div>
                <div>
                  <div style={{ fontSize: '0.85rem', fontWeight: '700', color: '#1a1a1a' }}>Settings</div>
                  <div style={{ fontSize: '0.72rem', color: '#888' }}>System preferences</div>
                </div>
              </div>

              {/* Logout */}
              <div
                onClick={logout}
                style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  padding: '13px 16px', cursor: 'pointer', transition: 'background 0.15s',
                }}
                onMouseEnter={e => e.currentTarget.style.background = '#fff5f5'}
                onMouseLeave={e => e.currentTarget.style.background = '#fff'}
              >
                <div style={{ width: 32, height: 32, borderRadius: '50%', background: '#fee2e2', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <FontAwesomeIcon icon={faSignOutAlt} style={{ color: '#dc2626', fontSize: 15 }} />
                </div>
                <div>
                  <div style={{ fontSize: '0.85rem', fontWeight: '700', color: '#dc2626' }}>Logout</div>
                  <div style={{ fontSize: '0.72rem', color: '#888' }}>Sign out of admin</div>
                </div>
              </div>
            </div>
          )}

          {/* Profile Bar — clickable trigger */}
          <div
            onClick={() => setDropdownOpen(!dropdownOpen)}
            style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '10px 12px', borderRadius: '12px',
              background: dropdownOpen ? 'rgba(255,255,255,0.15)' : 'rgba(255,255,255,0.08)',
              border: '1px solid rgba(255,255,255,0.12)',
              cursor: 'pointer', transition: 'background 0.2s, border 0.2s',
              userSelect: 'none',
            }}
            onMouseEnter={e => { if (!dropdownOpen) e.currentTarget.style.background = 'rgba(255,255,255,0.13)'; }}
            onMouseLeave={e => { if (!dropdownOpen) e.currentTarget.style.background = 'rgba(255,255,255,0.08)'; }}
          >
            <div style={{
              width: 38, height: 38, borderRadius: '50%',
              background: 'var(--gold)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0, boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
            }}>
              <FontAwesomeIcon icon={faUser} style={{ color: '#1a4731', fontSize: 16 }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              {/* Show actual username from auth data if available */}
              <div style={{ fontSize: '.82rem', color: '#fff', fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {auth.full_name || auth.username || 'TODA Admin'}
              </div>
              <div style={{ fontSize: '.68rem', color: 'rgba(255,255,255,0.5)' }}>
                Administrator
              </div>
            </div>
            <FontAwesomeIcon
              icon={faChevronUp}
              style={{
                color: 'rgba(255,255,255,0.5)', fontSize: 11,
                transform: dropdownOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                transition: 'transform 0.2s', flexShrink: 0,
              }}
            />
          </div>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div>
            <div className="tb-title">{TITLE[panel] || 'Dashboard'}</div>
            <div className="tb-sub">eTODA Nagcarlan Management System</div>
          </div>
          <div className="tb-right">
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '.74rem', color: 'var(--gray)' }}>
              <div className="sync-dot" /><span>Go + PostgreSQL</span>
            </div>
            <div style={{ fontSize: '.74rem', color: 'var(--gray)' }}>
              {new Date().toLocaleDateString('en-PH', { weekday: 'short', month: 'short', day: 'numeric' })}
            </div>
          </div>
        </header>
        <div className="content">
          {panel === 'dashboard'  && <Dashboard  notify={notify} setPanel={setPanel} />}
          {panel === 'drivers'    && <Drivers    notify={notify} setPanel={setPanel} />}
          {panel === 'passengers' && <Passengers notify={notify} setPanel={setPanel} />}
          {panel === 'fare'       && <Fare       notify={notify} setPanel={setPanel} />}
          {panel === 'payments'   && <Payments   notify={notify} setPanel={setPanel} />}
          {panel === 'qrcodes'    && <QRCodes    notify={notify} setPanel={setPanel} />}
          {panel === 'complaints' && <Complaints notify={notify} setPanel={setPanel} />}
          {panel === 'trips'      && <Trips      notify={notify} setPanel={setPanel} />}
          {panel === 'audit'      && <Audit      notify={notify} setPanel={setPanel} />}
        </div>
      </div>
      <Toasts toasts={toasts} dismiss={dismiss} />
    </div>
  );
}