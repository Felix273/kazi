# Post-Launch Monitoring Setup for Kazi

## 1. Firebase Crashlytics

### Setup
```bash
flutter pub add firebase_crashlytics
```

### Configuration in main.dart
- `FlutterError.onError` → `FirebaseCrashlytics.instance.recordFlutterFatalError`
- `PlatformDispatcher.instance.onError` → record fatal errors
- Import: `import 'package:firebase_crashlytics/firebase_crashlytics.dart';`
- Initialize in `main()` with `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true)`

Note: The provided main.dart already includes this setup.

## 2. Firebase Analytics

### Setup
```bash
flutter pub add firebase_analytics
```

### Events to Track

| Event Name | Parameters | Trigger |
|---|---|---|
| `screen_view` | `screen_name`, `screen_class` | Every route change |
| `onboarding_completed` | `role` | User completes onboarding |
| `role_selected` | `role` ("employer"/"jobseeker") | Role selection screen |
| `first_job_posted` | `job_id`, `category` | First job posted |
| `job_posted` | `job_id`, `category`, `salary_kes` | Any job posted |
| `first_application` | `job_id`, `worker_id` | First-ever application |
| `first_payment` | `job_id`, `amount_kes` | First earnings payment |
| `wallet_withdrawal` | `amount_kes`, `method` | M-Pesa withdrawal |
| `payment_initiated` | `job_id`, `amount_kes`, `type` | STK Push initiated |
| `payment_success` | `job_id`, `amount_kes`, `type` | Payment succeeded |
| `payment_failed` | `job_id`, `error_message` | Payment failed |
| `boost_purchased` | `job_id`, `tier`, `amount_kes` | Boost purchased |
| `dispute_filed` | `dispute_id`, `reason` | Dispute submitted |
| `rating_submitted` | `job_id`, `rating` | Rating left |

### User Properties
- `role`: "employer" or "jobseeker"
- `neighborhood`: user's registered neighborhood
- `has_completed_onboarding`: boolean

## 3. Firebase Performance

### Setup
```bash
flutter pub add firebase_performance
```

### Monitored Metrics
- **App startup time** (cold/warm)
- **HTTP/S request time** (Firestore queries, API calls)
- **Image load time** (profile photos, icons)
- **Screen render time** (per-screen frame timing)
- **Custom traces**:
  - `job_list_load` — time to load home screen
  - `job_detail_load` — time to load job detail
  - `application_submit` — time to submit application
  - `payment_process` — time for payment flow
  - `chat_message_send` — time to send message
  - `mpesa_callback` — time for M-Pesa callback processing

## 4. Admin Alerts (Cloud Functions)

Create a `functions/src/alerts.ts` with the following triggers:

| Trigger | Condition | Notification Channel |
|---|---|---|
| Payment failure | M-Pesa callback returns error | WhatsApp + Email |
| Dispute filed | New document in `/disputes` | WhatsApp + Email |
| New signup | New user created | Daily digest email |
| Revenue milestone | Cumulative revenue crosses KES 10,000 | WhatsApp |

### Alert Thresholds
- **Revenue milestone**: KES 10,000 cumulative
- **Dispute spike**: >5 disputes in 24 hours
- **Payment failure rate**: >10% of transactions in 24 hours

## 5. Cloud Functions for Monitoring

```typescript
// functions/src/alerts.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Alert on payment failure
export const onPaymentFailed = functions.firestore
  .document('transactions/{txId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    if (after.status === 'failed') {
      // Send WhatsApp + Email alert to admin
      await sendAdminAlert({
        type: 'payment_failure',
        transactionId: context.params.txId,
        amount: after.amount,
        reason: after.error || 'Unknown',
      });
    }
  });

// Alert on new dispute
export const onDisputeFiled = functions.firestore
  .document('disputes/{disputeId}')
  .onCreate(async (snap, context) => {
    const dispute = snap.data();
    await sendAdminAlert({
      type: 'new_dispute',
      disputeId: context.params.disputeId,
      reason: dispute.reasonLabel,
      jobId: dispute.jobId,
    });
  });

// Daily digest for new signups
export const dailySignupDigest = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    const newUsers = await admin.firestore()
      .collection('users')
      .where('createdAt', '>=', yesterday)
      .get();

    await sendAdminDigest({
      type: 'daily_signups',
      count: newUsers.size,
      users: newUsers.docs.map(d => d.data()),
    });
  });

// Revenue milestone check
export const onRevenueMilestone = functions.firestore
  .document('transactions/{txId}')
  .onWrite(async (change, context) => {
    const totalRevenue = await calculateTotalRevenue();
    if (totalRevenue >= 10000 && Math.round(totalRevenue) % 10000 < 100) {
      await sendAdminAlert({
        type: 'revenue_milestone',
        amount: totalRevenue,
        message: `Total revenue crossed KES ${totalRevenue.toLocaleString()}`,
      });
    }
  });

async function sendAdminAlert(alert: any) {
  // Implement WhatsApp API and/or FCM push notification to admin devices
}

async function sendAdminDigest(digest: any) {
  // Implement email via SendGrid or similar
}

async function calculateTotalRevenue(): Promise<number> {
  const completed = await admin.firestore()
    .collection('transactions')
    .where('status', '==', 'completed')
    .get();

  return completed.docs.reduce((sum, doc) => {
    const data = doc.data();
    return sum + (data.amount || 0);
  }, 0);
}
```
