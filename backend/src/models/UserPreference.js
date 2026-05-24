const mongoose = require('mongoose');
const userPreferenceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  silentSos: { type: Boolean, default: false },
  autoRecordAudio: { type: Boolean, default: true },
  autoRecordVideo: { type: Boolean, default: false },
  language: { type: String, default: 'en' },
}, { timestamps: true });
module.exports = mongoose.model('UserPreference', userPreferenceSchema);
