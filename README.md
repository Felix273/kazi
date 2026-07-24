# Kazi

Kazi is a Flutter and Firebase marketplace that connects nearby employers with job seekers. Employers can publish jobs, review applicants, hire through M-Pesa escrow, monitor work check-in/check-out, chat, and rate workers. Job seekers can discover nearby work, apply, manage active jobs, receive payment into a wallet, request M-Pesa withdrawals, chat, submit disputes, and complete identity verification.

## Implemented application flow

### Authentication and profiles

- Email/password registration and login
- Firebase phone authentication with OTP
- Role-specific onboarding for employers and job seekers
- Firebase Auth-backed session restoration
- Profile editing, profile image upload, skills, location, availability, and notification preferences
- Private identity-verification submission with a pending-review state

### Job marketplace

- Employer job publishing with salary, fees, requirements, dates, urgency, and map location
- Nearby-job discovery using the job seeker's current location and saved search radius
- Category and distance filtering
- Transaction-safe applications with deterministic IDs to prevent duplicates
- Employer applicant review, decline, chat, and hire actions
- Stable one-chat-per-job-and-worker conversations

### Work and payments

- M-Pesa STK Push hiring/escrow flow through Cloud Functions
- Mock payment mode for local development
- GPS-validated work check-in and check-out
- Server-authoritative completion and worker-wallet credit
- M-Pesa B2C withdrawal requests and callback handling
- Job boosts with Basic, Standard, and Premium tiers
- Idempotent callback processing to reduce duplicate credits or repeated hiring

### Trust and communication

- Foreground and background push notifications
- User-controlled notification preferences
- New-job proximity notifications
- Chat-message notifications
- Post-job ratings with server-maintained averages
- Dispute creation, evidence upload, admin alerts, and server-side dispute resolution

## Project structure

```text
lib/
  models/       Firestore data models
  providers/    Riverpod language and theme state
  screens/      Authentication, employer, job-seeker, and shared UI
  services/     Firebase, jobs, payments, chat, profile, ratings, and location
  constants/    App-wide constants
functions/      Firebase Cloud Functions and M-Pesa integration
firestore.rules
firestore.indexes.json
storage.rules
firebase.json
```

## Requirements

- Flutter with Dart 3.10.8 or later
- Android SDK and Java 17
- Node.js 20 for Firebase Functions
- Firebase CLI
- A Firebase project with Authentication, Firestore, Storage, Functions, Messaging, Analytics, and Crashlytics enabled
- A Google Maps API key for Android
- Safaricom Daraja credentials for real M-Pesa payments

## Run the Flutter app

The project root is the directory that directly contains `pubspec.yaml`, `lib/`, `android/`, and `test/`. Before running Flutter commands, verify it with:

```bash
pwd
test -f pubspec.yaml && echo "Correct Kazi project root"
```

Do not run Flutter commands from the parent extraction directory. Flutter may walk upward and use an unrelated `pubspec.yaml`, causing hundreds of false missing-package errors.

From the verified project root:

```bash
flutter pub get
```

Create the local Android configuration if it is missing:

```bash
cp android/local.properties.example android/local.properties
```

Then update the Flutter SDK, Android SDK, and Maps values in `android/local.properties`:

```properties
sdk.dir=/home/your-user/Android/Sdk
flutter.sdk=/home/your-user/flutter
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

Run the app. The support WhatsApp number is supplied as digits without `+`:

```bash
flutter run --dart-define=SUPPORT_WHATSAPP=2547XXXXXXXX
```

The Android Firebase configuration is registered for package `com.kazi.app`. Configure every additional platform before running it there. For iOS, for example, add the correct `GoogleService-Info.plist` or run your normal FlutterFire configuration workflow.

## Configure Firebase Functions

Install backend dependencies:

```bash
npm --prefix functions install
```

For local development, copy the environment template to the environment file used by your Firebase project:

```bash
cp functions/.env.example functions/.env.kazi-e81ea
```

`MPESA_MOCK=true` completes supported payment flows without contacting Daraja. It must be disabled before production deployment.

For real payments, populate all required variables in the environment file:

- `MPESA_CONSUMER_KEY`
- `MPESA_CONSUMER_SECRET`
- `MPESA_SHORTCODE`
- `MPESA_PASSKEY`
- `MPESA_CALLBACK_URL`
- `MPESA_B2C_SHORTCODE`
- `MPESA_B2C_INITIATOR`
- `MPESA_B2C_SECURITY_CREDENTIAL`
- `MPESA_B2C_RESULT_URL`
- `MPESA_B2C_TIMEOUT_URL`

The callback URLs must be publicly reachable HTTPS endpoints for the deployed Cloud Functions in region `africa-south1`.

## Deploy Firebase resources

Select the correct Firebase project, then deploy the rules, indexes, Storage rules, and Functions:

```bash
firebase use kazi-e81ea
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

For local backend development:

```bash
firebase emulators:start --only firestore,functions
```

## Validation commands

Run these on a machine with Flutter installed:

```bash
flutter analyze
flutter test
flutter build apk --debug
npm --prefix functions run lint
```

## Production checklist

Before release:

1. Replace mock M-Pesa mode with valid Daraja credentials and verified callback URLs.
2. Add a restricted Google Maps API key.
3. Configure Firebase for every target platform.
4. Create a production Android signing key; the current release build still uses debug signing.
5. Set the support WhatsApp number through `--dart-define` or your release build configuration.
6. Assign the Firebase custom claim `admin: true` only to trusted administrators responsible for disputes and identity reviews.
7. Test Firestore and Storage rules in the Firebase Emulator Suite.
8. Run end-to-end tests for duplicate callbacks, failed STK requests, failed B2C payouts, offline operation, denied location permission, and notification delivery.
