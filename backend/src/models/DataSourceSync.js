const mongoose = require('mongoose');

const dataSourceSyncSchema = new mongoose.Schema(
  {
    sourceKey: { type: String, required: true, unique: true, index: true },
    region: { type: String, default: 'nashik' },
    status: { type: String, enum: ['ok', 'error', 'running'], default: 'ok' },
    lastSyncAt: { type: Date },
    lastSuccessAt: { type: Date },
    featureCount: { type: Number, default: 0 },
    message: { type: String, default: '' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('DataSourceSync', dataSourceSyncSchema);
