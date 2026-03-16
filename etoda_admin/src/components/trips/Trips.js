// src/components/trips/Trips.js
import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import DG from '../ui/DetailGrid';

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

export default Trips;