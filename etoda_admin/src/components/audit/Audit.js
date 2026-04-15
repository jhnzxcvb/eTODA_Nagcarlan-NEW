// src/components/audit/Audit.js
import React, { useState, useEffect, useCallback, useRef } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faClipboardList, faSearch, faFilter, faEye,
  faChevronLeft, faChevronRight, faRefresh,
  faPlus, faPen, faTrash, faBan, faRotateLeft,
  faFileLines, faArrowDown, faCalendar, faTimes,
  faUser, faRobot, faUserShield,
} from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

// ─────────────────────────────────────────────
// Static constants
// ─────────────────────────────────────────────

const ACTION_BADGE = {
  ENROLL:  'badge-enroll',
  CREATE:  'badge-create',
  INSERT:  'badge-insert',
  UPDATE:  'badge-update',
  DELETE:  'badge-delete',
  REVOKE:  'badge-revoke',
  RESTORE: 'badge-restore',
};

const ENTITY_LIST = ['All', 'Driver', 'Passenger', 'Fare', 'Payment', 'QRCode', 'Complaint', 'Trip'];

const PAGE_SIZES = [10, 25, 50];

const ACTION_ICON_MAP = {
  ENROLL:  faPlus,
  CREATE:  faPlus,
  INSERT:  faArrowDown,
  UPDATE:  faPen,
  DELETE:  faTrash,
  REVOKE:  faBan,
  RESTORE: faRotateLeft,
};

const DATE_PRESETS = [
  { label: 'Today',      value: 'today' },
  { label: 'Yesterday',  value: 'yesterday' },
  { label: 'This week',  value: 'week' },
  { label: 'This month', value: 'month' },
];

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

const formatDate = (str) => {
  if (!str) return '—';
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString('en-PH', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
};

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

const resolveActor = (log) => {
  let name = log.performed_by || '—';
  
  // Strip out Go's <nil> formatting artifacts if they leaked into the database
  name = name.replace(':<nil>', '').replace(':nil', '').trim();

  if (name === '—' || name === 'Admin' || name === 'User' || name === 'System') {
    return log.actor_type || name;
  }
  return name;
};

const ActorBadge = ({ log }) => {
  const actor = resolveActor(log);

  if (actor === 'System') {
    return (
      <span style={{
        display: 'inline-flex', alignItems: 'center', gap: 5,
        background: 'var(--gray2)', color: 'var(--gray)',
        borderRadius: 20, padding: '3px 10px', fontSize: '.74rem', fontWeight: 600,
      }}>
        <FontAwesomeIcon icon={faRobot} style={{ fontSize: 10 }} />
        System
      </span>
    );
  }

  if (actor === 'Admin' || log.actor_type === 'Admin') {
    return (
      <span style={{
        display: 'inline-flex', alignItems: 'center', gap: 5,
        background: 'rgba(234,179,8,0.12)', color: '#b45309',
        borderRadius: 20, padding: '3px 10px', fontSize: '.74rem', fontWeight: 600,
      }}>
        <FontAwesomeIcon icon={faUserShield} style={{ fontSize: 10 }} />
        {actor}
      </span>
    );
  }

  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      background: 'rgba(34,197,94,0.12)', color: '#15803d',
      borderRadius: 20, padding: '3px 10px', fontSize: '.74rem', fontWeight: 600,
    }}>
      <FontAwesomeIcon icon={faUser} style={{ fontSize: 10 }} />
      {actor}
    </span>
  );
};

const ActionIcon = ({ action }) => (
  <FontAwesomeIcon
    icon={ACTION_ICON_MAP[action] || faFileLines}
    style={{ marginRight: 6, fontSize: 11 }}
  />
);

const entityPath = (entity) => {
  const map = {
    Driver:    'drivers',
    Passenger: 'passengers',
    Fare:      'fare',
    Payment:   'payments',
    QRCode:    'qrcodes',
    Complaint: 'complaints',
    Trip:      'trips',
  };
  return map[entity] || null;
};

const buildPageWindow = (current, total) => {
  if (total <= 5) return Array.from({ length: total }, (_, i) => i + 1);
  const pages = [];
  const start = Math.max(2, current - 1);
  const end   = Math.min(total - 1, current + 1);
  pages.push(1);
  if (start > 2) pages.push('…');
  for (let i = start; i <= end; i++) pages.push(i);
  if (end < total - 1) pages.push('…');
  pages.push(total);
  return pages;
};

