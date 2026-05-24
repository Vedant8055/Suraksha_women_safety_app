const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const isProduction = process.env.NODE_ENV === 'production';

const parseOrigins = (value) => {
  if (!value) {
    return [];
  }

  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
};

const getRequiredEnv = (key) => {
  const value = process.env[key];
  if (value && value.trim()) {
    return value.trim();
  }

  if (isProduction) {
    throw new Error(`Missing required environment variable: ${key}`);
  }

  return null;
};

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 5000),
  mongoUri:
    process.env.MONGO_URI ||
    process.env.MONGODB_URI ||
    'mongodb://localhost:27017/suraksha',
  jwtSecret: getRequiredEnv('JWT_SECRET') || process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '30d',
  jwtRefreshSecret:
    getRequiredEnv('JWT_REFRESH_SECRET') || process.env.JWT_REFRESH_SECRET,
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  clientOrigins: parseOrigins(process.env.CLIENT_ORIGINS),
  authRateLimitWindowMs: Number(process.env.AUTH_RATE_LIMIT_WINDOW_MS || 900000),
  authRateLimitMax: Number(process.env.AUTH_RATE_LIMIT_MAX || 10),
  apiRateLimitWindowMs: Number(process.env.API_RATE_LIMIT_WINDOW_MS || 900000),
  apiRateLimitMax: Number(process.env.API_RATE_LIMIT_MAX || 100),
  mongoMaxRetries: Number(process.env.MONGO_MAX_RETRIES || 8),
  mongoInitialRetryDelayMs: Number(process.env.MONGO_INITIAL_RETRY_DELAY_MS || 1000),
  mongoMaxRetryDelayMs: Number(process.env.MONGO_MAX_RETRY_DELAY_MS || 15000),
  tempAuthEnabled: process.env.TEMP_AUTH_ENABLED === 'true',
  tempAuthName: process.env.TEMP_AUTH_NAME || 'Temporary User',
  tempAuthEmail: process.env.TEMP_AUTH_EMAIL || 'temp@local.dev',
  tempAuthPhone: process.env.TEMP_AUTH_PHONE || '9999999999',
  tempAuthPassword: process.env.TEMP_AUTH_PASSWORD || null,
};

if (!env.jwtSecret) {
  throw new Error('JWT_SECRET must be configured before starting the server.');
}

if (!env.jwtRefreshSecret) {
  throw new Error('JWT_REFRESH_SECRET must be configured before starting the server.');
}

module.exports = env;
