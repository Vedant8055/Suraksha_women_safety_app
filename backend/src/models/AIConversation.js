const mongoose = require('mongoose');

const aiConversationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  messages: [{ role: { type: String, enum: ['user', 'assistant', 'system'] }, content: String, createdAt: { type: Date, default: Date.now } }],
}, { timestamps: true });

module.exports = mongoose.model('AIConversation', aiConversationSchema);
