# Kazi — On-Demand Jobs Marketplace

> Connect workers and employers in real-time. Built for Africa, starting in Nairobi.

---

## Project Structure

```
kazi/
├── backend/          # Django REST API + WebSockets
│   ├── kazi_backend/ # Project settings, URLs, ASGI config
│   └── apps/
│       ├── users/        # Auth (OTP), profiles, skills, KYC
│       ├── jobs/         # Job posting, matching, applications, reviews
│       ├── chat/         # WebSocket real-time messaging
│       ├── payments/     # M-Pesa escrow via IntaSend
│       └── notifications/ # Push + WebSocket notifications
└── flutter_app/      # Flutter Android app
    └── lib/
        ├── core/          # Theme, router, API client, storage
        └── features/
            ├── auth/      # OTP login, registration
            ├── jobs/      # Job list, detail, post, applications
            ├── chat/      # Real-time chat
            ├── profile/   # Profile, edit, KYC
            └── notifications/
```

---

## Prerequisites

### Backend
- Python 3.11+
- PostgreSQL 14+ with PostGIS extension
- Redis 6+
- GDAL (for GeoDjango location queries)

### Flutter
- Flutter 3.16+
- Android Studio (for emulator) or physical Android device
- Java 17

---

## Backend Setup

### 1. Install System Dependencies

**macOS:**
```bash
brew install postgresql postgis redis gdal
```

**Ubuntu / Debian:**
```bash
sudo apt-get install postgresql postgresql-contrib postgis redis-server \
  gdal-bin libgdal-dev libgeos-dev libproj-dev
```

### 2. Create Database

```bash
# Start PostgreSQL
brew services start postgresql  # macOS
sudo service postgresql start   # Ubuntu

# Create DB and enable PostGIS
psql -U postgres
CREATE DATABASE kazi_db;
\c kazi_db
CREATE EXTENSION postgis;
\q
```

### 3. Set Up Python Environment

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 4. Configure Environment

```bash
cp .env.example .env
# Open .env and fill in your values
# At minimum: SECRET_KEY, DB_PASSWORD
# Everything else can stay as default for local development
```

### 5. Run Migrations

```bash
python manage.py migrate
```

This will:
- Create all database tables
- Seed 34 skill categories automatically

### 6. Create Superuser (for Django Admin)

```bash
python manage.py createsuperuser
# It will ask for phone number (use +254XXXXXXXXX format) and password
```

### 7. Start Redis

```bash
redis-server  # macOS/Linux
# Windows: use Redis for Windows or WSL
```

### 8. Start the Backend

```bash
# Development (auto-reload)
python manage.py runserver

# The API is now at: http://localhost:8000/api/v1/
# Django Admin: http://localhost:8000/admin/
```

---

## Flutter App Setup

### 1. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Firebase Setup (for Push Notifications)

1. Go to https://console.firebase.google.com
2. Create a new project called "Kazi"
3. Add an Android app with package name: `com.kazi.app`
4. Download `google-services.json`
5. Place it at: `flutter_app/android/app/google-services.json`

### 3. Configure API URL

The app points to `http://10.0.2.2:8000` by default.
`10.0.2.2` is Android emulator's alias for your Mac/PC localhost.

For a physical device on the same WiFi:
- Find your machine's local IP: `ifconfig | grep inet` (macOS) or `ip addr` (Linux)
- Edit `lib/core/services/api_client.dart`: change `defaultValue` to `http://YOUR_IP:8000/api/v1`

### 4. Run on Emulator or Device

```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run

# Run on specific device
flutter run -d <device-id>
```

---

## External Services Setup

### Africa's Talking (SMS for OTP)
1. Sign up at https://africastalking.com
2. In sandbox mode, OTP codes will appear in the **debug_code** field of the API response — no real SMS needed for testing
3. For production: add your number to the sandbox testers list, then upgrade to live

