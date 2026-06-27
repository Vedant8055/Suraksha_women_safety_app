const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const {
  getLiveSafetyAssessment,
  assessRouteOptions,
  getSafetyIntelligenceHealth,
} = require('../services/safetyIntelligenceService');
const { recordAnonymousPing } = require('../services/crowdHeatmapService');
const {
  processJourneyUpdate,
  getSafetyPreferences,
  updateSafetyPreferences,
} = require('../services/journeyZoneService');
const { generateSafetySummary } = require('../services/safetySummaryService');
const { runFusionAnalysis, loadContext } = require('../services/safetyIntelligenceService');
const { loadExternalSignals } = require('../services/safetyContextLoader');

const liveAssessmentSchema = z.object({
  query: z.object({
    lat: z.coerce.number(),
    lng: z.coerce.number(),
    heading: z.coerce.number().optional(),
    accuracy: z.coerce.number().optional(),
    destinationLat: z.coerce.number().optional(),
    destinationLng: z.coerce.number().optional(),
    includeSummary: z
      .union([z.literal('true'), z.literal('false'), z.coerce.boolean()])
      .optional()
      .transform((value) => value === true || value === 'true'),
    lang: z.string().optional(),
    journeyMode: z
      .union([z.literal('true'), z.literal('false'), z.coerce.boolean()])
      .optional()
      .transform((value) => value === true || value === 'true'),
  }),
});

const routeAssessmentSchema = z.object({
  body: z.object({
    origin: z.object({
      lat: z.number(),
      lng: z.number(),
    }),
    destination: z.object({
      lat: z.number(),
      lng: z.number(),
      name: z.string().optional(),
    }),
    candidates: z
      .array(
        z.object({
          id: z.string(),
          profileId: z.string(),
          durationSeconds: z.number().optional(),
          distanceMeters: z.number().optional(),
          path: z.array(
            z.object({
              lat: z.number(),
              lng: z.number(),
            }),
          ),
        }),
      )
      .min(1),
  }),
});

const pingSchema = z.object({
  body: z.object({
    lat: z.number(),
    lng: z.number(),
  }),
});

const journeyUpdateSchema = z.object({
  body: z.object({
    lat: z.number(),
    lng: z.number(),
    heading: z.number().optional(),
    accuracy: z.number().optional(),
    destinationLat: z.number().optional(),
    destinationLng: z.number().optional(),
    lang: z.string().optional(),
  }),
});

const preferencesPatchSchema = z.object({
  body: z.object({
    journeyAlertsEnabled: z.boolean().optional(),
    safetySummaryLanguage: z.string().optional(),
    quietHoursStart: z.number().min(0).max(23).optional(),
    quietHoursEnd: z.number().min(0).max(23).optional(),
  }),
});

const summarySchema = z.object({
  body: z.object({
    lat: z.number(),
    lng: z.number(),
    lang: z.string().optional(),
    accuracy: z.number().optional(),
  }),
});

const getLiveAssessment = asyncHandler(async (req, res) => {
  const {
    lat,
    lng,
    heading,
    accuracy,
    destinationLat,
    destinationLng,
    includeSummary,
    lang,
    journeyMode,
  } = req.validated.query;
  const payload = await getLiveSafetyAssessment({
    lat,
    lng,
    heading,
    accuracy,
    includeSummary: includeSummary ?? false,
    lang: lang || 'en',
    journeyMode: journeyMode ?? false,
    destination:
      typeof destinationLat === 'number' && typeof destinationLng === 'number'
        ? { lat: destinationLat, lng: destinationLng }
        : null,
  });
  res.json(payload);
});

const postRouteAssessment = asyncHandler(async (req, res) => {
  const payload = await assessRouteOptions(req.validated.body);
  res.json(payload);
});

const postAnonymousPing = asyncHandler(async (req, res) => {
  const { lat, lng } = req.validated.body;
  const result = await recordAnonymousPing(lat, lng);
  res.json(result);
});

const getHealth = asyncHandler(async (req, res) => {
  const payload = await getSafetyIntelligenceHealth();
  res.json(payload);
});

const postJourneyUpdate = asyncHandler(async (req, res) => {
  const { lat, lng, heading, accuracy, destinationLat, destinationLng, lang } =
    req.validated.body;
  const payload = await processJourneyUpdate({
    userId: req.user._id,
    lat,
    lng,
    heading,
    accuracy,
    lang,
    destination:
      typeof destinationLat === 'number' && typeof destinationLng === 'number'
        ? { lat: destinationLat, lng: destinationLng }
        : null,
  });
  res.json(payload);
});

const getPreferences = asyncHandler(async (req, res) => {
  const payload = await getSafetyPreferences(req.user._id);
  res.json(payload);
});

const patchPreferences = asyncHandler(async (req, res) => {
  const payload = await updateSafetyPreferences(req.user._id, req.validated.body);
  res.json(payload);
});

const postSummary = asyncHandler(async (req, res) => {
  const { lat, lng, lang, accuracy } = req.validated.body;
  const at = new Date();
  const context = await loadContext(lat, lng);
  const analysis = await runFusionAnalysis({ lat, lng, at, accuracy, context, useCache: true });
  const external = analysis.external || (await loadExternalSignals(lat, lng, at));
  const aiSummary = await generateSafetySummary({
    analysis,
    external,
    at,
    lang: lang || 'en',
  });
  res.json({ aiSummary, safetyScore: analysis.safetyScore, updatedAt: at.toISOString() });
});

module.exports = {
  liveAssessmentSchema,
  routeAssessmentSchema,
  pingSchema,
  journeyUpdateSchema,
  preferencesPatchSchema,
  summarySchema,
  getLiveAssessment,
  postRouteAssessment,
  postAnonymousPing,
  getHealth,
  postJourneyUpdate,
  getPreferences,
  patchPreferences,
  postSummary,
};