// ─────────────────────────────────────────────
// Component
// ─────────────────────────────────────────────

function Audit({ notify, navigate }) {
  const [data,         setData]         = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [search,       setSearch]       = useState('');
  const [entityFilter, setEntityFilter] = useState('All');
  const [viewItem,     setViewItem]     = useState(null);
  const [pageSize,     setPageSize]     = useState(10);
  const [currentPage,  setCurrentPage]  = useState(1);
  const [total,        setTotal]        = useState(0);

  const [stats, setStats] = useState({
    ENROLL: 0, UPDATE: 0, DELETE: 0, REVOKE: 0,
    total: 0, today: 0, lastActivity: null,
    byEntity: {},
  });

  const [datePreset, setDatePreset] = useState('');
  const [dateFrom,   setDateFrom]   = useState('');
  const [dateTo,     setDateTo]     = useState('');
  const [showDatePicker, setShowDatePicker] = useState(false);

  // Track whether the current load was triggered by a page change
  // so we know NOT to scroll to top in that case
  const isPaginating = useRef(false);

  const loadStats = useCallback(async () => {
    const r = await api('/api/audit/stats');
    if (r.success) setStats(r.data);
  }, []);

  const load = useCallback(async () => {
    // Capture scroll position before any state updates
    const savedScrollY = window.scrollY;
    const wasPaginating = isPaginating.current;

    setLoading(true);
    const params = new URLSearchParams({
      page:     currentPage,
      pageSize,
      ...(entityFilter !== 'All' && { entity: entityFilter }),
      ...(search.trim()           && { search: search.trim() }),
      ...(dateFrom                && { dateFrom }),
      ...(dateTo                  && { dateTo }),
    });

    try {
      const r = await api(`/api/audit?${params}`);
      if (r.success) {
        setData(r.data   || []);
        setTotal(r.total ?? 0);
      } else {
        notify?.('error', r.message || 'Failed to load audit logs.');
        setData([]);
        setTotal(0);
      }
    } catch {
      notify?.('error', 'Network error while loading audit logs.');
      setData([]);
      setTotal(0);
    } finally {
      setLoading(false);
      isPaginating.current = false;

      // Restore scroll position only when paginating
      // Double requestAnimationFrame ensures the DOM has updated and layout is stable
      if (wasPaginating) {
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            window.scrollTo({ top: savedScrollY, behavior: 'instant' });
          });
        });
      }
    }
  }, [currentPage, pageSize, entityFilter, search, dateFrom, dateTo, notify]);

  useEffect(() => { setCurrentPage(1); }, [entityFilter, pageSize, search, dateFrom, dateTo]);
  useEffect(() => { load(); },       [load]);
  useEffect(() => { loadStats(); },  [loadStats]);

  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const pageWindow = buildPageWindow(currentPage, totalPages);

  const summaryCards = [
    [stats.ENROLL ?? 0, 'Enrollments',  'var(--green)'],
    [stats.UPDATE ?? 0, 'Updates',      'var(--blue)'],
    [stats.DELETE ?? 0, 'Deletions',    'var(--red)'],
    [stats.REVOKE ?? 0, 'Revocations',  'var(--ora)'],
    [stats.today  ?? 0, 'Today\'s Logs','var(--dark)'],
  ];

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

  // Mark as paginating before changing page so scroll is preserved
  const goToPage = (page) => {
    isPaginating.current = true;
    setCurrentPage(page);
  };

  const activeDateLabel = datePreset
    ? DATE_PRESETS.find(p => p.value === datePreset)?.label
    : dateFrom
      ? 'Custom range'
      : null;

  return (
    <div>
      {/* ── Summary Cards ── */}
      <div className="status-row">
        {summaryCards.map(([v, l, c]) => (
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
            Audit Logs <span>({total})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: 'relative', flex: 1, minWidth: 0, maxWidth: 360 }}>
              <FontAwesomeIcon
                icon={faSearch}
                style={{
                  position: 'absolute', left: 10, top: '50%',
                  transform: 'translateY(-50%)', color: '#aaa',
                  fontSize: 12, pointerEvents: 'none',
                }}
              />
              <input
                className="search-box"
                style={{ width: '100%', paddingLeft: 30 }}
                placeholder="Search detail, entity ID, performed by..."
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

            <button
              className="btn btn-ghost btn-sm"
              onClick={() => { load(); loadStats(); notify?.('info', 'Audit logs refreshed.'); }}
            >
              <FontAwesomeIcon icon={faRefresh} style={{ marginRight: 6 }} />Refresh
            </button>
          </div>
        </div>

        {/* ── Filters ── */}
        <div style={{ padding: '10px 18px 0', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <FontAwesomeIcon icon={faFilter} style={{ color: 'var(--gray)', fontSize: 12 }} />
          <span style={{ fontSize: '.8rem', color: 'var(--gray)', marginRight: 4 }}>Filter:</span>
          {ENTITY_LIST.map(e => {
            const count = e === 'All' ? stats.total : (stats.byEntity?.[e] ?? '');
            return (
              <button
                key={e}
                onClick={() => setEntityFilter(e)}
                style={{
                  padding: '4px 12px', borderRadius: 20,
                  border: entityFilter === e ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
                  background: entityFilter === e ? 'var(--green)' : 'transparent',
                  color: entityFilter === e ? '#fff' : 'var(--gray)',
                  fontSize: '.78rem', fontWeight: entityFilter === e ? 700 : 400,
                  cursor: 'pointer', transition: 'all 0.15s',
                }}
              >
                {e === 'All' ? `All (${stats.total ?? 0})` : `${e}${count !== '' ? ` (${count})` : ''}`}
              </button>
            );
          })}
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: '.78rem', color: 'var(--gray)' }}>Show</span>
            {PAGE_SIZES.map(n => (
              <button
                key={n}
                onClick={() => { isPaginating.current = true; setPageSize(n); }}
                style={{
                  padding: '3px 10px', borderRadius: 6,
                  border: pageSize === n ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
                  background: pageSize === n ? 'var(--green)' : 'transparent',
                  color: pageSize === n ? '#fff' : 'var(--gray)',
                  fontSize: '.78rem', fontWeight: pageSize === n ? 700 : 400,
                  cursor: 'pointer', transition: 'all 0.15s',
                }}
              >{n}</button>
            ))}
          </div>
        </div>

        <div style={{ minHeight: '500px' }}>
        {loading ? <Loading /> : data.length === 0 && total === 0 ? <Empty msg="No audit logs found" /> : (
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
                  {data.length === 0 ? (
                    <tr>
                      <td colSpan={8} style={{ textAlign: 'center', padding: '24px', color: 'var(--gray)' }}>
                        No logs match your filters.
                      </td>
                    </tr>
                  ) : data.map(a => (
                    <tr key={a.id}>
                      <td style={{ color: 'var(--gray)', fontSize: '.75rem' }}>{a.id}</td>
                      <td>
                        <span className={`badge ${ACTION_BADGE[a.action] || 'badge-inactive'}`}>
                          <ActionIcon action={a.action} />{a.action}
                        </span>
                      </td>
                      <td>{a.entity}</td>
                      <td>
                        {entityPath(a.entity) ? (
                          <a
                            href={`#${entityPath(a.entity)}`}
                            onClick={e => {
                              if (navigate) {
                                e.preventDefault();
                                navigate(entityPath(a.entity), a.entity_id);
                              }
                            }}
                            style={{
                              fontSize: '.78rem',
                              background: 'var(--bg)',
                              padding: '2px 6px',
                              borderRadius: 4,
                              fontFamily: 'monospace',
                              color: 'var(--blue)',
                              textDecoration: 'underline',
                              textDecorationStyle: 'dotted',
                              cursor: 'pointer',
                            }}
                          >
                            {a.entity_id}
                          </a>
                        ) : (
                          <code style={{ fontSize: '.78rem', background: 'var(--bg)', padding: '2px 6px', borderRadius: 4 }}>
                            {a.entity_id}
                          </code>
                        )}
                      </td>
                      <td
                        title={a.detail}
                        style={{ maxWidth: 240, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', cursor: 'default' }}
                      >
                        {a.detail}
                      </td>
                      <td><ActorBadge log={a} /></td>
                      <td style={{ fontSize: '.78rem', color: 'var(--gray)', whiteSpace: 'nowrap' }}>
                        {formatDate(a.created_at)}
                      </td>
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

            {totalPages > 1 && (
              <div style={{
                display: 'flex', alignItems: 'center',
                justifyContent: 'space-between',
                padding: '12px 18px', borderTop: '1px solid var(--gray2)',
              }}>
                <span style={{ fontSize: '.8rem', color: 'var(--gray)' }}>
                  Showing {Math.min((currentPage - 1) * pageSize + 1, total)}–{Math.min(currentPage * pageSize, total)} of {total} entries
                </span>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <button
                    onClick={() => goToPage(Math.max(1, currentPage - 1))}
                    disabled={currentPage === 1}
                    style={{
                      background: 'none', border: '1px solid var(--gray2)',
                      borderRadius: 6, padding: '4px 10px',
                      cursor: currentPage === 1 ? 'not-allowed' : 'pointer',
                      opacity: currentPage === 1 ? 0.4 : 1,
                    }}
                  >
                    <FontAwesomeIcon icon={faChevronLeft} style={{ fontSize: 11 }} />
                  </button>

                  {pageWindow.map((p, idx) =>
                    p === '…' ? (
                      <span key={`ellipsis-${idx}`} style={{ fontSize: '.8rem', color: 'var(--gray)', padding: '0 4px' }}>…</span>
                    ) : (
                      <button
                        key={p}
                        onClick={() => goToPage(p)}
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
                    onClick={() => goToPage(Math.min(totalPages, currentPage + 1))}
                    disabled={currentPage === totalPages}
                    style={{
                      background: 'none', border: '1px solid var(--gray2)',
                      borderRadius: 6, padding: '4px 10px',
                      cursor: currentPage === totalPages ? 'not-allowed' : 'pointer',
                      opacity: currentPage === totalPages ? 0.4 : 1,
                    }}
                  >
                    <FontAwesomeIcon icon={faChevronRight} style={{ fontSize: 11 }} />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
        </div>
      </div>

      {/* ── View Modal ── */}
      {viewItem && (
        <Modal title={`Audit Log #${viewItem.id}`} onClose={() => setViewItem(null)}>
          <div style={{ background: 'var(--bg)', borderRadius: 9, padding: 16, marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
              <span style={{ fontSize: '1.2rem', color: 'var(--dark)' }}>
                <ActionIcon action={viewItem.action} />
              </span>
              <div>
                <div style={{ fontFamily: 'Roboto', fontWeight: 700, fontSize: '1rem' }}>{viewItem.action}</div>
                <div style={{ fontSize: '.75rem', color: 'var(--gray)' }}>{formatDate(viewItem.created_at)}</div>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {[
                ['Log ID',    `#${viewItem.id}`],
                ['Action',    viewItem.action],
                ['Entity',    viewItem.entity],
                ['Entity ID', viewItem.entity_id],
                ['Timestamp', formatDate(viewItem.created_at)],
              ].map(([k, v]) => (
                <div key={k}>
                  <div style={{ fontSize: '.64rem', color: 'var(--gray)', textTransform: 'uppercase', letterSpacing: '.5px', marginBottom: 2 }}>{k}</div>
                  <div style={{ fontWeight: 600, fontSize: '.85rem' }}>{v || '—'}</div>
                </div>
              ))}
              <div>
                <div style={{ fontSize: '.64rem', color: 'var(--gray)', textTransform: 'uppercase', letterSpacing: '.5px', marginBottom: 4 }}>Performed By</div>
                <ActorBadge log={viewItem} />
              </div>
            </div>
          </div>

          {entityPath(viewItem.entity) && (
            <div style={{ marginBottom: 14 }}>
              <a
                href={`#${entityPath(viewItem.entity)}`}
                onClick={e => {
                  if (navigate) {
                    e.preventDefault();
                    navigate(entityPath(viewItem.entity), viewItem.entity_id);
                    setViewItem(null);
                  }
                }}
                style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  padding: '7px 14px', borderRadius: 7,
                  background: 'rgba(59,130,246,0.08)', color: 'var(--blue)',
                  border: '1px solid rgba(59,130,246,0.2)',
                  fontSize: '.82rem', fontWeight: 600, textDecoration: 'none',
                  cursor: 'pointer',
                }}
              >
                <FontAwesomeIcon icon={faEye} style={{ fontSize: 11 }} />
                View {viewItem.entity} record →
              </a>
            </div>
          )}

          <div className="field">
            <label>Detail / Description</label>
            <div style={{
              background: '#fff', border: '1.5px solid var(--gray2)',
              borderRadius: 7, padding: '10px 13px',
              fontSize: '.85rem', minHeight: 60,
              whiteSpace: 'pre-wrap', wordBreak: 'break-word',
            }}>
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