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
    ],
  },
  description: { type: String, required: true, trim: true },
  evidenceUrls: [{ type: String, trim: true }],
  status: {
    type: String,
    enum: ['Reported', 'Under Investigation', 'Resolved'],
    default: 'Reported',
    index: true,
  },
}, { timestamps: true });

module.exports = mongoose.model('CyberCrimeReport', cyberCrimeReportSchema);
