const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const {
  getLiveSafetyAssessment,
  assessRouteOptions,
} = require('../services/safetyIntelligenceService');

const liveAssessmentSchema = z.object({
  query: z.object({
    lat: z.coerce.number(),
    lng: z.coerce.number(),
    heading: z.coerce.number().optional(),
    accuracy: z.coerce.number().optional(),
    destinationLat: z.coerce.number().optional(),
    destinationLng: z.coerce.number().optional(),
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

const getLiveAssessment = asyncHandler(async (req, res) => {
  const { lat, lng, heading, accuracy, destinationLat, destinationLng } = req.validated.query;
  const payload = await getLiveSafetyAssessment({
    lat,
    lng,
    heading,
    accuracy,
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

module.exports = {
  liveAssessmentSchema,
  routeAssessmentSchema,
  getLiveAssessment,
  postRouteAssessment,
};
