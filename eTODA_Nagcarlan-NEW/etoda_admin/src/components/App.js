// src/components/App.js
import React, { useState, useEffect, useRef } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faHome, faUsers, faUser, faDollarSign, faCreditCard, faMobileAlt, faExclamationTriangle, faCar, faClipboard } from '@fortawesome/free-solid-svg-icons';
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
  const [auth, setAuth] = useState(null);
  const [panel, setPanel] = useState('dashboard');
  const { toasts, notify, dismiss } = useToast();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef();

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const logout = () => {
    localStorage.removeItem('adminToken');
    setAuth(null);
    notify('Logged out', 'info');
  };

  // if not authenticated show login/signup
  if (!auth) {
    return (
      <>
        <Auth onSuccess={setAuth} notify={notify} />
        <Toasts toasts={toasts} dismiss={dismiss} />
      </>
    );
  }

  const NAV = [
    ['dashboard', faHome, 'Dashboard'],
    ['drivers', faUsers, 'Drivers'],
    ['passengers', faUser, 'Passengers'],
    ['fare', faDollarSign, 'Fare Matrix'],
    ['payments', faCreditCard, 'Payments'],
    ['qrcodes', faMobileAlt, 'QR Codes'],
    ['complaints', faExclamationTriangle, 'Complaints'],
    ['trips', faCar, 'Trip History'],
    ['audit', faClipboard, 'Audit Trail'],
  ];
  const TITLE = Object.fromEntries(NAV.map(([id,,l]) => [id, l]));

  return (
    <div className="app">
      <aside className="sb">
        <div className="sb-brand">
          <div className="sb-logo">e<span>TODA</span></div>
          <div className="sb-tag">Nagcarlan Admin</div>
        </div>
        <nav style={{paddingTop:8}}>
          <div className="sb-sec">Navigation</div>
          {NAV.map(([id, icon, lbl]) => (
            <button key={id} className={`sb-btn${panel===id?' active':''}`} onClick={() => setPanel(id)}>
              <FontAwesomeIcon icon={icon} className="sb-ico" style={{color: 'var(--gold)'}} />{lbl}
            </button>
          ))}
        </nav>
        <div className="sb-foot" ref={dropdownRef} onClick={() => setDropdownOpen(!dropdownOpen)} style={{cursor:'pointer', position:'relative'}}>
          <FontAwesomeIcon icon={faUser} className="sb-av" style={{color: 'var(--gold)'}} />
          <div>
            <div style={{fontSize:'.81rem',color:'#fff',fontWeight:600}}>TODA Admin</div>
            <div style={{fontSize:'.67rem',color:'rgba(255,255,255,.4)'}}>Administrator</div>
          </div>
          {dropdownOpen && (
            <div style={{position:'absolute', bottom:'100%', left:0, background:'#fff', border:'1px solid #ccc', borderRadius:4, boxShadow:'0 2px 10px rgba(0,0,0,0.1)', zIndex:1000, minWidth:120}}>
              <div style={{padding:'8px 12px', cursor:'pointer', borderBottom:'1px solid #eee'}} onClick={() => {setPanel('profile'); setDropdownOpen(false);}}>👤 Profile</div>
              <div style={{padding:'8px 12px', cursor:'pointer', borderBottom:'1px solid #eee'}} onClick={() => {setPanel('settings'); setDropdownOpen(false);}}>⚙️ Settings</div>
              <div style={{padding:'8px 12px', cursor:'pointer'}} onClick={logout}>🚪 Logout</div>
            </div>
          )}
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div>
            <div className="tb-title">{TITLE[panel]}</div>
            <div className="tb-sub">eTODA Nagcarlan Management System</div>
          </div>
          <div className="tb-right">
            <div style={{display:'flex',alignItems:'center',gap:6,fontSize:'.74rem',color:'var(--gray)'}}>
              <div className="sync-dot"/><span>Go + PostgreSQL</span>
            </div>
            <div style={{fontSize:'.74rem',color:'var(--gray)'}}>
              {new Date().toLocaleDateString('en-PH',{weekday:'short',month:'short',day:'numeric'})}
            </div>
          </div>
        </header>
        <div className="content">
          {panel==='dashboard'  && <Dashboard  notify={notify}/>}
          {panel==='drivers'    && <Drivers    notify={notify}/>}
          {panel==='passengers' && <Passengers notify={notify}/>}
          {panel==='fare'       && <Fare       notify={notify}/>}
          {panel==='payments'   && <Payments   notify={notify}/>}
          {panel==='qrcodes'    && <QRCodes    notify={notify}/>}
          {panel==='complaints' && <Complaints notify={notify}/>}
          {panel==='trips'      && <Trips      notify={notify}/>}
          {panel==='audit'      && <Audit      notify={notify}/>}
        </div>
      </div>
      <Toasts toasts={toasts} dismiss={dismiss}/>
    </div>
  );
}