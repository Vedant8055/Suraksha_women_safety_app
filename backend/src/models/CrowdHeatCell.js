const mongoose = require('mongoose');

const crowdHeatCellSchema = new mongoose.Schema(
  {
    region: { type: String, default: 'nashik', index: true },
    cellId: { type: String, required: true, unique: true, index: true },
    location: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true },
    },
    pingCount2h: { type: Number, default: 0 },
    windowStartedAt: { type: Date, default: Date.now },
    lastPingAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

crowdHeatCellSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('CrowdHeatCell', crowdHeatCellSchema);
