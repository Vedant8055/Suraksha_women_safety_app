const dotenv = require('dotenv');
dotenv.config({ path: '.env' });

const splitCsv = (value = '') => value.split(',').map((v) => v.trim()).filter(Boolean);

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 5000),
  mongoUri: process.env.MONGO_URI,
  jwtSecret: process.env.JWT_SECRET,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
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
};
