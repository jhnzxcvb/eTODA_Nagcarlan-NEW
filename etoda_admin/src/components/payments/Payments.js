// src/components/payments/Payments.js
import React, { useState, useEffect, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faCreditCard, faSearch, faFilter, faEye,
  faChevronLeft, faChevronRight, faMoneyBillWave,
  faMobileAlt, faRefresh,
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
  return d.toLocaleDateString('en-PH', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
};

function Payments({ notify }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [viewItem, setViewItem] = useState(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/payments');
    if (r.success) setData(r.data || []);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);
  useEffect(() => { setCurrentPage(1); }, [statusFilter, pageSize, search]);

  const filtered = useMemo(() => {
    let rows = data;
    if (statusFilter !== 'All') rows = rows.filter(p => p.status === statusFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      rows = rows.filter(p =>
        (p.ref_code        || '').toLowerCase().includes(q) ||
        (p.passenger_name  || '').toLowerCase().includes(q) ||
        (p.driver_name     || '').toLowerCase().includes(q) ||
        (p.contact_number  || '').toLowerCase().includes(q)
      );
    }
    return rows;
  }, [data, statusFilter, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const pageWindow = buildPageWindow(currentPage, totalPages);

  const SB = { Pending: 'badge-pending', Settled: 'badge-settled', Refunded: 'badge-refunded' };

  const MethodIcon = ({ method }) => {
    let icon = faMoneyBillWave, color = 'var(--green)';
    if (method === 'Card')       { icon = faCreditCard; color = '#3b82f6'; }
    if (method === 'GCash')      { icon = faMobileAlt;  color = '#007bff'; }
    if (method === 'Maya')       { icon = faMobileAlt;  color = '#4ade80'; }
    if (method === 'Konek2CARD') { icon = faMobileAlt;  color = '#ff6600'; }
    return <FontAwesomeIcon icon={icon} style={{ color, marginRight: 6 }} />;
  };

  return (
    <div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faCreditCard} style={{ marginRight: 8, color: 'var(--gold)' }} />
            Transactions <span>({filtered.length})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: 'relative' }}>
              <FontAwesomeIcon icon={faSearch} style={{
                position: 'absolute', left: 10, top: '50%',
                transform: 'translateY(-50%)', color: '#aaa', fontSize: 12, pointerEvents: 'none',
              }} />
              <input
                className="search-box"
                style={{ width: 230, paddingLeft: 30 }}
                placeholder="Search ref, passenger, driver, contact..."
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
          {['All', 'Pending', 'Settled', 'Refunded'].map(s => (
            <button key={s} onClick={() => setStatusFilter(s)} style={{
              padding: '4px 12px', borderRadius: 20,
              border: statusFilter === s ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
              background: statusFilter === s ? 'var(--green)' : 'transparent',
              color: statusFilter === s ? '#fff' : 'var(--gray)',
              fontSize: '.78rem', fontWeight: statusFilter === s ? 700 : 400,
              cursor: 'pointer', transition: 'all 0.15s',
            }}>
              {s === 'All'
                ? `All (${data.length})`
                : `${s} (${data.filter(p => p.status === s).length})`}
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
                    <th>Ref Code</th>
                    <th>Passenger</th>
                    <th>Driver</th>
                    <th>Route</th>
                    <th>Amount</th>
                    <th>Method</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.length === 0 ? (
                    <tr>
                      <td colSpan={9} style={{ textAlign: 'center', padding: '24px', color: 'var(--gray)' }}>
                        No payments match your criteria.
                      </td>
                    </tr>
                  ) : paginated.map(p => (
                    <tr key={p.id}>
                      <td><strong>{p.ref_code}</strong></td>
                      <td>{p.passenger_name}</td>
                      <td>{p.driver_name}</td>
                      <td style={{ fontSize: '.85rem', color: 'var(--gray)' }}>{p.route}</td>
                      <td><strong>₱{Number(p.amount).toFixed(2)}</strong></td>
                      <td style={{ fontSize: '.85rem' }}>
                        <MethodIcon method={p.method} />{p.method}
                      </td>
                      <td>
                        <span className={`badge ${SB[p.status] || 'badge-pending'}`}>
                          {p.status}
                        </span>
                      </td>
                      <td style={{ fontSize: '.85rem' }}>{formatDate(p.paid_at)}</td>
                      <td>
                        <div className="row-actions">
                          <button className="ib ib-view" onClick={() => setViewItem(p)} style={{ minWidth: 60 }}>
                            <FontAwesomeIcon icon={faEye} style={{ marginRight: 4, fontSize: 11 }} />
                            View
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* ── PAGINATION ── */}
            {filtered.length > pageSize && (
              <div style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '12px 18px', borderTop: '1px solid var(--gray2)',
              }}>
                <span style={{ fontSize: '.8rem', color: 'var(--gray)' }}>
                  Showing {Math.min((currentPage - 1) * pageSize + 1, filtered.length)}–
                  {Math.min(currentPage * pageSize, filtered.length)} of {filtered.length} transactions
                </span>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <button
                    onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                    disabled={currentPage === 1}
                    style={{
                      background: 'none', border: '1px solid var(--gray2)', borderRadius: 6,
                      padding: '4px 10px',
                      cursor: currentPage === 1 ? 'not-allowed' : 'pointer',
                      opacity: currentPage === 1 ? 0.4 : 1,
                    }}>
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
                  <button
                    onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                    disabled={currentPage === totalPages}
                    style={{
                      background: 'none', border: '1px solid var(--gray2)', borderRadius: 6,
                      padding: '4px 10px',
                      cursor: currentPage === totalPages ? 'not-allowed' : 'pointer',
                      opacity: currentPage === totalPages ? 0.4 : 1,
                    }}>
                    <FontAwesomeIcon icon={faChevronRight} style={{ fontSize: 11 }} />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* ── VIEW MODAL ── */}
      {viewItem && (
        <Modal title={`Transaction: ${viewItem.ref_code}`} onClose={() => setViewItem(null)}>
          <DG rows={[
            ['Ref Code',       viewItem.ref_code],
            ['Passenger',      viewItem.passenger_name],
            ['Driver',         viewItem.driver_name],
            ['Contact No.',    viewItem.contact_number  || '—'],
            ['Route',          viewItem.route           || '—'],
            ['Amount',         `₱${Number(viewItem.amount).toFixed(2)}`],
            ['Method',         viewItem.method],
            ...(viewItem.ewallet_account
              ? [['E-Wallet Acct', viewItem.ewallet_account]]
              : []),
            ['Passenger Type', viewItem.passenger_type  || '—'],
            ['Trip Type',      viewItem.trip_type       || '—'],
            ['Status',         viewItem.status],
            ['Date',           formatDate(viewItem.paid_at)],
          ]} />
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setViewItem(null)}>Close</button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export default Payments;