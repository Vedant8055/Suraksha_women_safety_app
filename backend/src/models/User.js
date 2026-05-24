const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const emergencyContactSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  phone: { type: String, required: true, trim: true },
  relation: { type: String, trim: true },
  isPrimary: { type: Boolean, default: false },
}, { _id: true, timestamps: true });

const userSchema = new mongoose.Schema({
  role: { type: String, enum: ['citizen', 'police', 'admin', 'responder'], default: 'citizen', index: true },
  fullName: { type: String, required: true, trim: true },
  phone: { type: String, required: true, unique: true, index: true },
  email: { type: String, trim: true, lowercase: true, sparse: true },
  passwordHash: { type: String, required: true, select: false },
  isPhoneVerified: { type: Boolean, default: false },
  emergencyContacts: [emergencyContactSchema],
  profilePhotoUrl: String,
  bloodGroup: String,
  medicalConditions: [String],
  allergies: [String],
  lastKnownLocation: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: [0, 0] },
  },
}, { timestamps: true });

userSchema.index({ lastKnownLocation: '2dsphere' });

userSchema.methods.setPassword = async function setPassword(password) {
  this.passwordHash = await bcrypt.hash(password, 10);
};

userSchema.methods.comparePassword = async function comparePassword(password) {
  return bcrypt.compare(password, this.passwordHash);
};

module.exports = mongoose.model('User', userSchema);
