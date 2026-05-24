const mongoose = require('mongoose');
const emergencyContactSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  relation: String,
  priority: { type: Number, default: 1 },
}, { timestamps: true });
module.exports = mongoose.model('EmergencyContact', emergencyContactSchema);
