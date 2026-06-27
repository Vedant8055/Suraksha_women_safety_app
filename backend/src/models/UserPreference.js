const mongoose = require('mongoose');
const userPreferenceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  silentSos: { type: Boolean, default: false },
  autoRecordAudio: { type: Boolean, default: true },
  autoRecordVideo: { type: Boolean, default: false },
  language: { type: String, default: 'en' },
  journeyAlertsEnabled: { type: Boolean, default: true },
  safetySummaryLanguage: { type: String, default: 'en' },
  quietHoursStart: { type: Number, default: 22, min: 0, max: 23 },
  quietHoursEnd: { type: Number, default: 7, min: 0, max: 23 },
}, { timestamps: true });
module.exports = mongoose.model('UserPreference', userPreferenceSchema);
