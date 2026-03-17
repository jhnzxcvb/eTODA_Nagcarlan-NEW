// src/components/qrcodes/QRCodes.js
import React, { useState, useEffect, useRef } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faPrint,
  faDownload,
  faTimes,
  faQrcode,
} from "@fortawesome/free-solid-svg-icons";
import { api } from "../../lib/api";
import Loading from "../ui/Loading";
import Empty from "../ui/Empty";
import QRCode from "qrcode";

function QRCodes({ notify }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);
  const [qrDataUrl, setQrDataUrl] = useState("");

  const load = async () => {
    setLoading(true);
    const r = await api("/api/qrcodes");
    if (r.success) setData(r.data || []);
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const update = async (id, status) => {
    const r = await api(`/api/qrcodes/${id}`, "PATCH", { status });
    if (r.success) {
      load();
      notify(`QR → ${status}`, status === "Active" ? "success" : "warn");
    }
  };

  const openModal = async (q) => {
    setSelected(q);
    try {
      const url = await QRCode.toDataURL(q.qr_id, {
        width: 200,
        margin: 2,
        color: { dark: "#2d5a1b", light: "#ffffff" },
      });
      setQrDataUrl(url);
    } catch {
      notify("Failed to generate QR code", "error");
    }
  };

  const closeModal = () => {
    setSelected(null);
    setQrDataUrl("");
  };

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
      <!DOCTYPE html>
      <html>
      <head>
        <title>QR Sticker - ${selected.franchise}</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: 'Segoe UI', sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; background: #fff; }
          .sticker { width: 280px; border: 2px solid #2d5a1b; border-radius: 16px; overflow: hidden; text-align: center; }
          .sticker-header { background: #2d5a1b; padding: 14px 16px; color: #fff; }
          .sticker-header h1 { font-size: 18px; font-weight: bold; margin-bottom: 2px; }
          .sticker-header p  { font-size: 11px; opacity: 0.8; }
          .sticker-body { padding: 20px 16px; }
          .qr-wrap { display: inline-block; padding: 10px; border: 2px solid #2d5a1b; border-radius: 10px; margin-bottom: 14px; }
          .qr-wrap img { display: block; width: 160px; height: 160px; }
          .driver-name { font-size: 16px; font-weight: bold; color: #1a1a1a; margin-bottom: 4px; }
          .franchise   { font-size: 13px; color: #555; margin-bottom: 6px; }
          .qr-id       { font-size: 9px; font-family: monospace; color: #888; margin-bottom: 12px; word-break: break-all; }
          .badge       { display: inline-block; padding: 4px 12px; background: #e8f5e9; color: #2d5a1b; border-radius: 20px; font-size: 11px; font-weight: bold; margin-bottom: 4px; }
          .sticker-footer { background: #f5f5f5; padding: 8px 12px; font-size: 10px; color: #888; border-top: 1px solid #e0e0e0; }
          @media print { body { margin: 0; } .sticker { border: 2px solid #2d5a1b !important; } }
        </style>
      </head>
      <body>
        <div class="sticker">
          <div class="sticker-header">
            <h1>eTODA Nagcarlan</h1>
            <p>Official Driver QR Code</p>
          </div>
          <div class="sticker-body">
            <div class="qr-wrap">
              <img src="${qrDataUrl}" alt="QR Code" />
            </div>
            <div class="driver-name">${selected.driver_name}</div>
            <div class="franchise">Franchise: ${selected.franchise}</div>
            <div class="qr-id">${selected.qr_id}</div>
            <div class="badge">✓ Active · AES-256 Encrypted</div>
          </div>
          <div class="sticker-footer">
            Nagcarlan LGU · eTODA System · Issued ${selected.issued_at}
          </div>
        </div>
        <script>window.onload = () => { window.print(); window.close(); }<\/script>
      </body>
      </html>
    `);
    win.document.close();
  };

  return (
    <div>
      <div className="box-info">
        Each QR is AES-256 encrypted. Revoking immediately invalidates it.
        Restoring generates a brand-new QR ID.
      </div>
      <div className="card">
        <div className="card-head">
          <div className="card-title">
            📲 QR Codes <span>({data.length})</span>
          </div>
          <button className="btn btn-ghost btn-sm" onClick={load}>
            ↻ Refresh
          </button>
        </div>
        {loading ? (
          <Loading />
        ) : data.length === 0 ? (
          <Empty />
        ) : (
          <div className="tbl-wrap">
            <table>
              <thead>
                <tr>
                  <th>Franchise</th>
                  <th>Driver</th>
                  <th>QR CODE ID</th>
                  <th>Status</th>
                  <th>Issued</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.map((q) => (
                  <tr key={q.id}>
                    <td>
                      <strong>{q.franchise}</strong>
                    </td>
                    <td>{q.driver_name}</td>
                    <td
                      style={{
                        fontFamily: "monospace",
                        fontSize: ".75rem",
                        color: "var(--green)",
                      }}
                    >
                      {q.qr_id}
                    </td>
                    <td>
                      <span
                        className={`badge ${q.status === "Active" ? "badge-active" : "badge-inactive"}`}
                      >
                        {q.status}
                      </span>
                    </td>
                    <td>{q.issued_at}</td>
                    <td>
                      <div className="row-actions">
                        {q.status === "Active" && (
                          <button
                            className="ib ib-del"
                            onClick={() => update(q.id, "Revoked")}
                          >
                            Revoke
                          </button>
                        )}
                        {q.status !== "Active" && (
                          <button
                            className="ib ib-edit"
                            onClick={() => update(q.id, "Active")}
                          >
                            Restore & Regen
                          </button>
                        )}
                        <button
                          className="ib ib-edit"
                          onClick={() => openModal(q)}
                          style={{
                            background: "#e8f5e9",
                            color: "#2d5a1b",
                            borderColor: "#2d5a1b",
                          }}
                        >
                          <FontAwesomeIcon
                            icon={faQrcode}
                            style={{ marginRight: "5px" }}
                          />
                          View QR
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

      {/* ── QR Modal ── */}
      {selected && (
        <div
          onClick={closeModal}
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(0,0,0,0.55)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 9999,
            padding: "24px",
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              background: "#fff",
              borderRadius: "20px",
              width: "320px",
              overflow: "hidden",
              boxShadow: "0 24px 60px rgba(0,0,0,0.2)",
            }}
          >
            {/* Header */}
            <div
              style={{
                background: "#2d5a1b",
                padding: "16px 20px",
                textAlign: "center",
              }}
            >
              <div
                style={{ fontSize: "18px", fontWeight: "bold", color: "#fff" }}
              >
                eTODA Nagcarlan
              </div>
              <div
                style={{
                  fontSize: "12px",
                  color: "rgba(255,255,255,0.75)",
                  marginTop: "2px",
                }}
              >
                Official Driver QR Code
              </div>
            </div>

            {/* Body */}
            <div style={{ padding: "24px 20px", textAlign: "center" }}>
              {qrDataUrl ? (
                <div
                  style={{
                    display: "inline-block",
                    padding: "12px",
                    border: "2px solid #2d5a1b",
                    borderRadius: "12px",
                    marginBottom: "16px",
                  }}
                >
                  <img
                    src={qrDataUrl}
                    alt="QR Code"
                    style={{
                      display: "block",
                      width: "160px",
                      height: "160px",
                    }}
                  />
                </div>
              ) : (
                <div
                  style={{
                    width: "160px",
                    height: "160px",
                    margin: "0 auto 16px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: "#aaa",
                    fontSize: "13px",
                  }}
                >
                  Generating...
                </div>
              )}

              <div
                style={{
                  fontSize: "16px",
                  fontWeight: "bold",
                  color: "#1a1a1a",
                  marginBottom: "4px",
                }}
              >
                {selected.driver_name}
              </div>
              <div
                style={{ fontSize: "13px", color: "#555", marginBottom: "4px" }}
              >
                Franchise: {selected.franchise}
              </div>
              <div
                style={{
                  fontSize: "10px",
                  fontFamily: "monospace",
                  color: "#999",
                  marginBottom: "14px",
                  wordBreak: "break-all",
                }}
              >
                {selected.qr_id}
              </div>

              <div
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "6px",
                  background: "#e8f5e9",
                  borderRadius: "20px",
                  padding: "5px 14px",
                  marginBottom: "20px",
                }}
              >
                <div
                  style={{
                    width: "8px",
                    height: "8px",
                    borderRadius: "50%",
                    background: "#2d5a1b",
                  }}
                />
                <span
                  style={{
                    fontSize: "12px",
                    color: "#2d5a1b",
                    fontWeight: "600",
                  }}
                >
                  Active · AES-256 Encrypted
                </span>
              </div>

              {/* Action buttons */}
              <div style={{ display: "flex", gap: "8px", marginBottom: "8px" }}>
                <button
                  onClick={printSticker}
                  style={{
                    flex: 1,
                    padding: "11px",
                    fontSize: "13px",
                    fontWeight: "700",
                    borderRadius: "10px",
                    cursor: "pointer",
                    background: "#2d5a1b",
                    color: "#fff",
                    border: "none",
                  }}
                >
                  <FontAwesomeIcon
                    icon={faPrint}
                    style={{ marginRight: "6px" }}
                  />
                  Print Sticker
                </button>
                <button
                  onClick={downloadQR}
                  style={{
                    flex: 1,
                    padding: "11px",
                    fontSize: "13px",
                    fontWeight: "600",
                    borderRadius: "10px",
                    cursor: "pointer",
                    background: "#f5f5f5",
                    color: "#333",
                    border: "1px solid #e0e0e0",
                  }}
                >
                  <FontAwesomeIcon
                    icon={faDownload}
                    style={{ marginRight: "6px" }}
                  />
                  Download
                </button>
              </div>

              {/* Close button — red */}
              <button
                onClick={closeModal}
                style={{
                  width: "100%",
                  padding: "10px",
                  fontSize: "13px",
                  fontWeight: "700",
                  borderRadius: "10px",
                  cursor: "pointer",
                  background: "#fee2e2",
                  color: "#dc2626",
                  border: "1px solid #fca5a5",
                }}
              >
                <FontAwesomeIcon
                  icon={faTimes}
                  style={{ marginRight: "6px" }}
                />
                Close
              </button>
            </div>

            {/* Footer */}
            <div
              style={{
                background: "#f9f9f9",
                borderTop: "1px solid #eee",
                padding: "8px 16px",
                textAlign: "center",
              }}
            >
              <span style={{ fontSize: "11px", color: "#aaa" }}>
                Nagcarlan LGU · eTODA System · Issued {selected.issued_at}
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default QRCodes;
