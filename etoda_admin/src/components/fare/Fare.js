// src/components/fare/Fare.js
import React, { useState, useEffect, useRef, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faSearch, faSort, faSortUp, faSortDown, faFileExport, faFileImport, faPencil, faTrash, faMoneyBillWave } from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';

function Fare({ notify }) {
  const [data,        setData]        = useState([]);
  const [loading,     setLoading]     = useState(true);
  const [addOpen,     setAddOpen]     = useState(false);
  const [editOpen,    setEditOpen]    = useState(false);
  const [editTarget,  setEditTarget]  = useState(null);
  const [uploadOpen,  setUploadOpen]  = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [saving,      setSaving]      = useState(false);
  const [uploading,   setUploading]   = useState(false);
  const [fileRows,    setFileRows]    = useState([]);
  const [excludedRows,setExcludedRows]= useState(new Set()); // rows unchecked in preview
  const [fileError,   setFileError]   = useState('');
  const [fileName,    setFileName]    = useState('');
  const [search,      setSearch]      = useState('');
  const [sortKey,     setSortKey]     = useState('origin');
  const [sortDir,     setSortDir]     = useState('asc');
  const [selected,    setSelected]    = useState(new Set());
  const [bulkDelOpen, setBulkDelOpen] = useState(false);
  const [bulkDeleting,setBulkDeleting]= useState(false);
  const fileRef = useRef(null);

  const [newRows,       setNewRows]       = useState([]);
  const [overwriteRows, setOverwriteRows] = useState([]);

  const BLANK = { origin:'', destination:'', base_fare:'' };
  const [form,     setForm]     = useState(BLANK);
  const [editForm, setEditForm] = useState(BLANK);

  const load = async () => {
    setLoading(true);
    const r = await api('/api/fare');
    if (r.success) setData(r.data||[]);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  // ── Search + Sort ──
  const filtered = useMemo(() => {
    let rows = [...data];
    if (search.trim()) {
      const q = search.toLowerCase();
      rows = rows.filter(f =>
        f.origin.toLowerCase().includes(q) ||
        f.destination.toLowerCase().includes(q)
      );
    }
    rows.sort((a, b) => {
      let av = a[sortKey], bv = b[sortKey];
      if (typeof av === 'string') av = av.toLowerCase();
      if (typeof bv === 'string') bv = bv.toLowerCase();
      if (av < bv) return sortDir === 'asc' ? -1 : 1;
      if (av > bv) return sortDir === 'asc' ? 1 : -1;
      return 0;
    });
    return rows;
  }, [data, search, sortKey, sortDir]);

  const handleSort = key => {
    if (sortKey === key) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    else { setSortKey(key); setSortDir('asc'); }
  };

  const SortIcon = ({ col }) => {
    if (sortKey !== col) return <FontAwesomeIcon icon={faSort} style={{ marginLeft: 4, opacity: 0.3, fontSize: 10 }} />;
    return <FontAwesomeIcon icon={sortDir === 'asc' ? faSortUp : faSortDown} style={{ marginLeft: 4, color: 'var(--green)', fontSize: 10 }} />;
  };

  // ── Bulk select (table) ──
  const allFilteredIds = filtered.map(f => f.id);
  const allChecked     = allFilteredIds.length > 0 && allFilteredIds.every(id => selected.has(id));
  const someChecked    = allFilteredIds.some(id => selected.has(id));

  const toggleAll = () => {
    if (allChecked) {
      setSelected(prev => { const n = new Set(prev); allFilteredIds.forEach(id => n.delete(id)); return n; });
    } else {
      setSelected(prev => { const n = new Set(prev); allFilteredIds.forEach(id => n.add(id)); return n; });
    }
  };

  const toggleOne = id => {
    setSelected(prev => { const n = new Set(prev); n.has(id) ? n.delete(id) : n.add(id); return n; });
  };

  const deselectAll = () => setSelected(new Set());

  // ── Bulk delete ──
  const doBulkDelete = async () => {
    setBulkDeleting(true);
    let ok = 0, fail = 0;
    for (const id of selected) {
      const r = await api(`/api/fare/${id}`, 'DELETE');
      if (r.success) ok++; else fail++;
    }
    setBulkDeleting(false);
    setBulkDelOpen(false);
    setSelected(new Set());
    load();
    notify(`Deleted ${ok} route(s)${fail ? `, ${fail} failed` : ''}`, 'warn');
  };

  // ── Export CSV ──
  const exportCSV = () => {
    if (data.length === 0) {
      notify('No fare routes to export.', 'error');
      return;
    }
    const header = 'origin,destination,base_fare,discounted_fare,night_fare,special_fare';
    const rows = data.map(f =>
      `${f.origin},${f.destination},${f.base_fare},${f.discounted_fare},${f.night_fare},${f.special_fare}`
    );
    const csv = [header, ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `fare_matrix_${new Date().toISOString().slice(0,10)}.csv`;
    a.click();
    notify('Fare matrix exported ✅', 'success');
  };

  // ── Add ──
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

  // ── Edit ──
  const openEdit = (f) => {
    setEditTarget(f);
    setEditForm({ origin: f.origin, destination: f.destination, base_fare: String(f.base_fare) });
    setEditOpen(true);
  };

  const saveEdit = async () => {
    if (!editForm.base_fare || parseFloat(editForm.base_fare) <= 0) {
      notify('Base fare must be greater than 0','error'); return;
    }
    setSaving(true);
    const r = await api('/api/fare','POST',{
      origin: editTarget.origin,
      destination: editTarget.destination,
      base_fare: parseFloat(editForm.base_fare),
    });
    setSaving(false);
    if (r.success) {
      setEditOpen(false); setEditTarget(null); load();
      notify(`${editTarget.origin} → ${editTarget.destination} updated ✅`);
    } else notify(r.error||'Failed','error');
  };

  // ── Single delete ──
  const del = async (id, label) => {
    if (!window.confirm(`Delete "${label}"?`)) return;
    const r = await api(`/api/fare/${id}`,'DELETE');
    if (r.success) {
      setSelected(prev => { const n = new Set(prev); n.delete(id); return n; });
      load();
      notify(`"${label}" deleted`,'warn');
    }
  };

  // ── File parsing ──
  const parseCSV = text => {
    const lines = text.split('\n').map(l=>l.trim()).filter(Boolean);
    const rows = [];
    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i].split(',').map(c=>c.trim().replace(/^"|"$/g,''));
      if (cols.length < 3) continue;
      const [origin, destination, raw] = cols;
      const base = parseFloat(raw);
      if (!origin||!destination||isNaN(base)||base<=0) return { error: `Row ${i+1} is invalid: "${lines[i]}"` };
      rows.push({ origin, destination, base_fare: base });
    }
    return rows.length ? { rows } : { error: 'No valid rows found.' };
  };

  const parseExcel = (buffer) => {
    try {
      const XLSX = window.XLSX;
      if (!XLSX) return { error: 'Excel library not loaded yet.' };
      const wb = XLSX.read(buffer, { type: 'array' });
      const ws = wb.Sheets[wb.SheetNames[0]];
      const raw = XLSX.utils.sheet_to_json(ws, { header: 1, defval: '' });
      if (raw.length < 2) return { error: 'Spreadsheet is empty.' };
      const rows = [];
      for (let i = 1; i < raw.length; i++) {
        const [origin, destination, baseFare] = raw[i].map(c => String(c).trim());
        if (!origin && !destination) continue;
        const base = parseFloat(baseFare);
        if (!origin||!destination||isNaN(base)||base<=0) return { error: `Row ${i+1} is invalid.` };
        rows.push({ origin, destination, base_fare: base });
      }
      return rows.length ? { rows } : { error: 'No valid rows found.' };
    } catch(e) { return { error: 'Could not read file: ' + e.message }; }
  };

  const handleFile = e => {
    setFileError(''); setFileRows([]); setFileName('');
    setExcludedRows(new Set()); // reset exclusions on new file
    const file = e.target.files[0];
    if (!file) return;
    setFileName(file.name);
    const ext = file.name.split('.').pop().toLowerCase();
    if (ext === 'csv') {
      const reader = new FileReader();
      reader.onload = ev => { const r = parseCSV(ev.target.result); if (r.error) { setFileError(r.error); return; } setFileRows(r.rows); };
      reader.readAsText(file);
    } else if (ext === 'xlsx' || ext === 'xls') {
      const reader = new FileReader();
      reader.onload = ev => { const r = parseExcel(new Uint8Array(ev.target.result)); if (r.error) { setFileError(r.error); return; } setFileRows(r.rows); };
      reader.readAsArrayBuffer(file);
    } else {
      setFileError('Unsupported file type.');
    }
  };

  // Only upload rows that are checked (not excluded)
  const activeFileRows = fileRows.filter((_, i) => !excludedRows.has(i));

  const handleUploadClick = () => {
    if (activeFileRows.length === 0) {
      notify('No routes selected to upload.', 'error');
      return;
    }
    const existing = new Set(data.map(d => `${d.origin.toLowerCase()}|${d.destination.toLowerCase()}`));
    const willOverwrite = activeFileRows.filter(r => existing.has(`${r.origin.toLowerCase()}|${r.destination.toLowerCase()}`));
    const willAdd = activeFileRows.filter(r => !existing.has(`${r.origin.toLowerCase()}|${r.destination.toLowerCase()}`));
    setOverwriteRows(willOverwrite);
    setNewRows(willAdd);
    if (willOverwrite.length > 0) setConfirmOpen(true);
    else doUpload(activeFileRows);
  };

  const doUpload = async (rows) => {
    setConfirmOpen(false);
    setUploading(true);
    let ok = 0, fail = 0;
    for (const row of rows) {
      const r = await api('/api/fare','POST',row);
      if (r.success) ok++; else fail++;
    }
    setUploading(false);
    setUploadOpen(false);
    setFileRows([]); setFileError(''); setFileName('');
    setNewRows([]); setOverwriteRows([]);
    setExcludedRows(new Set());
    if (fileRef.current) fileRef.current.value = '';
    load();
    notify(`Uploaded ${ok} route(s)${fail?`, ${fail} failed`:''} ✅`, fail?'warn':'success');
  };

  const base     = parseFloat(form.base_fare)||0;
  const editBase = parseFloat(editForm.base_fare)||0;

  const formatDate = (str) => {
    if (!str) return '—';
    const d = new Date(str);
    if (isNaN(d)) return str;
    return d.toLocaleDateString('en-PH', { year:'numeric', month:'short', day:'numeric' });
  };

  // Preview: select/deselect all in file rows
  const allPreviewChecked = fileRows.length > 0 && excludedRows.size === 0;
  const toggleAllPreview  = () => {
    if (allPreviewChecked) {
      setExcludedRows(new Set(fileRows.map((_, i) => i)));
    } else {
      setExcludedRows(new Set());
    }
  };

  return (
    <div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faMoneyBillWave} style={{ marginRight: 8, color: 'var(--gold)' }} />
            Fare Matrix <span>(Discounted / Night / Special auto-calculated)</span>
          </div>
          <div className="card-actions">
            <button className="btn btn-ghost btn-sm" onClick={() => { setFileRows([]); setFileError(''); setFileName(''); setExcludedRows(new Set()); setUploadOpen(true); }}>
              <FontAwesomeIcon icon={faFileImport} style={{ marginRight: 6 }} />Import Tariff
            </button>
            <button className="btn btn-ghost btn-sm" onClick={exportCSV}>
              <FontAwesomeIcon icon={faFileExport} style={{ marginRight: 6 }} />Export CSV
            </button>
            <button className="btn btn-green" onClick={() => { setForm(BLANK); setAddOpen(true); }}>
              + Add Route
            </button>
          </div>
        </div>

        {/* Search bar */}
        <div style={{ padding: '12px 18px 0', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: 320 }}>
            <FontAwesomeIcon icon={faSearch} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: '#aaa', fontSize: 12 }} />
            <input
              type="text" placeholder="Search origin or destination..."
              value={search} onChange={e => setSearch(e.target.value)}
              style={{ width: '100%', padding: '7px 10px 7px 30px', border: '1.5px solid var(--gray2)', borderRadius: 8, fontSize: '.85rem', outline: 'none', boxSizing: 'border-box' }}
            />
          </div>
          {search && <span style={{ fontSize: '.8rem', color: 'var(--gray)' }}>{filtered.length} result{filtered.length !== 1 ? 's' : ''}</span>}
          <span style={{ fontSize: '.8rem', color: 'var(--gray)', marginLeft: 'auto' }}>{data.length} routes</span>
        </div>

        {loading ? <Loading/> : data.length===0 ? <Empty/> : (
          <>
            {/* Bulk action bar */}
            {selected.size > 0 && (
              <div style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '8px 18px',
                background: '#fef2f2',
                borderTop: '1px solid #fecaca',
                borderBottom: '1px solid #fecaca',
                marginTop: 12,
              }}>
                <span style={{ fontSize: '.85rem', color: '#7f1d1d', fontWeight: 600 }}>
                  {selected.size} route{selected.size !== 1 ? 's' : ''} selected
                </span>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <button onClick={deselectAll}
                    style={{ fontSize: '.8rem', color: 'var(--gray)', background: 'none', border: '1px solid var(--gray2)', borderRadius: 6, padding: '4px 12px', cursor: 'pointer' }}>
                    Deselect all
                  </button>
                  <button onClick={() => setBulkDelOpen(true)}
                    style={{ fontSize: '.8rem', color: '#7f1d1d', background: '#fee2e2', border: '1px solid #fca5a5', borderRadius: 6, padding: '4px 12px', cursor: 'pointer', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                    <FontAwesomeIcon icon={faTrash} style={{ fontSize: 11 }} />
                    Delete {selected.size} routes
                  </button>
                </div>
              </div>
            )}

            <div className="tbl-wrap">
              <table>
                <thead>
                  <tr>
                    <th style={{ width: 40, textAlign: 'center', paddingRight: 0 }}>
                      <input type="checkbox" checked={allChecked}
                        ref={el => { if (el) el.indeterminate = someChecked && !allChecked; }}
                        onChange={toggleAll} style={{ cursor: 'pointer', width: 14, height: 14 }}
                      />
                    </th>
                    <th onClick={() => handleSort('origin')} style={{ cursor: 'pointer', userSelect: 'none' }}>Origin <SortIcon col="origin" /></th>
                    <th onClick={() => handleSort('destination')} style={{ cursor: 'pointer', userSelect: 'none' }}>Destination <SortIcon col="destination" /></th>
                    <th onClick={() => handleSort('base_fare')} style={{ cursor: 'pointer', userSelect: 'none' }}>Base <SortIcon col="base_fare" /></th>
                    <th>Discounted (−20%)</th>
                    <th>Night (+15%)</th>
                    <th>Special (×3)</th>
                    <th>Last Updated</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.length === 0 ? (
                    <tr><td colSpan={9} style={{ textAlign: 'center', padding: '24px', color: 'var(--gray)' }}>No routes match "{search}"</td></tr>
                  ) : filtered.map(f => (
                    <tr key={f.id} style={{ background: selected.has(f.id) ? '#fff5f5' : undefined }}>
                      <td style={{ textAlign: 'center', paddingRight: 0 }}>
                        <input type="checkbox" checked={selected.has(f.id)} onChange={() => toggleOne(f.id)} style={{ cursor: 'pointer', width: 14, height: 14 }} />
                      </td>
                      <td><strong>{f.origin}</strong></td>
                      <td>{f.destination}</td>
                      <td><strong>₱{Number(f.base_fare).toFixed(2)}</strong></td>
                      <td>₱{Number(f.discounted_fare).toFixed(2)}</td>
                      <td>₱{Number(f.night_fare).toFixed(2)}</td>
                      <td>₱{Number(f.special_fare).toFixed(2)}</td>
                      <td style={{ fontSize: '.82rem', color: 'var(--gray)' }}>{formatDate(f.created_at)}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '.82rem' }}>
                          <button onClick={() => openEdit(f)}
                            style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--green)', fontWeight: 600, padding: 0, display: 'flex', alignItems: 'center', gap: 4 }}>
                            <FontAwesomeIcon icon={faPencil} style={{ fontSize: 11 }} />Edit
                          </button>
                          <span style={{ color: 'var(--gray2)' }}>·</span>
                          <button onClick={() => del(f.id, `${f.origin} → ${f.destination}`)}
                            style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#dc2626', fontWeight: 600, padding: 0 }}>
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>

      {/* ── BULK DELETE CONFIRM ── */}
      {bulkDelOpen && (
        <Modal title="Delete Selected Routes" onClose={() => setBulkDelOpen(false)}>
          <div style={{ background: '#fee2e2', border: '1px solid #fca5a5', borderRadius: 10, padding: '14px 16px', marginBottom: 16, fontSize: '.88rem', color: '#7f1d1d', lineHeight: 1.6 }}>
            You are about to delete <strong>{selected.size} route(s)</strong>. This cannot be undone.
          </div>
          <div className="tbl-wrap" style={{ maxHeight: 200, overflowY: 'auto', border: '1px solid #fca5a5', borderRadius: 7, marginBottom: 14 }}>
            <table>
              <thead><tr><th>Origin</th><th>Destination</th><th>Base Fare</th></tr></thead>
              <tbody>
                {data.filter(f => selected.has(f.id)).map(f => (
                  <tr key={f.id} style={{ background: '#fff5f5' }}>
                    <td>{f.origin}</td><td>{f.destination}</td>
                    <td style={{ color: '#dc2626', fontWeight: 600 }}>₱{Number(f.base_fare).toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setBulkDelOpen(false)}>Cancel</button>
            <button onClick={doBulkDelete} disabled={bulkDeleting}
              style={{ background: '#dc2626', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 18px', fontWeight: 700, cursor: 'pointer' }}>
              {bulkDeleting ? 'Deleting...' : `Yes, Delete ${selected.size} Routes`}
            </button>
          </div>
        </Modal>
      )}

      {/* ── ADD ROUTE ── */}
      {addOpen && (
        <Modal title="Add Fare Route" onClose={() => setAddOpen(false)}>
          <div className="box-info">Discounted (−20%), Night (+15%), Special (×3) are auto-calculated.</div>
          <div className="form-row">
            <div className="field">
              <label>Origin *</label>
              <input value={form.origin} onChange={e=>setForm(p=>({...p,origin:e.target.value}))} placeholder="Poblacion"/>
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
          {base > 0 && (
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:8,marginBottom:16}}>
              {[['Discounted',(base*.8).toFixed(2),'var(--green)'],['Night',(base*1.15).toFixed(2),'var(--blue)'],['Special',(base*3).toFixed(2),'var(--ora)']].map(([l,v,c])=>(
                <div key={l} style={{background:'var(--bg)',borderRadius:7,padding:'10px 12px',textAlign:'center'}}>
                  <div style={{fontSize:'.65rem',color:'var(--gray)',textTransform:'uppercase',marginBottom:3}}>{l}</div>
                  <div style={{fontWeight:700,color:c,fontSize:'1.1rem'}}>₱{v}</div>
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

      {/* ── EDIT ROUTE ── */}
      {editOpen && editTarget && (
        <Modal title={`Edit: ${editTarget.origin} → ${editTarget.destination}`} onClose={() => setEditOpen(false)}>
          <div className="box-info">Only base fare can be edited. Origin and destination are fixed.</div>
          <div style={{ display: 'flex', gap: 12, marginBottom: 14 }}>
            <div style={{ flex: 1, background: 'var(--bg)', borderRadius: 7, padding: '10px 12px' }}>
              <div style={{ fontSize: '.7rem', color: 'var(--gray)', textTransform: 'uppercase', marginBottom: 2 }}>Origin</div>
              <div style={{ fontWeight: 600 }}>{editTarget.origin}</div>
            </div>
            <div style={{ flex: 1, background: 'var(--bg)', borderRadius: 7, padding: '10px 12px' }}>
              <div style={{ fontSize: '.7rem', color: 'var(--gray)', textTransform: 'uppercase', marginBottom: 2 }}>Destination</div>
              <div style={{ fontWeight: 600 }}>{editTarget.destination}</div>
            </div>
          </div>
          <div className="field">
            <label>Base Fare (₱) *</label>
            <input type="number" min="1" step="0.5" value={editForm.base_fare} onChange={e => setEditForm(p => ({ ...p, base_fare: e.target.value }))} />
          </div>
          {editBase > 0 && (
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:8,marginBottom:16}}>
              {[['Discounted',(editBase*.8).toFixed(2),'var(--green)'],['Night',(editBase*1.15).toFixed(2),'var(--blue)'],['Special',(editBase*3).toFixed(2),'var(--ora)']].map(([l,v,c])=>(
                <div key={l} style={{background:'var(--bg)',borderRadius:7,padding:'10px 12px',textAlign:'center'}}>
                  <div style={{fontSize:'.65rem',color:'var(--gray)',textTransform:'uppercase',marginBottom:3}}>{l}</div>
                  <div style={{fontWeight:700,color:c,fontSize:'1.1rem'}}>₱{v}</div>
                </div>
              ))}
            </div>
          )}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEditOpen(false)}>Cancel</button>
            <button className="btn btn-green" onClick={saveEdit} disabled={saving}>{saving?'Saving...':'Save Changes'}</button>
          </div>
        </Modal>
      )}

      {/* ── IMPORT TARIFF ── */}
      {uploadOpen && (
        <Modal title="Import Tariff" onClose={() => { setUploadOpen(false); setFileRows([]); setFileError(''); setFileName(''); setExcludedRows(new Set()); }}>
          <div className="box-blue">
            Upload a <strong>.csv</strong> or <strong>.xlsx / .xls</strong> file.<br/>
            Required columns: <code>origin</code>, <code>destination</code>, <code>base_fare</code><br/>
            Existing routes will be <strong>updated</strong>. New routes will be <strong>added</strong>.
          </div>
          <div className="field">
            <label>Select File (.csv, .xlsx, .xls)</label>
            <input type="file" accept=".csv,.xlsx,.xls" ref={fileRef} onChange={handleFile}
              style={{padding:'8px',border:'1.5px solid var(--gray2)',borderRadius:7,background:'#fff',fontFamily:'inherit',fontSize:'.83rem'}}
            />
          </div>
          {fileName && !fileError && fileRows.length===0 && <div className="box-warn">Reading "{fileName}"...</div>}
          {fileError && <div className="box-red">⚠️ {fileError}</div>}

          {fileRows.length > 0 && (
            <>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                <div style={{ fontWeight: 600, fontSize: '.83rem', color: 'var(--green)' }}>
                  ✅ {activeFileRows.length} of {fileRows.length} route(s) selected
                </div>
                {excludedRows.size > 0 && (
                  <span style={{ fontSize: '.78rem', color: 'var(--gray)' }}>
                    {excludedRows.size} excluded
                  </span>
                )}
              </div>

              <div className="tbl-wrap" style={{ maxHeight: 220, overflowY: 'auto', border: '1px solid var(--gray2)', borderRadius: 7, marginBottom: 12 }}>
                <table>
                  <thead>
                    <tr>
                      <th style={{ width: 36, textAlign: 'center' }}>
                        <input type="checkbox"
                          checked={allPreviewChecked}
                          ref={el => { if (el) el.indeterminate = !allPreviewChecked && excludedRows.size < fileRows.length; }}
                          onChange={toggleAllPreview}
                          style={{ cursor: 'pointer', width: 14, height: 14 }}
                        />
                      </th>
                      <th>Origin</th>
                      <th>Destination</th>
                      <th>Base</th>
                      <th>Disc.</th>
                      <th>Night</th>
                      <th>Special</th>
                    </tr>
                  </thead>
                  <tbody>
                    {fileRows.map((row, i) => {
                      const isExisting = data.some(d =>
                        d.origin.toLowerCase() === row.origin.toLowerCase() &&
                        d.destination.toLowerCase() === row.destination.toLowerCase()
                      );
                      const excluded = excludedRows.has(i);
                      return (
                        <tr key={i} style={{
                          background: excluded ? '#f5f5f5' : isExisting ? '#fff8e1' : 'transparent',
                          opacity: excluded ? 0.45 : 1,
                          transition: 'opacity 0.15s',
                        }}>
                          <td style={{ textAlign: 'center' }}>
                            <input type="checkbox"
                              checked={!excluded}
                              onChange={() => {
                                setExcludedRows(prev => {
                                  const n = new Set(prev);
                                  n.has(i) ? n.delete(i) : n.add(i);
                                  return n;
                                });
                              }}
                              style={{ cursor: 'pointer', width: 14, height: 14 }}
                            />
                          </td>
                          <td>{row.origin}</td>
                          <td>{row.destination}</td>
                          <td>₱{row.base_fare.toFixed(2)}</td>
                          <td>₱{(row.base_fare*.8).toFixed(2)}</td>
                          <td>₱{(row.base_fare*1.15).toFixed(2)}</td>
                          <td>₱{(row.base_fare*3).toFixed(2)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>

              {/* Yellow row legend */}
              {data.some(d => fileRows.some(r =>
                r.origin.toLowerCase() === d.origin.toLowerCase() &&
                r.destination.toLowerCase() === d.destination.toLowerCase()
              )) && (
                <div style={{ display:'flex', alignItems:'center', gap:8, background:'#fff8e1', border:'1px solid #f59e0b', borderRadius:8, padding:'8px 12px', marginBottom:12, fontSize:'.8rem', color:'#92400e' }}>
                  <span>⚠️</span><span><strong>Yellow rows</strong> already exist and will be updated.</span>
                </div>
              )}
            </>
          )}

          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => { setUploadOpen(false); setFileRows([]); setFileError(''); setFileName(''); setExcludedRows(new Set()); }}>Cancel</button>
            <button className="btn btn-green" onClick={handleUploadClick} disabled={uploading || activeFileRows.length === 0}>
              {uploading ? 'Uploading...' : activeFileRows.length > 0 ? `Upload ${activeFileRows.length} Routes` : 'Select routes to upload'}
            </button>
          </div>
        </Modal>
      )}

      {/* ── OVERWRITE CONFIRMATION ── */}
      {confirmOpen && (
        <Modal title="⚠️ Confirm Price Update" onClose={() => setConfirmOpen(false)}>
          <div style={{ background:'#fff8e1', border:'1px solid #f59e0b', borderRadius:10, padding:'14px 16px', marginBottom:16, fontSize:'.88rem', color:'#78350f', lineHeight:1.6 }}>
            <strong>{overwriteRows.length} existing route(s)</strong> will have their prices updated. This cannot be undone.
          </div>
          {overwriteRows.length > 0 && (
            <>
              <div style={{ fontWeight:600, fontSize:'.82rem', color:'#d97706', marginBottom:6 }}>🔄 Routes to be updated ({overwriteRows.length}):</div>
              <div className="tbl-wrap" style={{ maxHeight:160, overflowY:'auto', border:'1px solid #fde68a', borderRadius:7, marginBottom:14 }}>
                <table>
                  <thead><tr><th>Origin</th><th>Destination</th><th>Old Price</th><th>New Price</th></tr></thead>
                  <tbody>
                    {overwriteRows.map((row,i) => {
                      const old = data.find(d => d.origin.toLowerCase()===row.origin.toLowerCase() && d.destination.toLowerCase()===row.destination.toLowerCase());
                      return (
                        <tr key={i} style={{ background:'#fffbeb' }}>
                          <td>{row.origin}</td><td>{row.destination}</td>
                          <td style={{ color:'#dc2626', fontWeight:600 }}>₱{old?Number(old.base_fare).toFixed(2):'—'}</td>
                          <td style={{ color:'#2d5a1b', fontWeight:600 }}>₱{row.base_fare.toFixed(2)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </>
          )}
          {newRows.length > 0 && (
            <>
              <div style={{ fontWeight:600, fontSize:'.82rem', color:'var(--green)', marginBottom:6 }}>✅ New routes to be added ({newRows.length}):</div>
              <div className="tbl-wrap" style={{ maxHeight:130, overflowY:'auto', border:'1px solid #bbf7d0', borderRadius:7, marginBottom:14 }}>
                <table>
                  <thead><tr><th>Origin</th><th>Destination</th><th>Base Fare</th></tr></thead>
                  <tbody>
                    {newRows.map((row,i) => (
                      <tr key={i} style={{ background:'#f0fdf4' }}>
                        <td>{row.origin}</td><td>{row.destination}</td>
                        <td style={{ color:'#2d5a1b', fontWeight:600 }}>₱{row.base_fare.toFixed(2)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setConfirmOpen(false)}>Cancel</button>
            <button className="btn btn-green" onClick={() => doUpload(activeFileRows)} disabled={uploading}>
              {uploading ? 'Uploading...' : `Yes, Update ${overwriteRows.length} & Add ${newRows.length}`}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export default Fare;