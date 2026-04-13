// src/components/trips/Trips.js
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faRoute, faSearch, faFilter, faEye,
  faChevronLeft, faChevronRight, faRefresh,
  faMoneyBillWave, faCreditCard, faMobileAlt
} from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';
import { buildPageWindow } from '../../lib/pagination';

const formatDate = (str) => {
  if (!str) return '—';
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString('en-PH', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
};

function Trips({ notify }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [viewItem, setViewItem] = useState(null);

  // ── Filters & Pagination ──
  const [methodFilter, setMethodFilter] = useState('All');
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);

  const load = useCallback(async () => {
    setLoading(true);
    const r = await api('/api/trips');
    if (r.success) setData(r.data || []);
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setCurrentPage(1); }, [methodFilter, pageSize, search]);

  const filtered = useMemo(() => {
    let rows = data;
    if (methodFilter !== 'All') {
      rows = rows.filter(t => t.payment_method === methodFilter);
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
  }, [data, methodFilter, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const pageWindow = buildPageWindow(currentPage, totalPages);

  const MethodIcon = ({ method }) => {
    let icon = faMoneyBillWave;
    let color = 'var(--green)';
    if (method === 'Card')  { icon = faCreditCard; color = '#3b82f6'; }
    if (method === 'GCash') { icon = faMobileAlt;  color = '#007bff'; }
    if (method === 'Maya')  { icon = faMobileAlt;  color = '#4ade80'; }
    return <FontAwesomeIcon icon={icon} style={{ color, marginRight: 6 }} />;
  };

  return (
    <div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faRoute} style={{ marginRight: 8, color: 'var(--gold)' }} />
            Trip Logs <span>({filtered.length})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: 'relative' }}>
              <FontAwesomeIcon icon={faSearch} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: '#aaa', fontSize: 12, pointerEvents: 'none' }} />
              <input
                className="search-box"
                style={{ width: 230, paddingLeft: 30 }}
                placeholder="Search trip, passenger, driver..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
            <button className="btn btn-ghost btn-sm" onClick={load}>
              <FontAwesomeIcon icon={faRefresh} style={{ marginRight: 6 }} />Refresh
            </button>
          </div>
        </div>

        {/* ── FILTERS ── */}
        <div style={{ padding: '10px 18px 0', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <FontAwesomeIcon icon={faFilter} style={{ color: 'var(--gray)', fontSize: 12 }} />
          <span style={{ fontSize: '.8rem', color: 'var(--gray)', marginRight: 4 }}>Filter:</span>
          {['All', 'Cash', 'GCash', 'Maya', 'Card'].map(m => (
            <button key={m} onClick={() => setMethodFilter(m)} style={{
              padding: '4px 12px', borderRadius: 20,
              border: methodFilter === m ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
              background: methodFilter === m ? 'var(--green)' : 'transparent',
              color: methodFilter === m ? '#fff' : 'var(--gray)',
              fontSize: '.78rem', fontWeight: methodFilter === m ? 700 : 400,
              cursor: 'pointer', transition: 'all 0.15s',
            }}>
              {m === 'All' ? `All (${data.length})` : `${m} (${data.filter(t => t.payment_method === m).length})`}
            </button>
          ))}
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
                    <th>Fare</th>
                    <th>Method</th>
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
                      <td><strong>₱{Number(t.fare_amount).toFixed(2)}</strong></td>
                      <td style={{ fontSize: '.85rem' }}><MethodIcon method={t.payment_method} />{t.payment_method}</td>
                      <td style={{ fontSize: '.85rem' }}>{t.duration_min} min</td>
                      <td style={{ fontSize: '.85rem' }}>{formatDate(t.started_at)}</td>
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
            ['Fare',      `₱${Number(viewItem.fare_amount).toFixed(2)}`],
            ['Method',    viewItem.payment_method],
            ['Duration',  `${viewItem.duration_min} min`],
            ['Date',      formatDate(viewItem.started_at)]
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