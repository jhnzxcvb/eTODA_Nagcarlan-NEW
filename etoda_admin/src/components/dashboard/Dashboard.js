// src/components/dashboard/Dashboard.js
import React, { useState, useEffect, useRef } from 'react';
import { api } from '../../lib/api';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faUserPlus, faExclamationTriangle, faDollarSign,
  faQrcode, faCheckCircle,
} from '@fortawesome/free-solid-svg-icons';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

const MOCK_CHART_DATA = {
  today: [
    { day: '6am',  trips: 3 },
    { day: '9am',  trips: 8 },
    { day: '12pm', trips: 14 },
    { day: '3pm',  trips: 11 },
    { day: '6pm',  trips: 17 },
    { day: '9pm',  trips: 6 },
  ],
  week: [
    { day: 'Mon', trips: 12 },
    { day: 'Tue', trips: 19 },
    { day: 'Wed', trips: 15 },
    { day: 'Thu', trips: 25 },
    { day: 'Fri', trips: 22 },
    { day: 'Sat', trips: 30 },
    { day: 'Sun', trips: 18 },
  ],
  month: [
    { day: 'Wk 1', trips: 84 },
    { day: 'Wk 2', trips: 97 },
    { day: 'Wk 3', trips: 110 },
    { day: 'Wk 4', trips: 103 },
  ],
};

// Map activity type → FA icon + color
const ACTIVITY_STYLE = {
  driver:    { icon: faUserPlus,            color: '#2d5a1b', bg: '#e8f5e9' },
  violation: { icon: faExclamationTriangle, color: '#dc2626', bg: '#fee2e2' },
  fare:      { icon: faDollarSign,          color: '#d97706', bg: '#fff8e1' },
  qrcode:    { icon: faQrcode,             color: '#0284c7', bg: '#e0f2fe' },
  resolved:  { icon: faCheckCircle,        color: '#16a34a', bg: '#dcfce7' },
};

