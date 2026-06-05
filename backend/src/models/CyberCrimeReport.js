const mongoose = require('mongoose');

const cyberCrimeReportSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  category: {
    type: String,
    required: true,
    trim: true,
    enum: [
      'Financial Fraud',
      'Cyber Stalking',
      'Online Bullying',
      'Identity Theft',
      'Social Media Harassment',
      'Harassment',
      'Blackmail',
      'Fake Profile',
      'Deepfake Threat',
      'Deepfake Scam',
      'Fake Job Scam',
      'UPI Fraud',
    ],
  },
  description: { type: String, required: true, trim: true },
  suspectContact: { type: String, trim: true },
  transactionId: { type: String, trim: true },
  incidentAt: { type: Date },
  complaintSummary: { type: String, trim: true },
  firStyleReport: { type: String, trim: true },
  pdfBase64: { type: String },
  isDraft: { type: Boolean, default: false, index: true },
  evidenceUrls: [{ type: String, trim: true }],
  status: {
    type: String,
    enum: ['Reported', 'Under Investigation', 'Resolved'],
    default: 'Reported',
    index: true,
  },
}, { timestamps: true });

module.exports = mongoose.model('CyberCrimeReport', cyberCrimeReportSchema);
