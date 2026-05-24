const http = require('http');
const { app } = require('./app');
const env = require('./config/env');
const { connectDb } = require('./config/db');
const { setupSockets } = require('./sockets');

const start = async () => {
  await connectDb(env.mongoUri);
  const server = http.createServer(app);
  setupSockets(server);
  server.listen(env.port, () => {
    console.log(`Backend running on ${env.port}`);
  });
};

start().catch((e) => {
  console.error('Startup failed:', e.message);
  process.exit(1);
});
