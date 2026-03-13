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
  const CLS  = { success:'toast-success', error:'toast-error', warn:'toast-warn', info:'toast-info', 'login-error':'toast-login-error' };
  const ICON = { success:'✅', error:'❌', warn:'⚠️', info:'ℹ️', 'login-error':'✕' };
  return (
    <div className="toast-wrap">
      {toasts.map(t => (
        <div key={t.id} className={`toast ${CLS[t.type]||'toast-success'}`} onClick={() => dismiss(t.id)} style={t.type === 'login-error' ? {justifyContent: 'space-between'} : {}}>
          {t.type === 'login-error' ? (
            <>
              <div style={{display:'flex', alignItems:'center', gap:12}}>
                <div style={{width:32, height:32, borderRadius:'50%', background:'#fee2e2', display:'flex', alignItems:'center', justifyContent:'center'}}>
                  <span style={{color:'#ef4444', fontSize:16}}>✕</span>
                </div>
                <div>
                  <div style={{color:'#fff', fontWeight:'bold', fontSize:14}}>Login Failed</div>
                  <div style={{color:'rgba(255,255,255,0.7)', fontSize:13}}>{t.msg}</div>
                </div>
              </div>
              <button onClick={(e) => {e.stopPropagation(); dismiss(t.id);}} style={{color:'rgba(255,255,255,0.5)', fontSize:18, background:'none', border:'none', cursor:'pointer'}}>×</button>
            </>
          ) : (
            <>
              <span>{ICON[t.type]}</span><span>{t.msg}</span>
            </>
          )}
        </div>
      ))}
    </div>
  );
}

export { useToast, Toasts };