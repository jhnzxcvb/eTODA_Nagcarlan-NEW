import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faSearch, faMapMarkerAlt, faPencil, faTrash, faPlus, faEye
} from '@fortawesome/free-solid-svg-icons';
import { api } from '../../lib/api';
import Loading from '../ui/Loading';
import Empty from '../ui/Empty';
import Modal from '../ui/Modal';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import Cropper from 'react-easy-crop';

// ── Image Cropping Helpers ──
const createImage = (url) =>
  new Promise((resolve, reject) => {
    const image = new Image();
    image.addEventListener('load', () => resolve(image));
    image.addEventListener('error', (error) => reject(error));
    image.setAttribute('crossOrigin', 'anonymous');
    image.src = url;
  });

async function getCroppedImg(imageSrc, pixelCrop) {
  const image = await createImage(imageSrc);
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  if (!ctx) return null;

  canvas.width = pixelCrop.width;
  canvas.height = pixelCrop.height;

  // Create a circular clipping path for transparent corners
  ctx.beginPath();
  ctx.arc(pixelCrop.width / 2, pixelCrop.height / 2, pixelCrop.width / 2, 0, Math.PI * 2);
  ctx.closePath();
  ctx.clip();

  ctx.drawImage(image, pixelCrop.x, pixelCrop.y, pixelCrop.width, pixelCrop.height, 0, 0, pixelCrop.width, pixelCrop.height);

  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (!blob) { reject(new Error('Canvas is empty')); return; }
      resolve(new File([blob], 'cropped-logo.png', { type: 'image/png' }));
    }, 'image/png');
  });
}

// Fix for default Leaflet marker icons in React
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';
let DefaultIcon = L.icon({
  iconUrl: icon,
  shadowUrl: iconShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41]
});
L.Marker.prototype.options.icon = DefaultIcon;

// Map Event Component to capture clicks and set coordinates
function LocationPicker({ position, setPosition }) {
  useMapEvents({
    click(e) {
      setPosition({ lat: e.latlng.lat, lng: e.latlng.lng });
    },
  });
  return position && position.lat && position.lng ? (
    <Marker position={[position.lat, position.lng]} />
  ) : null;
}

const BLANK = { name: '', lat: 14.1333, lng: 121.4167, logoFile: null, logoPreview: null, color: '#16a34a' }; // Default Nagcarlan coordinates
const PRESET_COLORS = ['#16a34a', '#3b82f6', '#ef4444', '#f97316', '#a855f7', '#14b8a6', '#f59e0b', '#64748b'];

