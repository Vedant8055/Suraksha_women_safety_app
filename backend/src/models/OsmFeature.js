const mongoose = require('mongoose');

const osmFeatureSchema = new mongoose.Schema(
  {
    region: { type: String, default: 'nashik', index: true },
    source: { type: String, default: 'openstreetmap', index: true },
    featureType: {
      type: String,
      enum: ['police', 'hospital', 'unlit_road', 'lit_road', 'clinic', 'fuel_station'],
      required: true,
      index: true,
    },
    externalId: { type: String, required: true, index: true },
    name: { type: String, trim: true, default: '' },
    location: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true },
    },
    tags: { type: Map, of: String },
  },
  { timestamps: true },
);

osmFeatureSchema.index({ location: '2dsphere' });
osmFeatureSchema.index({ region: 1, featureType: 1, externalId: 1 }, { unique: true });

module.exports = mongoose.model('OsmFeature', osmFeatureSchema);
