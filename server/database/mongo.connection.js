const mongoose = require('mongoose');

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const connectMongo = async ({
  mongoUri,
  maxRetries = 8,
  initialDelayMs = 1000,
  maxDelayMs = 15000,
}) => {
  let attempt = 0;

  while (attempt <= maxRetries) {
    try {
      await mongoose.connect(mongoUri, {
        serverSelectionTimeoutMS: 5000,
      });
      console.log('MongoDB connected');
      return;
    } catch (error) {
      attempt += 1;
      if (attempt > maxRetries) {
        throw error;
      }

      const backoffDelay = Math.min(
        initialDelayMs * 2 ** (attempt - 1),
        maxDelayMs
      );
      console.error(
        `MongoDB connection failed (attempt ${attempt}/${maxRetries}). Retrying in ${backoffDelay}ms`
      );
      await wait(backoffDelay);
    }
  }
};

const disconnectMongo = async () => {
  try {
    await mongoose.connection.close();
    console.log('MongoDB disconnected');
  } catch (error) {
    console.error('MongoDB disconnect error:', error.message);
  }
};

module.exports = {
  connectMongo,
  disconnectMongo,
};
