// src/components/passengers/Passengers.js
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faSearch, faFilter, faUsers, faBan, faCircleCheck,
  faChevronLeft, faChevronRight, faPencil, faTrash,
} from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import MaskedUsername from '../ui/MaskedUsername';

const formatDate = (str) => {
  if (!str) return '—';
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString('en-PH', { year: 'numeric', month: 'short', day: 'numeric' });
};

const capitalizeName = (name = '') => name.replace(/\b\w/g, c => c.toUpperCase());

function Passengers({ notify }) {
  const [data,         setData]         = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [search,       setSearch]       = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [suspendItem,  setSuspendItem]  = useState(null);
  const [deleteItem,   setDeleteItem]   = useState(null);
  const [editItem,     setEditItem]     = useState(null);
  const [toggling,     setToggling]     = useState(null);
  const [saving,       setSaving]       = useState(false);
  const [editForm,     setEditForm]     = useState({ name: '', email: '', contact: '' });
  const [pageSize,     setPageSize]     = useState(10);
  const [currentPage,  setCurrentPage]  = useState(1);

  const load = useCallback(async (q = '') => {
    setLoading(true);
    const r = await api(`/api/passengers${q ? `?search=${encodeURIComponent(q)}` : ''}`);
    if (r.success) setData(r.data || []);
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    const t = setTimeout(() => { load(search); setCurrentPage(1); }, 300);
    return () => clearTimeout(t);
  }, [search, load]);
  useEffect(() => { setCurrentPage(1); }, [statusFilter, pageSize]);

  const filtered = useMemo(() => {
    if (statusFilter === 'All') return data;
    return data.filter(p => p.status === statusFilter);
  }, [data, statusFilter]);

  const totalPages     = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated      = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const activeCount    = data.filter(p => p.status === 'Active').length;
  const suspendedCount = data.filter(p => p.status === 'Suspended').length;

  const newThisMonth = useMemo(() => {
    const now = new Date();
    return data.filter(p => {
      if (!p.registered_at) return false;
      const d = new Date(p.registered_at);
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
    }).length;
  }, [data]);

  const confirmSuspend = async () => {
    const p = suspendItem;
    setToggling(p.id);
    const next = p.status === 'Suspended' ? 'Active' : 'Suspended';
    const r = await api(`/api/passengers/${p.id}`, 'PATCH', { status: next });
    setToggling(null);
    setSuspendItem(null);
    if (r.success) {
      load(search);
      notify(`${p.name || 'Passenger'} ${next === 'Suspended' ? 'suspended' : 'restored'}`, next === 'Suspended' ? 'warn' : 'success');
    }
  };

  const confirmDelete = async () => {
    const r = await api(`/api/passengers/${deleteItem.id}`, 'DELETE');
    setDeleteItem(null);
    if (r.success) { load(search); notify(`${deleteItem.name || 'Passenger'} deleted`, 'warn'); }
    else notify(r.error || 'Failed to delete', 'error');
  };

  const openEdit = (p) => {
    setEditItem(p);
    setEditForm({ name: p.name || '', email: p.email || '', contact: p.contact || '' });
  };

  const saveEdit = async () => {
    setSaving(true);
    const r = await api(`/api/passengers/${editItem.id}`, 'PATCH', editForm);
    setSaving(false);
    if (r.success) { setEditItem(null); load(search); notify('Passenger updated'); }
    else notify(r.error || 'Failed', 'error');
  };

  return (
    <div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faUsers} style={{ marginRight: 8, color: 'var(--gold)' }} />
            Passengers <span>({filtered.length})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: 'relative' }}>
              <FontAwesomeIcon icon={faSearch} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: '#aaa', fontSize: 12, pointerEvents: 'none' }} />
              <input
                className="search-box"
                style={{ width: 230, paddingLeft: 30 }}
                placeholder="Search name, username, ID..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>
        </div>

        <div style={{ padding: '10px 18px 0', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <FontAwesomeIcon icon={faFilter} style={{ color: 'var(--gray)', fontSize: 12 }} />
          <span style={{ fontSize: '.8rem', color: 'var(--gray)', marginRight: 4 }}>Filter:</span>
          {[
            { label: `All (${data.length})`,         value: 'All'       },
            { label: `Active (${activeCount})`,       value: 'Active'    },
            { label: `Suspended (${suspendedCount})`, value: 'Suspended' },
          ].map(({ label, value }) => (
            <button key={value} onClick={() => setStatusFilter(value)} style={{
              padding: '4px 12px', borderRadius: 20,
              border: statusFilter === value ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
              background: statusFilter === value ? 'var(--green)' : 'transparent',
              color: statusFilter === value ? '#fff' : 'var(--gray)',
              fontSize: '.78rem', fontWeight: statusFilter === value ? 700 : 400,
              cursor: 'pointer', transition: 'all 0.15s',
            }}>{label}</button>
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
                    <th style={{ width: 60 }}>ID</th>
                    <th>Name</th>
                    <th>Username</th>
                    <th>Contact</th>
                    <th style={{ width: 100 }}>Status</th>
                    <th>Registered</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.length === 0 ? (
                    <tr><td colSpan={7} style={{ textAlign: 'center', padding: '24px', color: 'var(--gray)' }}>
                      No {statusFilter !== 'All' ? statusFilter.toLowerCase() : ''} passengers found.
                    </td></tr>
                  ) : paginated.map(p => (
                    <tr key={p.id} style={{ opacity: p.status === 'Suspended' ? 0.6 : 1, transition: 'opacity 0.2s' }}>
                      <td><strong>{p.id}</strong></td>
                      <td><strong>{capitalizeName(p.name || '—')}</strong></td>
                      <td style={{ fontSize: '.85rem' }}><MaskedUsername username={p.username} /></td>
                      <td style={{ fontSize: '.85rem' }}>{p.contact || '—'}</td>
                      <td style={{ width: 100 }}>
                        <span
                          className={`badge ${p.status === 'Active' ? 'badge-active' : p.status === 'Suspended' ? 'badge-inactive' : 'badge-pending'}`}
                          style={{ display: 'inline-block', minWidth: 80, textAlign: 'center' }}
                        >
                          {p.status}
                        </span>
                      </td>
                      <td style={{ fontSize: '.85rem' }}>{formatDate(p.registered_at)}</td>
                      <td>
                        <div className="row-actions">
                          {p.status === 'Suspended' ? (
                            <button className="ib ib-del" onClick={() => setSuspendItem(p)} disabled={toggling === p.id}
                              style={{ background: '#f0fdf4', color: '#2d5a1b', borderColor: '#86efac', minWidth: 80 }}>
                              <FontAwesomeIcon icon={faCircleCheck} style={{ marginRight: 4, fontSize: 11 }} />Restore
                            </button>
                          ) : (
                            <button className="ib ib-del" onClick={() => setSuspendItem(p)} disabled={toggling === p.id}
                              style={{ background: '#fff8e1', color: '#b45309', borderColor: '#f59e0b', minWidth: 80 }}>
                              <FontAwesomeIcon icon={faBan} style={{ marginRight: 4, fontSize: 11 }} />Suspend
                            </button>
                          )}
                          <button className="ib ib-edit" onClick={() => openEdit(p)}>
                            <FontAwesomeIcon icon={faPencil} style={{ marginRight: 4, fontSize: 11 }} />Edit
                          </button>
                          <button className="ib ib-del" onClick={() => setDeleteItem(p)}>
                            <FontAwesomeIcon icon={faTrash} style={{ marginRight: 4, fontSize: 11 }} />Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {filtered.length > pageSize && (
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 18px', borderTop: '1px solid var(--gray2)' }}>
                <span style={{ fontSize: '.8rem', color: 'var(--gray)' }}>
                  Showing {Math.min((currentPage - 1) * pageSize + 1, filtered.length)}–{Math.min(currentPage * pageSize, filtered.length)} of {filtered.length} passengers
                </span>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
                    style={{ background: 'none', border: '1px solid var(--gray2)', borderRadius: 6, padding: '4px 10px', cursor: currentPage === 1 ? 'not-allowed' : 'pointer', opacity: currentPage === 1 ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronLeft} style={{ fontSize: 11 }} />
                  </button>
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map(pg => (
                    <button key={pg} onClick={() => setCurrentPage(pg)} style={{
                      padding: '4px 10px', borderRadius: 6, fontSize: '.8rem',
                      fontWeight: pg === currentPage ? 700 : 400,
                      border: pg === currentPage ? '1.5px solid var(--green)' : '1px solid var(--gray2)',
                      background: pg === currentPage ? 'var(--green)' : 'none',
                      color: pg === currentPage ? '#fff' : 'var(--gray)', cursor: 'pointer',
                    }}>{pg}</button>
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

      {/* ── EDIT ── */}
      {editItem && (
        <Modal title={`Edit: ${capitalizeName(editItem.name || 'Passenger')}`} onClose={() => setEditItem(null)}>
          <div className="field">
            <label>Full Name</label>
            <input value={editForm.name} onChange={e => setEditForm(p => ({ ...p, name: e.target.value }))} placeholder="Full name" />
          </div>
          <div className="form-row">
            <div className="field">
              <label>Email</label>
              <input value={editForm.email} onChange={e => setEditForm(p => ({ ...p, email: e.target.value }))} placeholder="email@example.com" />
            </div>
            <div className="field">
              <label>Contact Number</label>
              <input value={editForm.contact} onChange={e => setEditForm(p => ({ ...p, contact: e.target.value }))} placeholder="09XXXXXXXXX" />
            </div>
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEditItem(null)}>Cancel</button>
            <button className="btn btn-green" onClick={saveEdit} disabled={saving}>{saving ? 'Saving...' : 'Save Changes'}</button>
          </div>
        </Modal>
      )}

      {/* ── SUSPEND / RESTORE CONFIRM ── */}
      {suspendItem && (
        <Modal
          title={suspendItem.status === 'Suspended' ? 'Restore Passenger' : 'Suspend Passenger'}
          onClose={() => setSuspendItem(null)}
        >
          {suspendItem.status !== 'Suspended' ? (
            <div style={{ background: '#fff8e1', border: '1px solid #f59e0b', borderRadius: 10, padding: '14px 16px', marginBottom: 16, fontSize: '.88rem', color: '#78350f', lineHeight: 1.7 }}>
              Are you sure you want to suspend <strong>{capitalizeName(suspendItem.name || 'this passenger')}</strong>?<br />
              They will not be able to use the app until restored.
            </div>
          ) : (
            <div style={{ background: '#f0fdf4', border: '1px solid #86efac', borderRadius: 10, padding: '14px 16px', marginBottom: 16, fontSize: '.88rem', color: '#14532d', lineHeight: 1.7 }}>
              Restore <strong>{capitalizeName(suspendItem.name || 'this passenger')}</strong>?<br />
              Their account will be reactivated and they can use the app again.
            </div>
          )}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setSuspendItem(null)}>Cancel</button>
            {suspendItem.status !== 'Suspended' ? (
              <button onClick={confirmSuspend} disabled={toggling === suspendItem.id}
                style={{ background: '#d97706', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 18px', fontWeight: 700, cursor: 'pointer' }}>
                <FontAwesomeIcon icon={faBan} style={{ marginRight: 6 }} />
                {toggling === suspendItem.id ? 'Suspending...' : 'Yes, Suspend'}
              </button>
            ) : (
              <button onClick={confirmSuspend} disabled={toggling === suspendItem.id}
                style={{ background: 'var(--green)', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 18px', fontWeight: 700, cursor: 'pointer' }}>
                <FontAwesomeIcon icon={faCircleCheck} style={{ marginRight: 6 }} />
                {toggling === suspendItem.id ? 'Restoring...' : 'Yes, Restore'}
              </button>
            )}
          </div>
        </Modal>
      )}

      {/* ── DELETE CONFIRM ── */}
      {deleteItem && (
        <Modal title="Delete Passenger" onClose={() => setDeleteItem(null)}>
          <div style={{ background: '#fee2e2', border: '1px solid #fca5a5', borderRadius: 10, padding: '14px 16px', marginBottom: 16, fontSize: '.88rem', color: '#7f1d1d', lineHeight: 1.7 }}>
            Are you sure you want to delete <strong>{capitalizeName(deleteItem.name || 'this passenger')}</strong>?<br />
            This action cannot be undone.
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setDeleteItem(null)}>Cancel</button>
            <button onClick={confirmDelete}
              style={{ background: '#dc2626', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 18px', fontWeight: 700, cursor: 'pointer' }}>
              Yes, Delete Passenger
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export default Passengers;