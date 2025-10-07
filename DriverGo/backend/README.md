Backend - Quickstart
---------------------
1. Copy .env.example to .env and fill in values.
2. Place your Firebase serviceAccount JSON at backend/serviceAccountKey.json (or set FIREBASE_SERVICE_ACCOUNT_PATH).
3. Start Postgres + Backend locally (from backend/):
    docker-compose up --build
4. Seed the database:
    docker exec -it <postgres_container> psql -U postgres -d driverdb -f /path/to/db.sql
   (or connect with pgAdmin and run backend/db.sql)
5. The backend will run on http://localhost:4000
