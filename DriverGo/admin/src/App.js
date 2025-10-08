import React, { useEffect, useState } from 'react';

function App() {
  const [drivers, setDrivers] = useState([]);

  useEffect(() => {
    fetch('http://localhost:4000/api/admin/drivers')
      .then(r => r.json())
      .then(d => setDrivers(d.drivers || []))
      .catch(err => console.error(err));
  }, []);

  return (
    <div style={{padding:20}}>
      <h1>Admin Dashboard - Drivers</h1>
      <table border="1" cellPadding="8" style={{borderCollapse:'collapse'}}>
        <thead><tr><th>ID</th><th>Name</th><th>Vehicle</th><th>Available</th></tr></thead>
        <tbody>
          {drivers.map(d => (
            <tr key={d.id}>
              <td>{d.id}</td>
              <td>{d.name}</td>
              <td>{d.vehicle_type}</td>
              <td>{d.available ? 'Yes' : 'No'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default App;
