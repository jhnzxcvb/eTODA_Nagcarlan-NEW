// src/components/complaints/Complaints.js
import React, { useState, useEffect } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';

function Complaints({ notify }) {
  const [data,     setData]    = useState([]);
  const [loading,  setLoading] = useState(true);
  const [editItem, setEditItem] = useState(null);   // item being edited/reviewed
  const [editStatus, setEditStatus] = useState('');
  const [editNotes,  setEditNotes]  = useState('');
  const [saving,   setSaving]  = useState(false);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/complaints');
    if (r.success) setData(r.data||[]);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  /* open the edit/review modal */
  const openEdit = c => {
    setEditItem(c);
    setEditStatus(c.status);
    setEditNotes(c.admin_notes || '');
  };

  /* save any status + notes change */
  const saveEdit = async () => {
    setSaving(true);
    const r = await api(`/api/complaints/${editItem.id}`, 'PATCH', {
      status: editStatus,
      admin_notes: editNotes,
    });
    setSaving(false);
    if (r.success) {
      setEditItem(null);
      load();
      notify(`Complaint ${editItem.report_code} → ${editStatus}`, editStatus === 'Resolved' ? 'success' : 'info');
    } else notify(r.error || 'Failed to save', 'error');
  };

  /* quick-resolve directly from the table row */
  const quickResolve = async c => {
    const r = await api(`/api/complaints/${c.id}`, 'PATCH', { status: 'Resolved', admin_notes: c.admin_notes || '' });
    if (r.success) { load(); notify(`${c.report_code} resolved ✅`); }
  };

  const SB  = { Pending:'badge-pending', Investigating:'badge-invest', Resolved:'badge-resolved' };
  const ALL_STATUSES = ['Pending', 'Investigating', 'Resolved'];

  const vBadge = v => {
    const high = ['Reckless Driving','Driver Under the Influence','Physical Assault','Theft / Lost Item'];
    const med  = ['Overcharging','Discourteous Behavior','Unauthorized Route Deviation','Refusal to Convey Passenger','No Receipt Issued'];
    if (high.includes(v)) return 'badge-delete';
    if (med.includes(v))  return 'badge-pending';
    return 'badge-inactive';
  };

  return (
    <div>
      {/* summary counters */}
      <div className="status-row">
        {[
          [data.filter(c=>c.status==='Pending').length,      'Pending',      'var(--red)'],
          [data.filter(c=>c.status==='Investigating').length,'Investigating','var(--blue)'],
          [data.filter(c=>c.status==='Resolved').length,     'Resolved',     'var(--green)'],
          [data.length,                                       'Total',        'var(--dark)'],
        ].map(([v,l,c]) => (
          <div key={l} className="status-card">
            <div className="status-val" style={{color:c}}>{v}</div>
            <div className="status-lbl">{l}</div>
          </div>
        ))}
      </div>

      <div className="card">
        <div className="card-head">
          <div className="card-title">🚨 Complaints <span>({data.length})</span></div>
          <button className="btn btn-ghost btn-sm" onClick={load}>↻ Refresh</button>
        </div>
        {loading ? <Loading/> : data.length===0 ? <Empty/> : (
          <div className="tbl-wrap">
            <table>
              <thead>
                <tr>
                  <th>Report #</th><th>Passenger</th><th>Driver</th><th>Violation</th>
                  <th>Firebase ID</th><th>Status</th><th>Date</th><th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.map(c => (
                  <tr key={c.id}>
                    <td><strong>{c.report_code}</strong></td>
                    <td>{c.passenger_name}</td>
                    <td>{c.driver_name}</td>
                    <td><span className={`badge ${vBadge(c.violation_type)}`}>{c.violation_type}</span></td>
                    <td style={{fontFamily:'monospace',fontSize:'.75rem'}}>{c.firebase_id}</td>
                    <td>
                      <span className={`badge ${SB[c.status]||'badge-pending'}`}>{c.status}</span>
                    </td>
                    <td>{c.reported_at}</td>
                    <td>
                      <div className="row-actions">
                        {/* Edit / Review — opens full modal with status dropdown */}
                        <button className="ib ib-edit" onClick={() => openEdit(c)}>Edit</button>
                        {/* Quick resolve directly from table */}
                        {c.status !== 'Resolved' && (
                          <button className="ib ib-resolve" onClick={() => quickResolve(c)}>Resolve</button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ── EDIT / REVIEW MODAL ── */}
      {editItem && (
        <Modal title={`Edit Complaint: ${editItem.report_code}`} onClose={() => setEditItem(null)}>
          {/* complaint details (read-only) */}
          <DG rows={[
            ['Report #',    editItem.report_code],
            ['Passenger',   editItem.passenger_name],
            ['Driver',      editItem.driver_name],
            ['Franchise',   editItem.franchise],
            ['Violation',   editItem.violation_type],
            ['Firebase ID', editItem.firebase_id],
            ['Date Filed',  editItem.reported_at],
          ]}/>

          {/* editable status */}
          <div className="field">
            <label>Status</label>
            <select value={editStatus} onChange={e => setEditStatus(e.target.value)}>
              {ALL_STATUSES.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>

          {/* status helper hint */}
          {editStatus === 'Resolved' && (
            <div className="box-info" style={{marginBottom:14}}>
              Marking as <strong>Resolved</strong> will timestamp the resolution and log it to Audit Trail.
            </div>
          )}
          {editStatus === 'Investigating' && (
            <div className="box-warn" style={{marginBottom:14}}>
              Marking as <strong>Investigating</strong> — add notes below to document your findings.
            </div>
          )}

          {/* admin notes */}
          <div className="field">
            <label>Admin Notes</label>
            <textarea
              value={editNotes}
              onChange={e => setEditNotes(e.target.value)}
              placeholder="Write investigation findings, resolution notes, or any relevant remarks..."
              style={{minHeight:100}}
            />
          </div>

          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEditItem(null)}>Cancel</button>
            <button
              className={`btn ${editStatus==='Resolved' ? 'btn-green' : editStatus==='Investigating' ? 'btn-blue' : 'btn-orange'}`}
              onClick={saveEdit}
              disabled={saving}
            >
              {saving ? 'Saving...' : `Save — Mark as ${editStatus}`}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export default Complaints;