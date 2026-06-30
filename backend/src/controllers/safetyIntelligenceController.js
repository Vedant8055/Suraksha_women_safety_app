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
const { parseGoogleMapsCoordinates } = require('../services/googlePlacesService');

const liveAssessmentSchema = z.object({
  query: z.object({
    lat: z.coerce.number().optional(),
    lng: z.coerce.number().optional(),
    mapsUrl: z.string().url().optional(),
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
}).superRefine((data, ctx) => {
  const hasCoordinates =
    typeof data.query.lat === 'number' && typeof data.query.lng === 'number';
  const hasMapsUrl = Boolean(data.query.mapsUrl);
  if (!hasCoordinates && !hasMapsUrl) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Either lat/lng or mapsUrl is required.',
      path: ['query'],
    });
  }
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
    lat: z.number().optional(),
    lng: z.number().optional(),
    mapsUrl: z.string().url().optional(),
    lang: z.string().optional(),
    accuracy: z.number().optional(),
  }),
}).superRefine((data, ctx) => {
  const hasCoordinates =
    typeof data.body.lat === 'number' && typeof data.body.lng === 'number';
  const hasMapsUrl = Boolean(data.body.mapsUrl);
  if (!hasCoordinates && !hasMapsUrl) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Either lat/lng or mapsUrl is required.',
      path: ['body'],
    });
  }
});

function resolveSafetyCoordinates({ lat, lng, mapsUrl }) {
  if (typeof lat === 'number' && typeof lng === 'number') {
    return { lat, lng };
  }
  if (mapsUrl) {
    const parsed = parseGoogleMapsCoordinates(mapsUrl);
    if (parsed) return parsed;
  }
  return null;
}

const getLiveAssessment = asyncHandler(async (req, res) => {
  const {
    lat,
    lng,
    mapsUrl,
    heading,
    accuracy,
    destinationLat,
    destinationLng,
    includeSummary,
    lang,
    journeyMode,
  } = req.validated.query;
  const coordinates = resolveSafetyCoordinates({ lat, lng, mapsUrl });
  if (!coordinates) {
    return res.status(400).json({ message: 'Unable to resolve location from the provided input.' });
  }
  const payload = await getLiveSafetyAssessment({
    lat: coordinates.lat,
    lng: coordinates.lng,
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
  const { lat, lng, mapsUrl, lang, accuracy } = req.validated.body;
  const coordinates = resolveSafetyCoordinates({ lat, lng, mapsUrl });
  if (!coordinates) {
    return res.status(400).json({ message: 'Unable to resolve location from the provided input.' });
  }
  const at = new Date();
  const context = await loadContext(coordinates.lat, coordinates.lng);
  const analysis = await runFusionAnalysis({
    lat: coordinates.lat,
    lng: coordinates.lng,
    at,
    accuracy,
    context,
    useCache: true,
  });
  const external = analysis.external || (await loadExternalSignals(coordinates.lat, coordinates.lng, at));
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
