const { asyncHandler } = require('../utils/asyncHandler');
const { findNearbySupportPoints } = require('../services/nearbyResourceService');

const nearbyPolice = asyncHandler(async (req, res) => {
  const { lat, lng } = req.query;
  const docs = await findNearbySupportPoints(lat, lng, 'police');
  res.json(docs);
});

const nearbyHospitals = asyncHandler(async (req, res) => {
  const { lat, lng } = req.query;
  const docs = await findNearbySupportPoints(lat, lng, 'hospital');
  res.json(docs);
});

module.exports = { nearbyPolice, nearbyHospitals };
