// src/components/dashboard/Dashboard.js
import React, { useState, useEffect, useRef } from 'react';
import { api } from '../../lib/api';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

function Dashboard({ notify, setPanel }) {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState('today');
  const [chartData, setChartData] = useState([]);
  const [activity, setActivity] = useState([]);
  const dropdownRef = useRef();

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {}
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/dashboard');
    if (r.success) setStats(r.data); else notify(r.error, 'error');
    setLoading(false);
  };

  const loadChart = async () => {
    const mockData = [
      { day: 'Mon', trips: 12 },
      { day: 'Tue', trips: 19 },
      { day: 'Wed', trips: 15 },
      { day: 'Thu', trips: 25 },
      { day: 'Fri', trips: 22 },
      { day: 'Sat', trips: 30 },
      { day: 'Sun', trips: 18 },
    ];
    setChartData(mockData);
  };

  const loadActivity = async () => {
    const mockActivity = [
      { icon: '👤', desc: 'Juan dela Cruz enrolled as driver', time: '2 min ago' },
      { icon: '⚠️', desc: 'Violation reported against Body No. 042', time: '5 min ago' },
      { icon: '💰', desc: 'Fare matrix updated by Admin', time: '10 min ago' },
      { icon: '🔲', desc: 'QR Code issued to Body No. 018', time: '15 min ago' },
      { icon: '✅', desc: 'Complaint #005 marked as resolved', time: '20 min ago' },
    ];
    setActivity(mockActivity);
  };

  useEffect(() => { load(); loadChart(); loadActivity(); }, [dateRange]);

  const CARDS = stats ? [
    { val: stats.active_drivers,    lbl: 'Active Drivers',   sub: 'Registered',            trend: '▲ +1 from yesterday',  trendColor: 'green', color: 'var(--green)' },
    { val: stats.trips_today,       lbl: 'Trips Today',      sub: 'Completed',             trend: '▼ -2 from yesterday',  trendColor: 'red',   color: 'var(--blue)' },
    { val: `₱${Number(stats.revenue_today).toLocaleString()}`, lbl: 'Revenue Today', sub: '3 transactions · cash', trend: '▲ +₱500 from yesterday', trendColor: 'green', color: 'var(--ora)' },
    { val: stats.pending_complaints, lbl: 'Open Complaints', sub: 'Needs action',          trend: '▲ +3 from yesterday',  trendColor: 'red',   color: 'var(--red)' },
    { val: stats.total_drivers,     lbl: 'Total Drivers',    sub: 'All enrolled',          trend: '▲ +2 from yesterday',  trendColor: 'green', color: 'var(--green)' },
    { val: stats.passengers,        lbl: 'Total Passengers', sub: 'Registered',            trend: '▲ +5 from yesterday',  trendColor: 'green', color: '#8e44ad' },
    { val: stats.total_trips,       lbl: 'Total Trips',      sub: 'All time',              trend: '▲ +10 from yesterday', trendColor: 'green', color: 'var(--blue)' },
    { val: stats.active_qr,         lbl: 'Active QR Codes',  sub: 'AES-256',               trend: '▼ -1 from yesterday',  trendColor: 'red',   color: 'var(--green3)' },
  ] : [];

  return (
    <div>
      {loading ? <Loading /> : (
        <>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div></div>
            <div className="date-range" style={{ display: 'flex', gap: 8 }}>
              <button className={`btn ${dateRange === 'today'  ? 'btn-primary' : 'btn-outline'}`} onClick={() => setDateRange('today')}>Today</button>
              <button className={`btn ${dateRange === 'week'   ? 'btn-primary' : 'btn-outline'}`} onClick={() => setDateRange('week')}>This Week</button>
              <button className={`btn ${dateRange === 'month'  ? 'btn-primary' : 'btn-outline'}`} onClick={() => setDateRange('month')}>This Month</button>
            </div>
          </div>

          <div className="metrics">
            {CARDS.map((c, i) => (
              <div
                key={i}
                className={`metric ${c.lbl === 'Open Complaints' && c.val > 0 ? 'animate-pulse border-red-500' : ''}`}
                style={{ borderLeftColor: c.color }}
              >
                <div className="metric-val">{c.val}</div>
                <div className="metric-lbl">{c.lbl}</div>
                <div className="metric-sub">{c.sub}</div>
                <div className="metric-trend" style={{ color: c.trendColor === 'green' ? 'green' : 'red', fontSize: '0.75rem' }}>
                  {c.trend}
                </div>
                {c.lbl === 'Open Complaints' && c.val > 0 && (
                  <button
                    onClick={() => setPanel('complaints')}
                    style={{
                      display: 'inline-block',
                      marginTop: '10px',
                      padding: '6px 14px',
                      background: '#dc2626',
                      color: '#fff',
                      border: 'none',
                      borderRadius: '8px',
                      fontSize: '0.75rem',
                      fontWeight: '700',
                      cursor: 'pointer',
                      letterSpacing: '0.3px',
                      boxShadow: '0 2px 8px rgba(220,38,38,0.35)',
                      transition: 'background 0.2s',
                    }}
                    onMouseEnter={e => e.currentTarget.style.background = '#b91c1c'}
                    onMouseLeave={e => e.currentTarget.style.background = '#dc2626'}
                  >
                        Review Now →
                  </button>
                )}
              </div>
            ))}
          </div>

          {/* Quick Actions — all use setPanel() to stay within the app */}
          <div className="quick-actions" style={{ display: 'flex', gap: 12, margin: '20px 0' }}>
            <button
              className="btn btn-outline"
              style={{ borderColor: '#1a4731', color: '#1a4731' }}
              onClick={() => setPanel('drivers')}
            >
              + Enroll Driver
            </button>
            <button
              className="btn btn-outline"
              style={{ borderColor: '#1a4731', color: '#1a4731' }}
              onClick={() => setPanel('fare')}
            >
              Configure Fare
            </button>
            <button
              className="btn btn-outline"
              style={{ borderColor: '#1a4731', color: '#1a4731' }}
              onClick={() => setPanel('complaints')}
            >
              Review Complaints
            </button>
            <button
              className="btn btn-outline"
              style={{ borderColor: '#1a4731', color: '#1a4731' }}
              onClick={() => notify('Report generated', 'success')}
            >
              Generate Report
            </button>
          </div>

          <div className="card" style={{ marginBottom: 18 }}>
            <div className="card-head">
              <div className="card-title">Trips This Week</div>
            </div>
            <div style={{ padding: 18 }}>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="day" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="trips" fill="#1a4731" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 18 }}>
            <div className="card">
              <div className="card-head">
                <div className="card-title">🖥️ System Status</div>
                <button className="btn btn-ghost btn-sm" onClick={() => { load(); notify('Refreshed', 'info'); }}>↻ Refresh</button>
              </div>
              <div style={{ padding: '14px 18px' }}>
                {[
                  ['Go Backend API', 'Online'],
                  ['PostgreSQL Database', 'Connected'],
                  ['AES-256 QR Encryption', 'Active'],
                  ['Firebase FCM (Push Notifications)', 'Synced'],
                  ['Audit Trail Logging', 'Enabled'],
                ].map(([l, v]) => (
                  <div key={l} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '9px 0', borderBottom: '1px solid var(--gray2)' }}>
                    <span style={{ fontSize: '.83rem', fontWeight: 500 }}>{l}</span>
                    <span className="badge badge-active">{v}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="card">
              <div className="card-head"><div className="card-title">Recent Activity</div></div>
              <div style={{ padding: '14px 18px' }}>
                {activity.map((a, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 0', borderBottom: '1px solid var(--gray2)' }}>
                    <span style={{ fontSize: '1.2rem' }}>{a.icon}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '.82rem' }}>{a.desc}</div>
                      <div style={{ fontSize: '.7rem', color: 'var(--gray)' }}>{a.time}</div>
                    </div>
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