const mongoose = require('mongoose');

const cyberEvidenceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  reportId: { type: mongoose.Schema.Types.ObjectId, ref: 'CyberCrimeReport', index: true },
  title: { type: String, required: true, trim: true },
  category: {
    type: String,
    enum: ['Screenshot', 'Audio', 'Threat Message', 'Image', 'Transaction Proof', 'Document', 'Other'],
    default: 'Other',
    index: true,
  },
  filePath: { type: String, trim: true },
  fileType: { type: String, trim: true },
  fileSize: { type: Number, default: 0 },
  encrypted: { type: Boolean, default: true },
  checksum: { type: String, trim: true },
  tags: [{ type: String, trim: true }],
  incidentReference: { type: String, trim: true },
  privateMode: { type: Boolean, default: false, index: true },
}, { timestamps: true });

module.exports = mongoose.model('CyberEvidence', cyberEvidenceSchema);
