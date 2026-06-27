const mongoose = require('mongoose');

const areaCrimeStatsSchema = new mongoose.Schema(
  {
    region: { type: String, default: 'nashik', index: true },
    district: { type: String, required: true },
    state: { type: String, default: 'Maharashtra' },
    periodType: { type: String, enum: ['monthly', 'yearly'], default: 'yearly' },
    periodLabel: { type: String, required: true },
    totalIncidents: { type: Number, default: 0 },
    categoryBreakdown: { type: Map, of: Number },
    ratePer100k: { type: Number },
    populationEstimate: { type: Number },
    sources: [{ type: String }],
    disclaimer: { type: String, default: '' },
    lastSyncAt: { type: Date },
  },
  { timestamps: true },
);

areaCrimeStatsSchema.index({ region: 1, district: 1, periodLabel: 1 }, { unique: true });

module.exports = mongoose.model('AreaCrimeStats', areaCrimeStatsSchema);
