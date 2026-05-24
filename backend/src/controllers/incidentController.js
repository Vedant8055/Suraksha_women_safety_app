const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const IncidentReport = require('../models/IncidentReport');
const { toPoint } = require('../utils/geo');

const reportSchema = z.object({ body: z.object({ category: z.string().min(2), description: z.string().min(5), lat: z.number().optional(), lng: z.number().optional() }) });

const reportIncident = asyncHandler(async (req, res) => {
  const { category, description, lat, lng } = req.validated.body;
  const payload = { userId: req.user._id, category, description };
  if (lat !== undefined && lng !== undefined) payload.location = toPoint(lat, lng);
  const report = await IncidentReport.create(payload);
  res.status(201).json(report);
});

module.exports = { reportIncident, reportSchema };
