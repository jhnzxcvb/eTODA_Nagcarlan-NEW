import { useState, useEffect, useCallback, useRef } from 'react';

const BASE = 'http://localhost:8080';

async function api(path, method = 'GET', body = null) {
  try {
    const opts = { method, headers: {} };
    if (body) { opts.headers['Content-Type'] = 'application/json'; opts.body = JSON.stringify(body); }
    const r = await fetch(BASE + path, opts);
    return r.json();
  } catch {
    return { success: false, error: 'Cannot reach Go server on port 8080.' };
  }
}

function useToast() {
  const [toasts, setToasts] = useState([]);
  const n = useRef(0);
  const notify = useCallback((msg, type = 'success') => {
    const id = ++n.current;
    setToasts(p => [...p, { id, msg, type }]);
    setTimeout(() => setToasts(p => p.filter(t => t.id !== id)), 3800);
  }, []);
  const dismiss = id => setToasts(p => p.filter(t => t.id !== id));
  return { toasts, notify, dismiss };
}

function Toasts({ toasts, dismiss }) {
  const CLS  = { success:'toast-success', error:'toast-error', warn:'toast-warn', info:'toast-info' };
  const ICON = { success:'✅', error:'❌', warn:'⚠️', info:'ℹ️' };
  return (
    <div className="toast-wrap">
      {toasts.map(t => (
        <div key={t.id} className={`toast ${CLS[t.type]||'toast-success'}`} onClick={() => dismiss(t.id)}>
          <span>{ICON[t.type]}</span><span>{t.msg}</span>
        </div>
      ))}
    </div>
  );
}

function Modal({ title, onClose, children }) {
  return (
    <div className="overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal">
        <div className="modal-head">
          <div className="modal-title">{title}</div>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        {children}
      </div>
    </div>
  );
}

function DG({ rows }) {
  return (
    <div className="detail-grid">
      {rows.map(([k, v]) => (
        <div key={k}><div className="detail-key">{k}</div><div className="detail-val">{v||'—'}</div></div>
      ))}
    </div>
  );
}

const Loading = () => <div className="loading"><div className="spinner"/>Loading from database...</div>;
const Empty   = ({ msg='No records found' }) => <div className="empty">📭 {msg}</div>;

/* ── VIOLATION TYPES (replacing Colorum) ── */
const VIOLATIONS = [
  'Overcharging',
  'Underpayment of Fare',
  'Rude / Discourteous Behavior',
  'Reckless Driving',
  'Refusal to Convey Passenger',
  'Unauthorized Route Deviation',
  'No Receipt / No QR Scan',
  'Vehicle Not Roadworthy',
  'No Franchise Plate Displayed',
  'Driver Under the Influence',
  'Sexual Harassment',
  'Lost Item / Theft',
  'Other Violation',
];

