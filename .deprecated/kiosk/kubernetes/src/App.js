import React from 'react';

const DASHBOARD_URL = process.env.REACT_APP_HA_DASHBOARD_URL || '/dashboard-kitchenkiosk/';

function App() {
  return (
    <iframe
      title="Home Assistant Dashboard"
      src={DASHBOARD_URL}
      style={{
        width: '100vw',
        height: '100vh',
        border: 'none',
        display: 'block',
      }}
    />
  );
}

export default App;
