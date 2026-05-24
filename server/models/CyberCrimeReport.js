const mongoose = require('mongoose');

const cyberCrimeReportSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  category: {
    type: String,
    required: true,
    enum: ['Financial Fraud', 'Cyber Stalking', 'Online Bullying', 'Identity Theft', 'Social Media Harassment']
  },
  description: { type: String, required: true },
  evidenceUrls: [{ type: String }],
  status: { type: String, enum: ['Reported', 'Under Investigation', 'Resolved'], default: 'Reported' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('CyberCrimeReport', cyberCrimeReportSchema);
