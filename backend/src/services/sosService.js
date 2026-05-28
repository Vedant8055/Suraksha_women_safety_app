const crypto = require('crypto');
const SOSEvent = require('../models/SOSEvent');
const EmergencyHistory = require('../models/EmergencyHistory');
const { toPoint } = require('../utils/geo');

const createSos = ({ userId, lat, lng, mode, notes }) => SOSEvent.create({
  userId,
  shareToken: crypto.randomBytes(18).toString('hex'),
  location: toPoint(lat, lng),
  mode,
  notes,
});
const resolveSos = async ({ eventId, status = 'resolved' }) => {
  const event = await SOSEvent.findByIdAndUpdate(eventId, { status, resolvedAt: new Date() }, { new: true });
  if (event) {
    await EmergencyHistory.create({ userId: event.userId, sosEventId: event._id, outcome: status === 'cancelled' ? 'cancelled' : 'resolved' });
  }
  return event;
};

module.exports = { createSos, resolveSos };
