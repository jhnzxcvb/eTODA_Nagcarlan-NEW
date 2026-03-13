// src/components/fare/Fare.js
import React, { useState, useEffect, useRef } from 'react';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

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
                  <div style={{fontFamily:'Roboto',fontWeight:700,color:c,fontSize:'1.1rem'}}>₱{v}</div>
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

export default Fare;