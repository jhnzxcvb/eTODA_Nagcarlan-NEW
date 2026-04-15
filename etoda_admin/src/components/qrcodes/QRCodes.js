// src/components/qrcodes/QRCodes.js
import React, { useState, useEffect, useMemo } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faPrint, faDownload, faTimes, faQrcode, faSearch,
  faFilter, faChevronLeft, faChevronRight, faBan, faCircleCheck,
} from "@fortawesome/free-solid-svg-icons";
import { api } from "../../lib/api";
import Loading from "../ui/Loading";
import Empty from "../ui/Empty";
import Modal from "../ui/Modal";
import QRCode from "qrcode";
import { buildPageWindow } from '../../lib/pagination';

const COL = {
  franchise: { width: "110px", maxWidth: "110px", overflow: "hidden", whiteSpace: "nowrap", textOverflow: "ellipsis" },
  driver:    { width: "160px", maxWidth: "160px", overflow: "hidden", whiteSpace: "nowrap", textOverflow: "ellipsis" },
  qrid:      { width: "230px", maxWidth: "230px", overflow: "hidden", whiteSpace: "nowrap", textOverflow: "ellipsis", fontFamily: "monospace", fontSize: ".75rem", color: "var(--green)" },
  status:    { width: "90px",  maxWidth: "90px",  textAlign: "center" },
  issued:    { width: "110px", maxWidth: "110px", overflow: "hidden" },
  actions:   { width: "210px", maxWidth: "210px" },
};

