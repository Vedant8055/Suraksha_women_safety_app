const { z } = require('zod');
const { asyncHandler } = require('../utils/asyncHandler');
const authService = require('../services/authService');

const registerSchema = z.object({ body: z.object({ fullName: z.string().min(2), phone: z.string().min(8), email: z.string().email().optional(), password: z.string().min(8), role: z.enum(['citizen', 'police', 'admin', 'responder']).optional() }) });
const loginSchema = z.object({ body: z.object({ identifier: z.string().min(3), password: z.string().min(8) }) });

const register = asyncHandler(async (req, res) => {
  const { user, accessToken, refreshToken } = await authService.register(req.validated.body);
  res.status(201).json({ _id: user._id, name: user.fullName, email: user.email, phone: user.phone, role: user.role, token: accessToken, refreshToken });
});

const login = asyncHandler(async (req, res) => {
  const { user, accessToken, refreshToken } = await authService.login(req.validated.body);
  res.json({ _id: user._id, name: user.fullName, email: user.email, phone: user.phone, role: user.role, token: accessToken, refreshToken });
});

module.exports = { register, login, registerSchema, loginSchema };
