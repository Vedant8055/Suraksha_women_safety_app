const { asyncHandler } = require('../utils/asyncHandler');
const Authority = require('../models/Authority');

const nearbyPolice = asyncHandler(async (req, res) => {
  const { lat, lng } = req.query;
  const docs = await Authority.find({ authorityType: 'police', location: { $near: { $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] }, $maxDistance: 10000 } } }).limit(20);
  res.json(docs);
});

const nearbyHospitals = asyncHandler(async (req, res) => {
  const { lat, lng } = req.query;
  const docs = await Authority.find({ authorityType: 'hospital', location: { $near: { $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] }, $maxDistance: 10000 } } }).limit(20);
  res.json(docs);
});

module.exports = { nearbyPolice, nearbyHospitals };
