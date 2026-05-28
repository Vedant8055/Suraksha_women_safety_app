const mongoose = require('mongoose');

const sosEventSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  shareToken: { type: String, required: true, unique: true, index: true },
  status: { type: String, enum: ['active', 'acknowledged', 'resolved', 'cancelled'], default: 'active', index: true },
  mode: { type: String, enum: ['normal', 'silent'], default: 'normal' },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true },
  },
  notes: String,
  acknowledgedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  resolvedAt: Date,
}, { timestamps: true });

sosEventSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('SOSEvent', sosEventSchema);
