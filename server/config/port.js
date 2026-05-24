const net = require('net');

const isPortAvailable = (port) =>
  new Promise((resolve) => {
    const tester = net.createServer();

    tester.once('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        resolve(false);
        return;
      }
      resolve(false);
    });

    tester.once('listening', () => {
      tester.close(() => resolve(true));
    });

    tester.listen(port, '0.0.0.0');
  });

const resolveAvailablePort = async (preferredPort, maxAttempts = 20) => {
  let candidate = Number(preferredPort);
  if (!Number.isInteger(candidate) || candidate <= 0) {
    candidate = 5000;
  }

  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const nextPort = candidate + attempt;
    const available = await isPortAvailable(nextPort);
    if (available) {
      return nextPort;
    }
  }

  throw new Error(
    `Unable to resolve an open port after ${maxAttempts} attempts starting at ${candidate}.`
  );
};

module.exports = {
  resolveAvailablePort,
};
