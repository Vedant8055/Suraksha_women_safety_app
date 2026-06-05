const mongoose = require('mongoose');

const cyberLearningProgressSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  completedTopicIds: [{ type: String, trim: true }],
  quizScores: [{
    topicId: { type: String, trim: true },
    score: { type: Number, min: 0, max: 100 },
    completedAt: { type: Date, default: Date.now },
  }],
  badges: [{ type: String, trim: true }],
  safetyScore: { type: Number, min: 0, max: 100, default: 0 },
}, { timestamps: true });

cyberLearningProgressSchema.index({ userId: 1 }, { unique: true });

module.exports = mongoose.model('CyberLearningProgress', cyberLearningProgressSchema);
