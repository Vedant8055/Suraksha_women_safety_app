const { z } = require('zod');
const User = require('../models/User');
const EmergencyContact = require('../models/EmergencyContact');
const { asyncHandler } = require('../utils/asyncHandler');

const updateProfileSchema = z.object({ body: z.object({ fullName: z.string().min(2).optional(), email: z.string().email().optional(), bloodGroup: z.string().optional() }) });
const contactSchema = z.object({ body: z.object({ name: z.string().min(2), phone: z.string().min(8), relation: z.string().optional() }) });

const getProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id);
  res.json({ _id: user._id, name: user.fullName, email: user.email, phone: user.phone, bloodGroup: user.bloodGroup, role: user.role });
});

const updateProfile = asyncHandler(async (req, res) => {
  const updated = await User.findByIdAndUpdate(req.user._id, req.validated.body, { new: true });
  res.json(updated);
});

const addContact = asyncHandler(async (req, res) => {
  const contact = await EmergencyContact.create({ userId: req.user._id, ...req.validated.body });
  res.status(201).json(contact);
});

const listContacts = asyncHandler(async (req, res) => {
  const contacts = await EmergencyContact.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json(contacts);
});

module.exports = { getProfile, updateProfile, addContact, listContacts, updateProfileSchema, contactSchema };
