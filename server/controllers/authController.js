const User = require('../models/User');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const env = require('../config/env');
const { auditLog } = require('../utils/auditLogger');
const {
  TEMP_USER_ID,
  isTempAuthActive,
  buildTempUser,
  matchesTempIdentifier,
  getRefreshTokenHash,
  setRefreshTokenHash,
} = require('../utils/tempAuth');

const generateAccessToken = (id) => {
  return jwt.sign({ id }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });
};

const generateRefreshToken = (id) => {
  return jwt.sign({ id, type: 'refresh' }, env.jwtRefreshSecret, {
    expiresIn: env.jwtRefreshExpiresIn,
  });
};

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const buildAuthResponse = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  token: generateAccessToken(user._id),
});

const buildTokenPair = (user) => ({
  ...buildAuthResponse(user),
  refreshToken: generateRefreshToken(user._id),
});

const shouldUseTempAuthFallback = (error) =>
  isTempAuthActive() &&
  (error?.name === 'MongooseServerSelectionError' ||
    error?.name === 'MongoNetworkError' ||
    error?.name === 'MongoTimeoutError');

exports.register = async (req, res, next) => {
  try {
    const { name, email, phone, password } = req.body;

    const userExists = await User.findOne({ $or: [{ email }, { phone }] });
    if (userExists) {
      auditLog({
        action: 'auth.register.failed',
        status: 'failed',
        ip: req.ip,
        metadata: { reason: 'user_exists', email, phone },
      });
      return res.status(400).json({ message: 'User already exists' });
    }

    const user = await User.create({ name, email, phone, password });
    const authResponse = buildTokenPair(user);
    user.refreshTokenHash = hashToken(authResponse.refreshToken);
    await user.save();

    auditLog({
      action: 'auth.register.success',
      userId: user._id.toString(),
      ip: req.ip,
    });

    res.status(201).json(authResponse);
  } catch (error) {
    next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { identifier, password } = req.body; // identifier can be email or phone
    if (
      isTempAuthActive() &&
      matchesTempIdentifier(identifier) &&
      password === env.tempAuthPassword
    ) {
      const tempUser = buildTempUser();
      const authResponse = buildTokenPair(tempUser);
      setRefreshTokenHash(hashToken(authResponse.refreshToken));
      return res.json(authResponse);
    }

    const user = await User.findOne({
      $or: [{ email: identifier }, { phone: identifier }]
    }).select('+refreshTokenHash');

    if (user && (await user.comparePassword(password))) {
      const authResponse = buildTokenPair(user);
      user.refreshTokenHash = hashToken(authResponse.refreshToken);
      await user.save();

      auditLog({
        action: 'auth.login.success',
        userId: user._id.toString(),
        ip: req.ip,
      });

      return res.json(authResponse);
    } else {
      auditLog({
        action: 'auth.login.failed',
        status: 'failed',
        ip: req.ip,
        metadata: { identifier },
      });
      return res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    if (
      shouldUseTempAuthFallback(error) &&
      matchesTempIdentifier(req.body?.identifier) &&
      req.body?.password === env.tempAuthPassword
    ) {
      const tempUser = buildTempUser();
      const authResponse = buildTokenPair(tempUser);
      setRefreshTokenHash(hashToken(authResponse.refreshToken));
      return res.json(authResponse);
    }

    next(error);
  }
};

exports.refresh = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ message: 'Refresh token is required' });
    }

    const decoded = jwt.verify(refreshToken, env.jwtRefreshSecret);
    if (decoded.type !== 'refresh') {
      return res.status(401).json({ message: 'Invalid refresh token type' });
    }

    if (decoded.id === TEMP_USER_ID && isTempAuthActive()) {
      const storedHash = getRefreshTokenHash();
      if (!storedHash || storedHash !== hashToken(refreshToken)) {
        return res.status(401).json({ message: 'Refresh token mismatch' });
      }

      const tempUser = buildTempUser();
      const authResponse = buildTokenPair(tempUser);
      setRefreshTokenHash(hashToken(authResponse.refreshToken));
      return res.json(authResponse);
    }

    const user = await User.findById(decoded.id).select('+refreshTokenHash');
    if (!user || !user.refreshTokenHash) {
      return res.status(401).json({ message: 'Refresh session not found' });
    }

    if (user.refreshTokenHash !== hashToken(refreshToken)) {
      return res.status(401).json({ message: 'Refresh token mismatch' });
    }

    const authResponse = buildTokenPair(user);
    user.refreshTokenHash = hashToken(authResponse.refreshToken);
    await user.save();

    auditLog({
      action: 'auth.refresh.success',
      userId: user._id.toString(),
      ip: req.ip,
    });

    return res.json(authResponse);
  } catch (error) {
    auditLog({
      action: 'auth.refresh.failed',
      status: 'failed',
      ip: req.ip,
      metadata: { reason: 'verification_failed' },
    });
    return res.status(401).json({ message: 'Invalid or expired refresh token' });
  }
};

exports.logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      const decoded = jwt.verify(refreshToken, env.jwtRefreshSecret);
      if (decoded.id === TEMP_USER_ID && isTempAuthActive()) {
        setRefreshTokenHash(null);
        return res.status(200).json({ message: 'Logged out successfully' });
      }
      const user = await User.findById(decoded.id).select('+refreshTokenHash');
      if (user) {
        user.refreshTokenHash = null;
        await user.save();
        auditLog({
          action: 'auth.logout.success',
          userId: user._id.toString(),
          ip: req.ip,
        });
      }
    }

    return res.status(200).json({ message: 'Logged out successfully' });
  } catch (error) {
    return res.status(200).json({ message: 'Logged out successfully' });
  }
};

exports.getProfile = async (req, res, next) => {
  try {
    if (req.user?._id === TEMP_USER_ID && isTempAuthActive()) {
      return res.json(buildTempUser());
    }

    const user = await User.findById(req.user._id).select('-password');
    if (user) {
      return res.json(user);
    } else {
      return res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    next(error);
  }
};
