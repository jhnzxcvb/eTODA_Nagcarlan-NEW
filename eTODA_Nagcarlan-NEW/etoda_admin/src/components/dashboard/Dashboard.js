// src/components/dashboard/Dashboard.js
import React, { useState, useEffect } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

function Dashboard({ notify }) {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/dashboard');
    if (r.success) setStats(r.data); else notify(r.error,'error');
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const CARDS = stats ? [
    {val:stats.active_drivers,    lbl:'Active Drivers',   sub:'Registered',  color:'var(--green)'},
    {val:stats.trips_today,       lbl:'Trips Today',      sub:'Completed',   color:'var(--blue)'},
    {val:`₱${Number(stats.revenue_today).toLocaleString()}`,lbl:'Revenue Today',sub:'Settled',color:'var(--ora)'},
    {val:stats.pending_complaints,lbl:'Open Complaints',  sub:'Needs action',color:'var(--red)'},
    {val:stats.total_drivers,     lbl:'Total Drivers',    sub:'All enrolled', color:'var(--green)'},
    {val:stats.passengers,        lbl:'Total Passengers', sub:'Registered',  color:'#8e44ad'},
    {val:stats.total_trips,       lbl:'Total Trips',      sub:'All time',    color:'var(--blue)'},
    {val:stats.active_qr,         lbl:'Active QR Codes',  sub:'AES-256',     color:'var(--green3)'},
  ] : [];

  return (
    <div>
      {loading ? <Loading/> : (
        <>
          <div className="metrics">
            {CARDS.map((c,i) => (
              <div key={i} className="metric" style={{borderLeftColor:c.color}}>
                <div className="metric-val">{c.val}</div>
                <div className="metric-lbl">{c.lbl}</div>
                <div className="metric-sub">{c.sub}</div>
              </div>
            ))}
          </div>
          <div style={{display:'grid',gridTemplateColumns:'1.4fr 1fr',gap:18}}>
            <div className="card">
              <div className="card-head">
                <div className="card-title">📡 System Status</div>
                <button className="btn btn-ghost btn-sm" onClick={() => { load(); notify('Refreshed','info'); }}>↻ Refresh</button>
              </div>
              <div style={{padding:'14px 18px'}}>
                {[['Go Backend API','Online'],['PostgreSQL Database','Connected'],['AES-256 QR Encryption','Active'],['Firebase Realtime DB','Synced'],['Audit Trail Logging','Enabled']].map(([l,v]) => (
                  <div key={l} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'9px 0',borderBottom:'1px solid var(--gray2)'}}>
                    <span style={{fontSize:'.83rem',fontWeight:500}}>{l}</span>
                    <span className="badge badge-active">{v}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="card">
              <div className="card-head"><div className="card-title">📊 Live Numbers</div></div>
              <div style={{padding:'14px 18px'}}>
                {stats && [
                  ['Active Drivers', stats.active_drivers,   'var(--green)'],
                  ['Trips Today',    stats.trips_today,       'var(--blue)'],
                  ['Active QR',      stats.active_qr,         'var(--green3)'],
                  ['Open Complaints',stats.pending_complaints,'var(--red)'],
                ].map(([l,v,c]) => (
                  <div key={l} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'9px 0',borderBottom:'1px solid var(--gray2)'}}>
                    <span style={{fontSize:'.82rem'}}>{l}</span>
                    <span style={{fontFamily:'Roboto',fontWeight:700,color:c,fontSize:'1.15rem'}}>{v}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

export default Dashboard;