const mongoose = require('mongoose');
const JourneyZoneState = require('../models/JourneyZoneState');
const UserPreference = require('../models/UserPreference');
const { createNotification } = require('../notifications/notificationService');
const { sendPushToUser } = require('./fcmPushService');
const { generateSafetySummary } = require('./safetySummaryService');
const {
  runFusionAnalysis,
  loadContext,
  buildUpcomingRisk,
} = require('./safetyIntelligenceService');
const { encodeGeohash } = require('../utils/safetyGeoUtils');
const { nashikSafetyConfig } = require('../config/nashikSafetyConfig');

const TIER_RANK = { low: 0, moderate: 1, high: 2, critical: 3 };

function riskTierFromScore(score) {
  if (score < 45) return 'critical';
  if (score < 60) return 'high';
  if (score < 75) return 'moderate';
  return 'low';
}

function isQuietHours(now, startHour, endHour) {
  const hour = now.getHours();
  if (startHour === endHour) return false;
  if (startHour < endHour) return hour >= startHour && hour < endHour;
  return hour >= startHour || hour < endHour;
}

function buildZoneAlert({ previousTier, nextTier, geohashChanged, safetyScore }) {
  const prevRank = TIER_RANK[previousTier] ?? 1;
  const nextRank = TIER_RANK[nextTier] ?? 1;

  if (nextRank >= TIER_RANK.high && nextRank > prevRank) {
    return {
      type: 'entering_high_risk',
      priority: nextTier === 'critical' ? 'critical' : 'caution',
      title: 'Higher-risk zone ahead',
      body:
        nextTier === 'critical'
          ? `Safety score dropped to ${safetyScore}/100 in this area. Consider an alternate route.`
          : `Entering a ${nextTier}-risk area (score ${safetyScore}/100). Stay alert.`,
      recommendedAction: 'Share live location and prefer well-lit main roads.',
    };
  }

  if (prevRank >= TIER_RANK.high && nextRank <= TIER_RANK.moderate) {
    return {
      type: 'leaving_high_risk',
      priority: 'information',
      title: 'Leaving elevated-risk area',
      body: `Conditions improved to ${nextTier} risk (score ${safetyScore}/100).`,
      recommendedAction: 'Continue monitoring while you travel.',
    };
  }

  if (geohashChanged && nextTier === 'critical') {
    return {
      type: 'critical_cell',
      priority: 'critical',
      title: 'Critical risk cell',
      body: `You entered a high-alert map cell with score ${safetyScore}/100.`,
      recommendedAction: 'Arm SOS and inform a trusted contact.',
    };
  }

  return null;
}

async function getSafetyPreferences(userId) {
  if (!userId) {
    return {
      journeyAlertsEnabled: true,
      safetySummaryLanguage: 'en',
      quietHoursStart: nashikSafetyConfig.quietHoursStart,
      quietHoursEnd: nashikSafetyConfig.quietHoursEnd,
    };
  }
  const doc = await UserPreference.findOne({ userId }).lean();
  return {
    journeyAlertsEnabled: doc?.journeyAlertsEnabled ?? true,
    safetySummaryLanguage: doc?.safetySummaryLanguage || doc?.language || 'en',
    quietHoursStart: doc?.quietHoursStart ?? nashikSafetyConfig.quietHoursStart,
    quietHoursEnd: doc?.quietHoursEnd ?? nashikSafetyConfig.quietHoursEnd,
  };
}

async function updateSafetyPreferences(userId, patch) {
  await UserPreference.findOneAndUpdate(
    { userId },
    {
      userId,
      ...(patch.journeyAlertsEnabled !== undefined
        ? { journeyAlertsEnabled: patch.journeyAlertsEnabled }
        : {}),
      ...(patch.safetySummaryLanguage
        ? { safetySummaryLanguage: patch.safetySummaryLanguage }
        : {}),
      ...(patch.quietHoursStart !== undefined ? { quietHoursStart: patch.quietHoursStart } : {}),
      ...(patch.quietHoursEnd !== undefined ? { quietHoursEnd: patch.quietHoursEnd } : {}),
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  return getSafetyPreferences(userId);
}

async function processJourneyUpdate({
  userId,
  lat,
  lng,
  heading,
  accuracy,
  destination,
  lang,
}) {
  const at = new Date();
  const context = await loadContext(lat, lng);
  const analysis = await runFusionAnalysis({
    lat,
    lng,
    at,
    accuracy,
    context,
    useCache: false,
  });
  const external = analysis.external || {};
  const geohash = encodeGeohash(lat, lng, 6);
  const tier = riskTierFromScore(analysis.safetyScore);
  const preferences = await getSafetyPreferences(userId);

  let previous = null;
  if (userId && mongoose.connection.readyState === 1) {
    previous = await JourneyZoneState.findOne({ userId }).lean();
  }

  const geohashChanged = previous ? previous.geohash !== geohash : false;
  const alert = buildZoneAlert({
    previousTier: previous?.riskTier || 'moderate',
    nextTier: tier,
    geohashChanged,
    safetyScore: analysis.safetyScore,
  });

  let pushResult = null;
  const quiet = isQuietHours(at, preferences.quietHoursStart, preferences.quietHoursEnd);
  const shouldNotify =
    alert &&
    preferences.journeyAlertsEnabled &&
    (!quiet || alert.priority === 'critical') &&
    userId;

  if (shouldNotify) {
    const recentlyAlerted =
      previous?.lastAlertAt &&
      Date.now() - new Date(previous.lastAlertAt).getTime() < 4 * 60 * 1000 &&
      previous.lastAlertType === alert.type;
    if (!recentlyAlerted) {
      pushResult = await sendPushToUser(userId, {
        title: alert.title,
        body: alert.body,
        data: {
          type: 'safety_journey',
          alertType: alert.type,
          safetyScore: analysis.safetyScore,
          geohash,
        },
      });
      await createNotification({
        userId,
        title: alert.title,
        body: alert.body,
        type: 'safety_journey',
        metadata: { alertType: alert.type, safetyScore: analysis.safetyScore, geohash },
      });
    }
  }

  if (userId && mongoose.connection.readyState === 1) {
    await JourneyZoneState.findOneAndUpdate(
      { userId },
      {
        userId,
        geohash,
        riskTier: tier,
        safetyScore: analysis.safetyScore,
        ...(alert && shouldNotify ? { lastAlertAt: at, lastAlertType: alert.type } : {}),
      },
      { upsert: true, new: true },
    );
  }

  const summaryLang = lang || preferences.safetySummaryLanguage || 'en';
  const aiSummary = await generateSafetySummary({
    analysis,
    external,
    at,
    lang: summaryLang,
  });

  const upcomingRisk = await buildUpcomingRisk({
    lat,
    lng,
    heading,
    destination,
    baseAnalysis: analysis,
    context,
    at,
    accuracy,
  });

  let rerouteHint = null;
  if (destination && analysis.safetyScore < 55) {
    rerouteHint =
      'Current corridor shows elevated risk. Open route options to compare safer paths.';
  } else if (upcomingRisk) {
    rerouteHint = upcomingRisk.recommendedAction;
  }

  return {
    safetyScore: analysis.safetyScore,
    riskTier: tier,
    geohash,
    riskLevel: analysis.riskLevel?.label,
    dimensions: analysis.dimensions,
    upcomingRisk,
    inAppAlert: alert,
    push: pushResult,
    aiSummary,
    rerouteHint,
    updatedAt: at.toISOString(),
  };
}

module.exports = {
  processJourneyUpdate,
  getSafetyPreferences,
  updateSafetyPreferences,
  riskTierFromScore,
};
