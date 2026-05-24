const cloudinary = require('cloudinary').v2;
const env = require('../config/env');

if (env.cloudinaryCloudName && env.cloudinaryApiKey && env.cloudinaryApiSecret) {
  cloudinary.config({ cloud_name: env.cloudinaryCloudName, api_key: env.cloudinaryApiKey, api_secret: env.cloudinaryApiSecret });
}

const uploadToCloudinary = async (filePath, folder = 'suraksha') => {
  if (!env.cloudinaryCloudName) {
    return { secure_url: filePath };
  }
  return cloudinary.uploader.upload(filePath, { folder, resource_type: 'auto' });
};

module.exports = { uploadToCloudinary };
