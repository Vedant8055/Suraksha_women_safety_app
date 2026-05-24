const mongoose = require('mongoose');

const sosEventSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
    address: { type: String }
  },
  status: { type: String, enum: ['active', 'resolved', 'cancelled'], default: 'active' },
  emergencyType: { type: String },
  evidence: [{
    type: { type: String, enum: ['audio', 'video', 'image'] },
    url: { type: String },
    timestamp: { type: Date, default: Date.now }
  }],
  liveTracking: [{
    lat: { type: Number },
    lng: { type: Number },
    timestamp: { type: Date, default: Date.now }
  }],
  createdAt: { type: Date, default: Date.now },
  resolvedAt: { type: Date }
});

module.exports = mongoose.model('SOSEvent', sosEventSchema);
