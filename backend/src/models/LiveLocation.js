const mongoose = require('mongoose');

const liveLocationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  sosEventId: { type: mongoose.Schema.Types.ObjectId, ref: 'SOSEvent', index: true },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true },
  },
  speed: Number,
  heading: Number,
  accuracy: Number,
}, { timestamps: true });

liveLocationSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('LiveLocation', liveLocationSchema);
