const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const { addLiveLocation } = require('../services/locationService');

const updateLocationSchema = z.object({ body: z.object({ lat: z.number(), lng: z.number(), sosEventId: z.string().optional(), speed: z.number().optional(), heading: z.number().optional(), accuracy: z.number().optional() }) });

const updateLocation = asyncHandler(async (req, res) => {
  const location = await addLiveLocation({ userId: req.user._id, ...req.validated.body });
  res.status(201).json(location);
});

module.exports = { updateLocation, updateLocationSchema };