export default function TodaStations({ notify }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [addOpen, setAddOpen] = useState(false);
  const [editItem, setEditItem] = useState(null);
  const [delItem, setDelItem] = useState(null);
  const [viewItem, setViewItem] = useState(null);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState(BLANK);

  const [cropImageSrc, setCropImageSrc] = useState(null);
  const [crop, setCrop] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const [croppedAreaPixels, setCroppedAreaPixels] = useState(null);
  const [fetchTime, setFetchTime] = useState(Date.now());

  const load = useCallback(async (q = '') => {
    setLoading(true);
    // Assumes your backend will have this endpoint configured
    const r = await api(`/api/stations${q ? `?search=${encodeURIComponent(q)}` : ''}`);
    if (r.success) {
      setData(r.data || []);
      setFetchTime(Date.now()); // Update cache-buster to instantly display new images
    }
    // else notify(r.error, 'error'); // Uncomment if backend is fully implemented
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    const t = setTimeout(() => { load(search); }, 300);
    return () => clearTimeout(t);
  }, [search, load]);

  const filtered = useMemo(() => {
    if (!search) return data;
    const s = search.toLowerCase();
    return data.filter(d => d.name?.toLowerCase().includes(s));
  }, [data, search]);

  const saveAdd = async () => {
    if (!form.name.trim()) { notify("Station Name is required", "error"); return; }
    setSaving(true);
    
    const payload = new FormData();
    payload.append('name', form.name.trim());
    payload.append('lat', form.lat);
    payload.append('lng', form.lng);
    payload.append('color', form.color || '#16a34a');
    if (form.logoFile) payload.append('logo', form.logoFile);

    const r = await api('/api/stations', 'POST', payload);
    setSaving(false);
    
    if (r.success) {
      setAddOpen(false); setForm(BLANK); load(search);
      notify('TODA Station added successfully', 'success');
    } else {
      notify(r.error || 'Failed to add station', 'error');
    }
  };

  const saveEdit = async () => {
    if (!form.name.trim()) { notify("Station Name is required", "error"); return; }
    setSaving(true);
    
    const payload = new FormData();
    payload.append('name', form.name.trim());
    payload.append('lat', form.lat);
    payload.append('lng', form.lng);
    payload.append('color', form.color || '#16a34a');
    
    if (form.logoFile) {
      payload.append('logo', form.logoFile);
    } else if (!form.logoPreview && editItem?.logo) {
      payload.append('remove_logo', 'true');
      payload.append('logo', '');
    }

    const r = await api(`/api/stations/${editItem.id}`, 'PATCH', payload);
    setSaving(false);
    
    if (r.success) {
      setEditItem(null); load(search);
      notify('TODA Station updated successfully', 'success');
    } else {
      notify(r.error || 'Failed to update station', 'error');
    }
  };

  const remove = async () => {
    const r = await api(`/api/stations/${delItem.id}`, 'DELETE');
    if (r.success) {
      setDelItem(null); load(search);
      notify(`Station has been deleted.`, 'success');
    } else {
      notify(r.error || 'Failed to delete station', 'error');
    }
  };

  const getImageUrl = (logo) => logo ? (logo.startsWith('http') ? logo : `http://localhost:8080/uploads/${logo}?v=${fetchTime}`) : null;

  const openAdd = () => { setForm(BLANK); setAddOpen(true); };
  const openEdit = (s) => {
    setEditItem(s);
    setForm({ name: s.name || '', lat: s.lat || 14.1333, lng: s.lng || 121.4167, logoFile: null, logoPreview: s.logo ? getImageUrl(s.logo) : null, color: s.color || '#16a34a' });
  };

  const onFileChange = (e) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      const reader = new FileReader();
      reader.addEventListener('load', () => setCropImageSrc(reader.result));
      reader.readAsDataURL(file);
      e.target.value = ''; // Reset so the same file can be selected again
    }
  };

  const handleCropSave = async () => {
    try {
      const croppedFile = await getCroppedImg(cropImageSrc, croppedAreaPixels);
      setForm(p => ({ ...p, logoFile: croppedFile, logoPreview: URL.createObjectURL(croppedFile) }));
      setCropImageSrc(null); setCrop({ x: 0, y: 0 }); setZoom(1);
    } catch (e) {
      console.error(e);
      notify('Failed to crop image', 'error');
    }
  };

  const hasChanges = editItem && (
    form.name !== (editItem.name || '') ||
    form.lat !== (editItem.lat || 14.1333) ||
    form.lng !== (editItem.lng || 121.4167) ||
    form.color !== (editItem.color || '#16a34a') ||
    form.logoFile !== null ||
    // Check if the logo was removed (preview is gone but original existed)
    (form.logoPreview === null && editItem.logo)
  );

  return (
    <div>
      <div className="card">
        <div className="card-head" style={{ display: "flex", flexWrap: "wrap", gap: "12px", justifyContent: "space-between", alignItems: "center" }}>
          <div className="card-title" style={{ whiteSpace: "nowrap" }}>
            <FontAwesomeIcon icon={faMapMarkerAlt} style={{ marginRight: 8, color: "var(--gold)" }} />
            TODA Stations <span>({filtered.length})</span>
          </div>
          <div className="card-actions" style={{ display: "flex", flexWrap: "wrap", gap: "8px", flex: "1 1 300px", justifyContent: "flex-end" }}>
            <div style={{ position: "relative", flex: "1 1 200px", maxWidth: "300px" }}>
              <FontAwesomeIcon icon={faSearch} style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)", color: "#aaa", fontSize: 12, pointerEvents: "none" }} />
              <input className="search-box" style={{ width: "100%", paddingLeft: 30, boxSizing: "border-box" }} placeholder="Search stations..." value={search} onChange={e => setSearch(e.target.value)} />
            </div>
            <button className="btn btn-green" onClick={openAdd} style={{ whiteSpace: "nowrap" }}>
              <FontAwesomeIcon icon={faPlus} style={{ marginRight: 6 }} /> Add Station
            </button>
          </div>
        </div>

        {loading ? <Loading /> : data.length === 0 ? <Empty /> : (
          <div className="tbl-wrap" style={{ overflowX: "auto", WebkitOverflowScrolling: "touch" }}>
            <table style={{ width: "100%", minWidth: 600, whiteSpace: "nowrap" }}>
              <thead>
                <tr>
                  <th style={{ width: "10%" }}>ID</th>
                  <th style={{ width: "5%", textAlign: "center" }}>Color</th>
                  <th style={{ width: "8%", textAlign: "center" }}>Logo</th>
                  <th style={{ width: "30%" }}>Station Name</th>
                  <th style={{ width: "20%" }}>Latitude</th>
                  <th style={{ width: "20%" }}>Longitude</th>
                  <th style={{ width: "auto" }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(s => (
                  <tr key={s.id}>
                    <td><strong>{s.id}</strong></td>
                    <td style={{ textAlign: "center" }}>
                      <div style={{ width: 24, height: 24, borderRadius: '50%', backgroundColor: s.color || '#16a34a', display: 'inline-block', border: '2px solid rgba(0,0,0,0.1)' }} title={s.color} />
                    </td>
                    <td style={{ textAlign: "center" }}>
                      {s.logo ? <img src={getImageUrl(s.logo)} alt="Logo" style={{ width: 28, height: 28, borderRadius: "50%", objectFit: "cover", border: "1px solid var(--gray2)" }} /> : <span style={{ color: "var(--gray2)" }}>—</span>}
                    </td>
                    <td><strong>{s.name}</strong></td>
                    <td style={{ color: "var(--gray)", fontSize: ".85rem" }}>{Number(s.lat).toFixed(6)}</td>
                    <td style={{ color: "var(--gray)", fontSize: ".85rem" }}>{Number(s.lng).toFixed(6)}</td>
                    <td>
                      <div className="row-actions" style={{ display: "flex", flexWrap: "nowrap", gap: "6px" }}>
                        <button className="ib ib-edit" onClick={() => setViewItem(s)}>
                          <FontAwesomeIcon icon={faEye} style={{ marginRight: 4, fontSize: 11 }} />View
                        </button>
                        <button className="ib ib-edit" onClick={() => openEdit(s)}>
                          <FontAwesomeIcon icon={faPencil} style={{ marginRight: 4, fontSize: 11 }} />Edit
                        </button>
                        <button className="ib ib-del" onClick={() => setDelItem(s)}>
                          <FontAwesomeIcon icon={faTrash} style={{ marginRight: 4, fontSize: 11 }} />Delete
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

      {/* ── ADD MODAL ── */}
      {addOpen && (
        <Modal title="Add TODA Station" onClose={() => setAddOpen(false)}>
          <div className="form-row" style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
            <div className="field" style={{ flex: "1 1 200px" }}>
              <label>Station Name *</label>
              <input value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} placeholder="e.g. Nagcarlan Public Market" />
            </div>
            <div className="field" style={{ flex: "0 0 auto" }}>
              <label>Pin Color</label>
              <div style={{ display: "flex", alignItems: "center", gap: 8, height: 38 }}>
                {PRESET_COLORS.map(c => (
                  <div
                    key={c}
                    onClick={() => setForm(p => ({ ...p, color: c }))}
                    style={{ width: 24, height: 24, borderRadius: "50%", backgroundColor: c, cursor: "pointer", border: form.color === c ? "2px solid #1a1a1a" : "1px solid rgba(0,0,0,0.15)", transform: form.color === c ? "scale(1.15)" : "scale(1)", transition: "all 0.15s" }}
                    title={c}
                  />
                ))}
                <div style={{ width: 1, height: 24, backgroundColor: "var(--gray2)", margin: "0 2px" }} />
                <input type="color" value={form.color} onChange={e => setForm(p => ({ ...p, color: e.target.value }))} style={{ width: 34, height: 34, padding: 0, cursor: "pointer", border: "1px solid var(--gray2)", borderRadius: 6, background: "#fff" }} title="Custom Color" />
              </div>
            </div>
          </div>
          <div className="field" style={{ marginTop: 12 }}>
            <label>Station Logo Image <span style={{ fontWeight: 400, color: "var(--gray)", fontSize: ".72rem" }}>(optional)</span></label>
            <input 
              type="file" 
              accept="image/*" 
              onChange={onFileChange} 
              style={{ padding: "8px", border: "1.5px solid var(--gray2)", borderRadius: "8px", width: "100%", boxSizing: "border-box", fontSize: ".85rem" }}
            />
            {form.logoPreview && (
              <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 12 }}>
                <img src={form.logoPreview} alt="Logo Preview" style={{ width: 50, height: 50, borderRadius: "50%", objectFit: "cover", border: "2px solid var(--green)", background: "#fff" }} />
                <button type="button" onClick={() => setForm(p => ({ ...p, logoFile: null, logoPreview: null }))} style={{ fontSize: ".75rem", color: "#dc2626", background: "#fee2e2", border: "none", padding: "4px 10px", borderRadius: 6, cursor: "pointer", fontWeight: "bold" }}>Remove</button>
              </div>
            )}
          </div>
          <div className="field" style={{ marginTop: 12 }}>
            <label>Pin Location *</label>
            <div style={{ fontSize: '.75rem', color: 'var(--gray)', marginBottom: 8 }}>Click on the map to place the station pin.</div>
            <div style={{ height: 300, width: '100%', borderRadius: 8, overflow: 'hidden', border: '1px solid var(--gray2)' }}>
              <MapContainer center={[form.lat, form.lng]} zoom={15} style={{ height: '100%', width: '100%' }}>
                <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                <LocationPicker position={{ lat: form.lat, lng: form.lng }} setPosition={(pos) => setForm(p => ({ ...p, lat: pos.lat, lng: pos.lng }))} />
              </MapContainer>
            </div>
            <div style={{ display: 'flex', gap: '10px', marginTop: 8 }}>
              <div style={{ flex: 1, fontSize: '.75rem', color: 'var(--gray)' }}>Lat: <strong>{Number(form.lat).toFixed(6)}</strong></div>
              <div style={{ flex: 1, fontSize: '.75rem', color: 'var(--gray)' }}>Lng: <strong>{Number(form.lng).toFixed(6)}</strong></div>
            </div>
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setAddOpen(false)}>Cancel</button>
            <button className="btn btn-green" onClick={saveAdd} disabled={saving}>{saving ? "Saving..." : "Add Station"}</button>
          </div>
        </Modal>
      )}

      {/* ── EDIT MODAL ── */}
      {editItem && (
        <Modal title={`Edit Station: ${editItem.name}`} onClose={() => setEditItem(null)}>
          <div className="form-row" style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
            <div className="field" style={{ flex: "1 1 200px" }}>
              <label>Station Name *</label>
              <input value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} placeholder="e.g. Nagcarlan Public Market" />
            </div>
            <div className="field" style={{ flex: "0 0 auto" }}>
              <label>Pin Color</label>
              <div style={{ display: "flex", alignItems: "center", gap: 8, height: 38 }}>
                {PRESET_COLORS.map(c => (
                  <div
                    key={c}
                    onClick={() => setForm(p => ({ ...p, color: c }))}
                    style={{ width: 24, height: 24, borderRadius: "50%", backgroundColor: c, cursor: "pointer", border: form.color === c ? "2px solid #1a1a1a" : "1px solid rgba(0,0,0,0.15)", transform: form.color === c ? "scale(1.15)" : "scale(1)", transition: "all 0.15s" }}
                    title={c}
                  />
                ))}
                <div style={{ width: 1, height: 24, backgroundColor: "var(--gray2)", margin: "0 2px" }} />
                <input type="color" value={form.color} onChange={e => setForm(p => ({ ...p, color: e.target.value }))} style={{ width: 34, height: 34, padding: 0, cursor: "pointer", border: "1px solid var(--gray2)", borderRadius: 6, background: "#fff" }} title="Custom Color" />
              </div>
            </div>
          </div>
          <div className="field" style={{ marginTop: 12 }}>
            <label>Update Station Logo <span style={{ fontWeight: 400, color: "var(--gray)", fontSize: ".72rem" }}>(optional)</span></label>
            <input 
              type="file" 
              accept="image/*" 
              onChange={onFileChange} 
              style={{ padding: "8px", border: "1.5px solid var(--gray2)", borderRadius: "8px", width: "100%", boxSizing: "border-box", fontSize: ".85rem" }}
            />
            {form.logoPreview && (
              <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 12 }}>
                <img src={form.logoPreview} alt="Logo Preview" style={{ width: 50, height: 50, borderRadius: "50%", objectFit: "cover", border: "2px solid var(--green)", background: "#fff" }} />
                <button type="button" onClick={() => setForm(p => ({ ...p, logoFile: null, logoPreview: null }))} style={{ fontSize: ".75rem", color: "#dc2626", background: "#fee2e2", border: "none", padding: "4px 10px", borderRadius: 6, cursor: "pointer", fontWeight: "bold" }}>Remove</button>
              </div>
            )}
          </div>
          <div className="field" style={{ marginTop: 12 }}>
            <label>Update Pin Location</label>
            <div style={{ fontSize: '.75rem', color: 'var(--gray)', marginBottom: 8 }}>Click on the map to update the station pin.</div>
            <div style={{ height: 300, width: '100%', borderRadius: 8, overflow: 'hidden', border: '1px solid var(--gray2)' }}>
              <MapContainer center={[form.lat, form.lng]} zoom={15} style={{ height: '100%', width: '100%' }}>
                <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                <LocationPicker position={{ lat: form.lat, lng: form.lng }} setPosition={(pos) => setForm(p => ({ ...p, lat: pos.lat, lng: pos.lng }))} />
              </MapContainer>
            </div>
            <div style={{ display: 'flex', gap: '10px', marginTop: 8 }}>
              <div style={{ flex: 1, fontSize: '.75rem', color: 'var(--gray)' }}>Lat: <strong>{Number(form.lat).toFixed(6)}</strong></div>
              <div style={{ flex: 1, fontSize: '.75rem', color: 'var(--gray)' }}>Lng: <strong>{Number(form.lng).toFixed(6)}</strong></div>
            </div>
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEditItem(null)}>Cancel</button>
            <button className="btn btn-green" onClick={saveEdit} disabled={saving || !hasChanges}>{saving ? "Saving..." : "Save Changes"}</button>
          </div>
        </Modal>
      )}

      {/* ── DELETE MODAL ── */}
      {delItem && (
        <Modal title="Delete Station" onClose={() => setDelItem(null)}>
          <div style={{ background: "#fee2e2", border: "1px solid #fca5a5", borderRadius: 10, padding: "14px 16px", marginBottom: 16, fontSize: ".88rem", color: "#7f1d1d", lineHeight: 1.7 }}>
            Are you sure you want to delete <strong>{delItem.name}</strong>?<br />
            This action will remove it from the map and cannot be undone.
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setDelItem(null)}>Cancel</button>
            <button onClick={remove} style={{ background: "#dc2626", color: "#fff", border: "none", borderRadius: 8, padding: "8px 18px", fontWeight: 700, cursor: "pointer" }}>Yes, Delete</button>
          </div>
        </Modal>
      )}

      {/* ── VIEW MODAL ── */}
      {viewItem && (
        <Modal title="Station Location Details" onClose={() => setViewItem(null)}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '16px' }}>
            {viewItem.logo ? (
              <img src={getImageUrl(viewItem.logo)} alt="Logo" style={{ width: 60, height: 60, borderRadius: "50%", objectFit: "cover", border: "2px solid var(--green)" }} />
            ) : (
              <div style={{ width: 60, height: 60, borderRadius: "50%", background: "#f0fdf4", border: "2px solid var(--green)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <FontAwesomeIcon icon={faMapMarkerAlt} style={{ color: "var(--green)", fontSize: 24 }} />
              </div>
            )}
            <div>
              <div style={{ fontSize: "1.1rem", fontWeight: "bold", color: "#1a1a1a" }}>{viewItem.name}</div>
              <div style={{ fontSize: ".85rem", color: "var(--gray)" }}>Coordinates: {Number(viewItem.lat).toFixed(6)}, {Number(viewItem.lng).toFixed(6)}</div>
            </div>
          </div>
          <div style={{ height: 300, width: '100%', borderRadius: 8, overflow: 'hidden', border: '1px solid var(--gray2)' }}>
            <MapContainer center={[viewItem.lat, viewItem.lng]} zoom={16} style={{ height: '100%', width: '100%' }}>
              <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
              <Marker position={[viewItem.lat, viewItem.lng]} />
            </MapContainer>
          </div>
          <div className="modal-footer" style={{ marginTop: 16 }}>
            <button className="btn btn-ghost" onClick={() => setViewItem(null)}>Close</button>
          </div>
        </Modal>
      )}

      {/* ── CROP MODAL ── */}
      {cropImageSrc && (
        <Modal title="Crop Logo (Circle)" onClose={() => setCropImageSrc(null)}>
          <div style={{ position: 'relative', width: '100%', height: 320, background: '#333', borderRadius: 8, overflow: 'hidden' }}>
            <Cropper
              image={cropImageSrc}
              crop={crop}
              zoom={zoom}
              aspect={1}
              cropShape="round"
              showGrid={false}
              onCropChange={setCrop}
              onCropComplete={(croppedArea, croppedAreaPixels) => setCroppedAreaPixels(croppedAreaPixels)}
              onZoomChange={setZoom}
            />
          </div>
          <div style={{ padding: '16px 8px 0 8px', display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: '.8rem', color: 'var(--gray)', fontWeight: 600 }}>Zoom</span>
            <input type="range" value={zoom} min={1} max={3} step={0.1} aria-labelledby="Zoom" onChange={(e) => setZoom(e.target.value)} style={{ flex: 1, accentColor: 'var(--green)' }} />
          </div>
          <div className="modal-footer" style={{ marginTop: 24 }}>
            <button className="btn btn-ghost" onClick={() => setCropImageSrc(null)}>Cancel</button>
            <button className="btn btn-green" onClick={handleCropSave}>Apply Crop</button>
          </div>
        </Modal>
      )}
    </div>
  );
}