function Dashboard({ notify, setPanel }) {
  const [stats, setStats] = useState(null);
  const [initialLoading, setInitialLoading] = useState(true);
  const [chartLoading, setChartLoading] = useState(false);
  const [dateRange, setDateRange] = useState('today');
  const [chartData, setChartData] = useState([]);
  const [activity, setActivity] = useState([]);
  const isFirstRender = useRef(true);
  const dropdownRef = useRef();

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {}
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const loadStats = async () => {
    const r = await api('/api/dashboard');
    if (r.success) setStats(r.data); else notify(r.error, 'error');
  };

  const loadChart = async (range) => {
    setChartData(MOCK_CHART_DATA[range]);
  };

  const loadActivity = async () => {
    const mockActivity = [
      { type: 'driver',    desc: 'Juan dela Cruz enrolled as driver',        time: '2 min ago' },
      { type: 'violation', desc: 'Violation reported against Body No. 042',  time: '5 min ago' },
      { type: 'fare',      desc: 'Fare matrix updated by Admin',             time: '10 min ago' },
      { type: 'qrcode',    desc: 'QR Code issued to Body No. 018',           time: '15 min ago' },
      { type: 'resolved',  desc: 'Complaint #005 marked as resolved',        time: '20 min ago' },
    ];
    setActivity(mockActivity);
  };

  // Initial load
  useEffect(() => {
    const init = async () => {
      setInitialLoading(true);
      await Promise.all([loadStats(), loadChart('today'), loadActivity()]);
      setInitialLoading(false);
    };
    init();
  }, []);

  // ── Live Refresh ──
  // Poll the dashboard stats and recent activity every 15 seconds
  useEffect(() => {
    const poll = setInterval(() => {
      loadStats();
      loadActivity();
    }, 15000);
    return () => clearInterval(poll);
  }, []);

  // Date range change — only refresh chart
  useEffect(() => {
    if (isFirstRender.current) {
      isFirstRender.current = false;
      return;
    }
    const refresh = async () => {
      setChartLoading(true);
      await loadChart(dateRange);
      setChartLoading(false);
    };
    refresh();
  }, [dateRange]);

  const { faUsers, faRoute, faWallet, faExclamationCircle, faIdCard, faQrcode } = require('@fortawesome/free-solid-svg-icons');

  const CARDS = stats ? [
    { val: stats.active_drivers,    lbl: 'Active Drivers',   sub: 'Registered',            icon: faUsers, trend: '▲ +1 from yesterday',  trendColor: 'green', color: '#2d5a1b' },
    { val: stats.trips_today,       lbl: 'Trips Today',      sub: 'Completed',             icon: faRoute, trend: '▼ -2 from yesterday',  trendColor: 'red',   color: '#0284c7' },
    { val: `₱${Number(stats.revenue_today).toLocaleString()}`, lbl: 'Revenue Today', sub: `${stats.revenue_count || 0} transactions`, icon: faWallet, trend: '▲ +₱500 from yesterday', trendColor: 'green', color: '#d97706' },
    { val: stats.pending_complaints, lbl: 'Open Complaints', sub: 'Needs action',          icon: faExclamationCircle, trend: '▲ +3 from yesterday',  trendColor: 'red',   color: '#dc2626' },
    { val: stats.total_drivers,     lbl: 'Total Drivers',    sub: 'All enrolled',          icon: faIdCard, trend: '▲ +2 from yesterday',  trendColor: 'green', color: '#16a34a' },
    { val: stats.passengers,        lbl: 'Total Passengers', sub: 'Registered',            icon: faUsers, trend: '▲ +5 from yesterday',  trendColor: 'green', color: '#8e44ad' },
    { val: stats.total_trips,       lbl: 'Total Trips',      sub: 'All time',              icon: faCheckCircle, trend: '▲ +10 from yesterday', trendColor: 'green', color: '#0369a1' },
    { val: stats.active_qr,         lbl: 'Active QR Codes',  sub: 'AES-256',               icon: faQrcode, trend: '▼ -1 from yesterday',  trendColor: 'red',   color: '#0f172a' },
  ] : [];

  if (initialLoading) return <Loading />;

  return (
    <div>
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

      {/* Quick Actions */}
      <div className="quick-actions" style={{ display: 'flex', gap: 12, margin: '20px 0' }}>
        <button className="btn btn-outline" style={{ borderColor: '#1a4731', color: '#1a4731' }} onClick={() => setPanel('drivers')}>
          + Enroll Driver
        </button>
        <button className="btn btn-outline" style={{ borderColor: '#1a4731', color: '#1a4731' }} onClick={() => setPanel('fare')}>
          Configure Fare
        </button>
        <button className="btn btn-outline" style={{ borderColor: '#1a4731', color: '#1a4731' }} onClick={() => setPanel('complaints')}>
          Review Complaints
        </button>
        <button className="btn btn-outline" style={{ borderColor: '#1a4731', color: '#1a4731' }} onClick={() => notify('Report generated', 'success')}>
          Generate Report
        </button>
      </div>

      {/* Chart */}
      <div className="card" style={{ marginBottom: 18 }}>
        <div className="card-head" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div className="card-title">
            {dateRange === 'today' ? 'Trips Today' : dateRange === 'week' ? 'Trips This Week' : 'Trips This Month'}
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button className={`btn btn-sm ${dateRange === 'today' ? 'btn-primary' : 'btn-outline'}`} onClick={() => setDateRange('today')}>Today</button>
            <button className={`btn btn-sm ${dateRange === 'week'  ? 'btn-primary' : 'btn-outline'}`} onClick={() => setDateRange('week')}>This Week</button>
            <button className={`btn btn-sm ${dateRange === 'month' ? 'btn-primary' : 'btn-outline'}`} onClick={() => setDateRange('month')}>This Month</button>
          </div>
        </div>
        <div style={{ padding: 18, opacity: chartLoading ? 0.4 : 1, transition: 'opacity 0.2s' }}>
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

      {/* Recent Activity */}
      <div className="card">
        <div className="card-head"><div className="card-title">Recent Activity</div></div>
        <div style={{ padding: '14px 18px' }}>
          {activity.map((a, i) => {
            const s = ACTIVITY_STYLE[a.type] || ACTIVITY_STYLE.driver;
            return (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '9px 0', borderBottom: '1px solid var(--gray2)' }}>
                <div style={{ width: 34, height: 34, borderRadius: '50%', background: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <FontAwesomeIcon icon={s.icon} style={{ color: s.color, fontSize: 14 }} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '.82rem' }}>{a.desc}</div>
                  <div style={{ fontSize: '.7rem', color: 'var(--gray)' }}>{a.time}</div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

export default Dashboard;