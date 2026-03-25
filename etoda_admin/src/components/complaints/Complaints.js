import React, { useState, useEffect, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faTriangleExclamation, faSearch, faFilter,
  faEye, faCircleCheck, faMagnifyingGlass,
  faRotateLeft, faClockRotateLeft, faRefresh,
  faNotesMedical, faChevronLeft, faChevronRight,
} from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

const formatDate = (str) => {
  if (!str) return '—';
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString('en-PH', { year: 'numeric', month: 'short', day: 'numeric' });
};

const SB = {
  'Open':        'badge-pending',
  'In Progress': 'badge-invest',
  'Resolved':    'badge-resolved',
};

function Complaints({ notify }) {
  const [data,          setData]         = useState([]);
  const [loading,       setLoading]      = useState(true);
  const [search,        setSearch]       = useState('');
  const [statusFilter,  setStatusFilter] = useState('All');
  const [pageSize,      setPageSize]     = useState(10);
  const [currentPage,   setCurrentPage]  = useState(1);

  const [viewItem,    setViewItem]   = useState(null);
  const [viewNotes,   setViewNotes]  = useState('');
  const [viewStatus,  setViewStatus] = useState('');
  const [savingView,  setSavingView] = useState(false);

  const [updateItem,  setUpdateItem]  = useState(null);
  const [updateNotes, setUpdateNotes] = useState('');
  const [saving,      setSaving]      = useState(false);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/complaints');
    if (r.success) setData(r.data || []);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);
  useEffect(() => { setCurrentPage(1); }, [statusFilter, pageSize, search]);

  const filtered = useMemo(() => {
    let rows = [...data];
    if (statusFilter !== 'All') rows = rows.filter(c => c.status === statusFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      rows = rows.filter(c =>
        c.report_code?.toLowerCase().includes(q) ||
        c.passenger_name?.toLowerCase().includes(q) ||
        c.driver_name?.toLowerCase().includes(q) ||
        c.violation_type?.toLowerCase().includes(q) ||
        c.details?.toLowerCase().includes(q)
      );
    }
    return rows;
  }, [data, search, statusFilter]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  const openView = (c) => { 
    setViewItem(c); 
    setViewNotes(c.admin_notes || ''); 
    setViewStatus(c.status); 
  };

  const saveView = async () => {
    setSavingView(true);
    const r = await api(`/api/complaints/${viewItem.id}`, 'PATCH', { 
        status: viewStatus, 
        admin_notes: viewNotes 
    });
    setSavingView(false);
    if (r.success) {
      const updated = { ...viewItem, status: viewStatus, admin_notes: viewNotes };
      setData(prev => prev.map(c => c.id === viewItem.id ? updated : c));
      setViewItem(updated);
      notify(`${viewItem.report_code} updated`, 'success');
    } else notify(r.error || 'Failed to save', 'error');
  };

  const openUpdate = (c, targetStatus) => { 
    setUpdateItem({ ...c, targetStatus }); 
    setUpdateNotes(c.admin_notes || ''); 
  };

  const saveUpdate = async () => {
    setSaving(true);
    const r = await api(`/api/complaints/${updateItem.id}`, 'PATCH', { 
        status: updateItem.targetStatus, 
        admin_notes: updateNotes 
    });
    setSaving(false);
    if (r.success) {
      setUpdateItem(null); 
      load();
      notify(`${updateItem.report_code} → ${updateItem.targetStatus}`, 'success');
    } else notify(r.error || 'Failed to update', 'error');
  };

  const vBadge = v => {
    const high = ['Reckless Driving','Driver Under the Influence','Physical Assault','Theft / Lost Item'];
    const med  = ['Overcharging','Discourteous Behavior','Unauthorized Route Deviation'];
    if (high.includes(v)) return 'badge-delete';
    if (med.includes(v))  return 'badge-pending';
    return 'badge-inactive';
  };

  const actionButtons = (c) => {
    const commonView = (
        <button className="ib ib-view" onClick={() => openView(c)} style={{ minWidth: 60 }}>
          <FontAwesomeIcon icon={faEye} style={{ marginRight: 4, fontSize: 11 }} />View
        </button>
    );

    if (c.status === 'Open') return (
      <div className="row-actions">
        {commonView}
        <button className="ib" onClick={() => openUpdate(c, 'In Progress')}
          style={{ background:'#eff6ff', color:'#1d4ed8', borderColor:'#93c5fd', minWidth: 100 }}>
          <FontAwesomeIcon icon={faMagnifyingGlass} style={{ marginRight: 4, fontSize: 11 }} />In Progress
        </button>
        <button className="ib ib-edit" onClick={() => openUpdate(c, 'Resolved')} style={{ minWidth: 80 }}>
          <FontAwesomeIcon icon={faCircleCheck} style={{ marginRight: 4, fontSize: 11 }} />Resolve
        </button>
      </div>
    );
    if (c.status === 'In Progress') return (
      <div className="row-actions">
        {commonView}
        <button className="ib ib-edit" onClick={() => openUpdate(c, 'Resolved')} style={{ minWidth: 80 }}>
          <FontAwesomeIcon icon={faCircleCheck} style={{ marginRight: 4, fontSize: 11 }} />Resolve
        </button>
        <button className="ib" onClick={() => openUpdate(c, 'Open')}
          style={{ background:'#fff8e1', color:'#b45309', borderColor:'#f59e0b', minWidth: 80 }}>
          <FontAwesomeIcon icon={faRotateLeft} style={{ marginRight: 4, fontSize: 11 }} />Reopen
        </button>
      </div>
    );
    return (
      <div className="row-actions">
        {commonView}
        <button className="ib" onClick={() => openUpdate(c, 'Open')}
          style={{ background:'#fef2f2', color:'#dc2626', borderColor:'#fca5a5', minWidth: 80 }}>
          <FontAwesomeIcon icon={faClockRotateLeft} style={{ marginRight: 4, fontSize: 11 }} />Reopen
        </button>
      </div>
    );
  };

  const DetailGrid = ({ rows }) => (
    <div style={{ background: 'var(--bg)', borderRadius: 10, padding: '14px 16px', marginBottom: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 24px' }}>
        {rows.map(([label, val]) => (
          <div key={label}>
            <div style={{ fontSize: '.7rem', color: 'var(--gray)', textTransform: 'uppercase', letterSpacing: '.5px', marginBottom: 2 }}>{label}</div>
            <div style={{ fontWeight: 600, fontSize: '.88rem' }}>{val || '—'}</div>
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faTriangleExclamation} style={{ marginRight: 8, color: 'var(--gold)' }} />
            Complaints <span>({filtered.length})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: 'relative' }}>
              <FontAwesomeIcon icon={faSearch} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: '#aaa', fontSize: 12, pointerEvents: 'none' }} />
              <input className="search-box" style={{ paddingLeft: 30, width: 240 }} placeholder="Search code, name, violation..." value={search} onChange={e => setSearch(e.target.value)} />
            </div>
            <button className="btn btn-ghost btn-sm" onClick={load}>
              <FontAwesomeIcon icon={faRefresh} style={{ marginRight: 6 }} />Refresh
            </button>
          </div>
        </div>

        <div style={{ padding: '10px 18px 0', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <FontAwesomeIcon icon={faFilter} style={{ color: 'var(--gray)', fontSize: 12 }} />
          <span style={{ fontSize: '.8rem', color: 'var(--gray)', marginRight: 4 }}>Filter:</span>
          {['All', 'Open', 'In Progress', 'Resolved'].map(s => (
            <button key={s} onClick={() => setStatusFilter(s)} style={{
              padding: '4px 12px', borderRadius: 20,
              border: statusFilter === s ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
              background: statusFilter === s ? 'var(--green)' : 'transparent',
              color: statusFilter === s ? '#fff' : 'var(--gray)',
              fontSize: '.78rem', fontWeight: statusFilter === s ? 700 : 400,
              cursor: 'pointer', transition: 'all 0.15s',
            }}>
              {s === 'All' ? `All (${data.length})` : `${s} (${data.filter(c => c.status === s).length})`}
            </button>
          ))}
        </div>

        {loading ? <Loading /> : data.length === 0 ? <Empty /> : (
          <>
            <div className="tbl-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Report #</th>
                    <th>Passenger</th>
                    <th>Driver</th>
                    <th>Violation</th>
                    <th>Description</th>
                    <th style={{ width: 110 }}>Status</th>
                    <th>Date Filed</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.map(c => (
                    <tr key={c.id}>
                      <td><strong>{c.report_code}</strong></td>
                      <td>{c.passenger_name}</td>
                      <td>{c.driver_name}</td>
                      <td><span className={`badge ${vBadge(c.violation_type)}`}>{c.violation_type}</span></td>
                      <td style={{ fontSize: '.8rem', color: 'var(--gray)' }}>{c.details || '—'}</td>
                      <td>
                        <span className={`badge ${SB[c.status] || 'badge-pending'}`}>
                          {c.status}
                        </span>
                      </td>
                      <td style={{ fontSize: '.85rem' }}>{formatDate(c.reported_at)}</td>
                      <td>{actionButtons(c)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Pagination controls ... same as original */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 18px', borderTop: '1px solid var(--gray2)' }}>
                <span style={{ fontSize: '.8rem', color: 'var(--gray)' }}>
                    Showing {paginated.length} of {filtered.length} complaints
                </span>
                <div style={{ display: 'flex', gap: 6 }}>
                    <button onClick={() => setCurrentPage(p => Math.max(1, p-1))} className="btn btn-ghost btn-sm" disabled={currentPage === 1}>Prev</button>
                    <button onClick={() => setCurrentPage(p => Math.min(totalPages, p+1))} className="btn btn-ghost btn-sm" disabled={currentPage === totalPages}>Next</button>
                </div>
            </div>
          </>
        )}
      </div>

      {/* VIEW MODAL */}
      {viewItem && (
        <Modal title={`Report Details: ${viewItem.report_code}`} onClose={() => setViewItem(null)}>
          <DetailGrid rows={[
            ['Passenger', viewItem.passenger_name],
            ['Driver', viewItem.driver_name],
            ['Franchise', viewItem.franchise],
            ['Violation', viewItem.violation_type],
            ['Details', viewItem.details],
            ['Date Filed', formatDate(viewItem.reported_at)],
          ]} />
          <div className="field">
            <label>Update Status</label>
            <select value={viewStatus} onChange={e => setViewStatus(e.target.value)}>
              <option value="Open">Open</option>
              <option value="In Progress">In Progress</option>
              <option value="Resolved">Resolved</option>
            </select>
          </div>
          <div className="field">
            <label><FontAwesomeIcon icon={faNotesMedical} /> Admin Notes</label>
            <textarea value={viewNotes} onChange={e => setViewNotes(e.target.value)} placeholder="Enter investigation notes..." />
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setViewItem(null)}>Cancel</button>
            <button className="btn btn-green" onClick={saveView} disabled={savingView}>{savingView ? 'Saving...' : 'Save Changes'}</button>
          </div>
        </Modal>
      )}

      {/* QUICK STATUS UPDATE MODAL */}
      {updateItem && (
        <Modal title={`Mark as ${updateItem.targetStatus}`} onClose={() => setUpdateItem(null)}>
           <div style={{ marginBottom: 16 }}>
              <strong>Report:</strong> {updateItem.report_code}<br/>
              <strong>Violation:</strong> {updateItem.violation_type}
           </div>
           <div className="field">
             <label>Notes for this action</label>
             <textarea value={updateNotes} onChange={e => setUpdateNotes(e.target.value)} placeholder="Optional remarks..." />
           </div>
           <div className="modal-footer">
             <button className="btn btn-ghost" onClick={() => setUpdateItem(null)}>Cancel</button>
             <button className="btn btn-green" onClick={saveUpdate} disabled={saving}>
               {saving ? 'Updating...' : `Confirm ${updateItem.targetStatus}`}
             </button>
           </div>
        </Modal>
      )}
    </div>
  );
}

export default Complaints;