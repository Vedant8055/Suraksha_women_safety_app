const mongoose = require('mongoose');

const externalIncidentSchema = new mongoose.Schema(
  {
    region: { type: String, default: 'nashik', index: true },
    source: { type: String, required: true, index: true },
    sourceId: { type: String, index: true },
    category: { type: String, trim: true, default: 'incident' },
    description: { type: String, trim: true, default: '' },
    location: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true },
    },
    occurredAt: { type: Date, default: Date.now, index: true },
    confidence: { type: Number, min: 0, max: 1, default: 0.7 },
    spatialPrecision: {
      type: String,
      enum: ['point', 'district', 'approximate'],
      default: 'point',
    },
    disclaimer: { type: String, default: '' },
  },
  { timestamps: true },
);

externalIncidentSchema.index({ location: '2dsphere' });
externalIncidentSchema.index({ region: 1, source: 1, sourceId: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('ExternalIncident', externalIncidentSchema);
