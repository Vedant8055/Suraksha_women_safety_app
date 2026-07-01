const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { apiLimiter, authLimiter } = require('./middleware/rateLimit');
const { errorHandler } = require('./middleware/error');
const env = require('./config/env');

const authRoutes = require('./routes/authRoutes');
const sosRoutes = require('./routes/sosRoutes');
const locationRoutes = require('./routes/locationRoutes');
const incidentRoutes = require('./routes/incidentRoutes');
const cyberCrimeRoutes = require('./routes/cyberCrimeRoutes');
const nearbyRoutes = require('./routes/nearbyRoutes');
const aiRoutes = require('./routes/aiRoutes');
const mediaRoutes = require('./routes/mediaRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const profileRoutes = require('./routes/profileRoutes');
const liveSosRoutes = require('./routes/liveSosRoutes');
const safetyIntelligenceRoutes = require('./routes/safetyIntelligenceRoutes');
const safetyRoutes = require('./routes/safetyRoutes');

const app = express();
app.use(helmet());
app.use(cors({ origin: env.clientOrigins.length ? env.clientOrigins : true }));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));
app.use((req, res, next) => {
  res.setTimeout(env.requestTimeoutMs);
  next();
});
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));

app.get('/health', (req, res) => res.json({ status: 'ok', at: new Date().toISOString() }));
app.use(liveSosRoutes);

app.use('/api', apiLimiter);
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/incident', incidentRoutes);
app.use('/api/cybercrime', cyberCrimeRoutes);
app.use('/api/nearby', nearbyRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/media', mediaRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/safety-intelligence', safetyIntelligenceRoutes);
app.use('/api/safety', safetyRoutes);

app.use(errorHandler);
module.exports = { app };
