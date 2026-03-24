// src/components/audit/Audit.js
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faClipboardList, faSearch, faFilter, faEye,
  faChevronLeft, faChevronRight, faRefresh,
  faPlus, faPen, faTrash, faBan, faRotateLeft, faCheck,
  faFileLines
} from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

const formatDate = (str) => {
  if (!str) return '—';
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString('en-PH', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
};

function Audit({ notify }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [entityFilter, setEntityFilter] = useState('All');
  const [viewItem, setViewItem] = useState(null);

  // ── Pagination ──
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);

  const load = useCallback(async () => {
    setLoading(true);
    const r = await api('/api/audit'); // Fetch all for client-side filtering/stats
    if (r.success) setData(r.data || []);
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setCurrentPage(1); }, [entityFilter, pageSize, search]);

  const filtered = useMemo(() => {
    let rows = data;
    if (entityFilter !== 'All') {
      rows = rows.filter(a => a.entity === entityFilter);
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      rows = rows.filter(a =>
        a.detail?.toLowerCase().includes(q) ||
        a.entity_id?.toLowerCase().includes(q) ||
        a.performed_by?.toLowerCase().includes(q)
      );
    }
    return rows;
  }, [data, entityFilter, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  const AB = { ENROLL: 'badge-enroll', UPDATE: 'badge-update', DELETE: 'badge-delete', CREATE: 'badge-create', REVOKE: 'badge-revoke', RESTORE: 'badge-restore' };
  
  const ActionIcon = ({ action }) => {
    let icon = faFileLines;
    if (action === 'ENROLL' || action === 'CREATE') icon = faPlus;
    if (action === 'UPDATE')  icon = faPen;
    if (action === 'DELETE')  icon = faTrash;
    if (action === 'REVOKE')  icon = faBan;
    if (action === 'RESTORE') icon = faRotateLeft;
    return <FontAwesomeIcon icon={icon} style={{ marginRight: 6, fontSize: 11 }} />;
  };

  const ENT = ['All', 'Driver', 'Passenger', 'Fare', 'Payment', 'QRCode', 'Complaint'];

  return (
    <div>
      {/* ── Summary Cards ── */}
      <div className="status-row">
        {[
          [data.filter(a => a.action === 'ENROLL').length, 'Enrollments', 'var(--green)'],
          [data.filter(a => a.action === 'UPDATE').length, 'Updates',     'var(--blue)'],
          [data.filter(a => a.action === 'DELETE').length, 'Deletions',   'var(--red)'],
          [data.filter(a => a.action === 'REVOKE').length, 'Revocations', 'var(--ora)'],
          [data.length,                                    'Total Logs',  'var(--dark)'],
        ].map(([v, l, c]) => (
          <div key={l} className="status-card">
            <div className="status-val" style={{ color: c }}>{v}</div>
            <div className="status-lbl">{l}</div>
          </div>
        ))}
      </div>

      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faClipboardList} style={{ marginRight: 8, color: 'var(--gold)' }} />
            Audit Logs <span>({filtered.length})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: 'relative' }}>
              <FontAwesomeIcon icon={faSearch} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: '#aaa', fontSize: 12, pointerEvents: 'none' }} />
              <input
                className="search-box"
                style={{ width: 230, paddingLeft: 30 }}
                placeholder="Search detail, entity ID..."
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
          {ENT.map(e => (
            <button key={e} onClick={() => setEntityFilter(e)} style={{
              padding: '4px 12px', borderRadius: 20,
              border: entityFilter === e ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
              background: entityFilter === e ? 'var(--green)' : 'transparent',
              color: entityFilter === e ? '#fff' : 'var(--gray)',
              fontSize: '.78rem', fontWeight: entityFilter === e ? 700 : 400,
              cursor: 'pointer', transition: 'all 0.15s',
            }}>
              {e === 'All' ? `All (${data.length})` : `${e} (${data.filter(a => a.entity === e).length})`}
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

        {loading ? <Loading /> : data.length === 0 ? <Empty msg="No audit logs found" /> : (
          <>
            <div className="tbl-wrap">
              <table>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Action</th>
                    <th>Entity</th>
                    <th>Entity ID</th>
                    <th>Detail</th>
                    <th>By</th>
                    <th>Timestamp</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.length === 0 ? (
                    <tr><td colSpan={8} style={{ textAlign: 'center', padding: '24px', color: 'var(--gray)' }}>
                      No logs match your filters.
                    </td></tr>
                  ) : paginated.map(a => (
                    <tr key={a.id}>
                      <td style={{ color: 'var(--gray)', fontSize: '.75rem' }}>{a.id}</td>
                      <td><span className={`badge ${AB[a.action] || 'badge-inactive'}`}><ActionIcon action={a.action} />{a.action}</span></td>
                      <td>{a.entity}</td>
                      <td><code style={{ fontSize: '.78rem', background: 'var(--bg)', padding: '2px 6px', borderRadius: 4 }}>{a.entity_id}</code></td>
                      <td style={{ maxWidth: 240, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{a.detail}</td>
                      <td><span className="badge badge-active">{a.performed_by}</span></td>
                      <td style={{ fontSize: '.78rem', color: 'var(--gray)', whiteSpace: 'nowrap' }}>{formatDate(a.created_at)}</td>
                      <td>
                        <button className="ib ib-view" onClick={() => setViewItem(a)} style={{ minWidth: 60 }}>
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
                  Showing {Math.min((currentPage - 1) * pageSize + 1, filtered.length)}–{Math.min(currentPage * pageSize, filtered.length)} of {filtered.length} entries
                </span>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
                    style={{ background: 'none', border: '1px solid var(--gray2)', borderRadius: 6, padding: '4px 10px', cursor: currentPage === 1 ? 'not-allowed' : 'pointer', opacity: currentPage === 1 ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronLeft} style={{ fontSize: 11 }} />
                  </button>
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                    <button key={p} onClick={() => setCurrentPage(p)} style={{
                      padding: '4px 10px', borderRadius: 6, fontSize: '.8rem',
                      fontWeight: p === currentPage ? 700 : 400,
                      border: p === currentPage ? '1.5px solid var(--green)' : '1px solid var(--gray2)',
                      background: p === currentPage ? 'var(--green)' : 'none',
                      color: p === currentPage ? '#fff' : 'var(--gray)', cursor: 'pointer',
                    }}>{p}</button>
                  ))}
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
        <Modal title={`Audit Log #${viewItem.id}`} onClose={() => setViewItem(null)}>
          <div style={{ background: 'var(--bg)', borderRadius: 9, padding: 16, marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
              <span style={{ fontSize: '1.2rem', color: 'var(--dark)' }}><ActionIcon action={viewItem.action} /></span>
              <div>
                <div style={{ fontFamily: 'Roboto', fontWeight: 700, fontSize: '1rem' }}>{viewItem.action}</div>
                <div style={{ fontSize: '.75rem', color: 'var(--gray)' }}>{formatDate(viewItem.created_at)}</div>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {[
                ['Log ID', `#${viewItem.id}`],
                ['Action', viewItem.action],
                ['Entity', viewItem.entity],
                ['Entity ID', viewItem.entity_id],
                ['Performed By', viewItem.performed_by],
                ['Timestamp', formatDate(viewItem.created_at)]
              ].map(([k, v]) => (
                <div key={k}>
                  <div style={{ fontSize: '.64rem', color: 'var(--gray)', textTransform: 'uppercase', letterSpacing: '.5px', marginBottom: 2 }}>{k}</div>
                  <div style={{ fontWeight: 600, fontSize: '.85rem' }}>{v || '—'}</div>
                </div>
              ))}
            </div>
          </div>
          <div className="field">
            <label>Detail / Description</label>
            <div style={{ background: '#fff', border: '1.5px solid var(--gray2)', borderRadius: 7, padding: '10px 13px', fontSize: '.85rem', minHeight: 60 }}>
              {viewItem.detail || '—'}
            </div>
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setViewItem(null)}>Close</button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export default Audit;