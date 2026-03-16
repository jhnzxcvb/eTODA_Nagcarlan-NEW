// src/components/drivers/Drivers.js
import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';

function Drivers({ notify }) {
  const [data,       setData]       = useState([]);
  const [loading,    setLoading]    = useState(true);
  const [search,     setSearch]     = useState('');
  const [enrollOpen, setEnrollOpen] = useState(false);
  const [viewItem,   setViewItem]   = useState(null);
  const [editItem,   setEditItem]   = useState(null);
  const [delItem,    setDelItem]    = useState(null);
  const [saving,     setSaving]     = useState(false);

  const BLANK = { username:'', password:'', name:'', franchise:'', body_no:'', contact:'', license_no:'', association:'Nagcarlan TODA' };
  const [form, setForm] = useState(BLANK);

  const ASSOCS = ['Nagcarlan TODA','Oobi TODA','Talangan TODA','San Antonio TODA'];

  const load = useCallback(async (q='') => {
    setLoading(true);
    const r = await api(`/api/drivers${q?`?search=${encodeURIComponent(q)}`:''}`);
    if (r.success) setData(r.data||[]); else notify(r.error,'error');
    setLoading(false);
  },[]);

  useEffect(() => { load(); },[load]);
  useEffect(() => { const t = setTimeout(() => load(search), 300); return () => clearTimeout(t); },[search,load]);

  const enroll = async () => {
    if (!form.name.trim()||!form.franchise.trim()) { notify('Name and Franchise are required','error'); return; }
    setSaving(true);
    const r = await api('/api/drivers','POST',form);
    setSaving(false);
    if (r.success) { setEnrollOpen(false); setForm(BLANK); load(search); notify(`${form.name} enrolled ✅`); }
    else notify(r.error||'Failed','error');
  };

  const saveEdit = async () => {
    setSaving(true);
    const r = await api(`/api/drivers/${editItem.id}`,'PATCH',form);
    setSaving(false);
    if (r.success) { setEditItem(null); load(search); notify('Driver updated ✅'); }
    else notify(r.error||'Failed','error');
  };

  const toggleStatus = async d => {
    const next = d.status==='Active'?'Inactive':'Active';
    const r = await api(`/api/drivers/${d.id}`,'PATCH',{status:next});
    if (r.success) { load(search); notify(`${d.name} → ${next}`,next==='Active'?'success':'warn'); }
  };

  const remove = async () => {
    const r = await api(`/api/drivers/${delItem.id}`,'DELETE');
    if (r.success) { setDelItem(null); load(search); notify(`${delItem.name} removed`,'warn'); }
    else notify(r.error,'error');
  };

  const openEdit = d => {
    setEditItem(d);
    setForm({ username:d.username||'', password:'', name:d.name, franchise:d.franchise, body_no:d.body_no||'', contact:d.contact||'', license_no:d.license_no||'', association:d.association||'Nagcarlan TODA' });
  };

  /* ── JSX variable (NOT a component) — stable inline onChange handlers ── */
  const formFields = (
    <>
      <div className="form-row">
        <div className="field">
          <label>Username (optional)</label>
          <input value={form.username}   onChange={e => setForm(p=>({...p,username:e.target.value}))}   placeholder="login name"/>
        </div>
        <div className="field">
          <label>Password (optional)</label>
          <input type="password" value={form.password}   onChange={e => setForm(p=>({...p,password:e.target.value}))}   placeholder="secret"/>
        </div>
      </div>
      <div className="form-row">
        <div className="field">
          <label>Full Name *</label>
          <input value={form.name}       onChange={e => setForm(p=>({...p,name:e.target.value}))}       placeholder="Juan A. Dela Cruz"/>
        </div>
        <div className="field">
          <label>Franchise # *</label>
          <input value={form.franchise}  onChange={e => setForm(p=>({...p,franchise:e.target.value}))}  placeholder="NVC-006F"/>
        </div>
      </div>
      <div className="form-row">
        <div className="field">
          <label>Body #</label>
          <input value={form.body_no}    onChange={e => setForm(p=>({...p,body_no:e.target.value}))}    placeholder="06"/>
        </div>
        <div className="field">
          <label>Contact</label>
          <input value={form.contact}    onChange={e => setForm(p=>({...p,contact:e.target.value}))}    placeholder="09XXXXXXXXX"/>
        </div>
      </div>
      <div className="form-row">
        <div className="field">
          <label>License No.</label>
          <input value={form.license_no} onChange={e => setForm(p=>({...p,license_no:e.target.value}))} placeholder="NAG-XXXXXX"/>
        </div>
        <div className="field">
          <label>Association</label>
          <select value={form.association} onChange={e => setForm(p=>({...p,association:e.target.value}))}>
            {ASSOCS.map(a => <option key={a}>{a}</option>)}
          </select>
        </div>
      </div>
    </>
  );

  return (
    <div>
      <div className="box-warn">Drivers cannot self-register. Each enrollment auto-generates an AES-256 encrypted QR sticker logged to Audit Trail.</div>

      <div className="card">
        <div className="card-head">
          <div className="card-title">👥 Driver Registry <span>({data.length} drivers)</span></div>
          <div className="card-actions">
            <input className="search-box" style={{width:230}} placeholder="🔍 Search name, franchise, ID..."
              value={search} onChange={e => setSearch(e.target.value)}/>
            <button className="btn btn-green" onClick={() => { setForm(BLANK); setEnrollOpen(true); }}>+ Enroll Driver</button>
          </div>
        </div>
        {loading ? <Loading/> : data.length===0 ? <Empty/> : (
          <div className="tbl-wrap">
            <table>
              <thead><tr>
                <th>ID</th><th>Name</th><th>Franchise</th><th>Body #</th>
                <th>Contact</th><th>License</th><th>Association</th><th>Status</th><th>QR</th><th>Actions</th>
              </tr></thead>
              <tbody>
                {data.map(d => (
                  <tr key={d.id}>
                    <td><strong>{d.driver_code}</strong></td>
                    <td><strong>{d.name}</strong></td>
                    <td>{d.franchise}</td>
                    <td>{d.body_no||'—'}</td>
                    <td>{d.contact||'—'}</td>
                    <td>{d.license_no||'—'}</td>
                    <td>{d.association||'—'}</td>
                    <td>
                      <span className={`badge ${d.status==='Active'?'badge-active':'badge-inactive'}`}
                        style={{cursor:'pointer'}} title="Click to toggle" onClick={() => toggleStatus(d)}>
                        {d.status}
                      </span>
                    </td>
                    <td><span style={{fontSize:'.75rem',color:d.qr_id?'var(--green)':'var(--gray)'}}>{d.qr_id?'✅ Issued':'—'}</span></td>
                    <td>
                      <div className="row-actions">
                        <button className="ib ib-view" onClick={() => setViewItem(d)}>View</button>
                        <button className="ib ib-edit" onClick={() => openEdit(d)}>Edit</button>
                        <button className="ib ib-del"  onClick={() => setDelItem(d)}>Remove</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {enrollOpen && (
        <Modal title="+ Enroll New Driver" onClose={() => setEnrollOpen(false)}>
          <div className="box-info">Driver will be saved to PostgreSQL. An AES-256 QR sticker is auto-generated and logged.</div>
          {formFields}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEnrollOpen(false)}>Cancel</button>
            <button className="btn btn-green" onClick={enroll} disabled={saving}>{saving?'Enrolling...':'✅ Enroll & Generate QR'}</button>
          </div>
        </Modal>
      )}

      {viewItem && (
        <Modal title={`Driver: ${viewItem.name}`} onClose={() => setViewItem(null)}>
          <DG rows={[
            ['Driver ID',viewItem.driver_code],['Full Name',viewItem.name],
            ['Franchise',viewItem.franchise],  ['Body #',viewItem.body_no],
            ['Contact',viewItem.contact],      ['License No.',viewItem.license_no],
            ['Association',viewItem.association],['Status',viewItem.status],
            ['QR Code',viewItem.qr_id],        ['Enrolled',viewItem.created_at],
          ]}/>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setViewItem(null)}>Close</button>
            <button className="btn btn-gold"  onClick={() => { toggleStatus(viewItem); setViewItem(null); }}>
              {viewItem.status==='Active'?'Deactivate':'Reactivate'}
            </button>
            <button className="btn btn-blue"  onClick={() => { openEdit(viewItem); setViewItem(null); }}>Edit</button>
          </div>
        </Modal>
      )}

      {editItem && (
        <Modal title={`Edit: ${editItem.name}`} onClose={() => setEditItem(null)}>
          <div className="box-info">Changes saved to PostgreSQL and logged to Audit Trail.</div>
          {formFields}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEditItem(null)}>Cancel</button>
            <button className="btn btn-green" onClick={saveEdit} disabled={saving}>{saving?'Saving...':'Save Changes'}</button>
          </div>
        </Modal>
      )}

      {delItem && (
        <Modal title="Remove Driver" onClose={() => setDelItem(null)}>
          <div className="box-red">
            Remove <strong>{delItem.name}</strong> ({delItem.franchise})? Their QR will be revoked. This is logged.
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setDelItem(null)}>Cancel</button>
            <button className="btn btn-red"   onClick={remove}>Yes, Remove Driver</button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export default Drivers;