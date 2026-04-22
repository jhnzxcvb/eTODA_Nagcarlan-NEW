// src/components/trips/Trips.js
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faRoute, faSearch, faFilter, faEye, 
  faChevronLeft, faChevronRight, faRefresh,
  faCalendar, faTimes
} from '@fortawesome/free-solid-svg-icons';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';
import { buildPageWindow } from '../../lib/pagination';

const api = async (endpoint) => {
  try {
    const response = await fetch(`http://localhost:8080${endpoint}`, {
      headers: { Authorization: `Bearer ${localStorage.getItem('adminToken')}` }
    });
    return await response.json();
  } catch (err) {
    return { success: false, error: 'Connection failed' };
  }
};

const DATE_PRESETS = [
  { label: 'Today',      value: 'today' },
  { label: 'Yesterday',  value: 'yesterday' },
  { label: 'This week',  value: 'week' },
  { label: 'This month', value: 'month' },
];

const presetToRange = (preset) => {
  const now   = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  switch (preset) {
    case 'today':
      return {
        dateFrom: today.toISOString(),
        dateTo:   new Date(today.getTime() + 86400000 - 1).toISOString(),
      };
    case 'yesterday': {
      const yd = new Date(today.getTime() - 86400000);
      return {
        dateFrom: yd.toISOString(),
        dateTo:   new Date(today.getTime() - 1).toISOString(),
      };
    }
    case 'week': {
      const day  = today.getDay();
      const mon  = new Date(today.getTime() - day * 86400000);
      return {
        dateFrom: mon.toISOString(),
        dateTo:   new Date(today.getTime() + 86400000 - 1).toISOString(),
      };
    }
    case 'month': {
      const firstOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      return {
        dateFrom: firstOfMonth.toISOString(),
        dateTo:   new Date(today.getTime() + 86400000 - 1).toISOString(),
      };
    }
    default:
      return { dateFrom: '', dateTo: '' };
  }
};

const formatDate = (str) => {
  if (!str) return '—';
  
  // If the string is already formatted by the server (e.g. "Oct 27, 2023, 02:30 PM"),
  // return it as is to prevent browser timezone logic from shifting the time.
  if (typeof str === 'string' && str.includes(',') && (str.includes('AM') || str.includes('PM'))) {
    return str;
  }

  const d = new Date(str);
  if (isNaN(d.getTime())) return str;
  return d.toLocaleString('en-PH', {
    timeZone: 'Asia/Manila',
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  });
};

const formatDuration = (mins) => {
  mins = Math.max(0, mins);
  if (mins >= 60) {
    const h = Math.floor(mins / 60);
    const m = mins % 60;
    return m === 0 ? `${h}hr` : `${h}hr ${m}m`;
  }
  return `${mins} min`;
};

const StatusBadge = ({ status }) => {
  const colorMap = {
    'completed': 'badge-settled',
    'cancelled': 'badge-refunded',
  };
  return <span className={`badge ${colorMap[status.toLowerCase()] || 'badge-pending'}`}>{status}</span>;
};

