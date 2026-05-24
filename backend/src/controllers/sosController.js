const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const sosService = require('../services/sosService');
const SOSEvent = require('../models/SOSEvent');

const createSosSchema = z.object({ body: z.object({ lat: z.number(), lng: z.number(), mode: z.enum(['normal', 'silent']).default('normal'), notes: z.string().optional() }) });

const create = asyncHandler(async (req, res) => {
  const sos = await sosService.createSos({ userId: req.user._id, ...req.validated.body });
  res.status(201).json(sos);
});

const active = asyncHandler(async (req, res) => {
  const events = await SOSEvent.find({ userId: req.user._id }).sort({ createdAt: -1 }).limit(20);
  res.json(events);
});

module.exports = { create, active, createSosSchema };
