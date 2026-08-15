'use strict';

const axios = require('axios');
const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const REGION = 'africa-south1';
const callable = functions.region(REGION).https;

function requireAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be signed in to perform this action.',
    );
  }
  return context.auth.uid;
}

function normalizePhone(value) {
  const digits = String(value || '').replace(/\D/g, '');
  if (digits.length === 12 && digits.startsWith('254')) return digits;
  if (digits.length === 10 && digits.startsWith('0')) {
    return `254${digits.substring(1)}`;
  }
  if (digits.length === 9) return `254${digits}`;
  throw new functions.https.HttpsError(
    'invalid-argument',
    'Enter a valid Kenyan phone number.',
  );
}

function mpesaBaseUrl() {
  return process.env.MPESA_ENV === 'production'
    ? 'https://api.safaricom.co.ke'
    : 'https://sandbox.safaricom.co.ke';
}

function isMockPayments() {
  return String(process.env.MPESA_MOCK || '').toLowerCase() === 'true';
}

function requireMpesaConfig(keys, label = 'M-Pesa') {
  const missing = keys.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `${label} is not configured. Missing: ${missing.join(', ')}`,
    );
  }
}

async function getAccessToken() {
  requireMpesaConfig(
    ['MPESA_CONSUMER_KEY', 'MPESA_CONSUMER_SECRET'],
    'M-Pesa API access',
  );
  const auth = Buffer.from(
    `${process.env.MPESA_CONSUMER_KEY}:${process.env.MPESA_CONSUMER_SECRET}`,
  ).toString('base64');
  const response = await axios.get(
    `${mpesaBaseUrl()}/oauth/v1/generate?grant_type=client_credentials`,
    {
      headers: { Authorization: `Basic ${auth}` },
      timeout: 20000,
    },
  );
  return response.data.access_token;
}

