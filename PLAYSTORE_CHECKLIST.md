# Kazi — Play Store Submission Checklist

## 1. Build Signed APK/AAB

### Generate Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload \
  -storetype JKS \
  -dname "CN=Kazi App, OU=Kazi, O=Kazi Ltd, L=Nairobi, S=Nairobi, C=KE"
```

Store password, key password, and alias: remember these. Store the `.jks` file securely.

### Create Key Properties File

Create `~/.key.properties` (NEVER commit this file):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=/home/<user>/upload-keystore.jks
```

### Configure android/app/build.gradle

Add to the top of the file:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Update `android` block:

```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Build App Bundle (Recommended)

```bash
flutter build appbundle --release
```

Output: `build/app/output/bundle/release/app-release.aab`

### Build APK (Alternative)

```bash
flutter build apk --release --split-per-abi
```

Output: `build/app/output/flutter-apk/`

## 2. Play Store Listing Content

### App Title (max 30 chars)
| Language | Title |
|---|---|
| English | Kazi - Find Work Fast |

### Short Description (max 80 chars)
| Language | Description |
|---|---|
| English | Hyperlocal jobs in Nairobi. Apply instantly, get paid via M-Pesa. |

### Full Description (see PLAYSTORE_LISTING.md for complete content)

### 5 Keyword Tags for Kenya Discoverability
```
kazi, nairobi jobs, find work, mpesa jobs, casual labour
```

## 3. Play Console Setup

### App Category
**Primary Category**: Business
**Secondary Category**: Lifestyle (optional)

### Content Rating Questionnaire Answers

| Question | Answer |
|---|---|
| Does the app collect user data? | Yes |
| Is the app primarily directed to children? | No |
| Does the app require account creation? | Yes |
| Does the app allow user-to-user communication? | Yes |
| Does the app process payments? | Yes |
| Does the app access location? | Yes (approximate and precise) |
| Does the app access contacts? | No |
| Does the app access camera/photos? | Yes (for evidence in disputes) |
| Does the app access microphone? | No |
| Does the app access phone/calling? | No |

### Data Safety Section

**Data Collected:**

| Data Type | Required | Purpose |
|---|---|---|
| Phone number | Yes | Account verification, M-Pesa payments |
| Location | Yes | Job matching by proximity |
| Name | Yes | User profiles and job listings |
| Email | No | Optional account recovery |
| Photos | Optional | ID verification, dispute evidence |
| App activity | Yes | Analytics and crash reporting |
| Device IDs | Yes | Push notifications |

**Data Shared:**

| Data Type | Shared With | Purpose |
|---|---|---|
| Phone number | Payment processors | M-Pesa STK Push |
| Location | Other users (approximate) | Job matching |
| Name/Job info | Other users | Application matching |
| Crash data | Firebase/Google | App stability |
| Analytics | Firebase/Google | App improvement |

**Data Security:**
- Data encrypted in transit (HTTPS)
- Data encrypted at rest (Firebase)
- User can delete their account and all data
- Data retention: deleted within 30 days of account deletion

**Data Deletion:**
- Users can delete account via Settings → Danger Zone
- All user data removed from Firestore, Auth, and Storage
- Deletion processed within 30 days

### Target Age Group
**18+** (due to financial transactions, employment, and location services)

## 4. Pre-Launch Checklist

### Permissions
- [ ] `INTERNET` — for API calls
- [ ] `ACCESS_FINE_LOCATION` — for GPS job matching
- [ ] `ACCESS_COARSE_LOCATION` — for approximate location
- [ ] `CAMERA` — for ID verification and dispute evidence
- [ ] `READ_EXTERNAL_STORAGE` — for photo uploads
- [ ] `RECEIVE_SMS` — for OTP verification
- [ ] `FOREGROUND_SERVICE` — for location tracking during check-ins

### API Keys & Configuration
- [ ] `google_maps_flutter` API key configured in AndroidManifest.xml and Info.plist
- [ ] Firebase project linked (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)
- [ ] OAuth consent screen configured in Google Cloud Console
- [ ] Billing enabled on Firebase project (for Firestore storage)
- [ ] M-Pesa Daraja API credentials configured and tested
- [ ] FCM (Firebase Cloud Messaging) configured
- [ ] Cloud Functions deployed

### Debug Mode
- [ ] `debugShowCheckedModeBanner: false` in MaterialApp
- [ ] No `debugPrint` statements left in production code
- [ ] Proguard rules configured for obfuscation
- [ ] Release builds tested thoroughly

### Crashlytics
- [ ] `firebase_crashlytics` dependency added
- [ ] Crash reporting enabled in `main.dart`
- [ ] `FlutterError.onError` handler configured
- [ ] `PlatformDispatcher.onError` handler configured
- [ ] Test crash sent successfully in Firebase Console

### Analytics
- [ ] `firebase_analytics` dependency added
- [ ] Analytics initialized in `main.dart`
- [ ] All user journey events being logged
- [ ] Test events visible in Firebase Console DebugView

### Payments
- [ ] M-Pesa STK Push tested in sandbox
- [ ] Production M-Pesa credentials configured
- [ ] `lipa_na_mpesa_password` generated
- [ ] Callback URLs configured and reachable
- [ ] Payment test transactions verified end-to-end

### Content Rating
- [ ] Content rating questionnaire completed
- [ ] Target age: 18+ selected
- [ ] All data safety fields filled accurately

### Store Listing Assets
- [ ] App icon: 512x512 PNG (no transparency for Play Store)
- [ ] Feature graphic: 1024x500 PNG
- [ ] Phone screenshots: minimum 6, up to 8
- [ ] Tablet screenshots (recommended)
- [ ] Promo video (optional)

### Internal Testing
- [ ] Internal testing track created in Play Console
- [ ] Invite testers (minimum 2)
- [ ] Internal test version reviewed and approved
- [ ] All crash-free metrics above 99%

### Compliance
- [ ] Privacy policy URL provided (must be online)
- [ ] Terms of Service accessible
- [ ] GDPR / Kenya Data Protection Act compliance considered
- [ ] No personal data in screenshots (or properly blurred)

## 5. Upload Commands

```bash
# Authenticate with Google Play Console
dart run flutter_inapppurchase_prepare

# Or use Google Play Developer API directly
# Upload via Google Play Console web UI or API
```

Upload via [Google Play Console](https://play.google.com/console) → Your App → Production → Create Release

## 6. Post-Submission

- Monitor crash reports in Firebase Crashlytics for 48 hours
- Check ANR (Application Not Responding) reports
- Monitor user ratings and reviews
- Check Play Console pre-launch report for policy violations
- Track install metrics in Firebase Analytics
