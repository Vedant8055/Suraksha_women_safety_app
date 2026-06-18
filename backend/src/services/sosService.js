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

const resolveSos = async ({ eventId, userId, status = 'resolved' }) => {
  const filter = eventId
    ? { _id: eventId, ...(userId ? { userId } : {}) }
    : { userId, status: 'active' };
  const options = { new: true };
  if (!eventId) {
    options.sort = { createdAt: -1 };
  }

  const event = await SOSEvent.findOneAndUpdate(
    filter,
    { status, resolvedAt: new Date() },
    options,
  );
  if (event) {
    await EmergencyHistory.create({ userId: event.userId, sosEventId: event._id, outcome: status === 'cancelled' ? 'cancelled' : 'resolved' });
  }
  return event;
};

module.exports = { createSos, resolveSos };
