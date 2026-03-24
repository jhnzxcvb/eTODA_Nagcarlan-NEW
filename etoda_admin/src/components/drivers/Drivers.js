// src/components/drivers/Drivers.js
import React, { useState, useEffect, useCallback, useMemo } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faFilter, faSearch, faPencil, faTrash, faUserGroup, faQrcode,
  faPrint, faDownload, faTimes, faBan, faCircleCheck,
  faChevronLeft, faChevronRight, faEye, faEyeSlash,
  faKey, faCopy, faCheck, faRotate, faLockOpen, faLock,
  faCircleInfo, faTriangleExclamation,
} from "@fortawesome/free-solid-svg-icons";
import { api } from "../../lib/api";
import Loading from "../ui/Loading";
import Empty from "../ui/Empty";
import Modal from "../ui/Modal";
import QRCode from "qrcode";

// ── Helpers ──
const buildFullName = (first = "", middle = "", last = "") =>
  [first, middle, last].filter(Boolean).join(" ");

const capitalizeName = (name = "") => name.replace(/\b\w/g, (c) => c.toUpperCase());

const formatDate = (str) => {
  if (!str) return "—";
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString("en-PH", { year: "numeric", month: "short", day: "numeric" });
};

const ADJECTIVES = ["Blue","Red","Fast","Tall","Brave","Calm","Dark","Gold","Iron","Jade","Keen","Lime","Mint","Navy","Pink","Sage","Teal","Wild","Zest","Bold","Cool","Dawn","Epic","Flex","Glow","High","Just","Kind","Lush","Mute"];
const NOUNS      = ["Eagle","River","Stone","Tiger","Mango","Cloud","Flame","Grove","Haven","Jewel","Kite","Lotus","Mesa","Nova","Orbit","Pearl","Quest","Ridge","Storm","Trail","Unity","Vapor","Wave","Arrow","Blaze","Crest","Drift","Echo","Frost","Gleam"];
const SPECIALS   = ["!", "@", "#", "$", "%", "&"];

const generatePassword = () => {
  const adj  = ADJECTIVES[Math.floor(Math.random() * ADJECTIVES.length)];
  const noun = NOUNS[Math.floor(Math.random() * NOUNS.length)];
  const dig  = String(Math.floor(100 + Math.random() * 900));
  const sym  = SPECIALS[Math.floor(Math.random() * SPECIALS.length)];
  return `${adj}${noun}${dig}${sym}`;
};

const getStrength = (pw) => {
  if (!pw) return { score: 0, label: "", color: "#e5e7eb" };
  let s = 0;
  if (pw.length >= 8)           s++;
  if (pw.length >= 12)          s++;
  if (/[A-Z]/.test(pw))         s++;
  if (/[0-9]/.test(pw))         s++;
  if (/[^A-Za-z0-9]/.test(pw)) s++;
  if (s <= 1) return { score: s, label: "Weak",   color: "#dc2626" };
  if (s <= 3) return { score: s, label: "Fair",   color: "#d97706" };
  if (s === 4) return { score: s, label: "Good",  color: "#2d5a1b" };
  return               { score: s, label: "Strong", color: "#16a34a" };
};

const suggestUsername = (firstName = "", lastName = "") => {
  const f = firstName.trim().toLowerCase().replace(/[^a-z]/g, "");
  const l = lastName.trim().toLowerCase().replace(/[^a-z]/g, "");
  return l ? `${f}.${l}` : f;
};

const BLANK = {
  first_name: "", middle_name: "", last_name: "",
  username: "", password: "",
  franchise: "", body_no: "", contact: "",
  license_no: "", plate_number: "", association: "Nagcarlan TODA",
};
const ASSOCS = ["Nagcarlan TODA","Oobi TODA","Talangan TODA","San Antonio TODA"];