### IntaSend (M-Pesa Payments)
1. Sign up at https://intasend.com
2. You need a registered Kenyan business (even a sole proprietorship works)
3. Sandbox mode available immediately — no real money moves
4. STK push test: use the sandbox M-Pesa test credentials from the IntaSend dashboard
5. For webhooks during development: use [ngrok](https://ngrok.com) to expose your local server

```bash
# Install ngrok, then:
ngrok http 8000
# Copy the https URL to BACKEND_URL in your .env
```

### Smile Identity (ID Verification)
1. Sign up at https://smileidentity.com
2. Sandbox access is free and immediate
3. Test with: ID type `NATIONAL_ID`, country `KE`, any 8-digit number

---

## API Reference (Key Endpoints)

```
POST /api/v1/auth/request-otp/          Send OTP to phone
POST /api/v1/auth/verify-otp/           Verify OTP, get JWT tokens
POST /api/v1/auth/complete-registration/ First-time profile setup
POST /api/v1/auth/refresh/              Refresh JWT token

GET  /api/v1/users/me/                  Get my profile
POST /api/v1/users/location/            Update GPS location
POST /api/v1/users/online-status/       Toggle worker availability
GET  /api/v1/users/skills/             List all skill categories

GET  /api/v1/jobs/                      List open jobs (with filters)
POST /api/v1/jobs/create/               Post a new job
GET  /api/v1/jobs/:id/                  Job detail
POST /api/v1/jobs/:id/apply/            Worker applies for job
GET  /api/v1/jobs/:id/applications/     Employer sees applications
POST /api/v1/jobs/:id/applications/:id/accept/  Hire a worker
POST /api/v1/jobs/:id/complete/         Mark job complete + release payment
POST /api/v1/jobs/:id/review/           Submit rating

POST /api/v1/payments/initiate/         Trigger M-Pesa STK push
POST /api/v1/payments/webhook/intasend/ IntaSend payment webhook (public)

GET  /api/v1/chat/:job_id/              Get chat room for a job
GET  /api/v1/chat/:room_id/messages/    Load message history

WebSocket: ws://server/ws/chat/:room_id/?token=<jwt>
WebSocket: ws://server/ws/notifications/?token=<jwt>
```

---

## Development Workflow

### Testing OTP Without Real SMS
In DEBUG mode, the `/auth/request-otp/` response includes `debug_code`.
Use this code directly in `/auth/verify-otp/`. No SMS credit needed.

### Testing Payments Without Real M-Pesa
1. Set `INTASEND_TEST_MODE=True` in `.env`
2. Use IntaSend sandbox credentials
3. STK push goes to test M-Pesa, not real money
4. Simulate webhook: POST to `/api/v1/payments/webhook/intasend/` with test payload

### Running Tests
```bash
# Backend
python manage.py test

# Flutter
flutter test
```

---

## Deployment (Railway)

1. Push backend to GitHub
2. Create new Railway project → "Deploy from GitHub repo"
3. Add PostgreSQL plugin (enable PostGIS: `CREATE EXTENSION postgis;` in DB console)
4. Add Redis plugin
5. Set all environment variables from `.env.example`
6. Set start command: `gunicorn kazi_backend.asgi:application -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT`
7. Update `BACKEND_URL` in `.env` to your Railway URL
8. Update `ALLOWED_HOSTS` to include your Railway domain

---

## Sprint Roadmap

| Sprint | Status | What's Built |
|--------|--------|-------------|
| 1 | ✅ Done | Auth (OTP), user profiles, onboarding |
| 2 | ✅ Done | Job posting, categories, skills |
| 3 | ✅ Done | Location matching (PostGIS), job feed |
| 4 | ✅ Done | Real-time notifications (WebSocket + FCM) |
| 5 | ✅ Done | In-app chat (WebSocket) |
| 6 | ✅ Done | M-Pesa escrow (IntaSend) |
| 7 | 🔜 Next | Smile Identity KYC, ratings/reviews wire-up |
| 8 | 🔜 Next | Polish, edge cases, beta testing |

---

## What's TODO Before Launch

- [ ] Wire all Flutter BLoC events to real API calls (currently some screens use mock data)
- [ ] Implement Smile Identity KYC flow end-to-end
- [ ] Add `manage.py` migration for `0001_initial` (auto-generated by Django once models are stable)
- [ ] Set up ngrok + test full IntaSend payment flow
- [ ] Register business at bizregistry.go.ke
- [ ] Upload app to Google Play internal testing track
- [ ] Run with 5–10 beta users in Nairobi

---

## Built With

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Dart) |
| Backend | Django + Django REST Framework |
| Database | PostgreSQL + PostGIS (GeoDjango) |
| Real-time | Django Channels + Redis |
| Payments | IntaSend (M-Pesa) |
| SMS | Africa's Talking |
| KYC | Smile Identity |
| Push | Firebase Cloud Messaging |
| Hosting | Railway (backend) + Supabase (DB) |
