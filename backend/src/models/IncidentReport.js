const mongoose = require('mongoose');

const incidentReportSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  category: { type: String, required: true, trim: true },
  description: { type: String, required: true, trim: true },
  status: { type: String, enum: ['reported', 'under_review', 'resolved'], default: 'reported', index: true },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: [0, 0] },
  },
  evidenceIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'MediaEvidence' }],
}, { timestamps: true });

incidentReportSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('IncidentReport', incidentReportSchema);
