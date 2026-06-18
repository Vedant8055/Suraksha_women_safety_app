const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const sosService = require('../services/sosService');
const SOSEvent = require('../models/SOSEvent');

const createSosSchema = z.object({ body: z.object({ lat: z.number(), lng: z.number(), mode: z.enum(['normal', 'silent']).default('normal'), notes: z.string().optional() }) });
const cancelSosSchema = z.object({
  body: z.object({
    eventId: z.string().optional(),
    sosEventId: z.string().optional(),
  }),
});

const create = asyncHandler(async (req, res) => {
  const sos = await sosService.createSos({ userId: req.user._id, ...req.validated.body });
  const trackingUrl = `${req.protocol}://${req.get('host')}/live-sos/${sos.shareToken}`;
  res.status(201).json({ ...sos.toObject(), trackingUrl });
});

const active = asyncHandler(async (req, res) => {
  const events = await SOSEvent.find({ userId: req.user._id }).sort({ createdAt: -1 }).limit(20);
  res.json(events);
});

const cancel = asyncHandler(async (req, res) => {
  const eventId = req.validated.body.eventId || req.validated.body.sosEventId || null;
  const sos = await sosService.resolveSos({
    eventId,
    userId: req.user._id,
    status: 'cancelled',
  });

  if (!sos) {
    return res.status(404).json({ message: 'Active SOS not found.' });
  }

  res.json({ ...sos.toObject(), status: 'cancelled' });
});

module.exports = { cancel, create, active, createSosSchema, cancelSosSchema };
