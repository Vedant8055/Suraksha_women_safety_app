const mongoose = require('mongoose');

const connectDb = async (mongoUri) => {
  if (!mongoUri) throw new Error('MONGO_URI is missing');
  await mongoose.connect(mongoUri);
  return mongoose.connection;
};

module.exports = { connectDb };
