// src/components/audit/Audit.js
import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

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
                <div style={{fontFamily:'Roboto',fontWeight:700,fontSize:'1rem'}}>{viewItem.action}</div>
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

export default Audit;