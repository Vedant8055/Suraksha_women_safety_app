const { z } = require('zod');
const User = require('../models/User');
const EmergencyContact = require('../models/EmergencyContact');
const DeviceSession = require('../models/DeviceSession');
const { asyncHandler } = require('../utils/asyncHandler');
const { uploadToCloudinary } = require('../services/mediaService');
const multer = require('multer');
const fs = require('fs');
const { tempUploadsRoot } = require('../config/paths');

fs.mkdirSync(tempUploadsRoot, { recursive: true });
const upload = multer({ dest: tempUploadsRoot });

const updateProfileSchema = z.object({
  body: z.object({
    fullName: z.string().min(2).optional(),
    email: z.string().email().optional(),
    bloodGroup: z.string().optional(),
    allergies: z.array(z.string()).optional(),
    medicalConditions: z.array(z.string()).optional(),
    currentMedications: z.array(z.string()).optional(),
  }),
});
const contactSchema = z.object({ body: z.object({ name: z.string().min(2), phone: z.string().min(8), relation: z.string().optional() }) });
const updateContactSchema = z.object({
  params: z.object({ id: z.string().min(1) }),
  body: z.object({
    name: z.string().min(2).optional(),
    phone: z.string().min(8).optional(),
    relation: z.string().optional(),
  }),
});
const deleteContactSchema = z.object({
  params: z.object({ id: z.string().min(1) }),
});
const fcmTokenSchema = z.object({
  body: z.object({
    fcmToken: z.string().min(8),
    platform: z.string().optional(),
    deviceId: z.string().optional(),
  }),
});

const getProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id);
  res.json({
    _id: user._id,
    name: user.fullName,
    email: user.email,
    phone: user.phone,
    bloodGroup: user.bloodGroup,
    allergies: user.allergies || [],
    medicalConditions: user.medicalConditions || [],
    currentMedications: user.currentMedications || [],
    role: user.role,
    profilePhoto: user.profilePhotoUrl || null,
  });
});

const updateProfile = asyncHandler(async (req, res) => {
  const updates = {};
  if (req.validated.body.fullName !== undefined) updates.fullName = req.validated.body.fullName;
  if (req.validated.body.email !== undefined) updates.email = req.validated.body.email;
  if (req.validated.body.bloodGroup !== undefined) updates.bloodGroup = req.validated.body.bloodGroup;
  if (req.validated.body.allergies !== undefined) updates.allergies = req.validated.body.allergies;
  if (req.validated.body.medicalConditions !== undefined) updates.medicalConditions = req.validated.body.medicalConditions;
  if (req.validated.body.currentMedications !== undefined) updates.currentMedications = req.validated.body.currentMedications;

  const updated = await User.findByIdAndUpdate(req.user._id, updates, { new: true });
  res.json({
    _id: updated._id,
    name: updated.fullName,
    email: updated.email,
    phone: updated.phone,
    bloodGroup: updated.bloodGroup,
    allergies: updated.allergies || [],
    medicalConditions: updated.medicalConditions || [],
    currentMedications: updated.currentMedications || [],
    role: updated.role,
    profilePhoto: updated.profilePhotoUrl || null,
  });
});

const addContact = asyncHandler(async (req, res) => {
  const contact = await EmergencyContact.create({ userId: req.user._id, ...req.validated.body });
  res.status(201).json(contact);
});

const listContacts = asyncHandler(async (req, res) => {
  const contacts = await EmergencyContact.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json(contacts);
});

const updateContact = asyncHandler(async (req, res) => {
  const contact = await EmergencyContact.findOneAndUpdate(
    { _id: req.validated.params.id, userId: req.user._id },
    req.validated.body,
    { new: true },
  );
  if (!contact) return res.status(404).json({ message: 'Contact not found' });
  res.json(contact);
});

const deleteContact = asyncHandler(async (req, res) => {
  const deleted = await EmergencyContact.findOneAndDelete({
    _id: req.validated.params.id,
    userId: req.user._id,
  });
  if (!deleted) return res.status(404).json({ message: 'Contact not found' });
  res.json({ success: true });
});

const uploadProfilePhoto = asyncHandler(async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
  const result = await uploadToCloudinary(req.file.path, 'suraksha/profile');
  const updated = await User.findByIdAndUpdate(
    req.user._id,
    { profilePhotoUrl: result.secure_url },
    { new: true },
  );

  res.json({
    _id: updated._id,
    name: updated.fullName,
    email: updated.email,
    phone: updated.phone,
    bloodGroup: updated.bloodGroup,
    allergies: updated.allergies || [],
    medicalConditions: updated.medicalConditions || [],
    currentMedications: updated.currentMedications || [],
    role: updated.role,
    profilePhoto: updated.profilePhotoUrl || null,
  });
});

const registerFcmToken = asyncHandler(async (req, res) => {
  const { fcmToken, platform, deviceId } = req.validated.body;
  const updated = await DeviceSession.findOneAndUpdate(
    deviceId
      ? { userId: req.user._id, deviceId }
      : { userId: req.user._id, isActive: true },
    { fcmToken, platform, ...(deviceId ? { deviceId } : {}) },
    { sort: { updatedAt: -1 }, new: true },
  );
  if (!updated) {
    res.json({ ok: false, message: 'No active device session found. Sign in again.' });
    return;
  }
  res.json({ ok: true });
});

module.exports = {
  upload,
  getProfile,
  updateProfile,
  addContact,
  listContacts,
  updateContact,
  deleteContact,
  uploadProfilePhoto,
  registerFcmToken,
  updateProfileSchema,
  contactSchema,
  updateContactSchema,
  deleteContactSchema,
  fcmTokenSchema,
};
