const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  refreshTokenHash: { type: String, default: null, select: false },
  bloodGroup: { type: String },
  medicalConditions: [{ type: String }],
  allergies: [{ type: String }],
  profilePhoto: { type: String },
  emergencyContacts: [{
    name: { type: String },
    phone: { type: String },
    relation: { type: String }
  }],
  trustedLocations: [{
    name: { type: String },
    lat: { type: Number },
    lng: { type: Number }
  }],
  sosSettings: {
    silentSOS: { type: Boolean, default: false },
    autoRecordAudio: { type: Boolean, default: true },
    autoRecordVideo: { type: Boolean, default: false },
    countdownDuration: { type: Number, default: 5 }
  },
  createdAt: { type: Date, default: Date.now }
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
