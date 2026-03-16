// src/components/payments/Payments.js
import React, { useState, useEffect } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';

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

export default Payments;