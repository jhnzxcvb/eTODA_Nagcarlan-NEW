// src/components/qrcodes/QRCodes.js
import React, { useState, useEffect } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';

function QRCodes({ notify }) {
  const [data,setData]=useState([]);
  const [loading,setLoading]=useState(true);
  const load=async()=>{setLoading(true);const r=await api('/api/qrcodes');if(r.success)setData(r.data||[]);setLoading(false);};
  useEffect(()=>{load();},[]);
  const update=async(id,status)=>{const r=await api(`/api/qrcodes/${id}`,'PATCH',{status});if(r.success){load();notify(`QR → ${status}`,status==='Active'?'success':'warn');}};
  return(
    <div>
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

export default QRCodes;