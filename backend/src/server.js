const http = require('http');
const mongoose = require('mongoose');
const { app } = require('./app');
const env = require('./config/env');
const { connectDb } = require('./config/db');
const { setupSockets } = require('./sockets');
const { startSafetyDataSyncJob } = require('./jobs/safetyDataSyncJob');

const start = async () => {
  const server = http.createServer(app);
  server.requestTimeout = env.requestTimeoutMs;
  server.headersTimeout = env.requestTimeoutMs + 5000;
  setupSockets(server);
  startSafetyDataSyncJob();
  server.listen(env.port, () => {
    console.log(`Backend running on ${env.port}`);
  });

  void connectDb(env.mongoUri, {
    maxRetries: env.mongoMaxRetries,
    initialDelayMs: env.mongoInitialRetryDelayMs,
    maxDelayMs: env.mongoMaxRetryDelayMs,
    dnsServers: env.mongoDnsServers,
  })
    .then(() => {
      console.log('MongoDB connected');
    })
    .catch((error) => {
      console.warn(
        `MongoDB unavailable; continuing in degraded mode. ${error.message}`,
      );
    });

  const shutdown = async (signal) => {
    console.log(`${signal} received. Closing backend gracefully...`);
    server.close(async () => {
      try {
        if (mongoose.connection.readyState !== 0) {
          await mongoose.connection.close();
        }
      } finally {
        process.exit(0);
      }
    });
  };

  process.on('SIGINT', () => {
    void shutdown('SIGINT');
  });
  process.on('SIGTERM', () => {
    void shutdown('SIGTERM');
  });
};

start().catch((e) => {
  console.error('Startup failed:', e.message);
  process.exit(1);
});
