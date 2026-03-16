// src/components/passengers/Passengers.js
import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';

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

export default Passengers;