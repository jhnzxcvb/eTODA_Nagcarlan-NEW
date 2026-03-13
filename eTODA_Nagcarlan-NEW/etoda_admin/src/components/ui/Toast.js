// src/components/ui/Toast.js
import React from 'react';
import { useState, useCallback, useRef } from 'react';

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

function Toasts({ toasts, dismiss }) {
  const CLS  = { success:'toast-success', error:'toast-error', warn:'toast-warn', info:'toast-info' };
  const ICON = { success:'✅', error:'❌', warn:'⚠️', info:'ℹ️' };
  return (
    <div className="toast-wrap">
      {toasts.map(t => (
        <div key={t.id} className={`toast ${CLS[t.type]||'toast-success'}`} onClick={() => dismiss(t.id)}>
          <span>{ICON[t.type]}</span><span>{t.msg}</span>
        </div>
      ))}
    </div>
  );
}

export { useToast, Toasts };