const mongoose = require('mongoose');
const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  title: String,
  body: String,
  type: { type: String, default: 'general' },
  readAt: Date,
  metadata: { type: Object, default: {} },
}, { timestamps: true });
module.exports = mongoose.model('Notification', notificationSchema);
