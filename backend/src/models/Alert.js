const mongoose = require('mongoose');
const alertSchema = new mongoose.Schema({
  title: String,
  body: String,
  severity: { type: String, enum: ['low', 'medium', 'high'], default: 'low', index: true },
  area: { type: { type: String, enum: ['Point'], default: 'Point' }, coordinates: { type: [Number], default: [0, 0] } },
  radiusMeters: { type: Number, default: 1000 },
  active: { type: Boolean, default: true, index: true },
}, { timestamps: true });
alertSchema.index({ area: '2dsphere' });
module.exports = mongoose.model('Alert', alertSchema);
