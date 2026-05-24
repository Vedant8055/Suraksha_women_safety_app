const mongoose = require('mongoose');
const emergencyHistorySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  sosEventId: { type: mongoose.Schema.Types.ObjectId, ref: 'SOSEvent', required: true, index: true },
  outcome: { type: String, enum: ['resolved', 'cancelled', 'false_alarm'], default: 'resolved' },
  summary: String,
}, { timestamps: true });
module.exports = mongoose.model('EmergencyHistory', emergencyHistorySchema);
