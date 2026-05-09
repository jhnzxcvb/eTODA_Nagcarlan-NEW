// src/components/dashboard/Dashboard.js
import React, { useState, useEffect, useRef } from 'react';
import { api, BASE } from '../../lib/api';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faUserPlus, faExclamationTriangle, faDollarSign,
  faQrcode, faCheckCircle, faUsers, faRoute, faWallet,
  faExclamationCircle, faIdCard,
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
    const r = await api(`/api/dashboard/chart?range=${range}`);
    if (r.success) setChartData(r.data);
    else notify(r.error, 'error');
  };

  const loadActivity = async () => {
    const r = await api('/api/audit?pageSize=6');
    if (r.success) {
      const mapped = (r.data || []).map(log => {
        let type = 'driver';
        const entity = log.entity.toLowerCase();
        const detail = log.detail.toLowerCase();

        // Map audit entities to dashboard activity types/icons
        if (entity === 'driver') type = 'driver';
        else if (entity === 'complaint') type = detail.includes('resolved') ? 'resolved' : 'violation';
        else if (entity === 'fare' || entity === 'payment') type = 'fare';
        else if (entity === 'qrcode') type = 'qrcode';

        return {
          type,
          desc: log.detail,
          time: formatTimeAgo(log.created_at)
        };
      });
      setActivity(mapped);
    }
  };

  const formatTimeAgo = (dateStr) => {
    const date = new Date(dateStr.replace(' ', 'T'));
    const seconds = Math.floor((new Date() - date) / 1000);
    if (seconds < 60) return 'Just now';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    return date.toLocaleDateString();
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

  const handleGenerateReport = async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const response = await fetch(`${BASE}/api/dashboard/report`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) throw new Error('Download failed');
      
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `etoda_dashboard_${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      notify('Report generated and downloaded successfully', 'success');
    } catch (err) {
      notify('Failed to generate report: ' + err.message, 'error');
    }
  };

// Helper function to calculate trend string and color
const getTrendInfo = (currentValue, yesterdayValue, prefix = '', suffix = '', inverse = false) => {
  const diff = currentValue - (yesterdayValue || 0);
  let trendString;
  if (diff === 0) {
    trendString = `0 from yesterday`;
  } else {
    const arrow = diff > 0 ? '▲' : '▼';
    const mathSign = diff > 0 ? '+' : '-';
    const absDiff = Math.abs(diff);
    trendString = `${arrow} ${mathSign}${prefix}${absDiff.toLocaleString()}${suffix} from yesterday`;
  }

  const trendColor = diff === 0 ? 'gray' : (diff > 0 ? (inverse ? 'red' : 'green') : (inverse ? 'green' : 'red'));

  return { trend: trendString, trendColor };
};

  const CARDS = stats ? [
    { val: stats.active_drivers,    lbl: 'Active Drivers',   sub: 'Registered',            icon: faUsers, color: '#2d5a1b', ...getTrendInfo(stats.active_drivers, stats.active_drivers_yesterday) },
    { val: stats.trips_today,       lbl: 'Trips Today',      sub: 'Completed',             icon: faRoute, color: '#0284c7', ...getTrendInfo(stats.trips_today, stats.trips_yesterday) },
    { val: `₱${Number(stats.revenue_today || 0).toLocaleString()}`, lbl: 'Revenue Today', sub: `${stats.revenue_count || 0} transactions`, icon: faWallet, color: '#d97706', ...getTrendInfo(stats.revenue_today, stats.revenue_yesterday, '₱') },
    { val: stats.pending_complaints, lbl: 'Open Complaints', sub: 'Needs action',          icon: faExclamationCircle, color: '#dc2626', ...getTrendInfo(stats.pending_complaints, stats.pending_complaints_yesterday, '', '', true) },
    { val: stats.total_drivers,     lbl: 'Total Drivers',    sub: 'All enrolled',          icon: faIdCard, color: '#16a34a', ...getTrendInfo(stats.total_drivers, stats.total_drivers_yesterday) },
    { val: stats.passengers,        lbl: 'Total Passengers', sub: 'Registered',            icon: faUsers, color: '#8e44ad', ...getTrendInfo(stats.passengers, stats.passengers_yesterday) },
    { val: stats.total_trips,       lbl: 'Total Trips',      sub: 'All time',              icon: faCheckCircle, color: '#0369a1', ...getTrendInfo(stats.total_trips, stats.total_trips_yesterday) },
    { val: stats.active_qr,         lbl: 'Active QR Codes',  sub: 'AES-256',               icon: faQrcode, color: '#0f172a', ...getTrendInfo(stats.active_qr, stats.active_qr_yesterday) },
  ] : [];

  if (initialLoading) return <Loading />;

  return (
    <div>
      <style>{`
        .metrics {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
          gap: 24px;
          margin-bottom: 32px;
        }
        .metric {
          background: #ffffff;
          border: 1px solid #e2e8f0;
          border-left: 6px solid;
          border-radius: 16px;
          padding: 24px;
          box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
          transition: all 0.3s ease;
          position: relative;
        }
        .metric:hover {
          transform: translateY(-4px);
          box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
          background-color: #f0fdf4;
        }
        .metric-val {
          font-size: 1.85rem;
          font-weight: 800;
          color: #0f172a;
          margin-bottom: 4px;
          letter-spacing: -0.02em;
        }
        .metric-lbl {
          font-size: 0.85rem;
          font-weight: 700;
          color: #64748b;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }
        .metric-sub {
          font-size: 0.75rem;
          color: #94a3b8;
        }
        .card {
          background: #ffffff !important;
          border: 1px solid #e2e8f0 !important;
          border-radius: 16px !important;
          box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05) !important;
        }
        .premium-action-btn {
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
          border-color: #1a4731 !important;
          color: #1a4731 !important;
          background: transparent;
        }
        .premium-action-btn:hover {
          background-color: #1a4731 !important;
          color: #fff !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 15px rgba(26, 71, 49, 0.2);
        }
        .premium-action-btn:active {
          transform: translateY(0);
        }
        .chart-filter-btn {
          transition: all 0.2s ease !important;
        }
        .chart-filter-btn.btn-outline:hover {
          background-color: rgba(26, 71, 49, 0.08) !important;
          transform: translateY(-1px);
        }
        .chart-filter-btn.btn-primary {
          box-shadow: 0 4px 10px rgba(26, 71, 49, 0.15);
        }
      `}</style>
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
            <div className="metric-trend" style={{ color: c.trendColor, fontSize: '0.75rem' }}>
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
        <button className="btn btn-outline premium-action-btn" onClick={() => setPanel('drivers')}>
          + Enroll Driver
        </button>
        <button className="btn btn-outline premium-action-btn" onClick={() => setPanel('fare')}>
          Configure Fare
        </button>
        <button className="btn btn-outline premium-action-btn" onClick={() => setPanel('complaints')}>
          Review Complaints
        </button>
        <button className="btn btn-outline premium-action-btn" onClick={handleGenerateReport}>
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
            <button
              className={`btn btn-sm chart-filter-btn ${dateRange === 'today' ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setDateRange('today')}
            >
              Today
            </button>
            <button
              className={`btn btn-sm chart-filter-btn ${dateRange === 'week'  ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setDateRange('week')}
            >
              This Week
            </button>
            <button
              className={`btn btn-sm chart-filter-btn ${dateRange === 'month' ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setDateRange('month')}
            >
              This Month
            </button>
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