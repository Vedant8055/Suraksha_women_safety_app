const jwt = require('jsonwebtoken');
const User = require('../models/User');
const env = require('../config/env');
const { TEMP_USER_ID, isTempAuthActive, buildTempUser } = require('../utils/tempAuth');

const protect = async (req, res, next) => {
  const authorizationHeader = req.headers.authorization;
  const hasBearerToken =
    authorizationHeader && authorizationHeader.startsWith('Bearer ');

  if (!hasBearerToken) {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }

  try {
    const token = authorizationHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.jwtSecret);

    if (decoded.id === TEMP_USER_ID && isTempAuthActive()) {
      req.user = buildTempUser();
      return next();
    }

    const user = await User.findById(decoded.id).select('-password');

    if (!user) {
      return res.status(401).json({ message: 'Not authorized, user not found' });
    }

    req.user = user;
    return next();
  } catch (error) {
    console.error(error);
    return res.status(401).json({ message: 'Not authorized, token failed' });
  }
};

module.exports = { protect };
