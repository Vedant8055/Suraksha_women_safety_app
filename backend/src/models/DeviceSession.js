const mongoose = require('mongoose');
const deviceSessionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  refreshTokenHash: { type: String, required: true, index: true },
  deviceId: String,
  platform: String,
  fcmToken: String,
  isActive: { type: Boolean, default: true, index: true },
}, { timestamps: true });
module.exports = mongoose.model('DeviceSession', deviceSessionSchema);