function timestamp() {
  const now = new Date();
  const pad = (number) => String(number).padStart(2, '0');
  return `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

async function sendNotificationToUser(userId, title, body, data = {}) {
  if (!userId) return;
  const userSnapshot = await db.collection('users').doc(userId).get();
  const user = userSnapshot.data() || {};
  const token = user.fcmToken;
  const settings = user.notificationSettings || {};
  const type = String(data.type || 'general');
  const preferenceKey =
    type === 'KAZI_NEW_JOB'
      ? 'newJobs'
      : type === 'chat_message'
        ? 'chat'
        : type === 'KAZI_PAYMENT'
          ? 'payments'
          : type === 'promotion'
            ? 'promotions'
            : 'applications';
  if (settings[preferenceKey] === false) return;

  await db.collection('notifications').add({
    userId,
    title,
    body,
    data,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value)]),
      ),
      android: { priority: 'high' },
    });
  } catch (error) {
    functions.logger.warn('FCM send failed', { userId, error: error.message });
  }
}

async function declineOtherApplications(jobId, selectedApplicationId) {
  const snapshot = await db
    .collection('applications')
    .where('jobId', '==', jobId)
    .where('status', 'in', ['pending', 'payment_pending'])
    .get();
  const batch = db.batch();
  for (const document of snapshot.docs) {
    if (document.id !== selectedApplicationId) {
      batch.update(document.ref, {
        status: 'declined',
        declinedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
  await batch.commit();
}

async function finalizeHiring({ jobId, applicationId, transactionId, receipt }) {
  const jobRef = db.collection('jobs').doc(jobId);
  const applicationRef = db.collection('applications').doc(applicationId);
  const transactionRef = db.collection('transactions').doc(transactionId);

  const result = await db.runTransaction(async (transaction) => {
    const [jobSnapshot, applicationSnapshot, paymentSnapshot] = await Promise.all([
      transaction.get(jobRef),
      transaction.get(applicationRef),
      transaction.get(transactionRef),
    ]);
    if (!jobSnapshot.exists || !applicationSnapshot.exists) {
      throw new Error('Job or application no longer exists.');
    }
    const job = jobSnapshot.data();
    const application = applicationSnapshot.data();

    if (job.status === 'hired' && job.hiredWorkerId === application.workerId) {
      transaction.set(
        transactionRef,
        {
          status: 'escrowed',
          mpesaReceiptNumber: receipt || paymentSnapshot.data()?.mpesaReceiptNumber || null,
          completedAt: paymentSnapshot.data()?.completedAt ||
            admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return {
        employerId: job.employerId,
        workerId: application.workerId,
        job,
        alreadyFinalized: true,
      };
    }
    if (!['open', 'payment_pending'].includes(job.status)) {
      throw new Error('Job is not available for hiring.');
    }

    transaction.update(jobRef, {
      status: 'hired',
      paymentStatus: 'escrowed',
      hiredWorkerId: application.workerId,
      hiredWorkerName: application.workerName || 'Worker',
      hiredApplicationId: applicationId,
      hiredAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      pendingWorkerId: admin.firestore.FieldValue.delete(),
    });
    transaction.update(applicationRef, {
      status: 'accepted',
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.set(
      transactionRef,
      {
        status: 'escrowed',
        mpesaReceiptNumber: receipt || null,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const chatRef = db
      .collection('chats')
      .doc(`${jobId}_${application.workerId}`);
    transaction.set(
      chatRef,
      {
        jobId,
        employerId: job.employerId,
        workerId: application.workerId,
        participantIds: [job.employerId, application.workerId],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return {
      employerId: job.employerId,
      workerId: application.workerId,
      job,
      alreadyFinalized: false,
    };
  });

  if (!result.alreadyFinalized) {
    await declineOtherApplications(jobId, applicationId);
    await sendNotificationToUser(
      result.workerId,
      'Umechaguliwa!',
      `Umechaguliwa kwa kazi ya ${result.job.title || 'Kazi'}.`,
      { type: 'KAZI_HIRED', jobId },
    );
  }
  return result;
}

async function revertFailedHiring(transactionData, resultDescription) {
  const jobRef = db.collection('jobs').doc(transactionData.jobId);
  const applicationRef = db
    .collection('applications')
    .doc(transactionData.applicationId);
  const transactionRef = db.collection('transactions').doc(transactionData.id);
  await db.runTransaction(async (transaction) => {
    const jobSnapshot = await transaction.get(jobRef);
    if (jobSnapshot.exists && jobSnapshot.data().status === 'payment_pending') {
      transaction.update(jobRef, {
        status: 'open',
        paymentStatus: 'failed',
        pendingWorkerId: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    transaction.set(
      applicationRef,
      { status: 'pending' },
      { merge: true },
    );
    transaction.set(
      transactionRef,
      {
        status: 'failed',
        failureReason: resultDescription || 'M-Pesa payment failed.',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

exports.initiateSTKPush = callable.onCall(async (data, context) => {
  const employerId = requireAuth(context);
  const { jobId, applicationId, workerId } = data || {};
  if (!jobId || !applicationId || !workerId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'jobId, applicationId and workerId are required.',
    );
  }

  const jobRef = db.collection('jobs').doc(jobId);
  const applicationRef = db.collection('applications').doc(applicationId);
  const paymentRef = db.collection('transactions').doc();
  const phone = normalizePhone(data.phone);

  const payment = await db.runTransaction(async (transaction) => {
    const [jobSnapshot, applicationSnapshot] = await Promise.all([
      transaction.get(jobRef),
      transaction.get(applicationRef),
    ]);
    if (!jobSnapshot.exists || !applicationSnapshot.exists) {
      throw new functions.https.HttpsError('not-found', 'Job or application not found.');
    }
    const job = jobSnapshot.data();
    const application = applicationSnapshot.data();
    if (job.employerId !== employerId) {
      throw new functions.https.HttpsError('permission-denied', 'You do not own this job.');
    }
    if (job.status !== 'open') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This job is not open for hiring.',
      );
    }
    if (application.jobId !== jobId || application.workerId !== workerId) {
      throw new functions.https.HttpsError('invalid-argument', 'Application mismatch.');
    }
    if (application.status !== 'pending') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This application is no longer pending.',
      );
    }

    const salary = Number(job.salaryKES || 0);
    const amount = Math.max(1, Math.round(Number(job.employerPaysKES || salary * 1.1)));
    const workerEarns = Number(job.workerEarnsKES || salary * 0.95);
    const platformFee = Number(job.platformFeeKES || salary * 0.15);

    transaction.update(jobRef, {
      status: 'payment_pending',
      paymentStatus: 'pending',
      pendingWorkerId: workerId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.update(applicationRef, { status: 'payment_pending' });
    transaction.set(paymentRef, {
      userId: employerId,
      employerId,
      workerId,
      jobId,
      applicationId,
      type: 'job_payment',
      amount,
      workerEarns,
      platformFee,
      phone,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { amount, workerEarns, platformFee };
  });

  if (isMockPayments()) {
    await finalizeHiring({
      jobId,
      applicationId,
      transactionId: paymentRef.id,
      receipt: `MOCK-${Date.now()}`,
    });
    return { status: 'mock_completed', transactionId: paymentRef.id };
  }

  try {
    requireMpesaConfig(
      ['MPESA_SHORTCODE', 'MPESA_PASSKEY', 'MPESA_CALLBACK_URL'],
      'M-Pesa STK Push',
    );
    const token = await getAccessToken();
    const time = timestamp();
    const password = Buffer.from(
      `${process.env.MPESA_SHORTCODE}${process.env.MPESA_PASSKEY}${time}`,
    ).toString('base64');
    const response = await axios.post(
      `${mpesaBaseUrl()}/mpesa/stkpush/v1/processrequest`,
      {
        BusinessShortCode: process.env.MPESA_SHORTCODE,
        Password: password,
        Timestamp: time,
        TransactionType: 'CustomerPayBillOnline',
        Amount: payment.amount,
        PartyA: phone,
        PartyB: process.env.MPESA_SHORTCODE,
        PhoneNumber: phone,
        CallBackURL: process.env.MPESA_CALLBACK_URL,
        AccountReference: `KAZI-${jobId.substring(0, 12)}`,
        TransactionDesc: 'Kazi job escrow',
      },
      {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 30000,
      },
    );

    await paymentRef.set(
      {
        merchantRequestId: response.data.MerchantRequestID,
        checkoutRequestId: response.data.CheckoutRequestID,
        responseCode: response.data.ResponseCode,
        responseDescription: response.data.ResponseDescription,
      },
      { merge: true },
    );
    return {
      status: 'pending',
      transactionId: paymentRef.id,
      checkoutRequestId: response.data.CheckoutRequestID,
    };
  } catch (error) {
    functions.logger.error('STK push failed', error.response?.data || error);
    await revertFailedHiring(
      { id: paymentRef.id, jobId, applicationId },
      error.response?.data?.errorMessage || error.message,
    );
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError(
      'internal',
      error.response?.data?.errorMessage || 'M-Pesa request failed.',
    );
  }
});

exports.mpesaCallback = functions.region(REGION).https.onRequest(async (req, res) => {
  try {
    const callback = req.body?.Body?.stkCallback;
    if (!callback?.CheckoutRequestID) {
      res.status(400).json({ ResultCode: 1, ResultDesc: 'Invalid callback' });
      return;
    }
    const paymentSnapshot = await db
      .collection('transactions')
      .where('checkoutRequestId', '==', callback.CheckoutRequestID)
      .limit(1)
      .get();
    if (paymentSnapshot.empty) {
      res.status(200).json({ ResultCode: 0, ResultDesc: 'Unknown transaction ignored' });
      return;
    }
    const paymentDoc = paymentSnapshot.docs[0];
    const payment = { id: paymentDoc.id, ...paymentDoc.data() };
    const metadata = callback.CallbackMetadata?.Item || [];
    const receipt = metadata.find((item) => item.Name === 'MpesaReceiptNumber')?.Value;

    if (Number(callback.ResultCode) === 0) {
      if (payment.type === 'job_payment') {
        await finalizeHiring({
          jobId: payment.jobId,
          applicationId: payment.applicationId,
          transactionId: payment.id,
          receipt,
        });
      } else if (payment.type === 'boost') {
        await finalizeBoost(payment, receipt);
      }
    } else if (payment.type === 'job_payment') {
      await revertFailedHiring(payment, callback.ResultDesc);
    } else {
      await paymentDoc.ref.set(
        {
          status: 'failed',
          failureReason: callback.ResultDesc,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch (error) {
    functions.logger.error('M-Pesa callback failed', error);
    res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted with internal error' });
  }
});

function distanceKm(first, second) {
  const radians = (degrees) => (degrees * Math.PI) / 180;
  const earthRadius = 6371;
  const deltaLat = radians(second.latitude - first.latitude);
  const deltaLng = radians(second.longitude - first.longitude);
  const a =
    Math.sin(deltaLat / 2) ** 2 +
    Math.cos(radians(first.latitude)) *
      Math.cos(radians(second.latitude)) *
      Math.sin(deltaLng / 2) ** 2;
  return 2 * earthRadius * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

exports.recordCheckIn = callable.onCall(async (data, context) => {
  const workerId = requireAuth(context);
  const { jobId, latitude, longitude } = data || {};
  const userLocation = { latitude: Number(latitude), longitude: Number(longitude) };
  if (!jobId || !Number.isFinite(userLocation.latitude) || !Number.isFinite(userLocation.longitude)) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid location is required.');
  }

  const jobRef = db.collection('jobs').doc(jobId);
  const checkinRef = db.collection('checkins').doc();
  const result = await db.runTransaction(async (transaction) => {
    const jobSnapshot = await transaction.get(jobRef);
    if (!jobSnapshot.exists) {
      throw new functions.https.HttpsError('not-found', 'Job not found.');
    }
    const job = jobSnapshot.data();
    if (job.status !== 'hired' || job.hiredWorkerId !== workerId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You are not the hired worker for this job.',
      );
    }
    if (job.workStatus === 'in_progress') {
      return {
        employerId: job.employerId,
        title: job.title,
        alreadyCheckedIn: true,
      };
    }
    const jobLocation = job.location;
    const proximity = distanceKm(userLocation, {
      latitude: jobLocation.latitude,
      longitude: jobLocation.longitude,
    });
    if (proximity > 0.6) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `You are ${(proximity * 1000).toFixed(0)} metres from the job location.`,
      );
    }

    const applicationRef = db
      .collection('applications')
      .doc(job.hiredApplicationId || `${jobId}_${workerId}`);
    transaction.set(
      applicationRef,
      {
        status: 'in_progress',
        checkInTime: admin.firestore.FieldValue.serverTimestamp(),
        checkInLocation: new admin.firestore.GeoPoint(
          userLocation.latitude,
          userLocation.longitude,
        ),
      },
      { merge: true },
    );
    transaction.update(jobRef, {
      workStatus: 'in_progress',
      checkInTime: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.set(checkinRef, {
      jobId,
      workerId,
      type: 'check_in',
      location: new admin.firestore.GeoPoint(
        userLocation.latitude,
        userLocation.longitude,
      ),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
      employerId: job.employerId,
      title: job.title,
      alreadyCheckedIn: false,
    };
  });

  if (!result.alreadyCheckedIn) {
    await sendNotificationToUser(
      result.employerId,
      'Worker checked in',
      `Work has started for ${result.title || 'your job'}.`,
      { type: 'checkin', jobId },
    );
  }
  return { status: 'in_progress' };
});

async function releaseJobPayment(jobId, actorId) {
  const jobRef = db.collection('jobs').doc(jobId);
  const earningRef = db.collection('transactions').doc(`earning_${jobId}`);
  return db.runTransaction(async (transaction) => {
    const jobSnapshot = await transaction.get(jobRef);
    if (!jobSnapshot.exists) {
      throw new functions.https.HttpsError('not-found', 'Job not found.');
    }
    const job = jobSnapshot.data();
    if (![job.hiredWorkerId, job.employerId].includes(actorId)) {
      throw new functions.https.HttpsError('permission-denied', 'Not a job participant.');
    }
    if (job.paymentStatus === 'released') {
      const releasedAmount = Number(
        job.workerEarnsKES || Number(job.salaryKES || 0) * 0.95,
      );
      return { amount: releasedAmount, alreadyReleased: true, job };
    }
    if (job.paymentStatus !== 'escrowed') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Job payment is not held in escrow.',
      );
    }

    const workerId = job.hiredWorkerId;
    const amount = Number(job.workerEarnsKES || Number(job.salaryKES || 0) * 0.95);
    const walletRef = db.collection('wallets').doc(workerId);
    const userRef = db.collection('users').doc(workerId);
    const walletSnapshot = await transaction.get(walletRef);
    const currentBalance = Number(walletSnapshot.data()?.balanceKES || 0);
    const totalEarned = Number(walletSnapshot.data()?.totalEarnedKES || 0);

    transaction.set(
      walletRef,
      {
        userId: workerId,
        balanceKES: currentBalance + amount,
        totalEarnedKES: totalEarned + amount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.set(earningRef, {
      userId: workerId,
      employerId: job.employerId,
      workerId,
      jobId,
      type: 'earning',
      amount,
      description: `Payment for ${job.title || 'job'}`,
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.update(jobRef, {
      status: 'completed',
      workStatus: 'completed',
      paymentStatus: 'released',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.set(
      userRef,
      { totalJobsCompleted: admin.firestore.FieldValue.increment(1) },
      { merge: true },
    );
    if (job.hiredApplicationId) {
      transaction.set(
        db.collection('applications').doc(job.hiredApplicationId),
        {
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    return { amount, alreadyReleased: false, job };
  });
}

exports.recordCheckOut = callable.onCall(async (data, context) => {
  const workerId = requireAuth(context);
  const { jobId, latitude, longitude } = data || {};
  const userLocation = { latitude: Number(latitude), longitude: Number(longitude) };
  if (
    !jobId ||
    !Number.isFinite(userLocation.latitude) ||
    !Number.isFinite(userLocation.longitude)
  ) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'jobId and a valid location are required.',
    );
  }
  const jobRef = db.collection('jobs').doc(jobId);
  const checkinRef = db.collection('checkins').doc();

  const jobSnapshot = await jobRef.get();
  if (!jobSnapshot.exists || jobSnapshot.data().hiredWorkerId !== workerId) {
    throw new functions.https.HttpsError('permission-denied', 'Not the hired worker.');
  }
  if (jobSnapshot.data().workStatus !== 'in_progress') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Check in before checking out.',
    );
  }
  const job = jobSnapshot.data();
  const jobLocation = job.location;
  if (
    distanceKm(userLocation, {
      latitude: jobLocation.latitude,
      longitude: jobLocation.longitude,
    }) > 0.8
  ) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'You are too far from the job location to check out.',
    );
  }

  await checkinRef.set({
    jobId,
    workerId,
    type: 'check_out',
    location: new admin.firestore.GeoPoint(userLocation.latitude, userLocation.longitude),
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  const released = await releaseJobPayment(jobId, workerId);
  await sendNotificationToUser(
    job.employerId,
    'Job completed',
    `${job.title || 'The job'} has been completed.`,
    { type: 'job_completed', jobId },
  );
  await sendNotificationToUser(
    workerId,
    'Payment released',
    `KES ${released.amount.toFixed(0)} has been added to your Kazi wallet.`,
    { type: 'KAZI_PAYMENT', jobId },
  );
  return { status: 'completed', amount: released.amount };
});

exports.processJobPayment = callable.onCall(async (data, context) => {
  const userId = requireAuth(context);
  const { jobId } = data || {};
  if (!jobId) {
    throw new functions.https.HttpsError('invalid-argument', 'jobId is required.');
  }
  const jobSnapshot = await db.collection('jobs').doc(jobId).get();
  if (!jobSnapshot.exists) {
    throw new functions.https.HttpsError('not-found', 'Job not found.');
  }
  const job = jobSnapshot.data();
  if (job.employerId !== userId) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the employer can manually release this payment.',
    );
  }
  if (job.workStatus !== 'in_progress') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Work must be in progress before payment can be released.',
    );
  }
  const result = await releaseJobPayment(jobId, userId);
  return { status: 'released', amount: result.amount };
});

exports.initiateB2CPayout = callable.onCall(async (data, context) => {
  const workerId = requireAuth(context);
  const amount = Math.round(Number(data?.amount || 0));
  const phone = normalizePhone(data?.phone);
  if (amount < 50) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Minimum withdrawal is KES 50.',
    );
  }

  const walletRef = db.collection('wallets').doc(workerId);
  const payoutRef = db.collection('transactions').doc();
  await db.runTransaction(async (transaction) => {
    const walletSnapshot = await transaction.get(walletRef);
    const balance = Number(walletSnapshot.data()?.balanceKES || 0);
    if (balance < amount) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Insufficient wallet balance.',
      );
    }
    transaction.set(
      walletRef,
      {
        userId: workerId,
        balanceKES: balance - amount,
        pendingWithdrawal: admin.firestore.FieldValue.increment(amount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.set(payoutRef, {
      userId: workerId,
      workerId,
      type: 'withdrawal',
      amount,
      phone,
      status: isMockPayments() ? 'completed' : 'processing',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(isMockPayments()
        ? { completedAt: admin.firestore.FieldValue.serverTimestamp() }
        : {}),
    });
  });

  if (isMockPayments()) {
    await walletRef.set(
      {
        pendingWithdrawal: admin.firestore.FieldValue.increment(-amount),
        totalWithdrawnKES: admin.firestore.FieldValue.increment(amount),
      },
      { merge: true },
    );
    return { status: 'completed', transactionId: payoutRef.id };
  }

  const required = [
    'MPESA_B2C_SHORTCODE',
    'MPESA_B2C_INITIATOR',
    'MPESA_B2C_SECURITY_CREDENTIAL',
    'MPESA_B2C_RESULT_URL',
    'MPESA_B2C_TIMEOUT_URL',
  ];
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    await db.runTransaction(async (transaction) => {
      transaction.set(
        walletRef,
        {
          balanceKES: admin.firestore.FieldValue.increment(amount),
          pendingWithdrawal: admin.firestore.FieldValue.increment(-amount),
        },
        { merge: true },
      );
      transaction.update(payoutRef, {
        status: 'failed',
        failureReason: `Missing configuration: ${missing.join(', ')}`,
      });
    });
    throw new functions.https.HttpsError(
      'failed-precondition',
      `B2C is not configured. Missing: ${missing.join(', ')}`,
    );
  }

  try {
    const token = await getAccessToken();
    const response = await axios.post(
      `${mpesaBaseUrl()}/mpesa/b2c/v1/paymentrequest`,
      {
        InitiatorName: process.env.MPESA_B2C_INITIATOR,
        SecurityCredential: process.env.MPESA_B2C_SECURITY_CREDENTIAL,
        CommandID: 'BusinessPayment',
        Amount: amount,
        PartyA: process.env.MPESA_B2C_SHORTCODE,
        PartyB: phone,
        Remarks: 'Kazi wallet withdrawal',
        QueueTimeOutURL: process.env.MPESA_B2C_TIMEOUT_URL,
        ResultURL: process.env.MPESA_B2C_RESULT_URL,
        Occasion: `KAZI-${workerId.substring(0, 8)}`,
      },
      { headers: { Authorization: `Bearer ${token}` }, timeout: 30000 },
    );
    await payoutRef.set(
      {
        conversationId: response.data.ConversationID,
        originatorConversationId: response.data.OriginatorConversationID,
      },
      { merge: true },
    );
    return {
      status: 'processing',
      transactionId: payoutRef.id,
      conversationId: response.data.ConversationID,
    };
  } catch (error) {
    await db.runTransaction(async (transaction) => {
      transaction.set(
        walletRef,
        {
          balanceKES: admin.firestore.FieldValue.increment(amount),
          pendingWithdrawal: admin.firestore.FieldValue.increment(-amount),
        },
        { merge: true },
      );
      transaction.update(payoutRef, {
        status: 'failed',
        failureReason: error.message,
      });
    });
    throw new functions.https.HttpsError('internal', 'B2C request failed.');
  }
});

async function completeB2C(req, isTimeout) {
  const body = req.body?.Result || req.body;
  const conversationId = body?.ConversationID;
  if (!conversationId) return;
  const snapshot = await db
    .collection('transactions')
    .where('conversationId', '==', conversationId)
    .limit(1)
    .get();
  if (snapshot.empty) return;

  const payoutRef = snapshot.docs[0].ref;
  const success = !isTimeout && Number(body.ResultCode) === 0;
  await db.runTransaction(async (transaction) => {
    const currentSnapshot = await transaction.get(payoutRef);
    if (!currentSnapshot.exists) return;
    const payout = currentSnapshot.data();
    if (['completed', 'failed'].includes(payout.status)) return;

    transaction.update(payoutRef, {
      status: success ? 'completed' : 'failed',
      resultDescription: body.ResultDesc || (isTimeout ? 'Timed out' : 'Failed'),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.set(
      db.collection('wallets').doc(payout.workerId),
      {
        pendingWithdrawal: admin.firestore.FieldValue.increment(-payout.amount),
        ...(success
          ? { totalWithdrawnKES: admin.firestore.FieldValue.increment(payout.amount) }
          : { balanceKES: admin.firestore.FieldValue.increment(payout.amount) }),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

exports.mpesaB2CResult = functions.region(REGION).https.onRequest(async (req, res) => {
  await completeB2C(req, false);
  res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
});

exports.mpesaB2CTimeout = functions.region(REGION).https.onRequest(async (req, res) => {
  await completeB2C(req, true);
  res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
});

const BOOST_TIERS = {
  Basic: { amount: 50, milliseconds: 6 * 60 * 60 * 1000 },
  Standard: { amount: 100, milliseconds: 24 * 60 * 60 * 1000 },
  Premium: { amount: 200, milliseconds: 3 * 24 * 60 * 60 * 1000 },
};

async function finalizeBoost(payment, receipt) {
  const tierConfig = BOOST_TIERS[payment.tier];
  if (!tierConfig) throw new Error('Invalid boost tier.');
  const paymentRef = db.collection('transactions').doc(payment.id);
  const activated = await db.runTransaction(async (transaction) => {
    const paymentSnapshot = await transaction.get(paymentRef);
    if (paymentSnapshot.exists && paymentSnapshot.data().status === 'completed') {
      return false;
    }
    transaction.update(db.collection('jobs').doc(payment.jobId), {
      isBoosted: true,
      boostTier: payment.tier,
      boostExpiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + tierConfig.milliseconds),
      ),
      boostedAt: admin.firestore.FieldValue.serverTimestamp(),
      boostAmountKES: payment.amount,
    });
    transaction.set(
      paymentRef,
      {
        status: 'completed',
        mpesaReceiptNumber: receipt || null,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return true;
  });

  if (!activated) return;

  if (payment.tier === 'Premium') {
    const jobSnapshot = await db.collection('jobs').doc(payment.jobId).get();
    const job = jobSnapshot.data();
    const workers = await db
      .collection('users')
      .where('role', '==', 'jobseeker')
      .limit(500)
      .get();
    const tokens = workers.docs
      .map((doc) => doc.data())
      .filter((worker) =>
        worker.fcmToken && worker.notificationSettings?.newJobs !== false,
      )
      .map((worker) => worker.fcmToken);
    if (tokens.length > 0) {
      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: 'Urgent Job!',
          body: `${job.title} — ${job.neighborhood} — KES ${job.salaryKES}`,
        },
        data: { type: 'KAZI_NEW_JOB', jobId: payment.jobId },
      });
    }
  }
}

exports.initiateBoostPayment = callable.onCall(async (data, context) => {
  const employerId = requireAuth(context);
  const { jobId, tier } = data || {};
  const config = BOOST_TIERS[tier];
  if (!jobId || !config) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid job or boost tier.');
  }
  const jobSnapshot = await db.collection('jobs').doc(jobId).get();
  if (!jobSnapshot.exists) {
    throw new functions.https.HttpsError('not-found', 'Job not found.');
  }
  const job = jobSnapshot.data();
  if (job.employerId !== employerId) {
    throw new functions.https.HttpsError('permission-denied', 'You do not own this job.');
  }
  if (job.status !== 'open') {
    throw new functions.https.HttpsError('failed-precondition', 'Only open jobs can be boosted.');
  }
  const userSnapshot = await db.collection('users').doc(employerId).get();
  const phone = normalizePhone(data.phone || userSnapshot.data()?.phone);
  const paymentRef = db.collection('transactions').doc();
  const payment = {
    id: paymentRef.id,
    userId: employerId,
    employerId,
    jobId,
    type: 'boost',
    tier,
    amount: config.amount,
    phone,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await paymentRef.set(payment);

  if (isMockPayments()) {
    await finalizeBoost(payment, `MOCK-${Date.now()}`);
    return { status: 'mock_completed', transactionId: paymentRef.id };
  }

  try {
    requireMpesaConfig(
      ['MPESA_SHORTCODE', 'MPESA_PASSKEY', 'MPESA_CALLBACK_URL'],
      'M-Pesa STK Push',
    );
    const token = await getAccessToken();
    const time = timestamp();
    const password = Buffer.from(
      `${process.env.MPESA_SHORTCODE}${process.env.MPESA_PASSKEY}${time}`,
    ).toString('base64');
    const response = await axios.post(
      `${mpesaBaseUrl()}/mpesa/stkpush/v1/processrequest`,
      {
        BusinessShortCode: process.env.MPESA_SHORTCODE,
        Password: password,
        Timestamp: time,
        TransactionType: 'CustomerPayBillOnline',
        Amount: config.amount,
        PartyA: phone,
        PartyB: process.env.MPESA_SHORTCODE,
        PhoneNumber: phone,
        CallBackURL: process.env.MPESA_CALLBACK_URL,
        AccountReference: `BOOST-${jobId.substring(0, 12)}`,
        TransactionDesc: `Kazi ${tier} boost`,
      },
      { headers: { Authorization: `Bearer ${token}` }, timeout: 30000 },
    );
    await paymentRef.set(
      {
        checkoutRequestId: response.data.CheckoutRequestID,
        merchantRequestId: response.data.MerchantRequestID,
      },
      { merge: true },
    );
    return { status: 'pending', transactionId: paymentRef.id };
  } catch (error) {
    await paymentRef.set(
      { status: 'failed', failureReason: error.message },
      { merge: true },
    );
    throw new functions.https.HttpsError('internal', 'Boost payment request failed.');
  }
});

exports.sendNotification = callable.onCall(async (data, context) => {
  const callerId = requireAuth(context);
  const { userId, title, message, type, jobId } = data || {};
  if (!userId || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'userId and message are required.');
  }
  if (jobId) {
    const job = (await db.collection('jobs').doc(jobId).get()).data();
    if (!job || ![job.employerId, job.hiredWorkerId].includes(callerId)) {
      throw new functions.https.HttpsError('permission-denied', 'Not a job participant.');
    }
    if (![job.employerId, job.hiredWorkerId].includes(userId)) {
      throw new functions.https.HttpsError('permission-denied', 'Invalid notification recipient.');
    }
  } else if (callerId !== userId && context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Not allowed.');
  }
  await sendNotificationToUser(
    userId,
    title || 'Kazi',
    message,
    { type: type || 'general', ...(jobId ? { jobId } : {}) },
  );
  return { success: true };
});

exports.sendBulkNotification = callable.onCall(async (data, context) => {
  requireAuth(context);
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required.');
  }
  const tokens = Array.isArray(data?.tokens) ? data.tokens.slice(0, 500) : [];
  if (tokens.length === 0) return { successCount: 0, failureCount: 0 };
  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title: data.title || 'Kazi', body: data.body || '' },
    data: Object.fromEntries(
      Object.entries(data.data || {}).map(([key, value]) => [key, String(value)]),
    ),
  });
  return { successCount: response.successCount, failureCount: response.failureCount };
});

exports.alertAdmin = callable.onCall(async (data, context) => {
  const userId = requireAuth(context);
  const alertRef = await db.collection('adminAlerts').add({
    userId,
    type: data?.type || 'general',
    message: data?.message || '',
    jobId: data?.jobId || null,
    disputeId: data?.disputeId || null,
    status: 'open',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { alertId: alertRef.id };
});

exports.notifyNearbyJobSeekers = functions
  .region(REGION)
  .firestore.document('jobs/{jobId}')
  .onCreate(async (snapshot, context) => {
    const job = snapshot.data();
    if (job.status !== 'open') return null;
    const workers = await db
      .collection('users')
      .where('role', '==', 'jobseeker')
      .where('isAvailable', '==', true)
      .limit(500)
      .get();
    const jobLocation = job.location;
    const tokens = workers.docs
      .map((document) => document.data())
      .filter((worker) => {
        if (
          !worker.fcmToken ||
          worker.notificationSettings?.newJobs === false ||
          !jobLocation
        ) return false;
        const latitude = Number(worker.lat);
        const longitude = Number(worker.lng);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return false;
        return distanceKm(
          { latitude, longitude },
          { latitude: jobLocation.latitude, longitude: jobLocation.longitude },
        ) <= 10;
      })
      .map((worker) => worker.fcmToken);
    if (tokens.length === 0) return null;
    return messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: job.isUrgent ? 'Urgent Job!' : 'New Job Nearby',
        body: `${job.title} — ${job.neighborhood} — KES ${job.salaryKES}`,
      },
      data: { type: 'KAZI_NEW_JOB', jobId: context.params.jobId },
    });
  });

exports.notifyChatRecipient = functions
  .region(REGION)
  .firestore.document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const chatSnapshot = await db.collection('chats').doc(context.params.chatId).get();
    if (!chatSnapshot.exists) return null;
    const chat = chatSnapshot.data();
    if (![chat.employerId, chat.workerId].includes(message.senderId)) return null;
    const recipientId = message.senderId === chat.employerId
      ? chat.workerId
      : chat.employerId;
    const senderSnapshot = await db.collection('users').doc(message.senderId).get();
    const senderName = senderSnapshot.data()?.name || 'Kazi user';
    await sendNotificationToUser(
      recipientId,
      senderName,
      String(message.text || 'New message').substring(0, 160),
      {
        type: 'chat_message',
        chatId: context.params.chatId,
        jobId: chat.jobId || '',
      },
    );
    return null;
  });

exports.reviewUserVerification = callable.onCall(async (data, context) => {
  requireAuth(context);
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required.');
  }
  const { userId, approved, rejectionReason } = data || {};
  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required.');
  }
  const newStatus = approved ? 'verified' : 'rejected';
  const batch = db.batch();

  const verificationRef = db.collection('identityVerifications').doc(userId);
  batch.set(
    verificationRef,
    {
      status: newStatus,
      reviewedBy: context.auth.uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(rejectionReason ? { rejectionReason } : {}),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  const userRef = db.collection('users').doc(userId);
  batch.update(userRef, {
    verificationStatus: newStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  await sendNotificationToUser(
    userId,
    approved ? 'Identity Verified' : 'Identity Verification Update',
    approved
      ? 'Your identity verification has been approved! You now have a verified profile.'
      : `Your identity verification was not approved. ${rejectionReason || 'Please resubmit with valid documents.'}`,
    { type: 'identity_verification_update', status: newStatus },
  );

  return { success: true, status: newStatus };
});

exports.triggerRatingPrompt = functions
  .region(REGION)
  .firestore.document('jobs/{jobId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === 'completed' || after.status !== 'completed') return null;
    await Promise.all([
      sendNotificationToUser(
        after.employerId,
        'Rate your worker',
        `How was the work on ${after.title || 'your job'}?`,
        { type: 'rating_prompt', jobId: context.params.jobId },
      ),
      sendNotificationToUser(
        after.hiredWorkerId,
        'Rate your employer',
        `How was your experience on ${after.title || 'this job'}?`,
        { type: 'rating_prompt', jobId: context.params.jobId },
      ),
    ]);
    return null;
  });

exports.fileDispute = callable.onCall(async (data, context) => {
  const reporterId = requireAuth(context);
  const {
    jobId,
    applicationId,
    reason,
    reasonLabel,
    description,
    photoUrls,
  } = data || {};
  if (!jobId || !applicationId || !reason) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'jobId, applicationId and reason are required.',
    );
  }

  const [jobSnapshot, applicationSnapshot] = await Promise.all([
    db.collection('jobs').doc(jobId).get(),
    db.collection('applications').doc(applicationId).get(),
  ]);
  if (!jobSnapshot.exists || !applicationSnapshot.exists) {
    throw new functions.https.HttpsError('not-found', 'Job or application not found.');
  }
  const job = jobSnapshot.data();
  const application = applicationSnapshot.data();
  if (application.jobId !== jobId) {
    throw new functions.https.HttpsError('invalid-argument', 'Application mismatch.');
  }
  const participants = [job.employerId, application.workerId];
  if (!participants.includes(reporterId)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only job participants can file a dispute.',
    );
  }
  const reportedId = reporterId === job.employerId
    ? application.workerId
    : job.employerId;
  const disputeRef = db.collection('disputes').doc(`${jobId}_${reporterId}`);

  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(disputeRef);
    if (existing.exists && ['open', 'investigating'].includes(existing.data().status)) {
      throw new functions.https.HttpsError(
        'already-exists',
        'You already have an open dispute for this job.',
      );
    }
    transaction.set(disputeRef, {
      jobId,
      applicationId,
      reporterId,
      reportedId,
      reason,
      reasonLabel: reasonLabel || reason,
      description: String(description || '').substring(0, 1000),
      photoUrls: Array.isArray(photoUrls) ? photoUrls.slice(0, 3) : [],
      status: 'open',
      resolution: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (job.paymentStatus === 'escrowed') {
      transaction.update(jobSnapshot.ref, {
        paymentStatus: 'frozen',
        disputeStatus: 'open',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      transaction.update(jobSnapshot.ref, {
        disputeStatus: 'open',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  if (job.paymentStatus === 'escrowed') {
    const paymentSnapshot = await db
      .collection('transactions')
      .where('jobId', '==', jobId)
      .where('type', '==', 'job_payment')
      .limit(1)
      .get();
    if (!paymentSnapshot.empty) {
      await paymentSnapshot.docs[0].ref.set(
        { status: 'frozen', disputeId: disputeRef.id },
        { merge: true },
      );
    }
  }

  await Promise.all([
    sendNotificationToUser(
      reportedId,
      'Dispute filed',
      'A job dispute has been filed. The Kazi team will review it.',
      { type: 'dispute_filed', jobId, disputeId: disputeRef.id },
    ),
    db.collection('adminAlerts').add({
      userId: reporterId,
      type: 'new_dispute',
      message: `New dispute: ${reasonLabel || reason}`,
      jobId,
      disputeId: disputeRef.id,
      status: 'open',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }),
  ]);
  return { disputeId: disputeRef.id, status: 'open' };
});

exports.resolveDispute = callable.onCall(async (data, context) => {
  requireAuth(context);
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required.');
  }
  const { disputeId, resolution, releasePayment } = data || {};
  if (!disputeId || !resolution) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'disputeId and resolution are required.',
    );
  }
  const disputeRef = db.collection('disputes').doc(disputeId);
  const disputeSnapshot = await disputeRef.get();
  if (!disputeSnapshot.exists) {
    throw new functions.https.HttpsError('not-found', 'Dispute not found.');
  }
  const dispute = disputeSnapshot.data();
  await disputeRef.update({
    status: 'resolved',
    resolution,
    resolvedBy: context.auth.uid,
    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection('jobs').doc(dispute.jobId).set(
    {
      disputeStatus: 'resolved',
      ...(releasePayment ? { paymentStatus: 'escrowed' } : {}),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  if (releasePayment) {
    await releaseJobPayment(dispute.jobId, dispute.reporterId);
  }
  await Promise.all([
    sendNotificationToUser(
      dispute.reporterId,
      'Dispute resolved',
      resolution,
      { type: 'dispute_resolved', jobId: dispute.jobId, disputeId },
    ),
    sendNotificationToUser(
      dispute.reportedId,
      'Dispute resolved',
      resolution,
      { type: 'dispute_resolved', jobId: dispute.jobId, disputeId },
    ),
  ]);
  return { status: 'resolved' };
});

exports.updateAverageRating = functions
  .region(REGION)
  .firestore.document('ratings/{ratingId}')
  .onCreate(async (snapshot) => {
    const rating = snapshot.data();
    const ratings = await db
      .collection('ratings')
      .where('revieweeId', '==', rating.revieweeId)
      .get();
    const values = ratings.docs
      .map((document) => Number(document.data().stars || 0))
      .filter((stars) => stars >= 1 && stars <= 5);
    if (values.length === 0) return null;
    const average = values.reduce((sum, stars) => sum + stars, 0) / values.length;
    await db.collection('users').doc(rating.revieweeId).set(
      {
        averageRating: Number(average.toFixed(2)),
        ratingCount: values.length,
      },
      { merge: true },
    );
    return null;
  });
