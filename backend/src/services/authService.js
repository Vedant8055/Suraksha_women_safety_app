const User = require('../models/User');
const DeviceSession = require('../models/DeviceSession');
const { ApiError } = require('../utils/ApiError');
const { signAccessToken, signRefreshToken, hashToken } = require('../utils/jwt');

const register = async ({ fullName, phone, email, password, role = 'citizen' }) => {
  const existing = await User.findOne({ phone });
  if (existing) throw new ApiError(409, 'Phone already registered');
  const user = new User({ fullName, phone, email, role, isPhoneVerified: true });
  await user.setPassword(password);
  await user.save();
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  await DeviceSession.create({ userId: user._id, refreshTokenHash: hashToken(refreshToken) });
  return { user, accessToken, refreshToken };
};

const login = async ({ identifier, password }) => {
  const user = await User.findOne({ $or: [{ phone: identifier }, { email: identifier }] }).select('+passwordHash');
  if (!user) throw new ApiError(401, 'Invalid credentials');
  const ok = await user.comparePassword(password);
  if (!ok) throw new ApiError(401, 'Invalid credentials');
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);
  await DeviceSession.create({ userId: user._id, refreshTokenHash: hashToken(refreshToken) });
  return { user, accessToken, refreshToken };
};

module.exports = { register, login };
