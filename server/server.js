const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const dotenv = require('dotenv');

dotenv.config();

const env = require('./config/env');
const { resolveAvailablePort } = require('./config/port');
const { connectMongo, disconnectMongo } = require('./database/mongo.connection');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');
const { createRateLimiter } = require('./middleware/rateLimitMiddleware');
const { isTempAuthActive } = require('./utils/tempAuth');

const app = express();
app.set('trust proxy', 1);
const allowedOrigins = env.clientOrigins;
const corsOptions = {
  origin(origin, callback) {
    if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
const server = http.createServer(app);
const io = socketIo(server, {
  cors: corsOptions,
});

// Middleware
app.use(cors(corsOptions));
app.use(helmet());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

const apiRateLimiter = createRateLimiter({
  windowMs: env.apiRateLimitWindowMs,
  max: env.apiRateLimitMax,
  message: 'Too many requests. Please try again later.',
});

const authRateLimiter = createRateLimiter({
  windowMs: env.authRateLimitWindowMs,
  max: env.authRateLimitMax,
  message: 'Too many authentication attempts. Please retry later.',
});

// Socket.IO Logic
require('./sockets/sosSocket')(io);

// Routes
const authRoutes = require('./routes/authRoutes');
const cyberCrimeRoutes = require('./routes/cyberCrimeRoutes');
const liveSosRoutes = require('./routes/liveSosRoutes');
app.use(liveSosRoutes);
app.use('/api', apiRateLimiter);
app.use('/api/auth', authRateLimiter, authRoutes);
app.use('/api/cybercrime', cyberCrimeRoutes);

app.get('/', (req, res) => {
  res.send('Suraksha Backend API is running...');
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'suraksha-backend',
    timestamp: new Date().toISOString(),
  });
});

app.get('/ready', (req, res) => {
  const dbReadyState = mongoose.connection.readyState;
  const isDbReady = dbReadyState === 1;

  if (!isDbReady) {
    if (isTempAuthActive()) {
      return res.status(200).json({
        status: 'degraded',
        database: 'disconnected',
        tempAuth: 'enabled',
        timestamp: new Date().toISOString(),
      });
    }

    return res.status(503).json({
      status: 'not_ready',
      database: 'disconnected',
      timestamp: new Date().toISOString(),
    });
  }

  return res.status(200).json({
    status: 'ready',
    database: 'connected',
    timestamp: new Date().toISOString(),
  });
});

app.use(notFound);
app.use(errorHandler);

let activeServerPort = null;
let shuttingDown = false;

const gracefulShutdown = async (signal) => {
  if (shuttingDown) {
    return;
  }

  shuttingDown = true;
  console.log(`${signal} received. Starting graceful shutdown...`);

  io.close(() => {
    console.log('Socket server closed');
  });

  server.close(async () => {
    console.log('HTTP server closed');
    await disconnectMongo();
    process.exit(0);
  });

  setTimeout(async () => {
    console.error('Force shutdown triggered');
    await disconnectMongo();
    process.exit(1);
  }, 10000).unref();
};

const startServer = async () => {
  const tempAuthActive = isTempAuthActive();

  try {
    await connectMongo({
      mongoUri: env.mongoUri,
      maxRetries: tempAuthActive ? 1 : env.mongoMaxRetries,
      initialDelayMs: tempAuthActive ? 500 : env.mongoInitialRetryDelayMs,
      maxDelayMs: env.mongoMaxRetryDelayMs,
    });
  } catch (error) {
    if (!tempAuthActive) {
      throw error;
    }

    console.error('MongoDB connection failed. Starting with TEMP_AUTH fallback.');
  }

  activeServerPort = await resolveAvailablePort(env.port);
  if (activeServerPort !== env.port) {
    console.warn(
      `Preferred port ${env.port} is busy. Falling back to port ${activeServerPort}`
    );
  }

  await new Promise((resolve) => {
    server.listen(activeServerPort, () => {
      console.log(`Server running on port ${activeServerPort}`);
      resolve();
    });
  });
};

process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

startServer().catch(async (error) => {
  console.error('Fatal startup error:', error);
  await disconnectMongo();
  process.exit(1);
});