function Drivers({ notify }) {
  const [data,         setData]         = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [search,       setSearch]       = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [enrollOpen,   setEnrollOpen]   = useState(false);
  const [editItem,     setEditItem]     = useState(null);
  const [delItem,      setDelItem]      = useState(null);
  const [suspendItem,  setSuspendItem]  = useState(null);
  const [saving,       setSaving]       = useState(false);
  const [toggling,     setToggling]     = useState(null);
  const [pageSize,     setPageSize]     = useState(10);
  const [currentPage,  setCurrentPage]  = useState(1);
  const [qrSelected,   setQrSelected]   = useState(null);
  const [qrDataUrl,    setQrDataUrl]    = useState("");
  const [showPw,          setShowPw]          = useState(false);
  const [copiedPw,        setCopiedPw]        = useState(false);
  const [copiedCreds,     setCopiedCreds]     = useState(false);
  const [resetPwMode,     setResetPwMode]     = useState(false);
  const [usernameTouched, setUsernameTouched] = useState(false);
  const [form,            setForm]            = useState(BLANK);

  // ── Load ──
  const load = useCallback(async (q = "") => {
    setLoading(true);
    const r = await api(`/api/drivers${q ? `?search=${encodeURIComponent(q)}` : ""}`);
    if (r.success) setData(r.data || []);
    else notify(r.error, "error");
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    const t = setTimeout(() => { load(search); setCurrentPage(1); }, 300);
    return () => clearTimeout(t);
  }, [search, load]);
  useEffect(() => { setCurrentPage(1); }, [statusFilter, pageSize]);

  // ── Stats ──
  const activeCount   = data.filter(d => d.status === "Active").length;
  const inactiveCount = data.filter(d => d.status === "Inactive").length;
  const thisMonth     = useMemo(() => {
    const now = new Date();
    return data.filter(d => {
      if (!d.created_at) return false;
      const dt = new Date(d.created_at);
      return dt.getMonth() === now.getMonth() && dt.getFullYear() === now.getFullYear();
    }).length;
  }, [data]);

  const filtered   = useMemo(() => statusFilter === "All" ? data : data.filter(d => d.status === statusFilter), [data, statusFilter]);
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const strength   = getStrength(form.password);

  // ── QR ──
  const openQR = async (d) => {
    if (!d.qr_id) return;
    const name = capitalizeName(buildFullName(d.first_name, d.middle_name, d.last_name));
    setQrSelected({ qr_id: d.qr_id, driver_name: name, franchise: d.franchise, issued_at: d.created_at || "—" });
    try {
      const url = await QRCode.toDataURL(d.qr_id, { width: 200, margin: 2, color: { dark: "#2d5a1b", light: "#ffffff" } });
      setQrDataUrl(url);
    } catch { notify("Failed to generate QR code", "error"); }
  };
  const closeQR    = () => { setQrSelected(null); setQrDataUrl(""); };
  const downloadQR = () => {
    if (!qrDataUrl || !qrSelected) return;
    const a = document.createElement("a");
    a.href = qrDataUrl; a.download = `QR-${qrSelected.franchise}-${qrSelected.driver_name}.png`; a.click();
  };
  const printSticker = () => {
    if (!qrDataUrl || !qrSelected) return;
    const win = window.open("", "_blank");
    win.document.write(`<!DOCTYPE html><html><head><title>QR Sticker - ${qrSelected.franchise}</title><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:'Segoe UI',sans-serif;display:flex;justify-content:center;align-items:center;min-height:100vh;background:#fff}.sticker{width:280px;border:2px solid #2d5a1b;border-radius:16px;overflow:hidden;text-align:center}.sticker-header{background:#2d5a1b!important;-webkit-print-color-adjust:exact!important;print-color-adjust:exact!important;padding:14px 16px}.sticker-header h1{font-size:18px;font-weight:bold;color:#fff!important;margin-bottom:2px}.sticker-header p{font-size:11px;color:#fff!important}.sticker-body{padding:20px 16px}.qr-wrap{display:inline-block;padding:10px;border:2px solid #2d5a1b;border-radius:10px;margin-bottom:14px}.qr-wrap img{display:block;width:160px;height:160px}.driver-name{font-size:16px;font-weight:bold;color:#1a1a1a;margin-bottom:4px}.franchise{font-size:13px;color:#555;margin-bottom:6px}.qr-id{font-size:9px;font-family:monospace;color:#888;margin-bottom:12px;word-break:break-all}.badge{display:inline-block;padding:4px 12px;background:#e8f5e9!important;-webkit-print-color-adjust:exact!important;print-color-adjust:exact!important;color:#2d5a1b!important;border-radius:20px;font-size:11px;font-weight:bold;margin-bottom:4px}.sticker-footer{background:#f5f5f5!important;-webkit-print-color-adjust:exact!important;print-color-adjust:exact!important;padding:8px 12px;font-size:10px;color:#888!important;border-top:1px solid #e0e0e0}</style></head><body><div class="sticker"><div class="sticker-header"><h1>eTODA Nagcarlan</h1><p>Official Driver QR Code</p></div><div class="sticker-body"><div class="qr-wrap"><img src="${qrDataUrl}" alt="QR Code"/></div><div class="driver-name">${qrSelected.driver_name}</div><div class="franchise">Franchise: ${qrSelected.franchise}</div><div class="qr-id">${qrSelected.qr_id}</div><div class="badge">&#10003; Active &middot; AES-256 Encrypted</div></div><div class="sticker-footer">Nagcarlan LGU &middot; eTODA System &middot; Issued ${qrSelected.issued_at}</div></div><script>window.onload=function(){window.print();window.close()};<\/script></body></html>`);
    win.document.close();
  };

  // ── Credential helpers ──
  const doGenerate  = () => { setForm(p => ({ ...p, password: generatePassword() })); setShowPw(true); setCopiedPw(false); };
  const safeCopy    = (text) => {
    if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text);
    const el = document.createElement("textarea");
    el.value = text; el.style.cssText = "position:fixed;top:-9999px;opacity:0";
    document.body.appendChild(el); el.focus(); el.select(); document.execCommand("copy"); document.body.removeChild(el);
    return Promise.resolve();
  };
  const doCopyPw    = () => { if (!form.password) return; safeCopy(form.password).then(() => { setCopiedPw(true); setTimeout(() => setCopiedPw(false), 2000); }).catch(() => notify("Copy failed", "error")); };
  const doCopyCreds = () => {
    if (!form.username || !form.password) return;
    safeCopy(`Username: ${form.username}\nPassword: ${form.password}`).then(() => { setCopiedCreds(true); setTimeout(() => setCopiedCreds(false), 2000); }).catch(() => notify("Copy failed", "error"));
  };

  const handleNameBlur = () => {
    if (!usernameTouched && form.first_name && form.last_name)
      setForm(p => ({ ...p, username: suggestUsername(p.first_name, p.last_name) }));
  };

  // ── CRUD ──
  const enroll = async () => {
    if (!form.first_name.trim()) { notify("First Name is required", "error"); return; }
    if (!form.last_name.trim())  { notify("Last Name is required",  "error"); return; }
    if (!form.franchise.trim())  { notify("Franchise is required",  "error"); return; }
    setSaving(true);
    const payload = {
      first_name:   capitalizeName(form.first_name.trim()),
      middle_name:  capitalizeName(form.middle_name.trim()),
      last_name:    capitalizeName(form.last_name.trim()),
      franchise:    form.franchise.trim(),
      body_no:      form.body_no.trim(),
      contact:      form.contact.trim(),
      license_no:   form.license_no.trim(),
      plate_number: form.plate_number.trim(),
      association:  form.association || "Nagcarlan TODA",
      username:     form.username.trim(),
    };
    if (form.password.trim()) payload.password = form.password.trim();
    const r = await api("/api/drivers", "POST", payload);
    setSaving(false);
    if (r.success) {
      setEnrollOpen(false); setForm(BLANK); setUsernameTouched(false); setShowPw(false);
      load(search);
      notify(`${payload.first_name} ${payload.last_name} enrolled`);
    } else notify(r.error || "Failed", "error");
  };

  const saveEdit = async () => {
    if (!form.first_name.trim()) { notify("First Name is required", "error"); return; }
    if (!form.last_name.trim())  { notify("Last Name is required",  "error"); return; }
    setSaving(true);
    const payload = {
      first_name:   capitalizeName(form.first_name.trim()),
      middle_name:  capitalizeName(form.middle_name.trim()),
      last_name:    capitalizeName(form.last_name.trim()),
      franchise:    form.franchise.trim(),
      body_no:      form.body_no.trim(),
      contact:      form.contact.trim(),
      license_no:   form.license_no.trim(),
      plate_number: form.plate_number.trim(),
      association:  form.association,
      username:     form.username.trim(),
    };
    if (resetPwMode && form.password.trim()) payload.password = form.password.trim();
    const r = await api(`/api/drivers/${editItem.id}`, "PATCH", payload);
    setSaving(false);
    if (r.success) { setEditItem(null); load(search); notify("Driver updated"); }
    else notify(r.error || "Failed", "error");
  };

  const openEdit = (d) => {
    setShowPw(false); setResetPwMode(false); setCopiedPw(false); setCopiedCreds(false); setUsernameTouched(false);
    setEditItem(d);
    setForm({
      first_name:   d.first_name   || "",
      middle_name:  d.middle_name  || "",
      last_name:    d.last_name    || "",
      username:     d.username     || "",
      password:     "",
      franchise:    d.franchise    || "",
      body_no:      d.body_no      || "",
      contact:      d.contact      || "",
      license_no:   d.license_no   || "",
      plate_number: d.plate_number || "",
      association:  d.association  || "Nagcarlan TODA",
    });
  };

  const openEnroll = () => { setShowPw(false); setCopiedPw(false); setCopiedCreds(false); setUsernameTouched(false); setForm(BLANK); setEnrollOpen(true); };

  const confirmSuspend = async () => {
    setToggling(suspendItem.id);
    const next = suspendItem.status === "Active" ? "Inactive" : "Active";
    const r = await api(`/api/drivers/${suspendItem.id}`, "PATCH", { status: next });
    setToggling(null); setSuspendItem(null);
    if (r.success) {
      load(search);
      const name = capitalizeName(buildFullName(suspendItem.first_name, suspendItem.middle_name, suspendItem.last_name));
      notify(next === "Inactive" ? `${name} suspended` : `${name} restored`, next === "Active" ? "success" : "warn");
    }
  };

  const remove = async () => {
    const r = await api(`/api/drivers/${delItem.id}`, "DELETE");
    if (r.success) {
      setDelItem(null); load(search);
      notify(`${capitalizeName(buildFullName(delItem.first_name, delItem.middle_name, delItem.last_name))} deleted`, "warn");
    } else notify(r.error, "error");
  };

  const driverFullName = (d) => capitalizeName(buildFullName(d.first_name, d.middle_name, d.last_name)) || "—";

  // ── Credential section ──
  const credentialSection = (isEdit = false) => (
    <div style={{ borderTop: "1.5px solid var(--gray2)", marginTop: 4, paddingTop: 14, paddingBottom: 4 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
          <FontAwesomeIcon icon={faKey} style={{ color: "var(--green)", fontSize: 13 }} />
          <span style={{ fontWeight: 700, fontSize: ".83rem", color: "#1a1a1a" }}>Login Credentials</span>
        </div>
        {isEdit && (
          <button type="button" onClick={() => { setResetPwMode(v => !v); setShowPw(false); setCopiedPw(false); setForm(p => ({ ...p, password: "" })); }}
            style={{ fontSize: ".75rem", fontWeight: 600, padding: "3px 10px", borderRadius: 6, cursor: "pointer", border: resetPwMode ? "1px solid #fca5a5" : "1px solid var(--green)", background: resetPwMode ? "#fee2e2" : "#f0fdf4", color: resetPwMode ? "#dc2626" : "var(--green)", display: "flex", alignItems: "center", gap: 5 }}>
            <FontAwesomeIcon icon={resetPwMode ? faLock : faLockOpen} style={{ fontSize: 11 }} />
            {resetPwMode ? "Cancel Reset" : "Reset Password"}
          </button>
        )}
      </div>

      <div style={{ marginBottom: 12 }}>
        <label style={{ display: "block", fontSize: ".78rem", fontWeight: 600, marginBottom: 5, color: "#374151" }}>Username</label>
        <input value={form.username} onChange={e => { setUsernameTouched(true); setForm(p => ({ ...p, username: e.target.value })); }} placeholder="e.g. juan.delacruz" style={{ width: "100%", boxSizing: "border-box" }} />
        {!isEdit && !usernameTouched && form.first_name && form.last_name && (
          <div style={{ fontSize: ".72rem", color: "var(--gray)", marginTop: 3 }}>
            <FontAwesomeIcon icon={faCircleInfo} style={{ marginRight: 4, fontSize: 11 }} />Auto-suggested from name — click to override
          </div>
        )}
        {isEdit && !editItem?.username && (
          <div style={{ marginTop: 4, fontSize: ".72rem", color: "#92400e", background: "#fffbeb", border: "1px solid #fde68a", borderRadius: 4, padding: "2px 8px", display: "inline-block" }}>
            <FontAwesomeIcon icon={faTriangleExclamation} style={{ marginRight: 4, fontSize: 11 }} />No username set — driver cannot log in
          </div>
        )}
      </div>

      {(isEdit ? resetPwMode : true) && (
        <div>
          <label style={{ display: "block", fontSize: ".78rem", fontWeight: 600, marginBottom: 5, color: "#374151" }}>
            {isEdit ? "New Password" : "Temporary Password"}
            {isEdit && <span style={{ fontWeight: 400, color: "var(--gray)", marginLeft: 6, fontSize: ".72rem" }}>— leave blank to keep current</span>}
          </label>
          <div style={{ display: "flex", gap: 6, marginBottom: 6 }}>
            <div style={{ position: "relative", flex: 1 }}>
              <input type={showPw ? "text" : "password"} value={form.password} onChange={e => setForm(p => ({ ...p, password: e.target.value }))} placeholder={isEdit ? "Enter or generate new password…" : "Enter or generate a temporary password…"} style={{ width: "100%", boxSizing: "border-box", paddingRight: 36, fontFamily: form.password && !showPw ? "monospace" : "inherit" }} />
              <button type="button" onClick={() => setShowPw(v => !v)} tabIndex={-1} style={{ position: "absolute", right: 10, top: "50%", transform: "translateY(-50%)", background: "none", border: "none", cursor: "pointer", color: "var(--gray)", padding: 0, fontSize: 13 }}>
                <FontAwesomeIcon icon={showPw ? faEyeSlash : faEye} />
              </button>
            </div>
            <button type="button" onClick={doGenerate} style={{ padding: "0 12px", borderRadius: 7, border: "1.5px solid var(--green)", background: "#f0fdf4", color: "var(--green)", cursor: "pointer", fontSize: 13, display: "flex", alignItems: "center", gap: 5, fontWeight: 600, whiteSpace: "nowrap" }}>
              <FontAwesomeIcon icon={faRotate} style={{ fontSize: 12 }} />Generate
            </button>
            {form.password && (
              <button type="button" onClick={doCopyPw} style={{ padding: "0 12px", borderRadius: 7, border: "1px solid var(--gray2)", background: copiedPw ? "#f0fdf4" : "#fff", color: copiedPw ? "var(--green)" : "var(--gray)", cursor: "pointer", fontSize: 13 }}>
                <FontAwesomeIcon icon={copiedPw ? faCheck : faCopy} />
              </button>
            )}
          </div>
          {form.password && (
            <div style={{ marginBottom: 8 }}>
              <div style={{ display: "flex", gap: 3, marginBottom: 3 }}>
                {[1,2,3,4,5].map(i => <div key={i} style={{ flex: 1, height: 4, borderRadius: 99, background: i <= strength.score ? strength.color : "#e5e7eb", transition: "background 0.2s" }} />)}
              </div>
              <span style={{ fontSize: ".72rem", color: strength.color, fontWeight: 600 }}>{strength.label}</span>
            </div>
          )}
        </div>
      )}

      {isEdit && !resetPwMode && (
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          {editItem?.has_password ? (
            <span style={{ fontSize: ".75rem", color: "#2d5a1b", background: "#f0fdf4", border: "1px solid #86efac", borderRadius: 4, padding: "3px 10px" }}>
              <FontAwesomeIcon icon={faLock} style={{ marginRight: 5, fontSize: 10 }} />Password is set
            </span>
          ) : (
            <span style={{ fontSize: ".75rem", color: "#92400e", background: "#fffbeb", border: "1px solid #fde68a", borderRadius: 4, padding: "3px 10px" }}>
              <FontAwesomeIcon icon={faLockOpen} style={{ marginRight: 5, fontSize: 10 }} />No password set
            </span>
          )}
        </div>
      )}

      {form.username && form.password && (
        <div style={{ marginTop: 12, background: "#1e293b", borderRadius: 8, padding: "10px 14px" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 6 }}>
            <span style={{ fontSize: ".7rem", color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".05em" }}>Credentials to hand to driver</span>
            <button type="button" onClick={doCopyCreds} style={{ fontSize: ".72rem", padding: "2px 10px", borderRadius: 5, border: "1px solid #475569", background: copiedCreds ? "#166534" : "#334155", color: copiedCreds ? "#bbf7d0" : "#e2e8f0", cursor: "pointer", display: "flex", alignItems: "center", gap: 5, fontWeight: 600 }}>
              <FontAwesomeIcon icon={copiedCreds ? faCheck : faCopy} style={{ fontSize: 10 }} />{copiedCreds ? "Copied!" : "Copy All"}
            </button>
          </div>
          <div style={{ fontFamily: "monospace", fontSize: ".8rem", color: "#e2e8f0", lineHeight: 1.8 }}>
            <span style={{ color: "#94a3b8" }}>Username: </span>{form.username}<br />
            <span style={{ color: "#94a3b8" }}>Password: </span>
            <span style={{ color: "#86efac" }}>{showPw ? form.password : "•".repeat(form.password.length)}</span>
          </div>
        </div>
      )}
    </div>
  );

  // ── Profile fields ──
  const profileFields = () => (
    <>
      <div style={{ fontSize: ".78rem", fontWeight: 700, color: "#374151", marginBottom: 6, display: "flex", alignItems: "center", gap: 6 }}>
        <span style={{ width: 3, height: 14, background: "var(--green)", borderRadius: 99, display: "inline-block" }} />
        Driver Information
      </div>
      <div className="form-row">
        <div className="field">
          <label>First Name *</label>
          <input value={form.first_name} onChange={e => setForm(p => ({ ...p, first_name: e.target.value }))} onBlur={handleNameBlur} placeholder="Juan" />
        </div>
        <div className="field">
          <label>Middle Name <span style={{ fontWeight: 400, color: "var(--gray)", fontSize: ".72rem" }}>(optional)</span></label>
          <input value={form.middle_name} onChange={e => setForm(p => ({ ...p, middle_name: e.target.value }))} placeholder="A." />
        </div>
      </div>
      <div className="form-row">
        <div className="field">
          <label>Last Name *</label>
          <input value={form.last_name} onChange={e => setForm(p => ({ ...p, last_name: e.target.value }))} onBlur={handleNameBlur} placeholder="Dela Cruz" />
        </div>
        <div className="field">
          <label>Franchise # *</label>
          <input value={form.franchise} onChange={e => setForm(p => ({ ...p, franchise: e.target.value }))} placeholder="NVC-006F" />
        </div>
      </div>
      <div className="form-row">
        <div className="field"><label>Body #</label><input value={form.body_no} onChange={e => setForm(p => ({ ...p, body_no: e.target.value }))} placeholder="06" /></div>
        <div className="field"><label>Plate Number</label><input value={form.plate_number} onChange={e => setForm(p => ({ ...p, plate_number: e.target.value }))} placeholder="ABC 1234" /></div>
      </div>
      <div className="form-row">
        <div className="field"><label>Contact</label><input value={form.contact} onChange={e => setForm(p => ({ ...p, contact: e.target.value }))} placeholder="09XXXXXXXXX" /></div>
        <div className="field"><label>License No.</label><input value={form.license_no} onChange={e => setForm(p => ({ ...p, license_no: e.target.value }))} placeholder="NAG-XXXXXX" /></div>
      </div>
      <div className="form-row">
        <div className="field">
          <label>Association</label>
          <select value={form.association} onChange={e => setForm(p => ({ ...p, association: e.target.value }))}>
            {ASSOCS.map(a => <option key={a}>{a}</option>)}
          </select>
        </div>
      </div>
    </>
  );

  return (
    <div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faUserGroup} style={{ marginRight: 8, color: "var(--gold)" }} />
            Driver Registry <span>({filtered.length} drivers)</span>
          </div>
          <div className="card-actions">
            <div style={{ position: "relative" }}>
              <FontAwesomeIcon icon={faSearch} style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)", color: "#aaa", fontSize: 12, pointerEvents: "none" }} />
              <input className="search-box" style={{ width: 230, paddingLeft: 30 }} placeholder="Search name, franchise, ID..." value={search} onChange={e => setSearch(e.target.value)} />
            </div>
            <button className="btn btn-green" onClick={openEnroll}>+ Enroll Driver</button>
          </div>
        </div>

        <div style={{ padding: "10px 18px 0", display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
          <FontAwesomeIcon icon={faFilter} style={{ color: "var(--gray)", fontSize: 12 }} />
          <span style={{ fontSize: ".8rem", color: "var(--gray)", marginRight: 4 }}>Filter:</span>
          {[{ label: `All (${data.length})`, value: "All" }, { label: `Active (${activeCount})`, value: "Active" }, { label: `Suspended (${inactiveCount})`, value: "Inactive" }].map(({ label, value }) => (
            <button key={value} onClick={() => setStatusFilter(value)} style={{ padding: "4px 12px", borderRadius: 20, border: statusFilter === value ? "1.5px solid var(--green)" : "1.5px solid var(--gray2)", background: statusFilter === value ? "var(--green)" : "transparent", color: statusFilter === value ? "#fff" : "var(--gray)", fontSize: ".78rem", fontWeight: statusFilter === value ? 700 : 400, cursor: "pointer", transition: "all 0.15s" }}>
              {label}
            </button>
          ))}
          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6 }}>
            <span style={{ fontSize: ".78rem", color: "var(--gray)" }}>Show</span>
            {[10, 25, 50].map(n => (
              <button key={n} onClick={() => setPageSize(n)} style={{ padding: "3px 10px", borderRadius: 6, border: pageSize === n ? "1.5px solid var(--green)" : "1.5px solid var(--gray2)", background: pageSize === n ? "var(--green)" : "transparent", color: pageSize === n ? "#fff" : "var(--gray)", fontSize: ".78rem", fontWeight: pageSize === n ? 700 : 400, cursor: "pointer", transition: "all 0.15s" }}>
                {n}
              </button>
            ))}
          </div>
        </div>

        {loading ? <Loading /> : data.length === 0 ? <Empty /> : (
          <>
            <div className="tbl-wrap">
              <table>
                <thead>
                  <tr>
                    <th>ID</th><th>Name</th><th>Username</th><th>Franchise</th>
                    <th>Body #</th><th>Contact</th><th>QR</th><th>Status</th><th>Enrolled</th><th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.length === 0 ? (
                    <tr><td colSpan={10} style={{ textAlign: "center", padding: "24px", color: "var(--gray)" }}>
                      No {statusFilter !== "All" ? statusFilter.toLowerCase() : ""} drivers found.
                    </td></tr>
                  ) : paginated.map(d => (
                    <tr key={d.id} style={{ opacity: d.status === "Inactive" ? 0.6 : 1, transition: "opacity 0.2s" }}>
                      <td><strong>{d.driver_code}</strong></td>
                      <td><strong>{driverFullName(d)}</strong></td>
                      <td>
                        {d.username
                          ? <span style={{ fontSize: ".85rem" }}>{d.username}</span>
                          : <span style={{ fontSize: ".73rem", color: "#92400e", background: "#fffbeb", border: "1px solid #fde68a", borderRadius: 4, padding: "1px 6px" }}>No login</span>
                        }
                      </td>
                      <td>{d.franchise}</td>
                      <td>{d.body_no || "—"}</td>
                      <td>{d.contact || "—"}</td>
                      <td>
                        {d.qr_id ? (
                          d.qr_status === "Revoked" ? (
                            <span style={{ fontSize: ".78rem", color: "#dc2626", fontWeight: 600, display: "flex", alignItems: "center", gap: 4 }}>
                              <FontAwesomeIcon icon={faQrcode} style={{ fontSize: 12 }} />Revoked
                            </span>
                          ) : (
                            <button onClick={() => openQR(d)} style={{ background: "none", border: "none", cursor: "pointer", padding: 0, display: "flex", alignItems: "center", gap: 4, color: "var(--green)", fontSize: ".78rem", fontWeight: 600 }}>
                              <FontAwesomeIcon icon={faQrcode} style={{ fontSize: 12 }} />Issued
                            </button>
                          )
                        ) : <span style={{ color: "var(--gray2)" }}>—</span>}
                      </td>
                      <td style={{ width: 100 }}>
                        <span className={`badge ${d.status === "Active" ? "badge-active" : "badge-inactive"}`} style={{ display: "inline-block", minWidth: 80, textAlign: "center" }}>
                          {d.status === "Active" ? "Active" : "Suspended"}
                        </span>
                      </td>
                      <td style={{ fontSize: ".85rem" }}>{formatDate(d.created_at)}</td>
                      <td>
                        <div className="row-actions">
                          {d.status === "Active" ? (
                            <button className="ib ib-del" onClick={() => setSuspendItem(d)} disabled={toggling === d.id} style={{ background: "#fff8e1", color: "#b45309", borderColor: "#f59e0b", minWidth: 88 }}>
                              <FontAwesomeIcon icon={faBan} style={{ marginRight: 4, fontSize: 11 }} />Suspend
                            </button>
                          ) : (
                            <button className="ib ib-edit" onClick={() => setSuspendItem(d)} disabled={toggling === d.id} style={{ minWidth: 88 }}>
                              <FontAwesomeIcon icon={faCircleCheck} style={{ marginRight: 4, fontSize: 11 }} />Restore
                            </button>
                          )}
                          <button className="ib ib-edit" onClick={() => openEdit(d)}>
                            <FontAwesomeIcon icon={faPencil} style={{ marginRight: 4, fontSize: 11 }} />Edit
                          </button>
                          <button className="ib ib-del" onClick={() => setDelItem(d)}>
                            <FontAwesomeIcon icon={faTrash} style={{ marginRight: 4, fontSize: 11 }} />Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {filtered.length > pageSize && (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 18px", borderTop: "1px solid var(--gray2)" }}>
                <span style={{ fontSize: ".8rem", color: "var(--gray)" }}>
                  Showing {Math.min((currentPage - 1) * pageSize + 1, filtered.length)}–{Math.min(currentPage * pageSize, filtered.length)} of {filtered.length} drivers
                </span>
                <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
                  <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1} style={{ background: "none", border: "1px solid var(--gray2)", borderRadius: 6, padding: "4px 10px", cursor: currentPage === 1 ? "not-allowed" : "pointer", opacity: currentPage === 1 ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronLeft} style={{ fontSize: 11 }} />
                  </button>
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                    <button key={p} onClick={() => setCurrentPage(p)} style={{ padding: "4px 10px", borderRadius: 6, fontSize: ".8rem", fontWeight: p === currentPage ? 700 : 400, border: p === currentPage ? "1.5px solid var(--green)" : "1px solid var(--gray2)", background: p === currentPage ? "var(--green)" : "none", color: p === currentPage ? "#fff" : "var(--gray)", cursor: "pointer" }}>
                      {p}
                    </button>
                  ))}
                  <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages} style={{ background: "none", border: "1px solid var(--gray2)", borderRadius: 6, padding: "4px 10px", cursor: currentPage === totalPages ? "not-allowed" : "pointer", opacity: currentPage === totalPages ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronRight} style={{ fontSize: 11 }} />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* ── ENROLL ── */}
      {enrollOpen && (
        <Modal title="+ Enroll New Driver" onClose={() => setEnrollOpen(false)}>
          {profileFields()}
          <div style={{ marginTop: 8 }}>{credentialSection(false)}</div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEnrollOpen(false)}>Cancel</button>
            <button className="btn btn-green" onClick={enroll} disabled={saving}>{saving ? "Enrolling..." : "Enroll & Generate QR"}</button>
          </div>
        </Modal>
      )}

      {/* ── EDIT ── */}
      {editItem && (
        <Modal title={`Edit: ${driverFullName(editItem)}`} onClose={() => setEditItem(null)}>
          {credentialSection(true)}
          <div style={{ marginTop: 18 }}>{profileFields()}</div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setEditItem(null)}>Cancel</button>
            <button className="btn btn-green" onClick={saveEdit} disabled={saving}>{saving ? "Saving..." : "Save Changes"}</button>
          </div>
        </Modal>
      )}

      {/* ── SUSPEND / RESTORE ── */}
      {suspendItem && (
        <Modal title={suspendItem.status === "Active" ? "Suspend Driver" : "Restore Driver"} onClose={() => setSuspendItem(null)}>
          {suspendItem.status === "Active" ? (
            <div style={{ background: "#fff8e1", border: "1px solid #f59e0b", borderRadius: 10, padding: "14px 16px", marginBottom: 16, fontSize: ".88rem", color: "#78350f", lineHeight: 1.7 }}>
              Are you sure you want to suspend <strong>{driverFullName(suspendItem)}</strong> ({suspendItem.franchise})?<br />
              Their account will be deactivated and they won't be able to log in until restored.
            </div>
          ) : (
            <div style={{ background: "#f0fdf4", border: "1px solid #86efac", borderRadius: 10, padding: "14px 16px", marginBottom: 16, fontSize: ".88rem", color: "#14532d", lineHeight: 1.7 }}>
              Restore <strong>{driverFullName(suspendItem)}</strong> ({suspendItem.franchise})?<br />
              Their account will be restored and they can log in again.
            </div>
          )}
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setSuspendItem(null)}>Cancel</button>
            {suspendItem.status === "Active" ? (
              <button onClick={confirmSuspend} disabled={toggling === suspendItem.id} style={{ background: "#d97706", color: "#fff", border: "none", borderRadius: 8, padding: "8px 18px", fontWeight: 700, cursor: "pointer" }}>
                <FontAwesomeIcon icon={faBan} style={{ marginRight: 6 }} />{toggling === suspendItem.id ? "Suspending..." : "Yes, Suspend Driver"}
              </button>
            ) : (
              <button onClick={confirmSuspend} disabled={toggling === suspendItem.id} style={{ background: "var(--green)", color: "#fff", border: "none", borderRadius: 8, padding: "8px 18px", fontWeight: 700, cursor: "pointer" }}>
                <FontAwesomeIcon icon={faCircleCheck} style={{ marginRight: 6 }} />{toggling === suspendItem.id ? "Restoring..." : "Yes, Restore Driver"}
              </button>
            )}
          </div>
        </Modal>
      )}

      {/* ── DELETE ── */}
      {delItem && (
        <Modal title="Delete Driver" onClose={() => setDelItem(null)}>
          <div style={{ background: "#fee2e2", border: "1px solid #fca5a5", borderRadius: 10, padding: "14px 16px", marginBottom: 16, fontSize: ".88rem", color: "#7f1d1d", lineHeight: 1.7 }}>
            Are you sure you want to delete <strong>{driverFullName(delItem)}</strong> ({delItem.franchise})?<br />
            Their QR Code will be revoked and this action will be logged to the Audit Trail.<br />
            <strong>This cannot be undone.</strong>
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setDelItem(null)}>Cancel</button>
            <button onClick={remove} style={{ background: "#dc2626", color: "#fff", border: "none", borderRadius: 8, padding: "8px 18px", fontWeight: 700, cursor: "pointer" }}>Yes, Delete Driver</button>
          </div>
        </Modal>
      )}

      {/* ── QR MODAL ── */}
      {qrSelected && (
        <div onClick={closeQR} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 9999, padding: "24px" }}>
          <div onClick={e => e.stopPropagation()} style={{ background: "#fff", borderRadius: "20px", width: "320px", overflow: "hidden", boxShadow: "0 24px 60px rgba(0,0,0,0.2)" }}>
            <div style={{ background: "#2d5a1b", padding: "16px 20px", textAlign: "center" }}>
              <div style={{ fontSize: "18px", fontWeight: "bold", color: "#fff" }}>eTODA Nagcarlan</div>
              <div style={{ fontSize: "12px", color: "rgba(255,255,255,0.75)", marginTop: "2px" }}>Official Driver QR Code</div>
            </div>
            <div style={{ padding: "24px 20px", textAlign: "center" }}>
              {qrDataUrl ? (
                <div style={{ display: "inline-block", padding: "12px", border: "2px solid #2d5a1b", borderRadius: "12px", marginBottom: "16px" }}>
                  <img src={qrDataUrl} alt="QR Code" style={{ display: "block", width: "160px", height: "160px" }} />
                </div>
              ) : (
                <div style={{ width: "160px", height: "160px", margin: "0 auto 16px", display: "flex", alignItems: "center", justifyContent: "center", color: "#aaa", fontSize: "13px" }}>Generating...</div>
              )}
              <div style={{ fontSize: "16px", fontWeight: "bold", color: "#1a1a1a", marginBottom: "4px" }}>{qrSelected.driver_name}</div>
              <div style={{ fontSize: "13px", color: "#555", marginBottom: "4px" }}>Franchise: {qrSelected.franchise}</div>
              <div style={{ fontSize: "10px", fontFamily: "monospace", color: "#999", marginBottom: "14px", wordBreak: "break-all" }}>{qrSelected.qr_id}</div>
              <div style={{ display: "inline-flex", alignItems: "center", gap: "6px", background: "#e8f5e9", borderRadius: "20px", padding: "5px 14px", marginBottom: "20px" }}>
                <div style={{ width: "8px", height: "8px", borderRadius: "50%", background: "#2d5a1b" }} />
                <span style={{ fontSize: "12px", color: "#2d5a1b", fontWeight: "600" }}>Active · AES-256 Encrypted</span>
              </div>
              <div style={{ display: "flex", gap: "8px", marginBottom: "8px" }}>
                <button onClick={printSticker} style={{ flex: 1, padding: "11px", fontSize: "13px", fontWeight: "700", borderRadius: "10px", cursor: "pointer", background: "#2d5a1b", color: "#fff", border: "none" }}>
                  <FontAwesomeIcon icon={faPrint} style={{ marginRight: "6px" }} />Print Sticker
                </button>
                <button onClick={downloadQR} style={{ flex: 1, padding: "11px", fontSize: "13px", fontWeight: "600", borderRadius: "10px", cursor: "pointer", background: "#f5f5f5", color: "#333", border: "1px solid #e0e0e0" }}>
                  <FontAwesomeIcon icon={faDownload} style={{ marginRight: "6px" }} />Download
                </button>
              </div>
              <button onClick={closeQR} style={{ width: "100%", padding: "10px", fontSize: "13px", fontWeight: "700", borderRadius: "10px", cursor: "pointer", background: "#fee2e2", color: "#dc2626", border: "1px solid #fca5a5" }}>
                <FontAwesomeIcon icon={faTimes} style={{ marginRight: "6px" }} />Close
              </button>
            </div>
            <div style={{ background: "#f9f9f9", borderTop: "1px solid #eee", padding: "8px 16px", textAlign: "center" }}>
              <span style={{ fontSize: "11px", color: "#aaa" }}>Nagcarlan LGU · eTODA System · Issued {qrSelected.issued_at}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Drivers;