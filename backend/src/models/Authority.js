const mongoose = require('mongoose');
const authoritySchema = new mongoose.Schema({
  name: { type: String, required: true },
  authorityType: { type: String, enum: ['police', 'hospital', 'responder'], index: true },
  phone: String,
  location: { type: { type: String, enum: ['Point'], default: 'Point' }, coordinates: { type: [Number], required: true } },
  address: String,
}, { timestamps: true });
authoritySchema.index({ location: '2dsphere' });
module.exports = mongoose.model('Authority', authoritySchema);
