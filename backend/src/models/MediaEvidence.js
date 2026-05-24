const mongoose = require('mongoose');

const mediaEvidenceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  incidentId: { type: mongoose.Schema.Types.ObjectId, ref: 'IncidentReport', index: true },
  sosEventId: { type: mongoose.Schema.Types.ObjectId, ref: 'SOSEvent', index: true },
  mediaType: { type: String, enum: ['audio', 'video', 'image'], required: true },
  storageUrl: { type: String, required: true },
  mimeType: String,
  size: Number,
}, { timestamps: true });

module.exports = mongoose.model('MediaEvidence', mediaEvidenceSchema);
