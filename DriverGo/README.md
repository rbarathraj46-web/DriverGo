Driver Hiring App - Starter Kit
==================================

This archive contains a compact starter project for the Driver Hiring App built with:
- Mobile app: Flutter (Dart) (client)
- Backend: Node.js + Express
- Database: PostgreSQL (SQL schema provided)
- Authentication: Firebase Auth (client), Firebase Admin (server)
- Real-time: Firebase Realtime Database
- Storage: Firebase Storage
- Payments: Razorpay (server order creation, client checkout sample)
- Maps: Google Maps (Flutter plugin)
- Notifications: Firebase Cloud Messaging (client)
- Admin Dashboard: React.js (simple starter)
- Local dev: Docker Compose (postgres + backend)
- CI: GitHub Actions samples (backend + admin)

IMPORTANT:
- This is a starter scaffold showing working patterns and core files. You must configure Firebase project, Google Maps API key,
  Razorpay keys, and a Firebase service account for the backend to run end-to-end.
- Sensitive files (serviceAccount.json, .env with secrets) should NOT be committed to git. Use secrets in CI/GCloud deployments.

Quick local dev:
1. Copy .env.example to backend/.env and fill values.
2. Place your Firebase service account JSON at backend/serviceAccountKey.json (or set env var).
3. Run: docker-compose up --build  (in backend/) to start postgres + backend (backend talks to Firebase externally).
4. Run Flutter app (mobile/) after adding firebase config and Google Maps API key as described in mobile/README.md.
5. Run admin: cd admin && npm install && npm start

Zip contents provided in this folder.
