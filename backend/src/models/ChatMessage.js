const mongoose = require('mongoose');
const chatMessageSchema = new mongoose.Schema({
  fromUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  toUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  text: { type: String, required: true },
  incidentId: { type: mongoose.Schema.Types.ObjectId, ref: 'IncidentReport' },
}, { timestamps: true });
module.exports = mongoose.model('ChatMessage', chatMessageSchema);