function Trips({ notify }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [viewItem, setViewItem] = useState(null);

  const [datePreset, setDatePreset] = useState('');
  const [dateFrom,   setDateFrom]   = useState('');
  const [dateTo,     setDateTo]     = useState('');
  const [showDatePicker, setShowDatePicker] = useState(false);

  // ── Filters & Pagination ──
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);

  const load = useCallback(async () => {
    const r = await api('/api/trips');
    if (r.success) setData(r.data || []);
    setLoading(false);
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => { setCurrentPage(1); }, [pageSize, search, dateFrom, dateTo]);

  const filtered = useMemo(() => {
    let rows = data;

    if (dateFrom || dateTo) {
      const fromTime = dateFrom ? new Date(dateFrom).getTime() : -Infinity;
      const toTime = dateTo ? new Date(dateTo).getTime() : Infinity;

      rows = rows.filter(t => {
        if (!t.ended_at) return false;
        const tripTime = new Date(t.ended_at).getTime();
        if (isNaN(tripTime)) return true;
        return tripTime >= fromTime && tripTime <= toTime;
      });
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      rows = rows.filter(t =>
        t.trip_code?.toLowerCase().includes(q) ||
        t.passenger_name?.toLowerCase().includes(q) ||
        t.driver_name?.toLowerCase().includes(q) ||
        t.route?.toLowerCase().includes(q)
      );
    }
    return rows;
  }, [data, search, dateFrom, dateTo]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const pageWindow = buildPageWindow(currentPage, totalPages);

  const applyPreset = (preset) => {
    setDatePreset(preset);
    const { dateFrom: df, dateTo: dt } = presetToRange(preset);
    setDateFrom(df);
    setDateTo(dt);
    setShowDatePicker(false);
  };

  const clearDateFilter = () => {
    setDatePreset('');
    setDateFrom('');
    setDateTo('');
  };

  const activeDateLabel = datePreset
    ? DATE_PRESETS.find(p => p.value === datePreset)?.label
    : dateFrom
      ? 'Custom range'
      : null;

  return (
    <div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faRoute} style={{ marginRight: 8, color: 'var(--gold)' }} />
            Trip Logs <span>({filtered.length})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: 'relative', flex: 1, minWidth: 0, maxWidth: 360 }}>
              <FontAwesomeIcon icon={faSearch} style={{
                position: 'absolute', left: 10, top: '50%',
                transform: 'translateY(-50%)', color: '#aaa', fontSize: 12, pointerEvents: 'none',
              }} />
              <input
                className="search-box"
                style={{ width: '100%', paddingLeft: 30 }}
                placeholder="Search code, passenger, driver, route..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>

            <div style={{ position: 'relative' }}>
              <button
                className={`btn btn-ghost btn-sm${activeDateLabel ? ' btn-active' : ''}`}
                onClick={() => setShowDatePicker(v => !v)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 6,
                  ...(activeDateLabel && {
                    background: 'var(--green)', color: '#fff',
                    borderColor: 'var(--green)',
                  }),
                }}
              >
                <FontAwesomeIcon icon={faCalendar} />
                {activeDateLabel || 'Date'}
              </button>

              {showDatePicker && (
                <div style={{
                  position: 'absolute', right: 0, top: 'calc(100% + 6px)', zIndex: 100,
                  background: '#fff', border: '1px solid var(--gray2)',
                  borderRadius: 10, boxShadow: '0 4px 24px rgba(0,0,0,0.10)',
                  padding: 16, minWidth: 240,
                }}>
                  <div style={{ fontSize: '.75rem', color: 'var(--gray)', marginBottom: 8, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '.5px' }}>
                    Quick Select
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 14 }}>
                    {DATE_PRESETS.map(p => (
                      <button
                        key={p.value}
                        onClick={() => applyPreset(p.value)}
                        style={{
                          textAlign: 'left', padding: '7px 12px', borderRadius: 7,
                          border: 'none', cursor: 'pointer', fontSize: '.82rem',
                          background: datePreset === p.value ? 'var(--green)' : 'var(--bg)',
                          color: datePreset === p.value ? '#fff' : 'var(--dark)',
                          fontWeight: datePreset === p.value ? 700 : 400,
                          transition: 'all 0.1s',
                        }}
                      >{p.label}</button>
                    ))}
                  </div>

                  <div style={{ fontSize: '.75rem', color: 'var(--gray)', marginBottom: 6, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '.5px' }}>
                    Custom Range
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <input
                      type="date"
                      value={dateFrom ? dateFrom.slice(0, 10) : ''}
                      onChange={e => { setDatePreset(''); setDateFrom(e.target.value ? new Date(e.target.value).toISOString() : ''); }}
                      style={{ padding: '6px 10px', borderRadius: 6, border: '1px solid var(--gray2)', fontSize: '.82rem', width: '100%' }}
                    />
                    <input
                      type="date"
                      value={dateTo ? dateTo.slice(0, 10) : ''}
                      onChange={e => { setDatePreset(''); setDateTo(e.target.value ? new Date(e.target.value + 'T23:59:59').toISOString() : ''); }}
                      style={{ padding: '6px 10px', borderRadius: 6, border: '1px solid var(--gray2)', fontSize: '.82rem', width: '100%' }}
                    />
                  </div>

                  {activeDateLabel && (
                    <button
                      onClick={() => { clearDateFilter(); setShowDatePicker(false); }}
                      style={{
                        marginTop: 10, width: '100%', padding: '7px', borderRadius: 7,
                        border: '1px solid var(--red)', background: 'transparent',
                        color: 'var(--red)', fontSize: '.8rem', cursor: 'pointer',
                        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                      }}
                    >
                      <FontAwesomeIcon icon={faTimes} /> Clear filter
                    </button>
                  )}
                </div>
              )}
            </div>

            <button className="btn btn-ghost btn-sm" onClick={load}>
              <FontAwesomeIcon icon={faRefresh} style={{ marginRight: 6 }} />Refresh
            </button>
          </div>
        </div>

        {/* ── FILTER STATUS ── */}
        <div style={{ padding: '10px 18px 0', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <FontAwesomeIcon icon={faFilter} style={{ color: 'var(--gray)', fontSize: 12 }} />
          <span style={{ fontSize: '.8rem', color: 'var(--gray)', marginRight: 4 }}>Filter:</span>
          <span style={{ fontSize: '.82rem', fontWeight: 600, color: 'var(--dark)' }}>
            {activeDateLabel ? `Filtered: ${activeDateLabel}` : 'All Records'}
          </span>
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: '.78rem', color: 'var(--gray)' }}>Show</span>
            {[10, 25, 50].map(n => (
              <button key={n} onClick={() => setPageSize(n)} style={{
                padding: '3px 10px', borderRadius: 6,
                border: pageSize === n ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
                background: pageSize === n ? 'var(--green)' : 'transparent',
                color: pageSize === n ? '#fff' : 'var(--gray)',
                fontSize: '.78rem', fontWeight: pageSize === n ? 700 : 400,
                cursor: 'pointer', transition: 'all 0.15s',
              }}>{n}</button>
            ))}
          </div>
        </div>

        {loading ? <Loading /> : data.length === 0 ? <Empty /> : (
          <>
            <div className="tbl-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Trip Code</th>
                    <th>Passenger</th>
                    <th>Driver</th>
                    <th>Route</th>
                    <th>Status</th>
                    <th>Duration</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.length === 0 ? (
                    <tr><td colSpan={9} style={{ textAlign: 'center', padding: '24px', color: 'var(--gray)' }}>
                      No trips match your criteria.
                    </td></tr>
                  ) : paginated.map(t => (
                    <tr key={t.id}>
                      <td><strong>{t.trip_code}</strong></td>
                      <td>{t.passenger_name}</td>
                      <td>{t.driver_name}</td>
                      <td style={{ fontSize: '.85rem', color: 'var(--gray)' }}>{t.route}</td>
                      <td><StatusBadge status={t.status} /></td>
                      <td style={{ fontSize: '.85rem' }}>{formatDuration(t.duration_min)}</td>
                      <td style={{ fontSize: '.85rem' }}>{formatDate(t.ended_at)}</td>
                      <td>
                        <button className="ib ib-view" onClick={() => setViewItem(t)} style={{ minWidth: 60 }}>
                          <FontAwesomeIcon icon={faEye} style={{ marginRight: 4, fontSize: 11 }} />View
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* ── PAGINATION ── */}
            {filtered.length > pageSize && (
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 18px', borderTop: '1px solid var(--gray2)' }}>
                <span style={{ fontSize: '.8rem', color: 'var(--gray)' }}>
                  Showing {Math.min((currentPage - 1) * pageSize + 1, filtered.length)}–{Math.min(currentPage * pageSize, filtered.length)} of {filtered.length} trips
                </span>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
                    style={{ background: 'none', border: '1px solid var(--gray2)', borderRadius: 6, padding: '4px 10px', cursor: currentPage === 1 ? 'not-allowed' : 'pointer', opacity: currentPage === 1 ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronLeft} style={{ fontSize: 11 }} />
                  </button>
                  {pageWindow.map((p, idx) =>
                    p === '…' ? (
                      <span key={`ellipsis-${idx}`} style={{ fontSize: '.8rem', color: 'var(--gray)', padding: '0 4px' }}>…</span>
                    ) : (
                      <button
                        key={p}
                        onClick={() => setCurrentPage(p)}
                        style={{
                          padding: '4px 10px', borderRadius: 6, fontSize: '.8rem',
                          fontWeight: p === currentPage ? 700 : 400,
                          border: p === currentPage ? '1.5px solid var(--green)' : '1px solid var(--gray2)',
                          background: p === currentPage ? 'var(--green)' : 'none',
                          color: p === currentPage ? '#fff' : 'var(--gray)',
                          cursor: 'pointer',
                        }}
                      >{p}</button>
                    )
                  )}
                  <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages}
                    style={{ background: 'none', border: '1px solid var(--gray2)', borderRadius: 6, padding: '4px 10px', cursor: currentPage === totalPages ? 'not-allowed' : 'pointer', opacity: currentPage === totalPages ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronRight} style={{ fontSize: 11 }} />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {viewItem && (
        <Modal title={`Trip: ${viewItem.trip_code}`} onClose={() => setViewItem(null)}>
          <DG rows={[
            ['Trip Code', viewItem.trip_code],
            ['Passenger', viewItem.passenger_name],
            ['Driver',    viewItem.driver_name],
            ['Contact',   viewItem.driver_contact],
            ['Route',     viewItem.route],
            ['Status',    viewItem.status],
            ['Duration',  formatDuration(viewItem.duration_min)],
            ['Date',      formatDate(viewItem.ended_at)]
          ]} />
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setViewItem(null)}>Close</button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export default Trips;