const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const { fetchNearbyPublicToilets } = require('../services/publicToiletService');

const booleanQuerySchema = z.preprocess((value) => {
  if (value === undefined || value === null || value === '') return undefined;
  if (typeof value === 'boolean') return value;
  const normalized = String(value).trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;
  return value;
}, z.boolean().optional());

const nearbyToiletsQuerySchema = z
  .object({
    lat: z.coerce.number().min(-90).max(90),
    lng: z.coerce.number().min(-180).max(180),
    radius: z.coerce.number().int().positive().max(10000).optional(),
    limit: z.coerce.number().int().positive().max(100).optional(),
    cleanliness_min: z.coerce.number().int().min(0).max(100).optional(),
    include_closed: booleanQuerySchema,
  })
  .strict();

const nearbyToiletsRequestSchema = z.object({
  body: z.object({}).strict(),
  params: z.object({}).strict(),
  query: nearbyToiletsQuerySchema,
});

const getNearbyToilets = asyncHandler(async (req, res) => {
  const { lat, lng, radius, limit, cleanliness_min, include_closed } = req.validated.query;
  const payload = await fetchNearbyPublicToilets({
    lat,
    lng,
    radius,
    limit,
    cleanlinessMin: cleanliness_min,
    includeClosed: include_closed,
  });
  res.json(payload);
});

module.exports = {
  nearbyToiletsRequestSchema,
  getNearbyToilets,
};