/* ══════════════════════════════════════════════════════════════
   APP
══════════════════════════════════════════════════════════════ */
export default function App() {
  const [panel, setPanel] = useState('dashboard');
  const { toasts, notify, dismiss } = useToast();

  const NAV = [
    ['dashboard',  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>, 'Dashboard'],
    ['drivers',    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>, 'Drivers'],
    ['passengers', <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>, 'Passengers'],
    ['fare',       <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>, 'Fare Matrix'],
    ['payments',   <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>, 'Payments'],
    ['qrcodes',    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="5" height="5"/><rect x="16" y="3" width="5" height="5"/><rect x="3" y="16" width="5" height="5"/><path d="M21 16h-3v3"/><path d="M21 21h-3"/><path d="M12 3v3"/><path d="M12 9v3"/><path d="M12 15v6"/></svg>, 'QR Codes'],
    ['complaints', <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>, 'Complaints'],
    ['trips',      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>, 'Trip History'],
    ['audit',      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>, 'Audit Trail'],
  ];
  const TITLE = Object.fromEntries(NAV.map(([id,,l]) => [id, l]));

  return (
    <div className="app">
      <aside className="sb">
        <div className="sb-brand">
          <div className="sb-logo">e<span>TODA</span></div>
          <div className="sb-tag">Nagcarlan Admin</div>
        </div>
        <nav style={{paddingTop:8}}>
          <div className="sb-sec">Navigation</div>
          {NAV.map(([id, icon, lbl]) => (
            <button key={id} className={`sb-btn${panel===id?' active':''}`} onClick={() => setPanel(id)}>
              <span className="sb-ico">{icon}</span>{lbl}
            </button>
          ))}
        </nav>
        <div className="sb-foot">
          <div className="sb-av">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" width="18" height="18"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>
          </div>
          <div>
            <div style={{fontSize:'.81rem',color:'#fff',fontWeight:600}}>TODA Admin</div>
            <div style={{fontSize:'.67rem',color:'rgba(255,255,255,.4)'}}>Administrator</div>
          </div>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div>
            <div className="tb-title">{TITLE[panel]}</div>
            <div className="tb-sub">eTODA Nagcarlan Management System</div>
          </div>
          <div className="tb-right">
            <div style={{display:'flex',alignItems:'center',gap:6,fontSize:'.74rem',color:'var(--gray)'}}>
              <div className="sync-dot"/><span>Go + PostgreSQL</span>
            </div>
            <div style={{fontSize:'.74rem',color:'var(--gray)'}}>
              {new Date().toLocaleDateString('en-PH',{weekday:'short',month:'short',day:'numeric'})}
            </div>
          </div>
        </header>
        <div className="content">
          {panel==='dashboard'  && <Dashboard  notify={notify}/>}
          {panel==='drivers'    && <Drivers    notify={notify}/>}
          {panel==='passengers' && <Passengers notify={notify}/>}
          {panel==='fare'       && <Fare       notify={notify}/>}
          {panel==='payments'   && <Payments   notify={notify}/>}
          {panel==='qrcodes'    && <QRCodes    notify={notify}/>}
          {panel==='complaints' && <Complaints notify={notify}/>}
          {panel==='trips'      && <Trips      notify={notify}/>}
          {panel==='audit'      && <Audit      notify={notify}/>}
        </div>
      </div>
      <Toasts toasts={toasts} dismiss={dismiss}/>
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   DASHBOARD
══════════════════════════════════════════════════════════════ */
function Dashboard({ notify }) {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/dashboard');
    if (r.success) setStats(r.data); else notify(r.error,'error');
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const CARDS = stats ? [
    {val:stats.active_drivers,    lbl:'Active Drivers',   sub:'Registered',  color:'var(--green)'},
    {val:stats.trips_today,       lbl:'Trips Today',      sub:'Completed',   color:'var(--blue)'},
    {val:`₱${Number(stats.revenue_today).toLocaleString()}`,lbl:'Revenue Today',sub:'Settled',color:'var(--ora)'},
    {val:stats.pending_complaints,lbl:'Open Complaints',  sub:'Needs action',color:'var(--red)'},
    {val:stats.total_drivers,     lbl:'Total Drivers',    sub:'All enrolled', color:'var(--green)'},
    {val:stats.passengers,        lbl:'Total Passengers', sub:'Registered',  color:'#8e44ad'},
    {val:stats.total_trips,       lbl:'Total Trips',      sub:'All time',    color:'var(--blue)'},
    {val:stats.active_qr,         lbl:'Active QR Codes',  sub:'AES-256',     color:'var(--green3)'},
  ] : [];

  return (
    <div>
      {loading ? <Loading/> : (
        <>
          <div className="metrics">
            {CARDS.map((c,i) => (
              <div key={i} className="metric" style={{borderLeftColor:c.color}}>
                <div className="metric-val">{c.val}</div>
                <div className="metric-lbl">{c.lbl}</div>
                <div className="metric-sub">{c.sub}</div>
              </div>
            ))}
          </div>
          <div style={{display:'grid',gridTemplateColumns:'1.4fr 1fr',gap:18}}>
            <div className="card">
              <div className="card-head">
                <div className="card-title">📡 System Status</div>
                <button className="btn btn-ghost btn-sm" onClick={() => { load(); notify('Refreshed','info'); }}>↻ Refresh</button>
              </div>
              <div style={{padding:'14px 18px'}}>
                {[['Go Backend API','Online'],['PostgreSQL Database','Connected'],['AES-256 QR Encryption','Active'],['Firebase Realtime DB','Synced'],['Audit Trail Logging','Enabled']].map(([l,v]) => (
                  <div key={l} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'9px 0',borderBottom:'1px solid var(--gray2)'}}>
                    <span style={{fontSize:'.83rem',fontWeight:500}}>{l}</span>
                    <span className="badge badge-active">{v}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="card">
              <div className="card-head"><div className="card-title">📊 Live Numbers</div></div>
              <div style={{padding:'14px 18px'}}>
                {stats && [
                  ['Active Drivers', stats.active_drivers,   'var(--green)'],
                  ['Trips Today',    stats.trips_today,       'var(--blue)'],
                  ['Active QR',      stats.active_qr,         'var(--green3)'],
                  ['Open Complaints',stats.pending_complaints,'var(--red)'],
                ].map(([l,v,c]) => (
                  <div key={l} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'9px 0',borderBottom:'1px solid var(--gray2)'}}>
                    <span style={{fontSize:'.82rem'}}>{l}</span>
                    <span style={{fontFamily:'Syne',fontWeight:800,color:c,fontSize:'1.15rem'}}>{v}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   DRIVERS
   KEY FIX: form fields are plain JSX variables — NOT inner
   components. Defining them as const FormFields = () => (...)
   inside the parent causes React to unmount+remount the inputs
   on every keystroke (because it sees a new component type each
   render), which resets focus. Using a JSX variable instead
   keeps the same DOM nodes and typing works normally.
══════════════════════════════════════════════════════════════ */
function Drivers({ notify }) {
  const [data,       setData]       = useState([]);
  const [loading,    setLoading]    = useState(true);
  const [search,     setSearch]     = useState('');
  const [enrollOpen, setEnrollOpen] = useState(false);
  const [viewItem,   setViewItem]   = useState(null);
  const [editItem,   setEditItem]   = useState(null);
  const [delItem,    setDelItem]    = useState(null);
  const [saving,     setSaving]     = useState(false);

  const BLANK = { name:'', franchise:'', body_no:'', contact:'', license_no:'', association:'Nagcarlan TODA' };
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
    setForm({ name:d.name, franchise:d.franchise, body_no:d.body_no||'', contact:d.contact||'', license_no:d.license_no||'', association:d.association||'Nagcarlan TODA' });
  };

  /* ── JSX variable (NOT a component) — stable inline onChange handlers ── */
  const formFields = (
    <>
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
      <span className="phase p0">Phase 0 · Admin-Only Driver Registration</span>
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

/* ══════════════════════════════════════════════════════════════
   PASSENGERS
══════════════════════════════════════════════════════════════ */
function Passengers({ notify }) {
  const [data,setData]=useState([]);
  const [loading,setLoading]=useState(true);
  const [search,setSearch]=useState('');
  const [viewItem,setViewItem]=useState(null);

  const load=useCallback(async(q='')=>{
    setLoading(true);
    const r=await api(`/api/passengers${q?`?search=${encodeURIComponent(q)}`:''}`);
    if(r.success)setData(r.data||[]);
    setLoading(false);
  },[]);
  useEffect(()=>{load();},[load]);
  useEffect(()=>{const t=setTimeout(()=>load(search),300);return()=>clearTimeout(t);},[search,load]);

  const toggleSuspend=async p=>{
    const next=p.status==='Suspended'?'Active':'Suspended';
    const r=await api(`/api/passengers/${p.id}`,'PATCH',{status:next});
    if(r.success){load(search);notify(`${p.name||'Passenger'} → ${next}`,next==='Suspended'?'warn':'success');}
  };

  return(
    <div>
      <span className="phase p0">Phase 0 · Passenger Accounts</span>
      <div className="card">
        <div className="card-head">
          <div className="card-title">🧍 Passengers <span>({data.length})</span></div>
          <div className="card-actions">
            <input className="search-box" style={{width:230}} placeholder="🔍 Search name, email, ID..."
              value={search} onChange={e=>setSearch(e.target.value)}/>
          </div>
        </div>
        {loading?<Loading/>:data.length===0?<Empty/>:(
          <div className="tbl-wrap">
            <table>
              <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Registered</th><th>Session</th><th>Status</th><th>Actions</th></tr></thead>
              <tbody>
                {data.map(p=>(
                  <tr key={p.id}>
                    <td><strong>{p.passenger_code}</strong></td>
                    <td>{p.name||'Guest'}</td>
                    <td>{p.email||'—'}</td>
                    <td>{p.registered_at}</td>
                    <td><span className={`badge ${p.session_type==='Guest'?'badge-guest':'badge-active'}`}>{p.session_type}</span></td>
                    <td><span className={`badge ${p.status==='Active'?'badge-active':p.status==='Suspended'?'badge-inactive':'badge-pending'}`}>{p.status}</span></td>
                    <td>
                      <div className="row-actions">
                        <button className="ib ib-view" onClick={()=>setViewItem(p)}>View</button>
                        {p.session_type!=='Guest'&&(
                          <button className={`ib ${p.status==='Suspended'?'ib-edit':'ib-del'}`} onClick={()=>toggleSuspend(p)}>
                            {p.status==='Suspended'?'Restore':'Suspend'}
                          </button>
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
      {viewItem&&(
        <Modal title={`Passenger: ${viewItem.name||'Guest'}`} onClose={()=>setViewItem(null)}>
          <DG rows={[['ID',viewItem.passenger_code],['Name',viewItem.name],['Email',viewItem.email],['Session',viewItem.session_type],['Status',viewItem.status],['Registered',viewItem.registered_at]]}/>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={()=>setViewItem(null)}>Close</button>
            {viewItem.session_type!=='Guest'&&(
              <button className={`btn ${viewItem.status==='Suspended'?'btn-green':'btn-red'}`}
                onClick={()=>{toggleSuspend(viewItem);setViewItem(null);}}>
                {viewItem.status==='Suspended'?'Restore Account':'Suspend Account'}
              </button>
            )}
          </div>
        </Modal>
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   FARE MATRIX — with Upload Tariff (CSV bulk import)
══════════════════════════════════════════════════════════════ */
function Fare({ notify }) {
  const [data,       setData]       = useState([]);
  const [loading,    setLoading]    = useState(true);
  const [addOpen,    setAddOpen]    = useState(false);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [saving,     setSaving]     = useState(false);
  const [uploading,  setUploading]  = useState(false);
  const [fileRows,   setFileRows]   = useState([]);
  const [fileError,  setFileError]  = useState('');
  const [fileName,   setFileName]   = useState('');
  const fileRef = useRef(null);

  const BLANK = { origin:'', destination:'', base_fare:'' };
  const [form, setForm] = useState(BLANK);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/fare');
    if (r.success) setData(r.data||[]);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const addOne = async () => {
    if (!form.origin.trim()||!form.destination.trim()||!form.base_fare) {
      notify('All fields are required','error'); return;
    }
    setSaving(true);
    const r = await api('/api/fare','POST',{ ...form, base_fare: parseFloat(form.base_fare) });
    setSaving(false);
    if (r.success) { setAddOpen(false); setForm(BLANK); load(); notify('Fare route added ✅'); }
    else notify(r.error||'Failed','error');
  };

  const del = async (id, label) => {
    if (!window.confirm(`Delete "${label}"?`)) return;
    const r = await api(`/api/fare/${id}`,'DELETE');
    if (r.success) { load(); notify(`"${label}" deleted`,'warn'); }
  };

  /* ── parse CSV text into rows ── */
  const parseCSV = text => {
    const lines = text.split('\n').map(l=>l.trim()).filter(Boolean);
    const rows = [];
    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i].split(',').map(c=>c.trim().replace(/^"|"$/g,''));
      if (cols.length < 3) continue;
      const [origin, destination, raw] = cols;
      const base = parseFloat(raw);
      if (!origin||!destination||isNaN(base)||base<=0) {
        return { error: `Row ${i+1} is invalid: "${lines[i]}"` };
      }
      rows.push({ origin, destination, base_fare: base });
    }
    return rows.length ? { rows } : { error: 'No valid rows found. Check your file format.' };
  };

  /* ── parse Excel using SheetJS ── */
  const parseExcel = (buffer) => {
    try {
      const XLSX = window.XLSX;
      if (!XLSX) return { error: 'Excel library not loaded yet. Try again in a moment.' };
      const wb = XLSX.read(buffer, { type: 'array' });
      const ws = wb.Sheets[wb.SheetNames[0]];
      const raw = XLSX.utils.sheet_to_json(ws, { header: 1, defval: '' });
      if (raw.length < 2) return { error: 'Spreadsheet is empty or has no data rows.' };
      const rows = [];
      for (let i = 1; i < raw.length; i++) {
        const [origin, destination, baseFare] = raw[i].map(c => String(c).trim());
        if (!origin && !destination) continue; // skip blank rows
        const base = parseFloat(baseFare);
        if (!origin||!destination||isNaN(base)||base<=0) {
          return { error: `Row ${i+1} is invalid. Expected: origin, destination, base_fare` };
        }
        rows.push({ origin, destination, base_fare: base });
      }
      return rows.length ? { rows } : { error: 'No valid rows found in the spreadsheet.' };
    } catch(e) {
      return { error: 'Could not read Excel file: ' + e.message };
    }
  };

  /* ── file picker handler — supports .csv and .xlsx/.xls ── */
  const handleFile = e => {
    setFileError(''); setFileRows([]); setFileName('');
    const file = e.target.files[0];
    if (!file) return;
    setFileName(file.name);
    const ext = file.name.split('.').pop().toLowerCase();

    if (ext === 'csv') {
      const reader = new FileReader();
      reader.onload = ev => {
        const result = parseCSV(ev.target.result);
        if (result.error) { setFileError(result.error); return; }
        setFileRows(result.rows);
      };
      reader.readAsText(file);
    } else if (ext === 'xlsx' || ext === 'xls') {
      const reader = new FileReader();
      reader.onload = ev => {
        const result = parseExcel(new Uint8Array(ev.target.result));
        if (result.error) { setFileError(result.error); return; }
        setFileRows(result.rows);
      };
      reader.readAsArrayBuffer(file);
    } else {
      setFileError('Unsupported file type. Please upload a .csv, .xlsx, or .xls file.');
    }
  };

  /* ── bulk upload ── */
  const uploadTariff = async () => {
    if (fileRows.length===0) return;
    setUploading(true);
    let ok=0, fail=0;
    for (const row of fileRows) {
      const r = await api('/api/fare','POST',row);
      if (r.success) ok++; else fail++;
    }
    setUploading(false);
    setUploadOpen(false); setFileRows([]); setFileError(''); setFileName('');
    if (fileRef.current) fileRef.current.value='';
    load();
    notify(`Uploaded ${ok} route(s)${fail?`, ${fail} failed`:''} ✅`, fail?'warn':'success');
  };

  const base = parseFloat(form.base_fare)||0;

  return (
    <div>
      <span className="phase p2">Phase 2 · Tariff Ordinance</span>
      <div className="card">
        <div className="card-head">
          <div className="card-title">💰 Fare Matrix <span>(Discounted / Night / Special auto-calculated)</span></div>
          <div className="card-actions">
            <button className="btn btn-ghost btn-sm" onClick={() => { setFileRows([]); setFileError(''); setFileName(''); setUploadOpen(true); }}>
              📤 Upload Tariff
            </button>
            <button className="btn btn-green" onClick={() => { setForm(BLANK); setAddOpen(true); }}>
              + Add Route
            </button>
          </div>
        </div>
        {loading ? <Loading/> : data.length===0 ? <Empty/> : (
          <div className="tbl-wrap">
            <table>
              <thead><tr>
                <th>Origin</th><th>Destination</th><th>Base</th>
                <th>Discounted (−20%)</th><th>Night (+15%)</th><th>Special (×3)</th><th>Added</th><th>Actions</th>
              </tr></thead>
              <tbody>
                {data.map(f=>(
                  <tr key={f.id}>
                    <td><strong>{f.origin}</strong></td>
                    <td>{f.destination}</td>
                    <td><strong>₱{Number(f.base_fare).toFixed(2)}</strong></td>
                    <td>₱{Number(f.discounted_fare).toFixed(2)}</td>
                    <td>₱{Number(f.night_fare).toFixed(2)}</td>
                    <td>₱{Number(f.special_fare).toFixed(2)}</td>
                    <td>{f.created_at}</td>
                    <td><button className="ib ib-del" onClick={()=>del(f.id,`${f.origin} → ${f.destination}`)}>Delete</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ADD SINGLE ROUTE */}
      {addOpen && (
        <Modal title="Add Fare Route" onClose={() => setAddOpen(false)}>
          <div className="box-info">Discounted (−20%), Night (+15%), Special (×3) are auto-calculated.</div>
          <div className="form-row">
            <div className="field">
              <label>Origin *</label>
              <input value={form.origin}      onChange={e=>setForm(p=>({...p,origin:e.target.value}))}      placeholder="Poblacion"/>
            </div>
            <div className="field">
              <label>Destination *</label>
              <input value={form.destination} onChange={e=>setForm(p=>({...p,destination:e.target.value}))} placeholder="Talangan"/>
            </div>
          </div>
          <div className="field">
            <label>Base Fare (₱) *</label>
            <input type="number" min="1" step="0.5" value={form.base_fare} onChange={e=>setForm(p=>({...p,base_fare:e.target.value}))} placeholder="15.00"/>
          </div>
          {base>0 && (
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:8,marginBottom:16}}>
              {[['Discounted',(base*.8).toFixed(2),'var(--green)'],['Night',(base*1.15).toFixed(2),'var(--blue)'],['Special',(base*3).toFixed(2),'var(--ora)']].map(([l,v,c])=>(
                <div key={l} style={{background:'var(--bg)',borderRadius:7,padding:'10px 12px',textAlign:'center'}}>
                  <div style={{fontSize:'.65rem',color:'var(--gray)',textTransform:'uppercase',marginBottom:3}}>{l}</div>
                  <div style={{fontFamily:'Syne',fontWeight:800,color:c,fontSize:'1.1rem'}}>₱{v}</div>
                </div>
              ))}
            </div>
          )}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setAddOpen(false)}>Cancel</button>
            <button className="btn btn-green" onClick={addOne} disabled={saving}>{saving?'Adding...':'Add Route'}</button>
          </div>
        </Modal>
      )}

      {/* UPLOAD TARIFF — CSV or Excel */}
      {uploadOpen && (
        <Modal title="📤 Upload Tariff" onClose={() => { setUploadOpen(false); setFileRows([]); setFileError(''); setFileName(''); }}>
          <div className="box-blue">
            Upload a <strong>.csv</strong> or <strong>.xlsx / .xls</strong> file.<br/>
            Required columns (in order): <code>origin</code>, <code>destination</code>, <code>base_fare</code><br/>
            First row is the header — it will be skipped automatically.<br/>
            Existing routes with the same origin + destination will be <strong>updated</strong>.
          </div>

          <div style={{background:'var(--bg)',borderRadius:7,padding:'10px 14px',marginBottom:14,fontSize:'.78rem',lineHeight:1.7}}>
            <div style={{fontWeight:600,fontSize:'.73rem',color:'var(--gray)',marginBottom:4,textTransform:'uppercase',letterSpacing:'.5px'}}>CSV example:</div>
            <code>origin,destination,base_fare</code><br/>
            <code>Poblacion,Talangan,15</code><br/>
            <code>Poblacion,Malinao,20</code><br/>
            <code>Oobi,Banago,30</code>
          </div>

          <div style={{background:'var(--bg)',borderRadius:7,padding:'10px 14px',marginBottom:14,fontSize:'.78rem',lineHeight:1.7}}>
            <div style={{fontWeight:600,fontSize:'.73rem',color:'var(--gray)',marginBottom:4,textTransform:'uppercase',letterSpacing:'.5px'}}>Excel example (columns A, B, C):</div>
            <code>A: origin &nbsp;|&nbsp; B: destination &nbsp;|&nbsp; C: base_fare</code>
          </div>

          <div className="field">
            <label>Select File (.csv, .xlsx, .xls)</label>
            <input
              type="file" accept=".csv,.xlsx,.xls" ref={fileRef} onChange={handleFile}
              style={{padding:'8px',border:'1.5px solid var(--gray2)',borderRadius:7,background:'#fff',fontFamily:'inherit',fontSize:'.83rem'}}
            />
          </div>

          {fileName && !fileError && fileRows.length===0 && (
            <div className="box-warn">Reading "{fileName}"...</div>
          )}

          {fileError && <div className="box-red">⚠️ {fileError}</div>}

          {fileRows.length>0 && (
            <>
              <div style={{marginBottom:8,fontWeight:600,fontSize:'.83rem',color:'var(--green)'}}>
                ✅ {fileRows.length} route(s) ready — preview:
              </div>
              <div className="tbl-wrap" style={{maxHeight:200,overflowY:'auto',border:'1px solid var(--gray2)',borderRadius:7,marginBottom:12}}>
                <table>
                  <thead><tr><th>Origin</th><th>Destination</th><th>Base</th><th>Disc. (−20%)</th><th>Night (+15%)</th><th>Special (×3)</th></tr></thead>
                  <tbody>
                    {fileRows.map((row,i)=>(
                      <tr key={i}>
                        <td>{row.origin}</td>
                        <td>{row.destination}</td>
                        <td>₱{row.base_fare.toFixed(2)}</td>
                        <td>₱{(row.base_fare*.8).toFixed(2)}</td>
                        <td>₱{(row.base_fare*1.15).toFixed(2)}</td>
                        <td>₱{(row.base_fare*3).toFixed(2)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}

          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => { setUploadOpen(false); setFileRows([]); setFileError(''); setFileName(''); }}>Cancel</button>
            <button className="btn btn-green" onClick={uploadTariff} disabled={uploading||fileRows.length===0}>
              {uploading ? 'Uploading...' : fileRows.length>0 ? `Upload ${fileRows.length} Routes` : 'Upload'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   PAYMENTS
══════════════════════════════════════════════════════════════ */
function Payments({ notify }) {
  const [data,setData]=useState([]);
  const [loading,setLoading]=useState(true);
  const [viewItem,setViewItem]=useState(null);

  const load=async()=>{setLoading(true);const r=await api('/api/payments');if(r.success)setData(r.data||[]);setLoading(false);};
  useEffect(()=>{load();},[]);

  const update=async(id,status)=>{
    const r=await api(`/api/payments/${id}`,'PATCH',{status});
    if(r.success){load();notify(`Payment → ${status}`,status==='Refunded'?'warn':'success');}
  };

  const settled=data.filter(p=>p.status==='Settled').reduce((s,p)=>s+Number(p.amount),0);
  const MI={GCash:'💙',Maya:'💚',Card:'💳',Cash:'💵'};
  const SB={Pending:'badge-pending',Settled:'badge-settled',Refunded:'badge-refunded'};

  return(
    <div>
      <span className="phase p1">Phase 1 · Payment Records</span>
      <div className="status-row">
        {[['₱'+settled.toLocaleString(),'Total Settled','var(--green)'],[data.filter(p=>p.status==='Pending').length,'Pending','var(--ora)'],[data.filter(p=>p.status==='Refunded').length,'Refunded','var(--red)'],[data.length,'Total','var(--blue)']].map(([v,l,c])=>(
          <div key={l} className="status-card"><div className="status-val" style={{color:c}}>{v}</div><div className="status-lbl">{l}</div></div>
        ))}
      </div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">💳 Transactions <span>({data.length})</span></div>
          <button className="btn btn-ghost btn-sm" onClick={load}>↻ Refresh</button>
        </div>
        {loading?<Loading/>:data.length===0?<Empty/>:(
          <div className="tbl-wrap">
            <table>
              <thead><tr><th>Ref Code</th><th>Passenger</th><th>Driver</th><th>Route</th><th>Amount</th><th>Method</th><th>Status</th><th>Date</th><th>Actions</th></tr></thead>
              <tbody>
                {data.map(p=>(
                  <tr key={p.id}>
                    <td><strong>{p.ref_code}</strong></td>
                    <td>{p.passenger_name}</td><td>{p.driver_name}</td><td>{p.route}</td>
                    <td><strong>₱{Number(p.amount).toFixed(2)}</strong></td>
                    <td>{MI[p.method]} {p.method}</td>
                    <td><span className={`badge ${SB[p.status]||'badge-pending'}`}>{p.status}</span></td>
                    <td>{p.paid_at}</td>
                    <td>
                      <div className="row-actions">
                        <button className="ib ib-view" onClick={()=>setViewItem(p)}>View</button>
                        {p.status==='Pending'&&<button className="ib ib-resolve" onClick={()=>update(p.id,'Settled')}>Settle</button>}
                        {p.status==='Settled'&&<button className="ib ib-del" onClick={()=>update(p.id,'Refunded')}>Refund</button>}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
      {viewItem&&(
        <Modal title={`Transaction: ${viewItem.ref_code}`} onClose={()=>setViewItem(null)}>
          <DG rows={[['Ref Code',viewItem.ref_code],['Passenger',viewItem.passenger_name],['Driver',viewItem.driver_name],['Route',viewItem.route],['Amount',`₱${Number(viewItem.amount).toFixed(2)}`],['Method',viewItem.method],['Status',viewItem.status],['Date',viewItem.paid_at]]}/>
          <div className="modal-footer"><button className="btn btn-ghost" onClick={()=>setViewItem(null)}>Close</button></div>
        </Modal>
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   QR CODES
══════════════════════════════════════════════════════════════ */
function QRCodes({ notify }) {
  const [data,setData]=useState([]);
  const [loading,setLoading]=useState(true);
  const load=async()=>{setLoading(true);const r=await api('/api/qrcodes');if(r.success)setData(r.data||[]);setLoading(false);};
  useEffect(()=>{load();},[]);
  const update=async(id,status)=>{const r=await api(`/api/qrcodes/${id}`,'PATCH',{status});if(r.success){load();notify(`QR → ${status}`,status==='Active'?'success':'warn');}};
  return(
    <div>
      <span className="phase p0">Phase 0 · QR Code Management (AES-256)</span>
      <div className="box-info">Each QR is AES-256 encrypted. Revoking immediately invalidates it. Restoring generates a brand-new QR ID.</div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">📲 QR Codes <span>({data.length})</span></div>
          <button className="btn btn-ghost btn-sm" onClick={load}>↻ Refresh</button>
        </div>
        {loading?<Loading/>:data.length===0?<Empty/>:(
          <div className="tbl-wrap">
            <table>
              <thead><tr><th>Franchise</th><th>Driver</th><th>QR ID (AES-256)</th><th>Status</th><th>Issued</th><th>Actions</th></tr></thead>
              <tbody>
                {data.map(q=>(
                  <tr key={q.id}>
                    <td><strong>{q.franchise}</strong></td>
                    <td>{q.driver_name}</td>
                    <td style={{fontFamily:'monospace',fontSize:'.75rem',color:'var(--green)'}}>{q.qr_id}</td>
                    <td><span className={`badge ${q.status==='Active'?'badge-active':'badge-inactive'}`}>{q.status}</span></td>
                    <td>{q.issued_at}</td>
                    <td>
                      <div className="row-actions">
                        {q.status==='Active'&&<button className="ib ib-del"  onClick={()=>update(q.id,'Revoked')}>Revoke</button>}
                        {q.status!=='Active'&&<button className="ib ib-edit" onClick={()=>update(q.id,'Active')}>Restore & Regen</button>}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   COMPLAINTS — full edit: status dropdown + notes + resolve
══════════════════════════════════════════════════════════════ */
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
      <span className="phase p3">Phase 3 · Complaints &amp; Violations</span>

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

/* ══════════════════════════════════════════════════════════════
   TRIP HISTORY
══════════════════════════════════════════════════════════════ */
function Trips({ notify }) {
  const [data,setData]=useState([]);
  const [loading,setLoading]=useState(true);
  const [search,setSearch]=useState('');
  const [viewItem,setViewItem]=useState(null);
  const load=useCallback(async(q='')=>{setLoading(true);const r=await api(`/api/trips${q?`?search=${encodeURIComponent(q)}`:''}`);if(r.success)setData(r.data||[]);setLoading(false);},[]);
  useEffect(()=>{load();},[load]);
  useEffect(()=>{const t=setTimeout(()=>load(search),300);return()=>clearTimeout(t);},[search,load]);
  const MI={GCash:'💙',Maya:'💚',Card:'💳',Cash:'💵'};
  return(
    <div>
      <span className="phase p4">Trip History &amp; Logs</span>
      <div className="card">
        <div className="card-head">
          <div className="card-title">🗂️ Trip Logs <span>({data.length} trips)</span></div>
          <div className="card-actions">
            <input className="search-box" style={{width:240}} placeholder="🔍 Search passenger, driver, route..."
              value={search} onChange={e=>setSearch(e.target.value)}/>
          </div>
        </div>
        {loading?<Loading/>:data.length===0?<Empty/>:(
          <div className="tbl-wrap">
            <table>
              <thead><tr><th>Trip Code</th><th>Passenger</th><th>Driver</th><th>Route</th><th>Fare</th><th>Method</th><th>Duration</th><th>Date</th><th></th></tr></thead>
              <tbody>
                {data.map(t=>(
                  <tr key={t.id}>
                    <td><strong>{t.trip_code}</strong></td>
                    <td>{t.passenger_name}</td><td>{t.driver_name}</td><td>{t.route}</td>
                    <td><strong>₱{Number(t.fare_amount).toFixed(2)}</strong></td>
                    <td>{MI[t.payment_method]} {t.payment_method}</td>
                    <td>{t.duration_min} min</td><td>{t.started_at}</td>
                    <td><button className="ib ib-view" onClick={()=>setViewItem(t)}>View</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
      {viewItem&&(
        <Modal title={`Trip: ${viewItem.trip_code}`} onClose={()=>setViewItem(null)}>
          <DG rows={[['Trip Code',viewItem.trip_code],['Passenger',viewItem.passenger_name],['Driver',viewItem.driver_name],['Contact',viewItem.driver_contact],['Route',viewItem.route],['Fare',`₱${Number(viewItem.fare_amount).toFixed(2)}`],['Method',viewItem.payment_method],['Duration',`${viewItem.duration_min} min`],['Date',viewItem.started_at]]}/>
          <div className="modal-footer"><button className="btn btn-ghost" onClick={()=>setViewItem(null)}>Close</button></div>
        </Modal>
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   AUDIT TRAIL
══════════════════════════════════════════════════════════════ */
function Audit({ notify }) {
  const [data,setData]=useState([]);
  const [loading,setLoading]=useState(true);
  const [search,setSearch]=useState('');
  const [entity,setEntity]=useState('All');
  const [viewItem,setViewItem]=useState(null);

  const load=useCallback(async(q='',ent='All')=>{
    setLoading(true);
    const p=new URLSearchParams();
    if(q)p.set('search',q);if(ent!=='All')p.set('entity',ent);
    const r=await api(`/api/audit?${p}`);
    if(r.success)setData(r.data||[]);
    setLoading(false);
  },[]);
  useEffect(()=>{load();},[load]);
  useEffect(()=>{const t=setTimeout(()=>load(search,entity),300);return()=>clearTimeout(t);},[search,entity,load]);

  const AB={ENROLL:'badge-enroll',UPDATE:'badge-update',DELETE:'badge-delete',CREATE:'badge-create',REVOKE:'badge-revoke',RESTORE:'badge-restore'};
  const AI={ENROLL:'➕',UPDATE:'✏️',DELETE:'🗑️',CREATE:'✅',REVOKE:'🚫',RESTORE:'♻️'};
  const ENT=['All','Driver','Passenger','Fare','Payment','QRCode','Complaint'];

  return(
    <div>
      <span className="phase p4">Audit Trail · System Activity Log</span>
      <div className="box-blue">Every admin action is automatically logged here — enroll, edit, delete, resolve, revoke — with timestamp and full details.</div>
      <div className="status-row">
        {[[data.filter(a=>a.action==='ENROLL').length,'Enrollments','var(--green)'],[data.filter(a=>a.action==='UPDATE').length,'Updates','var(--blue)'],[data.filter(a=>a.action==='DELETE').length,'Deletions','var(--red)'],[data.filter(a=>a.action==='REVOKE').length,'Revocations','var(--ora)'],[data.length,'Total Logs','var(--dark)']].map(([v,l,c])=>(
          <div key={l} className="status-card"><div className="status-val" style={{color:c}}>{v}</div><div className="status-lbl">{l}</div></div>
        ))}
      </div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">📋 Audit Logs <span>({data.length} entries)</span></div>
          <div className="card-actions">
            <input className="search-box" style={{width:210}} placeholder="🔍 Search detail, entity ID..."
              value={search} onChange={e=>setSearch(e.target.value)}/>
            <select className="sel-box" value={entity} onChange={e=>setEntity(e.target.value)}>
              {ENT.map(e=><option key={e}>{e}</option>)}
            </select>
            <button className="btn btn-ghost btn-sm" onClick={()=>load(search,entity)}>↻ Refresh</button>
          </div>
        </div>
        {loading?<Loading/>:data.length===0?<Empty msg="No audit logs found"/>:(
          <div className="tbl-wrap">
            <table>
              <thead><tr><th>#</th><th>Action</th><th>Entity</th><th>Entity ID</th><th>Detail</th><th>By</th><th>Timestamp</th><th></th></tr></thead>
              <tbody>
                {data.map(a=>(
                  <tr key={a.id}>
                    <td style={{color:'var(--gray)',fontSize:'.75rem'}}>{a.id}</td>
                    <td><span className={`badge ${AB[a.action]||'badge-inactive'}`}>{AI[a.action]||'•'} {a.action}</span></td>
                    <td>{a.entity}</td>
                    <td><code style={{fontSize:'.78rem',background:'var(--bg)',padding:'2px 6px',borderRadius:4}}>{a.entity_id}</code></td>
                    <td style={{maxWidth:240,whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis'}}>{a.detail}</td>
                    <td><span className="badge badge-active">{a.performed_by}</span></td>
                    <td style={{fontSize:'.78rem',color:'var(--gray)',whiteSpace:'nowrap'}}>{a.created_at}</td>
                    <td><button className="ib ib-view" onClick={()=>setViewItem(a)}>View</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
      {viewItem&&(
        <Modal title={`Audit Log #${viewItem.id}`} onClose={()=>setViewItem(null)}>
          <div style={{background:'var(--bg)',borderRadius:9,padding:16,marginBottom:16}}>
            <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:12}}>
              <span style={{fontSize:'1.5rem'}}>{AI[viewItem.action]||'•'}</span>
              <div>
                <div style={{fontFamily:'Syne',fontWeight:800,fontSize:'1rem'}}>{viewItem.action}</div>
                <div style={{fontSize:'.75rem',color:'var(--gray)'}}>{viewItem.created_at}</div>
              </div>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
              {[['Log ID',`#${viewItem.id}`],['Action',viewItem.action],['Entity',viewItem.entity],['Entity ID',viewItem.entity_id],['Performed By',viewItem.performed_by],['Timestamp',viewItem.created_at]].map(([k,v])=>(
                <div key={k}>
                  <div style={{fontSize:'.64rem',color:'var(--gray)',textTransform:'uppercase',letterSpacing:'.5px',marginBottom:2}}>{k}</div>
                  <div style={{fontWeight:600,fontSize:'.85rem'}}>{v||'—'}</div>
                </div>
              ))}
            </div>
          </div>
          <div className="field">
            <label>Detail / Description</label>
            <div style={{background:'#fff',border:'1.5px solid var(--gray2)',borderRadius:7,padding:'10px 13px',fontSize:'.85rem',minHeight:60}}>
              {viewItem.detail||'—'}
            </div>
          </div>
          <div className="modal-footer"><button className="btn btn-ghost" onClick={()=>setViewItem(null)}>Close</button></div>
        </Modal>
      )}
    </div>
  );
}
