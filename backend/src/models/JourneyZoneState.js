const mongoose = require('mongoose');

const journeyZoneStateSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },
    geohash: { type: String, default: '', index: true },
    riskTier: {
      type: String,
      enum: ['low', 'moderate', 'high', 'critical'],
      default: 'moderate',
    },
    safetyScore: { type: Number, default: 50 },
    lastAlertAt: { type: Date },
    lastAlertType: { type: String, default: '' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('JourneyZoneState', journeyZoneStateSchema);
