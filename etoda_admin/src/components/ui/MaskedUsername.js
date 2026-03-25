import React, { useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faEye, faEyeSlash } from '@fortawesome/free-solid-svg-icons';

export default function MaskedUsername({ username }) {
  const [hidden, setHidden] = useState(true);

  if (!username) return <span>—</span>;

  let displayText = username;
  // Mask the username if it's hidden and long enough to be masked effectively
  if (hidden && username.length > 3) {
    const start = username.substring(0, 2);
    const end = username.substring(username.length - 1);
    const mask = '*'.repeat(username.length - 3);
    displayText = `${start}${mask}${end}`;
  }

  return (
    <span 
      onClick={() => setHidden(!hidden)} 
      style={{ cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: '6px' }}
      title={hidden ? "Click to reveal" : "Click to hide"}
    >
      {displayText}
      <FontAwesomeIcon icon={hidden ? faEyeSlash : faEye} style={{ color: '#aaa', fontSize: '13px' }} />
    </span>
  );
}