require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const admin = require('firebase-admin');
const fs = require('fs');
const { Pool } = require('pg');
const Razorpay = require('razorpay');

const PORT = process.env.PORT || 4000;

// Initialize Firebase Admin with service account
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './serviceAccountKey.json';
if (!fs.existsSync(serviceAccountPath)) {
  console.warn('Warning: Firebase service account file not found at', serviceAccountPath);
}
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL
});

// Postgres pool
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Razorpay instance
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || '',
  key_secret: process.env.RAZORPAY_KEY_SECRET || ''
});

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Middleware: verify Firebase token
async function verifyFirebaseToken(req, res, next) {
  const auth = req.headers.authorization || '';
  const match = auth.match(/^Bearer\s+(.*)$/i);
  if (!match) return res.status(401).json({ error: 'Missing Authorization header' });
  const idToken = match[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.user = decoded;
    next();
  } catch (err) {
    console.error('Token verify error', err);
    return res.status(401).json({ error: 'Invalid auth token' });
  }
}

// Upsert user profile after Firebase sign-in on client
app.post('/api/auth/upsert', verifyFirebaseToken, async (req, res) => {
  const uid = req.user.uid;
  const { name, phone } = req.body || {};
  try {
    const result = await pool.query(
      `INSERT INTO users(uid, name, email, phone, role)
       VALUES($1,$2,$3,$4,$5)
       ON CONFLICT (uid) DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone
       RETURNING id, uid, name, email, phone, role`,
      [uid, name || req.user.name || null, req.user.email || null, phone || null, 'client']
    );
    res.json({ user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error', details: err.message });
  }
});

// Get drivers (simple filter support)
app.get('/api/drivers', async (req, res) => {
  const { q, available } = req.query;
  try {
    let sql = 'SELECT id, name, vehicle_type, experience_years, rating, latitude, longitude, available FROM drivers WHERE 1=1';
    const params = [];
    if (available === 'true') { sql += ' AND available = true'; }
    if (q) { params.push('%' + q + '%'); sql += ` AND (name ILIKE $${params.length} OR vehicle_type ILIKE $${params.length})`; }
    const result = await pool.query(sql, params);
    res.json({ drivers: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error', details: err.message });
  }
});

// Get single driver
app.get('/api/drivers/:id', async (req, res) => {
  const id = req.params.id;
  try {
    const result = await pool.query('SELECT * FROM drivers WHERE id = $1', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ driver: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error', details: err.message });
  }
});

// Update driver availability (also mirror into Firebase Realtime DB)
app.post('/api/drivers/:id/availability', verifyFirebaseToken, async (req, res) => {
  const id = req.params.id;
  const { available, latitude, longitude } = req.body;
  try {
    await pool.query('UPDATE drivers SET available = $1, latitude = $2, longitude = $3 WHERE id = $4', [available, latitude, longitude, id]);
    // Mirror to Firebase Realtime DB for realtime clients
    const dbRef = admin.database().ref(`drivers/${id}`);
    await dbRef.update({ available: !!available, latitude: latitude || null, longitude: longitude || null, updatedAt: Date.now() });
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error', details: err.message });
  }
});

// Create booking and create Razorpay order (if amount provided)
app.post('/api/bookings', verifyFirebaseToken, async (req, res) => {
  const { driver_id, start_time, end_time, amount } = req.body;
  try {
    // Insert booking in DB (status = pending)
    const result = await pool.query(
      `INSERT INTO bookings(client_uid, driver_id, start_time, end_time, status)
       VALUES($1,$2,$3,$4,$5) RETURNING id`,
      [req.user.uid, driver_id, start_time || null, end_time || null, 'pending']
    );
    const bookingId = result.rows[0].id;
    let order = null;
    if (amount && Number(amount) > 0) {
      const options = {
        amount: Math.round(Number(amount) * 100), // amount in paise
        currency: 'INR',
        receipt: 'rcpt_' + bookingId,
        payment_capture: 1
      };
      order = await razorpay.orders.create(options);
      // Store payment record (partial)
      await pool.query(
        'INSERT INTO payments(booking_id, razorpay_order_id, amount, currency, status) VALUES($1,$2,$3,$4,$5)',
        [bookingId, order.id, amount, 'INR', 'created']
      );
    }
    res.json({ bookingId, order });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error', details: err.message });
  }
});

// Simple admin: list drivers (secured by verifying Firebase token and checking a claim later - for demo we allow any token)
app.get('/api/admin/drivers', verifyFirebaseToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM drivers ORDER BY id DESC LIMIT 500');
    res.json({ drivers: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'db_error', details: err.message });
  }
});

app.get('/', (req, res) => res.send('Driver Hiring Backend is running'));

app.listen(PORT, () => console.log('Server listening on', PORT));
