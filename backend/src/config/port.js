const net = require('net');

const isPortAvailable = (port) =>
  new Promise((resolve) => {
    const server = net.createServer();
    server.once('error', () => resolve(false));
    server.once('listening', () => {
      server.close(() => resolve(true));
    });
    server.listen(port);
  });

const resolveAvailablePort = async (preferredPort, maxAttempts = 20) => {
  for (let offset = 0; offset < maxAttempts; offset += 1) {
    const port = preferredPort + offset;
    if (await isPortAvailable(port)) {
      return port;
    }
  }

  throw new Error(`No available port found from ${preferredPort}`);
};

module.exports = {
  resolveAvailablePort,
};
