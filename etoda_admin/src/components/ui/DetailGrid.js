// src/components/ui/DetailGrid.js
import React from 'react';

function DG({ rows }) {
  return (
    <div className="detail-grid">
      {rows.map(([k, v]) => (
        <div key={k}><div className="detail-key">{k}</div><div className="detail-val">{v||'—'}</div></div>
      ))}
    </div>
  );
}

export default DG;