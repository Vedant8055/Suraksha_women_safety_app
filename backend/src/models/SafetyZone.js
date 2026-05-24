const mongoose = require('mongoose');
const safetyZoneSchema = new mongoose.Schema({
  name: { type: String, required: true },
  kind: { type: String, enum: ['safe', 'risk', 'hospital', 'police'], required: true, index: true },
  location: { type: { type: String, enum: ['Point'], default: 'Point' }, coordinates: { type: [Number], required: true } },
  radiusMeters: { type: Number, default: 500 },
}, { timestamps: true });
safetyZoneSchema.index({ location: '2dsphere' });
module.exports = mongoose.model('SafetyZone', safetyZoneSchema);
