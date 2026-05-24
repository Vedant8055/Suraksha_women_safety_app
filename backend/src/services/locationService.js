const LiveLocation = require('../models/LiveLocation');
const { toPoint } = require('../utils/geo');

const addLiveLocation = ({ userId, lat, lng, sosEventId, speed, heading, accuracy }) => LiveLocation.create({
  userId,
  sosEventId,
  location: toPoint(lat, lng),
  speed,
  heading,
  accuracy,
});

module.exports = { addLiveLocation };
