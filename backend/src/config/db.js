const mongoose = require('mongoose');

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const connectDb = async (mongoUri, options = {}) => {
  if (!mongoUri) throw new Error('MONGO_URI is missing');
  const {
    maxRetries = 1,
    initialDelayMs = 1000,
    maxDelayMs = 15000,
  } = options;

  let attempt = 0;
  let delayMs = initialDelayMs;
  while (attempt < maxRetries) {
    try {
      await mongoose.connect(mongoUri);
      return mongoose.connection;
    } catch (error) {
      attempt += 1;
      if (attempt >= maxRetries) throw error;
      console.error(`MongoDB connection failed. Retrying in ${delayMs}ms...`);
      await wait(delayMs);
      delayMs = Math.min(delayMs * 2, maxDelayMs);
    }
  }

  return mongoose.connection;
};

module.exports = { connectDb };
