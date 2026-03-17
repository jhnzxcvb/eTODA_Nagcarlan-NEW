// src/components/drivers/Drivers.js
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faFilter, faPencil, faTrash, faUserGroup, faQrcode, faPrint, faDownload, faTimes, faBan, faCircleCheck, faSearch } from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';
import QRCode from 'qrcode';

const capitalizeName = (name = '') => name.replace(/\b\w/g, c => c.toUpperCase());

function Drivers({ notify }) {
  const [data,         setData]         = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [search,       setSearch]       = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [enrollOpen,   setEnrollOpen]   = useState(false);
  const [editItem,     setEditItem]     = useState(null);
  const [delItem,      setDelItem]      = useState(null);
  const [suspendItem,  setSuspendItem]  = useState(null); // confirm suspend
  const [saving,       setSaving]       = useState(false);
  const [toggling,     setToggling]     = useState(null);

  // ── QR Modal state ──
  const [qrSelected, setQrSelected] = useState(null);
  const [qrDataUrl,  setQrDataUrl]  = useState('');

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

  const filtered = useMemo(() => {
    if (statusFilter === 'All') return data;
    return data.filter(d => d.status === statusFilter);
  }, [data, statusFilter]);

  // ── QR Modal ──
  const openQR = async (d) => {
    if (!d.qr_id) return;
    const qObj = { qr_id: d.qr_id, driver_name: capitalizeName(d.name), franchise: d.franchise, issued_at: d.created_at || '—' };
    setQrSelected(qObj);
    try {
      const url = await QRCode.toDataURL(d.qr_id, { width:200, margin:2, color:{ dark:'#2d5a1b', light:'#ffffff' } });
      setQrDataUrl(url);
    } catch { notify('Failed to generate QR code', 'error'); }
  };

  const closeQR = () => { setQrSelected(null); setQrDataUrl(''); };

  const downloadQR = () => {
    if (!qrDataUrl || !qrSelected) return;
    const a = document.createElement('a');
    a.href = qrDataUrl;
    a.download = `QR-${qrSelected.franchise}-${qrSelected.driver_name}.png`;
    a.click();
  };

  const printSticker = () => {
    if (!qrDataUrl || !qrSelected) return;
    const win = window.open('', '_blank');
    win.document.write(`
      <!DOCTYPE html><html><head>
        <title>QR Sticker - ${qrSelected.franchise}</title>
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          body { font-family:'Segoe UI',sans-serif; display:flex; justify-content:center; align-items:center; min-height:100vh; background:#fff; }
          .sticker { width:280px; border:2px solid #2d5a1b; border-radius:16px; overflow:hidden; text-align:center; }
          .sticker-header { background:#2d5a1b !important; -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; padding:14px 16px; }
          .sticker-header h1 { font-size:18px; font-weight:bold; color:#ffffff !important; margin-bottom:2px; }
          .sticker-header p  { font-size:11px; color:#ffffff !important; }
          .sticker-body { padding:20px 16px; }
          .qr-wrap { display:inline-block; padding:10px; border:2px solid #2d5a1b; border-radius:10px; margin-bottom:14px; }
          .qr-wrap img { display:block; width:160px; height:160px; }
          .driver-name { font-size:16px; font-weight:bold; color:#1a1a1a; margin-bottom:4px; }
          .franchise   { font-size:13px; color:#555; margin-bottom:6px; }
          .qr-id       { font-size:9px; font-family:monospace; color:#888; margin-bottom:12px; word-break:break-all; }
          .badge { display:inline-block; padding:4px 12px; background:#e8f5e9 !important; -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; color:#2d5a1b !important; border-radius:20px; font-size:11px; font-weight:bold; margin-bottom:4px; }
          .sticker-footer { background:#f5f5f5 !important; -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; padding:8px 12px; font-size:10px; color:#888 !important; border-top:1px solid #e0e0e0; }
          @media print {
            * { -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; }
            .sticker-header { background:#2d5a1b !important; }
            .sticker-header h1, .sticker-header p { color:#ffffff !important; }
            .badge { background:#e8f5e9 !important; color:#2d5a1b !important; }
            .sticker-footer { background:#f5f5f5 !important; color:#888 !important; }
          }
        </style>
      </head>
      <body>
        <div class="sticker">
          <div class="sticker-header"><h1>eTODA Nagcarlan</h1><p>Official Driver QR Code</p></div>
          <div class="sticker-body">
            <div class="qr-wrap"><img src="${qrDataUrl}" alt="QR Code" /></div>
            <div class="driver-name">${qrSelected.driver_name}</div>
            <div class="franchise">Franchise: ${qrSelected.franchise}</div>
            <div class="qr-id">${qrSelected.qr_id}</div>
            <div class="badge">&#10003; Active &middot; AES-256 Encrypted</div>
          </div>
          <div class="sticker-footer">Nagcarlan LGU &middot; eTODA System &middot; Issued ${qrSelected.issued_at}</div>
        </div>
        <script>window.onload=function(){window.print();window.close()};<\/script>
      </body></html>
    `);
    win.document.close();
  };

  // ── Enroll ──
  const enroll = async () => {
    if (!form.name.trim()||!form.franchise.trim()) { notify('Name and Franchise are required','error'); return; }
    setSaving(true);
    const r = await api('/api/drivers','POST',{ ...form, name: capitalizeName(form.name) });
    setSaving(false);
    if (r.success) { setEnrollOpen(false); setForm(BLANK); load(search); notify(`${capitalizeName(form.name)} enrolled ✅`); }
    else notify(r.error||'Failed','error');
  };

  // ── Edit ──
  const saveEdit = async () => {
    setSaving(true);
    const r = await api(`/api/drivers/${editItem.id}`,'PATCH',{ ...form, name: capitalizeName(form.name) });
    setSaving(false);
    if (r.success) { setEditItem(null); load(search); notify('Driver updated ✅'); }
    else notify(r.error||'Failed','error');
  };

  const openEdit = d => {
    setEditItem(d);
    setForm({ username:d.username||'', password:'', name:d.name, franchise:d.franchise, body_no:d.body_no||'', contact:d.contact||'', license_no:d.license_no||'', association:d.association||'Nagcarlan TODA' });
  };

  // ── Suspend / Reactivate ──
  const confirmSuspend = async () => {
    setToggling(suspendItem.id);
    const next = suspendItem.status === 'Active' ? 'Inactive' : 'Active';
    const r = await api(`/api/drivers/${suspendItem.id}`,'PATCH',{status:next});
    setToggling(null);
    setSuspendItem(null);
    if (r.success) {
      load(search);
      notify(
        next === 'Inactive'
          ? `${capitalizeName(suspendItem.name)} has been suspended`
          : `${capitalizeName(suspendItem.name)} has been reactivated`,
        next === 'Active' ? 'success' : 'warn'
      );
    }
  };

  // ── Delete ──
  const remove = async () => {
    const r = await api(`/api/drivers/${delItem.id}`,'DELETE');
    if (r.success) { setDelItem(null); load(search); notify(`${capitalizeName(delItem.name)} deleted`,'warn'); }
    else notify(r.error,'error');
  };

  const formFields = (
    <>
      <div className="form-row">
        <div className="field"><label>Username (optional)</label><input value={form.username} onChange={e=>setForm(p=>({...p,username:e.target.value}))} placeholder="login name"/></div>
        <div className="field"><label>Password (optional)</label><input type="password" value={form.password} onChange={e=>setForm(p=>({...p,password:e.target.value}))} placeholder="secret"/></div>
      </div>
      <div className="form-row">
        <div className="field"><label>Full Name *</label><input value={form.name} onChange={e=>setForm(p=>({...p,name:e.target.value}))} placeholder="Juan A. Dela Cruz"/></div>
        <div className="field"><label>Franchise # *</label><input value={form.franchise} onChange={e=>setForm(p=>({...p,franchise:e.target.value}))} placeholder="NVC-006F"/></div>
      </div>
      <div className="form-row">
        <div className="field"><label>Body #</label><input value={form.body_no} onChange={e=>setForm(p=>({...p,body_no:e.target.value}))} placeholder="06"/></div>
        <div className="field"><label>Contact</label><input value={form.contact} onChange={e=>setForm(p=>({...p,contact:e.target.value}))} placeholder="09XXXXXXXXX"/></div>
      </div>
      <div className="form-row">
        <div className="field"><label>License No.</label><input value={form.license_no} onChange={e=>setForm(p=>({...p,license_no:e.target.value}))} placeholder="NAG-XXXXXX"/></div>
        <div className="field"><label>Association</label>
          <select value={form.association} onChange={e=>setForm(p=>({...p,association:e.target.value}))}>
            {ASSOCS.map(a=><option key={a}>{a}</option>)}
          </select>
        </div>
      </div>
    </>
  );

  const activeCount   = data.filter(d => d.status === 'Active').length;
  const inactiveCount = data.filter(d => d.status === 'Inactive').length;

  return (
    <div>
      <div className="box-warn">Drivers cannot self-register. Each enrollment auto-generates an AES-256 encrypted QR sticker logged to Audit Trail.</div>

      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faUserGroup} style={{ marginRight:8, color:'var(--gold)' }} />
            Driver Registry <span>({filtered.length} drivers)</span>
          </div>
          <div className="card-actions">
            <div style={{ position:'relative', display:'inline-block' }}>
              <FontAwesomeIcon icon={faSearch} style={{ position:'absolute', left:10, top:'50%', transform:'translateY(-50%)', color:'#aaa', fontSize:12, pointerEvents:'none' }} />
              <input
                className="search-box"
                style={{ width:230, paddingLeft:30 }}
                placeholder="Search name, franchise, ID..."
                value={search}
                onChange={e=>setSearch(e.target.value)}
              />
            </div>
            <button className="btn btn-green" onClick={()=>{setForm(BLANK);setEnrollOpen(true);}}>+ Enroll Driver</button>
          </div>
        </div>

        {/* Status filter */}
        <div style={{ padding:'10px 18px 0', display:'flex', alignItems:'center', gap:8 }}>
          <FontAwesomeIcon icon={faFilter} style={{ color:'var(--gray)', fontSize:12 }} />
          <span style={{ fontSize:'.8rem', color:'var(--gray)', marginRight:4 }}>Filter:</span>
          {[
            { label:`All (${data.length})`,       value:'All'      },
            { label:`Active (${activeCount})`,     value:'Active'   },
            { label:`Suspended (${inactiveCount})`,value:'Inactive' },
          ].map(({label,value}) => (
            <button key={value} onClick={()=>setStatusFilter(value)} style={{
              padding:'4px 12px', borderRadius:20,
              border: statusFilter===value ? '1.5px solid var(--green)' : '1.5px solid var(--gray2)',
              background: statusFilter===value ? 'var(--green)' : 'transparent',
              color: statusFilter===value ? '#fff' : 'var(--gray)',
              fontSize:'.78rem', fontWeight: statusFilter===value ? 700 : 400,
              cursor:'pointer', transition:'all 0.15s',
            }}>{label}</button>
          ))}
        </div>

        {loading ? <Loading/> : data.length===0 ? <Empty/> : (
          <div className="tbl-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th><th>Name</th><th>Username</th><th>Franchise</th>
                  <th>Body #</th><th>Contact</th><th>QR</th><th>Status</th><th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr><td colSpan={9} style={{textAlign:'center',padding:'24px',color:'var(--gray)'}}>
                    No {statusFilter!=='All'?statusFilter.toLowerCase():''} drivers found.
                  </td></tr>
                ) : filtered.map(d => (
                  <tr key={d.id} style={{ opacity: d.status==='Inactive' ? 0.6 : 1, transition:'opacity 0.2s' }}>
                    <td><strong>{d.driver_code}</strong></td>
                    <td><strong>{capitalizeName(d.name)}</strong></td>
                    <td style={{ fontSize:'.8rem', color: d.username ? 'var(--gray)' : 'var(--gray2)', fontFamily:'monospace' }}>
                      {d.username || <span style={{color:'var(--gray2)',fontStyle:'italic',fontFamily:'inherit'}}>none</span>}
                    </td>
                    <td>{d.franchise}</td>
                    <td>{d.body_no||'—'}</td>
                    <td>{d.contact||'—'}</td>
                    <td>
                      {d.qr_id ? (
                        <button onClick={()=>openQR(d)} title="Click to view QR code"
                          style={{ background:'none', border:'none', cursor:'pointer', padding:0, display:'flex', alignItems:'center', gap:4, color:'var(--green)', fontSize:'.78rem', fontWeight:600 }}>
                          <FontAwesomeIcon icon={faQrcode} style={{fontSize:12}} />Issued
                        </button>
                      ) : (
                        <span style={{color:'var(--gray2)'}}>—</span>
                      )}
                    </td>
                    <td>
                      <span className={`badge ${d.status==='Active' ? 'badge-active' : 'badge-inactive'}`}>
                        {d.status === 'Active' ? 'Active' : 'Suspended'}
                      </span>
                    </td>
                    <td>
                      <div className="row-actions">
                        {d.status === 'Active' ? (
                          <button
                            className="ib"
                            onClick={() => setSuspendItem(d)}
                            disabled={toggling === d.id}
                            style={{ background:'#fff8e1', color:'#b45309', border:'1px solid #f59e0b', borderRadius:6, padding:'3px 10px', fontSize:'.78rem', fontWeight:600, cursor:'pointer', display:'flex', alignItems:'center', gap:4 }}
                          >
                            <FontAwesomeIcon icon={faBan} style={{fontSize:11}}/>Suspend
                          </button>
                        ) : (
                          <button
                            className="ib ib-edit"
                            onClick={() => setSuspendItem(d)}
                            disabled={toggling === d.id}
                          >
                            <FontAwesomeIcon icon={faCircleCheck} style={{marginRight:4}}/>Reactivate
                          </button>
                        )}
                        <button className="ib ib-edit" onClick={()=>openEdit(d)}>
                          <FontAwesomeIcon icon={faPencil} style={{marginRight:4}}/>Edit
                        </button>
                        <button className="ib ib-del" onClick={()=>setDelItem(d)}>
                          <FontAwesomeIcon icon={faTrash} style={{marginRight:4}}/>Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ── ENROLL ── */}
      {enrollOpen && (
        <Modal title="+ Enroll New Driver" onClose={()=>setEnrollOpen(false)}>
          <div className="box-info">Driver will be saved to PostgreSQL. An AES-256 QR sticker is auto-generated and logged.</div>
          {formFields}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={()=>setEnrollOpen(false)}>Cancel</button>
            <button className="btn btn-green" onClick={enroll} disabled={saving}>{saving?'Enrolling...':'✅ Enroll & Generate QR'}</button>
          </div>
        </Modal>
      )}

      {/* ── EDIT ── */}
      {editItem && (
        <Modal title={`Edit: ${capitalizeName(editItem.name)}`} onClose={()=>setEditItem(null)}>
          <div className="box-info">Changes saved to PostgreSQL and logged to Audit Trail.</div>
          {formFields}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={()=>setEditItem(null)}>Cancel</button>
            <button className="btn btn-green" onClick={saveEdit} disabled={saving}>{saving?'Saving...':'Save Changes'}</button>
          </div>
        </Modal>
      )}

      {/* ── SUSPEND CONFIRM ── */}
      {suspendItem && (
        <Modal
          title={suspendItem.status === 'Active' ? 'Suspend Driver' : 'Reactivate Driver'}
          onClose={()=>setSuspendItem(null)}
        >
          {suspendItem.status === 'Active' ? (
            <div style={{background:'#fff8e1',border:'1px solid #f59e0b',borderRadius:10,padding:'14px 16px',marginBottom:16,fontSize:'.88rem',color:'#78350f',lineHeight:1.7}}>
              Are you sure you want to suspend <strong>{capitalizeName(suspendItem.name)}</strong> ({suspendItem.franchise})?<br/>
              Their account will be <strong>deactivated</strong> and they won't be able to log in until reactivated.<br/>
              This action is logged to the Audit Trail.
            </div>
          ) : (
            <div style={{background:'#f0fdf4',border:'1px solid #86efac',borderRadius:10,padding:'14px 16px',marginBottom:16,fontSize:'.88rem',color:'#14532d',lineHeight:1.7}}>
              Reactivate <strong>{capitalizeName(suspendItem.name)}</strong> ({suspendItem.franchise})?<br/>
              Their account will be restored and they can log in again.<br/>
              This action is logged to the Audit Trail.
            </div>
          )}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={()=>setSuspendItem(null)}>Cancel</button>
            {suspendItem.status === 'Active' ? (
              <button onClick={confirmSuspend} disabled={toggling === suspendItem.id}
                style={{background:'#d97706',color:'#fff',border:'none',borderRadius:8,padding:'8px 18px',fontWeight:700,cursor:'pointer'}}>
                <FontAwesomeIcon icon={faBan} style={{marginRight:6}}/>
                {toggling === suspendItem.id ? 'Suspending...' : 'Yes, Suspend Driver'}
              </button>
            ) : (
              <button onClick={confirmSuspend} disabled={toggling === suspendItem.id}
                style={{background:'var(--green)',color:'#fff',border:'none',borderRadius:8,padding:'8px 18px',fontWeight:700,cursor:'pointer'}}>
                <FontAwesomeIcon icon={faCircleCheck} style={{marginRight:6}}/>
                {toggling === suspendItem.id ? 'Reactivating...' : 'Yes, Reactivate Driver'}
              </button>
            )}
          </div>
        </Modal>
      )}

      {/* ── DELETE CONFIRM ── */}
      {delItem && (
        <Modal title="Delete Driver" onClose={()=>setDelItem(null)}>
          <div style={{background:'#fee2e2',border:'1px solid #fca5a5',borderRadius:10,padding:'14px 16px',marginBottom:16,fontSize:'.88rem',color:'#7f1d1d',lineHeight:1.7}}>
            Are you sure you want to delete <strong>{capitalizeName(delItem.name)}</strong> ({delItem.franchise})?<br/>
            Their QR Code will be revoked and this action will be logged to the Audit Trail.<br/>
            <strong>This cannot be undone.</strong>
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={()=>setDelItem(null)}>Cancel</button>
            <button onClick={remove} style={{background:'#dc2626',color:'#fff',border:'none',borderRadius:8,padding:'8px 18px',fontWeight:700,cursor:'pointer'}}>
              Yes, Delete Driver
            </button>
          </div>
        </Modal>
      )}

      {/* ── QR MODAL ── */}
      {qrSelected && (
        <div onClick={closeQR} style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.55)', display:'flex', alignItems:'center', justifyContent:'center', zIndex:9999, padding:'24px' }}>
          <div onClick={e=>e.stopPropagation()} style={{ background:'#fff', borderRadius:'20px', width:'320px', overflow:'hidden', boxShadow:'0 24px 60px rgba(0,0,0,0.2)' }}>
            <div style={{ background:'#2d5a1b', padding:'16px 20px', textAlign:'center' }}>
              <div style={{ fontSize:'18px', fontWeight:'bold', color:'#fff' }}>eTODA Nagcarlan</div>
              <div style={{ fontSize:'12px', color:'rgba(255,255,255,0.75)', marginTop:'2px' }}>Official Driver QR Code</div>
            </div>
            <div style={{ padding:'24px 20px', textAlign:'center' }}>
              {qrDataUrl ? (
                <div style={{ display:'inline-block', padding:'12px', border:'2px solid #2d5a1b', borderRadius:'12px', marginBottom:'16px' }}>
                  <img src={qrDataUrl} alt="QR Code" style={{ display:'block', width:'160px', height:'160px' }} />
                </div>
              ) : (
                <div style={{ width:'160px', height:'160px', margin:'0 auto 16px', display:'flex', alignItems:'center', justifyContent:'center', color:'#aaa', fontSize:'13px' }}>Generating...</div>
              )}
              <div style={{ fontSize:'16px', fontWeight:'bold', color:'#1a1a1a', marginBottom:'4px' }}>{qrSelected.driver_name}</div>
              <div style={{ fontSize:'13px', color:'#555', marginBottom:'4px' }}>Franchise: {qrSelected.franchise}</div>
              <div style={{ fontSize:'10px', fontFamily:'monospace', color:'#999', marginBottom:'14px', wordBreak:'break-all' }}>{qrSelected.qr_id}</div>
              <div style={{ display:'inline-flex', alignItems:'center', gap:'6px', background:'#e8f5e9', borderRadius:'20px', padding:'5px 14px', marginBottom:'20px' }}>
                <div style={{ width:'8px', height:'8px', borderRadius:'50%', background:'#2d5a1b' }} />
                <span style={{ fontSize:'12px', color:'#2d5a1b', fontWeight:'600' }}>Active · AES-256 Encrypted</span>
              </div>
              <div style={{ display:'flex', gap:'8px', marginBottom:'8px' }}>
                <button onClick={printSticker} style={{ flex:1, padding:'11px', fontSize:'13px', fontWeight:'700', borderRadius:'10px', cursor:'pointer', background:'#2d5a1b', color:'#fff', border:'none' }}>
                  <FontAwesomeIcon icon={faPrint} style={{marginRight:'6px'}}/>Print Sticker
                </button>
                <button onClick={downloadQR} style={{ flex:1, padding:'11px', fontSize:'13px', fontWeight:'600', borderRadius:'10px', cursor:'pointer', background:'#f5f5f5', color:'#333', border:'1px solid #e0e0e0' }}>
                  <FontAwesomeIcon icon={faDownload} style={{marginRight:'6px'}}/>Download
                </button>
              </div>
              <button onClick={closeQR} style={{ width:'100%', padding:'10px', fontSize:'13px', fontWeight:'700', borderRadius:'10px', cursor:'pointer', background:'#fee2e2', color:'#dc2626', border:'1px solid #fca5a5' }}>
                <FontAwesomeIcon icon={faTimes} style={{marginRight:'6px'}}/>Close
              </button>
            </div>
            <div style={{ background:'#f9f9f9', borderTop:'1px solid #eee', padding:'8px 16px', textAlign:'center' }}>
              <span style={{ fontSize:'11px', color:'#aaa' }}>Nagcarlan LGU · eTODA System · Issued {qrSelected.issued_at}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Drivers;