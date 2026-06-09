const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

const envPath = path.resolve(process.cwd(), '.env');
dotenv.config({ path: envPath });

const splitCsv = (value = '') => value.split(',').map((v) => v.trim()).filter(Boolean);

const requiredInAllEnvs = ['MONGO_URI', 'JWT_SECRET', 'JWT_REFRESH_SECRET'];
const missing = requiredInAllEnvs.filter((key) => !process.env[key]);
if (missing.length && process.env.NODE_ENV !== 'test') {
  throw new Error(`Missing required backend env vars: ${missing.join(', ')}`);
}

if (!fs.existsSync(envPath) && process.env.NODE_ENV !== 'test') {
  console.warn(`Backend .env not found at ${envPath}. Using process environment only.`);
}

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 5000),
  mongoUri: process.env.MONGO_URI,
  jwtSecret:
    process.env.JWT_SECRET ||
    (process.env.NODE_ENV === 'test' ? 'test-access-secret' : undefined),
  jwtRefreshSecret:
    process.env.JWT_REFRESH_SECRET ||
    (process.env.NODE_ENV === 'test' ? 'test-refresh-secret' : undefined),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  clientOrigins: splitCsv(process.env.CLIENT_ORIGINS),
  authRateLimitWindowMs: Number(process.env.AUTH_RATE_LIMIT_WINDOW_MS || 900000),
  authRateLimitMax: Number(process.env.AUTH_RATE_LIMIT_MAX || 20),
  apiRateLimitWindowMs: Number(process.env.API_RATE_LIMIT_WINDOW_MS || 900000),
  apiRateLimitMax: Number(process.env.API_RATE_LIMIT_MAX || 300),
  mongoMaxRetries: Number(process.env.MONGO_MAX_RETRIES || 8),
  mongoInitialRetryDelayMs: Number(process.env.MONGO_INITIAL_RETRY_DELAY_MS || 1000),
  mongoMaxRetryDelayMs: Number(process.env.MONGO_MAX_RETRY_DELAY_MS || 15000),
  tempAuthEnabled: process.env.TEMP_AUTH_ENABLED === 'true',
  tempAuthName: process.env.TEMP_AUTH_NAME || 'Temporary User',
  tempAuthEmail: process.env.TEMP_AUTH_EMAIL || 'temp@local.dev',
  tempAuthPhone: process.env.TEMP_AUTH_PHONE || '9999999999',
  tempAuthPassword: process.env.TEMP_AUTH_PASSWORD || '',
  openAiApiKey: process.env.OPENAI_API_KEY || '',
  openAiModel: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
  cloudinaryCloudName: process.env.CLOUDINARY_CLOUD_NAME || '',
  cloudinaryApiKey: process.env.CLOUDINARY_API_KEY || '',
  cloudinaryApiSecret: process.env.CLOUDINARY_API_SECRET || '',
  fcmServiceAccountJson: process.env.FCM_SERVICE_ACCOUNT_JSON || '',
  requestTimeoutMs: Number(process.env.REQUEST_TIMEOUT_MS || 20000),
};