function QRCodes({ notify }) {
  const [data,         setData]         = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [search,       setSearch]       = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [pageSize,     setPageSize]     = useState(10);
  const [currentPage,  setCurrentPage]  = useState(1);
  const [selected,     setSelected]     = useState(null);
  const [qrDataUrl,    setQrDataUrl]    = useState("");
  const [revokeItem,   setRevokeItem]   = useState(null);  // ← confirm revoke
  const [restoreItem,  setRestoreItem]  = useState(null);  // ← confirm restore
  const [toggling,     setToggling]     = useState(null);

  const load = async () => {
    setLoading(true);
    const r = await api("/api/qrcodes");
    if (r.success) setData(r.data || []);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);
  useEffect(() => { setCurrentPage(1); }, [statusFilter, pageSize, search]);

  const activeCount  = data.filter(q => q.status === "Active").length;
  const revokedCount = data.filter(q => q.status === "Revoked").length;

  const filtered = useMemo(() => {
    let result = statusFilter === "All" ? data : data.filter(q => q.status === statusFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter(r =>
        r.franchise.toLowerCase().includes(q) ||
        r.driver_name.toLowerCase().includes(q) ||
        r.qr_id.toLowerCase().includes(q)
      );
    }
    return result;
  }, [data, search, statusFilter]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const pageWindow = buildPageWindow(currentPage, totalPages);

  const update = async (id, status, franchise) => {
    setToggling(id);
    const r = await api(`/api/qrcodes/${id}`, "PATCH", { status });
    setToggling(null);
    if (r.success) {
      load();
      notify(
        status === "Active" ? `QR Code restored for ${franchise}` : `QR Code revoked for ${franchise}`,
        status === "Active" ? "success" : "warn",
      );
    }
  };

  const confirmRevoke = async () => {
    await update(revokeItem.id, "Revoked", revokeItem.franchise);
    setRevokeItem(null);
  };

  const confirmRestore = async () => {
    await update(restoreItem.id, "Active", restoreItem.franchise);
    setRestoreItem(null);
  };

  const openModal = async (q) => {
    setSelected(q);
    try {
      const url = await QRCode.toDataURL(q.qr_id, {
        width: 200, margin: 2,
        color: { dark: "#2d5a1b", light: "#ffffff" },
      });
      setQrDataUrl(url);
    } catch {
      notify("Failed to generate QR code", "error");
    }
  };

  const closeModal = () => { setSelected(null); setQrDataUrl(""); };

  const downloadQR = () => {
    if (!qrDataUrl || !selected) return;
    const a = document.createElement("a");
    a.href = qrDataUrl;
    a.download = `QR-${selected.franchise}-${selected.driver_name}.png`;
    a.click();
  };

  const printSticker = () => {
    if (!qrDataUrl || !selected) return;
    const win = window.open("", "_blank");
    win.document.write(`
      <!DOCTYPE html><html><head>
        <title>QR Sticker - ${selected.franchise}</title>
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          body { font-family:'Segoe UI',sans-serif; display:flex; justify-content:center; align-items:center; min-height:100vh; background:#fff; }
          .sticker { width:280px; border:2px solid #2d5a1b; border-radius:16px; overflow:hidden; text-align:center; }
          .sticker-header { background:#2d5a1b !important; -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; padding:14px 16px; }
          .sticker-header h1 { font-size:18px; font-weight:bold; color:#ffffff !important; margin-bottom:2px; }
          .sticker-header p  { font-size:11px; color:#ffffff !important; }
          .sticker-body { padding:20px 16px; }
          .qr-wrap { display:inline-block; padding:10px; border:2px solid #2d5a1b; border-radius:10px; margin-bottom:14px; }
          .qr-wrap img { display:block; width:160px; height:160px; }
          .driver-name { font-size:16px; font-weight:bold; color:#1a1a1a; margin-bottom:4px; }
          .franchise   { font-size:13px; color:#555; margin-bottom:6px; }
          .qr-id       { font-size:9px; font-family:monospace; color:#888; margin-bottom:12px; word-break:break-all; }
          .badge { display:inline-block; padding:4px 12px; background:#e8f5e9 !important; -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; color:#2d5a1b !important; border-radius:20px; font-size:11px; font-weight:bold; margin-bottom:4px; }
          .sticker-footer { background:#f5f5f5 !important; -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; padding:8px 12px; font-size:10px; color:#888 !important; border-top:1px solid #e0e0e0; }
          @media print {
            * { -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; }
          }
        </style>
      </head>
      <body>
        <div class="sticker">
          <div class="sticker-header"><h1>eTODA Nagcarlan</h1><p>Official Driver QR Code</p></div>
          <div class="sticker-body">
            <div class="qr-wrap"><img src="${qrDataUrl}" alt="QR Code" /></div>
            <div class="driver-name">${selected.driver_name}</div>
            <div class="franchise">Franchise: ${selected.franchise}</div>
      
          </div>
          <div class="sticker-footer">Nagcarlan LGU &middot; eTODA System &middot; Issued ${selected.issued_at}</div>
        </div>
        <script>window.onload=function(){window.print();window.close()};<\/script>
      </body></html>
    `);
    win.document.close();
  };

  return (
    <div>
      <div className="card">
        {/* ── CARD HEAD ── */}
        <div className="card-head">
          <div className="card-title">
            <FontAwesomeIcon icon={faQrcode} style={{ marginRight: 8, color: "var(--gold)" }} />
            QR Codes <span>({filtered.length})</span>
          </div>
          <div className="card-actions">
            <div style={{ position: "relative" }}>
              <FontAwesomeIcon icon={faSearch} style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)", color: "#aaa", fontSize: 12, pointerEvents: "none" }} />
              <input
                className="search-box"
                style={{ width: 230, paddingLeft: 30 }}
                placeholder="Search franchise, driver, ID..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
            <button className="btn btn-ghost btn-sm" onClick={load}>↻ Refresh</button>
          </div>
        </div>

        {/* ── FILTER + PAGE SIZE BAR ── */}
        <div style={{ padding: "10px 18px 0", display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
          <FontAwesomeIcon icon={faFilter} style={{ color: "var(--gray)", fontSize: 12 }} />
          <span style={{ fontSize: ".8rem", color: "var(--gray)", marginRight: 4 }}>Filter:</span>
          {[
            { label: `All (${data.length})`,      value: "All"     },
            { label: `Active (${activeCount})`,    value: "Active"  },
            { label: `Revoked (${revokedCount})`,  value: "Revoked" },
          ].map(({ label, value }) => (
            <button key={value} onClick={() => setStatusFilter(value)}
              style={{
                padding: "4px 12px", borderRadius: 20, fontSize: ".78rem", cursor: "pointer", transition: "all 0.15s",
                border:      statusFilter === value ? "1.5px solid var(--green)" : "1.5px solid var(--gray2)",
                background:  statusFilter === value ? "var(--green)" : "transparent",
                color:       statusFilter === value ? "#fff" : "var(--gray)",
                fontWeight:  statusFilter === value ? 700 : 400,
              }}>
              {label}
            </button>
          ))}
          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6 }}>
            <span style={{ fontSize: ".78rem", color: "var(--gray)" }}>Show</span>
            {[10, 25, 50].map(n => (
              <button key={n} onClick={() => setPageSize(n)}
                style={{
                  padding: "3px 10px", borderRadius: 6, fontSize: ".78rem", cursor: "pointer", transition: "all 0.15s",
                  border:     pageSize === n ? "1.5px solid var(--green)" : "1.5px solid var(--gray2)",
                  background: pageSize === n ? "var(--green)" : "transparent",
                  color:      pageSize === n ? "#fff" : "var(--gray)",
                  fontWeight: pageSize === n ? 700 : 400,
                }}>
                {n}
              </button>
            ))}
          </div>
        </div>

        {/* ── TABLE ── */}
        {loading ? <Loading /> : data.length === 0 ? <Empty /> : (
          <>
            <div className="tbl-wrap">
              <table style={{ tableLayout: "fixed", width: "100%", borderCollapse: "collapse" }}>
                <colgroup>
                  <col style={{ width: "110px" }} />
                  <col style={{ width: "160px" }} />
                  <col style={{ width: "230px" }} />
                  <col style={{ width: "90px" }} />
                  <col style={{ width: "110px" }} />
                  <col style={{ width: "210px" }} />
                </colgroup>
                <thead>
                  <tr>
                    <th style={COL.franchise}>Franchise</th>
                    <th style={COL.driver}>Driver</th>
                    <th style={COL.qrid}>QR Code ID</th>
                    <th style={COL.status}>Status</th>
                    <th style={COL.issued}>Issued</th>
                    <th style={COL.actions}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.length === 0 ? (
                    <tr><td colSpan={6} style={{ textAlign: "center", padding: "24px", color: "var(--gray)" }}>
                      No {statusFilter !== "All" ? statusFilter.toLowerCase() : ""} QR codes found{search ? ` for "${search}"` : ""}.
                    </td></tr>
                  ) : paginated.map((q) => (
                    <tr key={q.id} style={{ opacity: q.status === "Revoked" ? 0.6 : 1, transition: "opacity 0.2s" }}>
                      <td style={COL.franchise}><strong>{q.franchise}</strong></td>
                      <td style={COL.driver}>{q.driver_name}</td>
                      <td style={COL.qrid}>{q.qr_id}</td>
                      <td style={COL.status}>
                        <span className={`badge ${q.status === "Active" ? "badge-active" : "badge-inactive"}`}>
                          {q.status}
                        </span>
                      </td>
                      <td style={COL.issued}>{q.issued_at}</td>
                      <td style={COL.actions}>
                        <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
                          {q.status === "Active" ? (
                            <button className="ib ib-edit" onClick={() => openModal(q)}
                              style={{ background: "#e8f5e9", color: "#2d5a1b", borderColor: "#2d5a1b" }}>
                              <FontAwesomeIcon icon={faQrcode} style={{ marginRight: "4px" }} />View QR
                            </button>
                          ) : (
                            <button className="ib ib-del" disabled
                              style={{ background: "#fee2e2", color: "#dc2626", borderColor: "#fca5a5", opacity: 1, cursor: "default" }}>
                              <FontAwesomeIcon icon={faQrcode} style={{ marginRight: "4px" }} />Revoked
                            </button>
                          )}
                          {q.status === "Active" ? (
                            <button className="ib ib-del" onClick={() => setRevokeItem(q)}
                              disabled={toggling === q.id} style={{ width: "68px" }}>
                              Revoke
                            </button>
                          ) : (
                            <button className="ib ib-edit" onClick={() => setRestoreItem(q)}
                              disabled={toggling === q.id} style={{ width: "68px" }}>
                              Restore
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* ── PAGINATION ── */}
            {filtered.length > pageSize && (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 18px", borderTop: "1px solid var(--gray2)" }}>
                <span style={{ fontSize: ".8rem", color: "var(--gray)" }}>
                  Showing {Math.min((currentPage - 1) * pageSize + 1, filtered.length)}–{Math.min(currentPage * pageSize, filtered.length)} of {filtered.length} QR codes
                </span>
                <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
                  <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}
                    style={{ background: "none", border: "1px solid var(--gray2)", borderRadius: 6, padding: "4px 10px", cursor: currentPage === 1 ? "not-allowed" : "pointer", opacity: currentPage === 1 ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronLeft} style={{ fontSize: 11 }} />
                  </button>
                  {pageWindow.map((p, idx) =>
                    p === '…' ? (
                      <span key={`ellipsis-${idx}`} style={{ fontSize: '.8rem', color: 'var(--gray)', padding: '0 4px' }}>…</span>
                    ) : (
                      <button
                        key={p}
                        onClick={() => setCurrentPage(p)}
                        style={{
                          padding: "4px 10px", borderRadius: 6, fontSize: ".8rem",
                          fontWeight: p === currentPage ? 700 : 400,
                          border: p === currentPage ? "1.5px solid var(--green)" : "1.5px solid var(--gray2)",
                          background: p === currentPage ? "var(--green)" : "none",
                          color: p === currentPage ? "#fff" : "var(--gray)",
                          cursor: "pointer",
                        }}
                      >{p}</button>
                    )
                  )}
                  <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages}
                    style={{ background: "none", border: "1px solid var(--gray2)", borderRadius: 6, padding: "4px 10px", cursor: currentPage === totalPages ? "not-allowed" : "pointer", opacity: currentPage === totalPages ? 0.4 : 1 }}>
                    <FontAwesomeIcon icon={faChevronRight} style={{ fontSize: 11 }} />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* ── QR MODAL ── */}
      {selected && (
        <div onClick={closeModal} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 9999, padding: "24px" }}>
          <div onClick={(e) => e.stopPropagation()} style={{ background: "#fff", borderRadius: "20px", width: "320px", overflow: "hidden", boxShadow: "0 24px 60px rgba(0,0,0,0.2)" }}>
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
              <div style={{ fontSize: "16px", fontWeight: "bold", color: "#1a1a1a", marginBottom: "4px" }}>{selected.driver_name}</div>
              <div style={{ fontSize: "13px", color: "#555", marginBottom: "4px" }}>Franchise: {selected.franchise}</div>
              <div style={{ fontSize: "10px", fontFamily: "monospace", color: "#999", marginBottom: "14px", wordBreak: "break-all" }}>{selected.qr_id}</div>
              <div style={{ display: "inline-flex", alignItems: "center", gap: "6px", background: "#e8f5e9", borderRadius: "20px", padding: "5px 14px", marginBottom: "20px" }}>
          
              </div>
              <div style={{ display: "flex", gap: "8px", marginBottom: "8px" }}>
                <button onClick={printSticker} style={{ flex: 1, padding: "11px", fontSize: "13px", fontWeight: "700", borderRadius: "10px", cursor: "pointer", background: "#2d5a1b", color: "#fff", border: "none" }}>
                  <FontAwesomeIcon icon={faPrint} style={{ marginRight: "6px" }} />Print Sticker
                </button>
                <button onClick={downloadQR} style={{ flex: 1, padding: "11px", fontSize: "13px", fontWeight: "600", borderRadius: "10px", cursor: "pointer", background: "#f5f5f5", color: "#333", border: "1px solid #e0e0e0" }}>
                  <FontAwesomeIcon icon={faDownload} style={{ marginRight: "6px" }} />Download
                </button>
              </div>
              <button onClick={closeModal} style={{ width: "100%", padding: "10px", fontSize: "13px", fontWeight: "700", borderRadius: "10px", cursor: "pointer", background: "#fee2e2", color: "#dc2626", border: "1px solid #fca5a5" }}>
                <FontAwesomeIcon icon={faTimes} style={{ marginRight: "6px" }} />Close
              </button>
            </div>
            <div style={{ background: "#f9f9f9", borderTop: "1px solid #eee", padding: "8px 16px", textAlign: "center" }}>
              <span style={{ fontSize: "11px", color: "#aaa" }}>Nagcarlan LGU · eTODA System · Issued {selected.issued_at}</span>
            </div>
          </div>
        </div>
      )}

      {/* ── REVOKE CONFIRM ── */}
      {revokeItem && (
        <Modal title="Revoke QR Code" onClose={() => setRevokeItem(null)}>
          <div style={{ background: "#fff8e1", border: "1px solid #f59e0b", borderRadius: 10, padding: "14px 16px", marginBottom: 16, fontSize: ".88rem", color: "#78350f", lineHeight: 1.7 }}>
            Are you sure you want to revoke the QR code for <strong>{revokeItem.driver_name}</strong> (Franchise: <strong>{revokeItem.franchise}</strong>)?<br />
            The driver will not be able to use this QR code until it is restored.
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setRevokeItem(null)}>Cancel</button>
            <button onClick={confirmRevoke} disabled={toggling === revokeItem.id}
              style={{ background: "#d97706", color: "#fff", border: "none", borderRadius: 8, padding: "8px 18px", fontWeight: 700, cursor: "pointer" }}>
              <FontAwesomeIcon icon={faBan} style={{ marginRight: 6 }} />
              {toggling === revokeItem.id ? "Revoking..." : "Yes, Revoke"}
            </button>
          </div>
        </Modal>
      )}

      {/* ── RESTORE CONFIRM ── */}
      {restoreItem && (
        <Modal title="Restore QR Code" onClose={() => setRestoreItem(null)}>
          <div style={{ background: "#f0fdf4", border: "1px solid #86efac", borderRadius: 10, padding: "14px 16px", marginBottom: 16, fontSize: ".88rem", color: "#14532d", lineHeight: 1.7 }}>
            Restore the QR code for <strong>{restoreItem.driver_name}</strong> (Franchise: <strong>{restoreItem.franchise}</strong>)?<br />
            The driver will be able to use this QR code again.
          </div>
          <div className="modal-footer">
            <button className="btn btn-ghost" onClick={() => setRestoreItem(null)}>Cancel</button>
            <button onClick={confirmRestore} disabled={toggling === restoreItem.id}
              style={{ background: "var(--green)", color: "#fff", border: "none", borderRadius: 8, padding: "8px 18px", fontWeight: 700, cursor: "pointer" }}>
              <FontAwesomeIcon icon={faCircleCheck} style={{ marginRight: 6 }} />
              {toggling === restoreItem.id ? "Restoring..." : "Yes, Restore"}
            </button>
          </div>
        </Modal>
      )}

    </div>
  );
}

export default QRCodes;