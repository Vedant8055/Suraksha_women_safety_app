const admin = require('firebase-admin');
const DeviceSession = require('../models/DeviceSession');
const env = require('../config/env');

let initialized = false;

function ensureFirebase() {
  if (initialized) return true;
  if (!env.fcmServiceAccountJson) return false;
  try {
    const credentials = JSON.parse(env.fcmServiceAccountJson);
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(credentials) });
    }
    initialized = true;
    return true;
  } catch (_) {
    return false;
  }
}

async function sendPushToTokens(tokens, { title, body, data = {} }) {
  if (!tokens.length || !ensureFirebase()) {
    return { sent: 0, skipped: tokens.length, reason: 'fcm_unavailable' };
  }

  const message = {
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value ?? '')]),
    ),
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    return {
      sent: response.successCount,
      failed: response.failureCount,
      skipped: 0,
    };
  } catch (error) {
    return { sent: 0, skipped: tokens.length, reason: error.message };
  }
}

async function sendPushToUser(userId, payload) {
  const sessions = await DeviceSession.find({
    userId,
    isActive: true,
    fcmToken: { $exists: true, $ne: '' },
  })
    .sort({ updatedAt: -1 })
    .limit(5)
    .lean();

  const tokens = [...new Set(sessions.map((item) => item.fcmToken).filter(Boolean))];
  return sendPushToTokens(tokens, payload);
}

module.exports = { sendPushToUser, sendPushToTokens, ensureFirebase };
