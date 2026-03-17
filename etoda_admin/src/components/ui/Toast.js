// src/components/ui/Toast.js
import React, { useState, useCallback, useRef } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faCheckCircle, faTimesCircle, faExclamationTriangle,
  faInfoCircle, faLock, faTimes,
} from '@fortawesome/free-solid-svg-icons';

function useToast() {
  const [toasts, setToasts] = useState([]);
  const n = useRef(0);
  const notify = useCallback((msg, type = 'success') => {
    const id = ++n.current;
    setToasts(p => [...p, { id, msg, type }]);
    setTimeout(() => setToasts(p => p.filter(t => t.id !== id)), 3800);
  }, []);
  const dismiss = id => setToasts(p => p.filter(t => t.id !== id));
  return { toasts, notify, dismiss };
}

// Config per type — color, icon, label
const CONFIG = {
  success:      { bg: '#2d5a1b', border: '#1e3d12', iconBg: 'rgba(255,255,255,0.15)', icon: faCheckCircle,          iconColor: '#fff', label: 'Success'     },
  error:        { bg: '#dc2626', border: '#b91c1c', iconBg: 'rgba(255,255,255,0.15)', icon: faTimesCircle,           iconColor: '#fff', label: 'Error'       },
  warn:         { bg: '#d97706', border: '#b45309', iconBg: 'rgba(255,255,255,0.15)', icon: faExclamationTriangle,   iconColor: '#fff', label: 'Warning'     },
  info:         { bg: '#0284c7', border: '#0369a1', iconBg: 'rgba(255,255,255,0.15)', icon: faInfoCircle,            iconColor: '#fff', label: 'Info'        },
  'login-error':{ bg: '#1e1e2e', border: '#dc2626', iconBg: '#fee2e2',               icon: faLock,                  iconColor: '#dc2626', label: 'Login Failed' },
};

function Toasts({ toasts, dismiss }) {
  return (
    <div style={{
      position: 'fixed',
      top: '20px',
      right: '20px',
      zIndex: 99999,
      display: 'flex',
      flexDirection: 'column',
      gap: '10px',
      minWidth: '300px',
      maxWidth: '380px',
    }}>
      {toasts.map(t => {
        const cfg = CONFIG[t.type] || CONFIG.success;
        return (
          <div
            key={t.id}
            onClick={() => dismiss(t.id)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px 14px',
              background: cfg.bg,
              border: `1px solid ${cfg.border}`,
              borderRadius: '12px',
              boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
              cursor: 'pointer',
              animation: 'slideIn 0.25s ease',
            }}
          >
            <style>{`
              @keyframes slideIn {
                from { opacity: 0; transform: translateX(40px); }
                to   { opacity: 1; transform: translateX(0); }
              }
            `}</style>

            {/* Icon circle */}
            <div style={{
              width: '34px', height: '34px', borderRadius: '50%',
              background: cfg.iconBg,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <FontAwesomeIcon icon={cfg.icon} style={{ color: cfg.iconColor, fontSize: '15px' }} />
            </div>

            {/* Text */}
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ color: '#fff', fontWeight: '700', fontSize: '13px', marginBottom: '2px' }}>
                {cfg.label}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: '12px', wordBreak: 'break-word' }}>
                {t.msg}
              </div>
            </div>

            {/* Dismiss button */}
            <button
              onClick={e => { e.stopPropagation(); dismiss(t.id); }}
              style={{
                background: 'none', border: 'none', cursor: 'pointer',
                color: 'rgba(255,255,255,0.5)', fontSize: '16px',
                flexShrink: 0, padding: '2px',
                display: 'flex', alignItems: 'center',
              }}
            >
              <FontAwesomeIcon icon={faTimes} />
            </button>
          </div>
        );
      })}
    </div>
  );
}

export { useToast, Toasts };